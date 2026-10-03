#!/usr/bin/env bash
# Independent black-box acceptance: clean clone → app stack without a host port → curl checks
# from acceptance/expectations.md → evidence. Never uses the app's own tests.
set -euo pipefail
: "${APP_REPO:?set APP_REPO (see .env.example)}"
: "${APP_REF:?set APP_REF (see .env.example)}"
ROOT="$(pwd)"
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
OUT="evidence/${STAMP}/acceptance"
APP="work/app-acceptance"
PROJECT=review-acceptance
SELF="$(hostname)"
mkdir -p "${OUT}/transcripts" work

fail() {
  echo "acceptance.sh: $1" >&2
  exit 1
}

rm -rf "${APP}"
git clone --quiet "${APP_REPO}" "${APP}" || fail "git clone of ${APP_REPO} failed"
git -C "${APP}" checkout --quiet "${APP_REF}" || fail "cannot check out APP_REF=${APP_REF}"
SHA="$(git -C "${APP}" rev-parse HEAD)"

app_compose() { (cd "${APP}" && docker compose -p "${PROJECT}" -f compose.yaml -f "${ROOT}/harness/no-host-port.yaml" "$@"); }

teardown() {
  docker network disconnect "${PROJECT}_default" "${SELF}" > /dev/null 2>&1 || true
  app_compose down -v --remove-orphans > /dev/null 2>&1 || true
}
trap teardown EXIT

wait_healthy() {
  for _ in $(seq 1 180); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$(app_compose ps -q web)" 2> /dev/null)" = healthy ] && return 0
    sleep 1
  done
  return 1
}

app_compose up -d --build > "${OUT}/up.log" 2>&1 || fail "compose up failed — see ${OUT}/up.log"
wait_healthy || { app_compose logs --no-color > "${OUT}/health-timeout.log" 2>&1 || true; fail "web did not become healthy within 180 s — see ${OUT}/health-timeout.log"; }
docker network connect "${PROJECT}_default" "${SELF}" || fail "cannot join network ${PROJECT}_default"

export APP PROJECT ROOT
# shellcheck source=/dev/null
source acceptance/lib.sh
for file in acceptance/checks/*.sh; do
  # shellcheck source=/dev/null
  source "${file}"
done

# Catalogue rows: | ID | Source | Expectation |
mapfile -t ROWS < <(awk -F'|' '/^\| [A-Z]{2}-[0-9]{2} \|/ { for (i = 2; i <= 4; i++) { gsub(/^ +| +$/, "", $i) } print $2 "\t" $3 "\t" $4 }' acceptance/expectations.md)
[ "${#ROWS[@]}" -gt 0 ] || fail "acceptance/expectations.md has no catalogue rows"

declare -A SEEN=()
total=0
failed=0
{
  echo "# Acceptance — ${APP_REPO} @ ${SHA}"
  echo
  echo "| ID | Source | Expectation | Result |"
  echo "|---|---|---|---|"
} > "${OUT}/results.md"

for row in "${ROWS[@]}"; do
  IFS=$'\t' read -r id source expectation <<< "${row}"
  [ -z "${SEEN[$id]:-}" ] || fail "duplicate catalogue id ${id}"
  SEEN[$id]=1
  fn="check_${id//-/_}"
  declare -F "${fn}" > /dev/null || fail "catalogue id ${id} has no check function ${fn}"
  TRANSCRIPT="${OUT}/transcripts/${id}.txt"
  : > "${TRANSCRIPT}"
  FAILS=()
  "${fn}"
  total=$((total + 1))
  if [ "${#FAILS[@]}" -eq 0 ]; then
    result=PASS
  else
    result=FAIL
    failed=$((failed + 1))
    printf 'FAIL: %s\n' "${FAILS[@]}" >> "${TRANSCRIPT}"
  fi
  printf '| %s | %s | %s | [%s](transcripts/%s.txt) |\n' "${id}" "${source}" "${expectation}" "${result}" "${id}" >> "${OUT}/results.md"
  printf '%s %s\n' "${result}" "${id}"
done

for fn in $(declare -F | awk '{ print $3 }' | grep '^check_'); do
  id="${fn#check_}"
  id="${id//_/-}"
  [ -n "${SEEN[$id]:-}" ] || fail "check function ${fn} has no catalogue row"
done

{
  echo "Acceptance of ${APP_REPO} @ ${SHA}"
  echo
  echo "- Expectations: ${total} · PASS $((total - failed)) · FAIL ${failed}"
  echo "- Results: [results.md](results.md) · transcripts in [transcripts/](transcripts/)"
} > "${OUT}/summary.md"
cat "${OUT}/summary.md"
[ "${failed}" -eq 0 ] || fail "${failed} expectation(s) failed — see ${OUT}/results.md"
