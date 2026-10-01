#!/usr/bin/env bash
# Fresh app stack per scenario → k6 → invariants → evidence.
set -euo pipefail
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
EVIDENCE="evidence/${STAMP}/stress"
APP="work/app"
mkdir -p "${EVIDENCE}" work
[ -d "${APP}" ] || git clone --quiet "${APP_REPO}" "${APP}"
git -C "${APP}" fetch --quiet && git -C "${APP}" checkout --quiet "${APP_REF}"

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
  (cd "${APP}" && docker compose -p review-stress up -d --build >/dev/null)
  wait_healthy
  docker run --rm --network review-stress_default -v "${HOST_DIR}:${HOST_DIR}" -w "${HOST_DIR}" \
    grafana/k6:1.3.0 run --quiet --summary-export "${EVIDENCE}/${scenario}.json" "k6/${scenario}.js" \
    > "${EVIDENCE}/${scenario}.log" 2>&1 || status=1
  docker run --rm --network review-stress_default -v "${HOST_DIR}:${HOST_DIR}" -w "${HOST_DIR}" \
    node:24.21-alpine node scripts/invariants.mjs "${scenario}" "${EVIDENCE}/${scenario}.json" http://web:8080/api \
    | tee "${EVIDENCE}/${scenario}.invariants.txt" || status=1
  (cd "${APP}" && docker compose -p review-stress down -v >/dev/null)
done
exit $status
