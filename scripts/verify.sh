#!/usr/bin/env bash
# Clean clone of APP_REPO@APP_REF → cold build → healthy stack → test gate → e2e → evidence.
set -euo pipefail

STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
EVIDENCE="evidence/${STAMP}"
APP="work/app"
mkdir -p "${EVIDENCE}" work
rm -rf "${APP}"

git clone --quiet "${APP_REPO}" "${APP}"
git -C "${APP}" checkout --quiet "${APP_REF}"
SHA="$(git -C "${APP}" rev-parse HEAD)"
echo "Verifying ${APP_REPO} @ ${SHA}" | tee "${EVIDENCE}/summary.md"

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

start=$(date +%s)
compose build --no-cache --pull > "../../${EVIDENCE}/build.log" 2>&1
compose up -d > "../../${EVIDENCE}/up.log" 2>&1
wait_healthy
ready=$(( $(date +%s) - start ))
echo "- Cold build → healthy stack: ${ready}s ($(uname -m))" | tee -a "../../${EVIDENCE}/summary.md"
compose ps --format json > "../../${EVIDENCE}/services.json"
compose down -v > /dev/null 2>&1

set +e
docker compose -p review-test --profile test run --rm --build test > "../../${EVIDENCE}/test-gate.log" 2>&1
gate=$?
docker compose -p review-test --profile test down -v > /dev/null 2>&1
docker compose -p review-e2e -f compose.yaml -f compose.e2e.yaml run --rm --build e2e > "../../${EVIDENCE}/e2e.log" 2>&1
e2e=$?
docker compose -p review-e2e -f compose.yaml -f compose.e2e.yaml down -v > /dev/null 2>&1
set -e

cp -R reports "../../${EVIDENCE}/reports" 2>/dev/null || true
cd ../..
echo "- Test gate (lint, typecheck, tests, 100% coverage): $([ $gate -eq 0 ] && echo PASS || echo FAIL)" | tee -a "${EVIDENCE}/summary.md"
echo "- End-to-end: $([ $e2e -eq 0 ] && echo PASS || echo FAIL)" | tee -a "${EVIDENCE}/summary.md"
jq -r '.total | "- Coverage: lines \(.lines.pct)%, statements \(.statements.pct)%, functions \(.functions.pct)%, branches \(.branches.pct)%"' \
  "${EVIDENCE}/reports/coverage/coverage-summary.json" >> "${EVIDENCE}/summary.md" || true
exit $(( gate || e2e ))
