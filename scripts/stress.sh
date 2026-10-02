#!/usr/bin/env bash
# Fresh app stack per scenario → k6 → invariants → evidence.
set -euo pipefail
: "${APP_REPO:?set APP_REPO (see .env.example)}"
: "${APP_REF:?set APP_REF (see .env.example)}"
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
EVIDENCE="evidence/${STAMP}/stress"
APP="work/app"
mkdir -p "${EVIDENCE}" work

fail() {
  echo "stress.sh: $1" >&2
  exit 1
}

# Fresh clone every run, so a branch name can never resolve to a stale local checkout.
rm -rf "${APP}"
git clone --quiet "${APP_REPO}" "${APP}" || fail "git clone of ${APP_REPO} failed"
git -C "${APP}" checkout --quiet "${APP_REF}" || fail "cannot check out APP_REF=${APP_REF} from ${APP_REPO}"
SHA="$(git -C "${APP}" rev-parse HEAD)"
echo "Stressing ${APP_REPO} @ ${SHA}" | tee "${EVIDENCE}/summary.md"

wait_healthy() {
  for _ in $(seq 1 180); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$(cd "${APP}" && docker compose -p review-stress ps -q web)" 2>/dev/null)" = healthy ] && return 0
    sleep 1
  done
  return 1
}

teardown() {
  (cd "${APP}" && docker compose -p review-stress down -v >/dev/null 2>&1) || true
}
trap teardown EXIT

status=0
for scenario in race-patch parallel-complete delete-storm idempotent-replay mixed-load; do
  (cd "${APP}" && docker compose -p review-stress up -d --build > "../../${EVIDENCE}/${scenario}.up.log" 2>&1) \
    || fail "${scenario}: compose up failed — see ${EVIDENCE}/${scenario}.up.log (is host port ${WEB_PORT:-8080} already in use? stop whatever holds it, or pass -e WEB_PORT=<free port>)"
  wait_healthy || fail "${scenario}: web did not become healthy within 180 s — see ${EVIDENCE}/${scenario}.up.log"
  k6=PASS
  docker run --rm --network review-stress_default -v "${HOST_DIR}:${HOST_DIR}" -w "${HOST_DIR}" \
    grafana/k6:1.3.0 run --quiet --summary-export "${EVIDENCE}/${scenario}.json" "k6/${scenario}.js" \
    > "${EVIDENCE}/${scenario}.log" 2>&1 || k6=FAIL
  invariants=PASS
  docker run --rm --network review-stress_default -v "${HOST_DIR}:${HOST_DIR}" -w "${HOST_DIR}" \
    node:24.21-alpine node scripts/invariants.mjs "${scenario}" "${EVIDENCE}/${scenario}.json" http://web:8080/api \
    | tee "${EVIDENCE}/${scenario}.invariants.txt" || invariants=FAIL
  verdict=$([ "${k6}${invariants}" = PASSPASS ] && echo PASS || echo FAIL)
  [ "${verdict}" = PASS ] || status=1
  echo "- ${scenario}: ${verdict} (k6 checks/thresholds ${k6}, invariants ${invariants})" | tee -a "${EVIDENCE}/summary.md"
  (cd "${APP}" && docker compose -p review-stress down -v >/dev/null)
done
echo "- Overall: $([ ${status} -eq 0 ] && echo PASS || echo FAIL)" | tee -a "${EVIDENCE}/summary.md"
exit $status
