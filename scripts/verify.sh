#!/usr/bin/env bash
# Clean clone of APP_REPO@APP_REF → --no-cache rebuild → healthy stack → test gate → e2e → evidence.
set -euo pipefail
: "${APP_REPO:?set APP_REPO (see .env.example)}"
: "${APP_REF:?set APP_REF (see .env.example)}"

STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
ROOT="${PWD}"
EVIDENCE="evidence/${STAMP}"
APP="work/app"
mkdir -p "${EVIDENCE}" work

fail() {
  echo "verify.sh: $1" >&2
  exit 1
}

# Tear down every stack this script may have started, however it exits.
cleanup() {
  [ -f "${ROOT}/${APP}/compose.yaml" ] || return 0
  (
    cd "${ROOT}/${APP}"
    docker compose -p review-verify down -v --remove-orphans
    docker compose -p review-test --profile test down -v --remove-orphans
    docker compose -p review-e2e -f compose.yaml -f compose.e2e.yaml down -v --remove-orphans
  ) > /dev/null 2>&1 || true
}
trap cleanup EXIT

rm -rf "${APP}"
git clone --quiet "${APP_REPO}" "${APP}" || fail "git clone of ${APP_REPO} failed"
git -C "${APP}" checkout --quiet "${APP_REF}" || fail "cannot check out APP_REF=${APP_REF} from ${APP_REPO}"
SHA="$(git -C "${APP}" rev-parse HEAD)"
echo "Verifying ${APP_REPO} @ ${SHA}" | tee "${EVIDENCE}/summary.md"

case "$(uname -m)" in
  aarch64 | arm64) ARCH=arm64 ;;
  x86_64 | amd64) ARCH=amd64 ;;
  *) ARCH="$(uname -m)" ;;
esac

cd "${APP}"
compose() { docker compose -p review-verify "$@"; }
# web is healthy only after db → migrate → api are (Compose depends_on chain).
# (`up --wait` is avoided: it can fail when the one-shot migrate container exits.)
wait_healthy() {
  for _ in $(seq 1 180); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$(compose ps -q web)" 2>/dev/null)" = healthy ] && return 0
    sleep 1
  done
  return 1
}

# --no-cache rebuilds every app layer from the fresh clone, but base images already on this
# machine and the Dockerfile's npm cache mount (--mount=type=cache) stay warm, so this is a
# clean-clone rebuild time, not a cold-machine time.
start=$(date +%s)
compose build --no-cache --pull > "${ROOT}/${EVIDENCE}/build.log" 2>&1 \
  || fail "image build failed — see ${EVIDENCE}/build.log"
compose up -d > "${ROOT}/${EVIDENCE}/up.log" 2>&1 \
  || fail "compose up failed — see ${EVIDENCE}/up.log (is host port ${WEB_PORT:-8080} already in use? stop whatever holds it, or pass -e WEB_PORT=<free port>)"
if ! wait_healthy; then
  { compose ps -a; compose logs --no-color; } > "${ROOT}/${EVIDENCE}/health-timeout.log" 2>&1 || true
  fail "web did not become healthy within 180 s — see ${EVIDENCE}/up.log and ${EVIDENCE}/health-timeout.log"
fi
ready=$(( $(date +%s) - start ))
echo "- Clean-clone rebuild → healthy: ${ready} s (${ARCH}; base images and npm cache warm)" | tee -a "${ROOT}/${EVIDENCE}/summary.md"
compose ps --format json > "${ROOT}/${EVIDENCE}/services.json"
compose down -v > /dev/null 2>&1

set +e
docker compose -p review-test --profile test run --rm --build test > "${ROOT}/${EVIDENCE}/test-gate.log" 2>&1
gate=$?
docker compose -p review-test --profile test down -v > /dev/null 2>&1
docker compose -p review-e2e -f compose.yaml -f compose.e2e.yaml run --rm --build e2e > "${ROOT}/${EVIDENCE}/e2e.log" 2>&1
e2e=$?
docker compose -p review-e2e -f compose.yaml -f compose.e2e.yaml down -v > /dev/null 2>&1
set -e

# Evidence keeps only the two reports the summary cites: the coverage totals and the
# Playwright HTML report. (The full coverage HTML tree stays in work/app/reports.)
mkdir -p "${ROOT}/${EVIDENCE}/reports/coverage" "${ROOT}/${EVIDENCE}/reports/e2e"
cp reports/coverage/coverage-summary.json "${ROOT}/${EVIDENCE}/reports/coverage/" 2>/dev/null \
  || echo "verify.sh: no reports/coverage/coverage-summary.json — see ${EVIDENCE}/test-gate.log" >&2
cp reports/e2e/index.html "${ROOT}/${EVIDENCE}/reports/e2e/" 2>/dev/null \
  || echo "verify.sh: no reports/e2e/index.html — see ${EVIDENCE}/e2e.log" >&2
cd "${ROOT}"
echo "- Test gate (lint, typecheck, tests, 100% coverage): $([ $gate -eq 0 ] && echo PASS || echo FAIL)" | tee -a "${EVIDENCE}/summary.md"
echo "- End-to-end: $([ $e2e -eq 0 ] && echo PASS || echo FAIL)" | tee -a "${EVIDENCE}/summary.md"
jq -r '.total | "- Coverage: lines \(.lines.pct)%, statements \(.statements.pct)%, functions \(.functions.pct)%, branches \(.branches.pct)%"' \
  "${EVIDENCE}/reports/coverage/coverage-summary.json" 2>/dev/null | tee -a "${EVIDENCE}/summary.md" \
  || echo "- Coverage: unavailable (no coverage-summary.json)" | tee -a "${EVIDENCE}/summary.md"
exit $(( gate || e2e ))
