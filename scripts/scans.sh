#!/usr/bin/env bash
# Image vulnerabilities (Trivy), Dockerfile lint (Hadolint), dependency audit (npm).
#
# This script collects evidence; it does not judge it. It exits 0 when the scanners ran
# and wrote real reports, findings or not — triage lives in findings/log.md.
#
# Exit-code contract per scanner (verified against the pinned image versions below —
# see task-5-report.md "Fix round 1" for the commands): a scanner's own "findings
# present" exit code is accepted only when its evidence file actually looks like a
# real report; any other exit code, or a report-shaped exit code with no real report
# (e.g. a registry/network failure), fails this script loudly, naming the scanner.
set -euo pipefail
: "${APP_REPO:?set APP_REPO (see .env.example)}"
: "${APP_REF:?set APP_REF (see .env.example)}"
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
EVIDENCE="evidence/${STAMP}/scans"
APP="work/app"
TRIVY_CACHE="work/trivy-cache"
mkdir -p "${EVIDENCE}" "${TRIVY_CACHE}" work

fail() {
  echo "scans.sh: $1" >&2
  exit 1
}

# Fresh clone every run, so a branch name can never resolve to a stale local checkout.
rm -rf "${APP}"
git clone --quiet "${APP_REPO}" "${APP}" || fail "git clone of ${APP_REPO} failed"
git -C "${APP}" checkout --quiet "${APP_REF}" || fail "cannot check out APP_REF=${APP_REF} from ${APP_REPO}"
SHA="$(git -C "${APP}" rev-parse HEAD)"
echo "Scanning ${APP_REPO} @ ${SHA}" | tee "${EVIDENCE}/summary.md"

(cd "${APP}" && docker compose -p review-scan build api web >/dev/null) || fail "building the api/web images failed"
# The database image the app's compose.yaml pins (shipped unmodified, so scanned as-is).
DB_IMAGE="$(cd "${APP}" && docker compose config --format json | jq -r '.services.db.image // empty')"
[ -n "${DB_IMAGE}" ] || fail "could not read services.db.image from the app's compose.yaml"
docker pull --quiet "${DB_IMAGE}" >/dev/null || fail "docker pull ${DB_IMAGE} failed"

# Trivy (aquasec/trivy:0.75.0, no --exit-code flag): exits 0 whether or not
# vulnerabilities were found, and only exits non-zero (1) on a genuine scan error
# (bad image ref, can't reach the Docker daemon, DB pull failure, etc.), which fails
# this script loudly, naming the image. We additionally require a non-empty evidence
# file (Trivy always prints a "Report Summary", even at 0 findings). Scanned: the two
# images built from the app's Dockerfile, plus the database image its compose.yaml pins.
for image in review-scan-api review-scan-web "${DB_IMAGE}"; do
  report="${EVIDENCE}/trivy-${image//[:\/]/-}.txt"
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${HOST_DIR}/${TRIVY_CACHE}:/root/.cache/" \
    aquasec/trivy:0.75.0 \
    image --quiet --severity HIGH,CRITICAL --ignore-unfixed "${image}" \
    | tee "${report}" || fail "trivy failed scanning ${image}"
  [ -s "${report}" ] || fail "trivy produced no output for ${image}"
  total="$(awk '/^Total: [0-9]+/ { sum += $2 } END { print sum + 0 }' "${report}")"
  echo "- Trivy ${image}: ${total} HIGH/CRITICAL with a fix available — $(basename "${report}")" >> "${EVIDENCE}/summary.md"
done

# Every Dockerfile the shipped images (api, web) are built from — one evidence file each.
# (The app ships a single multi-stage Dockerfile; both the api and web targets build from it.)
#
# Hadolint (hadolint/hadolint:v2.15.1): exits 0 when it reports nothing, 1 when it
# reports at least one rule at/above its default failure-threshold (info) — verified
# empirically against this Dockerfile (exit 1, 3 lines of output) and a one-line clean
# Dockerfile (exit 0, no output). A bad image reference or daemon error exits elsewhere
# (125/127) and is never swallowed here. --no-color keeps the evidence free of ANSI escapes.
set +e
docker run --rm -i hadolint/hadolint:v2.15.1 hadolint --no-color - < "${APP}/Dockerfile" | tee "${EVIDENCE}/hadolint-Dockerfile.txt"
hadolint_exit="${PIPESTATUS[0]}"
set -e
case "${hadolint_exit}" in
  0) ;; # clean
  1) [ -s "${EVIDENCE}/hadolint-Dockerfile.txt" ] || fail "hadolint exited 1 (findings) but its evidence file is empty" ;;
  *) fail "hadolint exited ${hadolint_exit} (expected 0=clean or 1=findings) — scanner failure" ;;
esac
echo "- Hadolint Dockerfile: $(grep -c . "${EVIDENCE}/hadolint-Dockerfile.txt" || true) findings — hadolint-Dockerfile.txt" >> "${EVIDENCE}/summary.md"

# npm audit (npm bundled with node:24.21-alpine): exits 0 when nothing meets
# --audit-level, 1 when something does — but ALSO exits 1 on a registry/network
# failure (verified with --network none: stdout is just the literal string
# "undefined", exit 1, with the real error on stderr), which `|| true` would
# otherwise swallow as if it were a clean/triaged run. A real report always starts
# with the literal line "# npm audit report" or (clean) "found 0 vulnerabilities";
# anything else at exit 1 is treated as a scanner failure, not a finding.
set +e
docker run --rm -v "${HOST_DIR}/${APP}:/app" -w /app node:24.21-alpine \
  npm audit --omit=dev --audit-level=high | tee "${EVIDENCE}/npm-audit.txt"
audit_exit="${PIPESTATUS[0]}"
set -e
case "${audit_exit}" in
  0) ;; # clean
  1)
    grep -q -e '^# npm audit report$' -e 'found 0 vulnerabilities' "${EVIDENCE}/npm-audit.txt" \
      || fail "npm audit exited 1 but its evidence file isn't a real audit report (registry/network failure?)"
    ;;
  *) fail "npm audit exited ${audit_exit} (expected 0=clean or 1=vulnerabilities found) — scanner failure" ;;
esac
audit_line="$(grep -E -m 1 'found 0 vulnerabilities|severity vulnerabilit' "${EVIDENCE}/npm-audit.txt" || echo 'see report')"
echo "- npm audit --omit=dev --audit-level=high: ${audit_line} — npm-audit.txt" >> "${EVIDENCE}/summary.md"
cat "${EVIDENCE}/summary.md"
