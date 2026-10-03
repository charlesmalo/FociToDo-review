#!/usr/bin/env bash
# Independent UI storyboard: clean clone → app stack without a host port → Playwright journeys
# (storyboard/journeys/*.spec.ts) → captioned frames beside docs/ui.md's wireframes → evidence.
# Never uses the app's own tests.
set -Eeuo pipefail
: "${APP_REPO:?set APP_REPO (see .env.example)}"
: "${APP_REF:?set APP_REF (see .env.example)}"
ROOT="$(pwd)"
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
OUT="evidence/${STAMP}/storyboard"
APP="work/app-storyboard"
PROJECT=review-storyboard
mkdir -p "${OUT}" work

fail() {
  echo "storyboard.sh: $1" >&2
  exit 1
}

rm -rf "${APP}"
git clone --quiet "${APP_REPO}" "${APP}" || fail "git clone of ${APP_REPO} failed"
git -C "${APP}" checkout --quiet "${APP_REF}" || fail "cannot check out APP_REF=${APP_REF}"
SHA="$(git -C "${APP}" rev-parse HEAD)"

app_compose() { (cd "${APP}" && docker compose -p "${PROJECT}" -f compose.yaml -f "${ROOT}/harness/no-host-port.yaml" "$@"); }

teardown() {
  app_compose down -v --remove-orphans > /dev/null 2>&1 || true
}
trap teardown EXIT
trap 'echo "storyboard.sh: unexpected error at line ${LINENO}" >&2' ERR

wait_healthy() {
  for _ in $(seq 1 180); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$(app_compose ps -q web)" 2> /dev/null)" = healthy ] && return 0
    sleep 1
  done
  return 1
}

app_compose down -v --remove-orphans > /dev/null 2>&1 || true
app_compose up -d --build > "${OUT}/up.log" 2>&1 || fail "compose up failed — see ${OUT}/up.log"
wait_healthy || { app_compose logs --no-color > "${OUT}/health-timeout.log" 2>&1 || true; fail "web did not become healthy within 180 s — see ${OUT}/health-timeout.log"; }

docker build -q -t foci-review-storyboard-pw storyboard > /dev/null || fail "storyboard image build failed"
docker run --rm --network "${PROJECT}_default" \
  -e BASE_URL=http://web:8080 -e OUT=/out -e APP_DIAGRAMS=/app-diagrams -e APP_SHA="${SHA}" \
  -v "${HOST_DIR}/${OUT}:/out" -v "${HOST_DIR}/${APP}/docs/diagrams:/app-diagrams:ro" \
  foci-review-storyboard-pw > "${OUT}/playwright.log" 2>&1 \
  || fail "storyboard run failed — see ${OUT}/playwright.log"
echo "Storyboard of ${APP_REPO} @ ${SHA}: $(tail -n 1 "${OUT}/playwright.log")" | tee "${OUT}/summary.md"
