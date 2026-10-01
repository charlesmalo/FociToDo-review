#!/usr/bin/env bash
# Image vulnerabilities (Trivy), Dockerfile lint (Hadolint), dependency audit (npm).
#
# Exit-code contract per scanner (verified against the pinned image versions below —
# see task-5-report.md "Fix round 1" for the commands): a scanner's own "findings
# present" exit code is accepted only when its evidence file actually looks like a
# real report; any other exit code, or a report-shaped exit code with no real report
# (e.g. a registry/network failure), fails this script loudly, naming the scanner.
set -euo pipefail
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
EVIDENCE="evidence/${STAMP}/scans"
APP="work/app"
TRIVY_CACHE="work/trivy-cache"
mkdir -p "${EVIDENCE}" "${TRIVY_CACHE}" work
[ -d "${APP}" ] || git clone --quiet "${APP_REPO}" "${APP}"
git -C "${APP}" fetch --quiet && git -C "${APP}" checkout --quiet "${APP_REF}"

fail() {
  echo "scans.sh: $1" >&2
  exit 1
}

(cd "${APP}" && docker compose -p review-scan build api web >/dev/null)

# Trivy (aquasec/trivy:0.75.0, no --exit-code flag): exits 0 whether or not
# vulnerabilities were found, and only exits non-zero (1) on a genuine scan error
# (bad image ref, can't reach the Docker daemon, DB pull failure, etc.) — so `set -e`
# already fails the script loudly on a real Trivy error. We additionally require a
# non-empty evidence file (Trivy always prints a "Report Summary", even at 0 findings).
for image in review-scan-api review-scan-web; do
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${HOST_DIR}/${TRIVY_CACHE}:/root/.cache/" \
    aquasec/trivy:0.75.0 \
    image --quiet --severity HIGH,CRITICAL --ignore-unfixed "${image}" \
    | tee "${EVIDENCE}/trivy-${image}.txt"
  [ -s "${EVIDENCE}/trivy-${image}.txt" ] || fail "trivy produced no output for ${image}"
done

# Every Dockerfile the shipped images (api, web) are built from — one evidence file each.
# (The app ships a single multi-stage Dockerfile; both the api and web targets build from it.)
#
# Hadolint (hadolint/hadolint:v2.15.1): exits 0 when it reports nothing, 1 when it
# reports at least one rule at/above its default failure-threshold (info) — verified
# empirically against this Dockerfile (exit 1, 3 lines of output) and a one-line clean
# Dockerfile (exit 0, no output). A bad image reference or daemon error exits elsewhere
# (125/127) and is never swallowed here.
set +e
docker run --rm -i hadolint/hadolint:v2.15.1 < "${APP}/Dockerfile" | tee "${EVIDENCE}/hadolint-Dockerfile.txt"
hadolint_exit="${PIPESTATUS[0]}"
set -e
case "${hadolint_exit}" in
  0) ;; # clean
  1) [ -s "${EVIDENCE}/hadolint-Dockerfile.txt" ] || fail "hadolint exited 1 (findings) but its evidence file is empty" ;;
  *) fail "hadolint exited ${hadolint_exit} (expected 0=clean or 1=findings) — scanner failure" ;;
esac

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
