#!/usr/bin/env bash
# Brief actions (catalogue section "Brief actions").

check_BR_01() {
  create_todo '{"title":"Buy milk"}'
  expect_status 201
  expect_header Location "^/api/todos/${ID}\$"
  expect_header ETag '^"1"$'
  expect_jq '.id | test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")'
  expect_json .title 'Buy milk'
  expect_json .description null
  expect_json .dueAt null
  expect_json .isCompleted false
  expect_json .version 1
  expect_jq '.createdAt | type == "string"'
}

check_BR_02() {
  create_todo '{"title":"Buy milk","description":"2% organic","dueAt":"2030-01-02T12:00:00Z"}'
  expect_status 201
  expect_json .description '2% organic'
  expect_json .dueAt '2030-01-02T12:00:00.000Z'
}

check_BR_03() {
  local p
  p="$(prefix BR03)"
  create_todo "{\"title\":\"${p}a\",\"dueAt\":\"2030-01-02T12:00:00Z\"}"
  [ -n "${ID}" ] || return 0
  req GET /api/todos
  expect_status 200
  expect_jq 'type == "array"'
  expect_jq ".[] | select(.id == \"${ID}\") | .title == \"${p}a\" and .dueAt == \"2030-01-02T12:00:00.000Z\" and .isCompleted == false and has(\"isOverdue\")"
}

check_BR_04() {
  create_todo '{"title":"View me"}'
  [ -n "${ID}" ] || return 0
  req GET "/api/todos/${ID}"
  expect_status 200
  expect_header ETag '^"1"$'
  expect_json .id "${ID}"
  expect_json .title 'View me'
}

check_BR_05() {
  create_todo '{"title":"Old","description":"keep","dueAt":"2030-01-02T12:00:00Z"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"New"}' -H 'If-Match: "1"'
  expect_status 200
  expect_header ETag '^"2"$'
  expect_json .title New
  expect_json .version 2
  expect_json .description keep
  expect_json .dueAt '2030-01-02T12:00:00.000Z'
}

check_BR_06() {
  create_todo '{"title":"Desc","description":"old"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"description":"new"}' -H 'If-Match: "1"'
  expect_status 200
  expect_json .description new
  expect_json .version 2
}

check_BR_07() {
  create_todo '{"title":"Due","dueAt":"2030-01-01T12:00:00Z"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"dueAt":"2030-02-02T12:00:00Z"}' -H 'If-Match: "1"'
  expect_status 200
  expect_json .dueAt '2030-02-02T12:00:00.000Z'
  expect_json .version 2
}

check_BR_08() {
  create_todo '{"title":"Complete me"}'
  [ -n "${ID}" ] || return 0
  req POST "/api/todos/${ID}/complete"
  expect_status 200
  expect_json .isCompleted true
}

check_BR_09() {
  create_todo '{"title":"Incomplete me"}'
  [ -n "${ID}" ] || return 0
  req POST "/api/todos/${ID}/complete"
  [ "${STATUS}" = 200 ] || { fail_check "setup: complete returned ${STATUS}"; return 0; }
  req POST "/api/todos/${ID}/incomplete"
  expect_status 200
  expect_json .isCompleted false
}

check_BR_10() {
  create_todo '{"title":"Delete me"}'
  [ -n "${ID}" ] || return 0
  req DELETE "/api/todos/${ID}" -H 'If-Match: "1"'
  expect_status 204
  req GET "/api/todos/${ID}"
  expect_status 404
}

# Shared setup for the filter checks (BR-11..BR-14): one completed, one incomplete
# due in the future, and one incomplete overdue todo, all under one prefix.
_br_filter_fixture() {
  local p="$1"
  create_todo "{\"title\":\"${p}done\"}"
  if [ -n "${ID}" ]; then
    req POST "/api/todos/${ID}/complete"
    [ "${STATUS}" = 200 ] || fail_check "setup: complete returned ${STATUS}"
  fi
  create_todo "{\"title\":\"${p}future\",\"dueAt\":\"$(utc_at '+3 days')\"}"
  create_todo "{\"title\":\"${p}overdue\",\"dueAt\":\"$(utc_at '-3 days')\"}"
}

# _sorted LIST: space-separated words, sorted, for order-independent set comparison.
_sorted() { printf '%s\n' "$@" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/^ *//; s/ *$//'; }

check_BR_11() {
  local p got
  p="$(prefix BR11)"
  _br_filter_fixture "${p}"
  req GET '/api/todos?status=completed'
  expect_status 200
  got="$(mine "${p}")"
  [ "${got}" = "${p}done" ] || fail_check "completed filter returned '${got}', expected '${p}done'"
}

check_BR_12() {
  local p got want
  p="$(prefix BR12)"
  _br_filter_fixture "${p}"
  req GET '/api/todos?status=incomplete'
  expect_status 200
  got="$(_sorted "$(mine "${p}")")"
  want="$(_sorted "${p}future" "${p}overdue")"
  [ "${got}" = "${want}" ] || fail_check "incomplete filter returned '${got}', expected '${want}'"
}

check_BR_13() {
  local p got
  p="$(prefix BR13)"
  _br_filter_fixture "${p}"
  req GET '/api/todos?status=overdue'
  expect_status 200
  got="$(mine "${p}")"
  [ "${got}" = "${p}overdue" ] || fail_check "overdue filter returned '${got}', expected '${p}overdue'"
}

check_BR_14() {
  local p got want
  p="$(prefix BR14)"
  _br_filter_fixture "${p}"
  want="$(_sorted "${p}done" "${p}future" "${p}overdue")"

  req GET '/api/todos'
  expect_status 200
  got="$(_sorted "$(mine "${p}")")"
  [ "${got}" = "${want}" ] || fail_check "default list returned '${got}', expected '${want}'"

  req GET '/api/todos?status=all'
  expect_status 200
  got="$(_sorted "$(mine "${p}")")"
  [ "${got}" = "${want}" ] || fail_check "status=all returned '${got}', expected '${want}'"
}

check_BR_15() {
  local p
  p="$(prefix BR15)"
  create_todo "{\"title\":\"${p}b\",\"dueAt\":\"2030-05-01T12:00:00Z\"}"
  create_todo "{\"title\":\"${p}a\",\"dueAt\":\"2030-01-01T12:00:00Z\"}"
  create_todo "{\"title\":\"${p}c\",\"dueAt\":\"2030-09-01T12:00:00Z\"}"
  create_todo "{\"title\":\"${p}none\"}"
  req GET '/api/todos?sort=dueAt&order=asc'
  expect_status 200
  local got
  got="$(mine "${p}")"
  [ "${got}" = "${p}a ${p}b ${p}c ${p}none" ] || fail_check "order '${got}', expected a b c none (no due date last)"
}

check_BR_16() {
  local p
  p="$(prefix BR16)"
  create_todo "{\"title\":\"${p}b\",\"dueAt\":\"2030-05-01T12:00:00Z\"}"
  create_todo "{\"title\":\"${p}a\",\"dueAt\":\"2030-01-01T12:00:00Z\"}"
  create_todo "{\"title\":\"${p}c\",\"dueAt\":\"2030-09-01T12:00:00Z\"}"
  create_todo "{\"title\":\"${p}none\"}"
  req GET '/api/todos?sort=dueAt&order=desc'
  expect_status 200
  local got
  got="$(mine "${p}")"
  [ "${got}" = "${p}c ${p}b ${p}a ${p}none" ] || fail_check "order '${got}', expected c b a none (no due date last)"
}

check_BR_17() {
  local p
  p="$(prefix BR17)"
  create_todo "{\"title\":\"${p}first\"}"
  create_todo "{\"title\":\"${p}second\"}"
  create_todo "{\"title\":\"${p}third\"}"
  req GET /api/todos
  expect_status 200
  local got
  got="$(mine "${p}")"
  [ "${got}" = "${p}third ${p}second ${p}first" ] || fail_check "default order '${got}', expected third second first (newest first)"
}

check_BR_18() {
  local p
  p="$(prefix BR18)"
  create_todo "{\"title\":\"${p}first\"}"
  create_todo "{\"title\":\"${p}second\"}"
  create_todo "{\"title\":\"${p}third\"}"
  req GET '/api/todos?sort=createdAt&order=asc'
  expect_status 200
  local got
  got="$(mine "${p}")"
  [ "${got}" = "${p}first ${p}second ${p}third" ] || fail_check "asc createdAt order '${got}', expected first second third"
}

check_BR_19() {
  local p
  p="$(prefix BR19)"
  create_todo "{\"title\":\"${p}apple\"}"
  create_todo "{\"title\":\"${p}Banana\"}"
  create_todo "{\"title\":\"${p}cherry\"}"
  req GET '/api/todos?sort=title&order=asc'
  expect_status 200
  local got
  got="$(mine "${p}")"
  [ "${got}" = "${p}apple ${p}Banana ${p}cherry" ] || fail_check "title asc order '${got}', expected apple Banana cherry"
  req GET '/api/todos?sort=title&order=desc'
  expect_status 200
  got="$(mine "${p}")"
  [ "${got}" = "${p}cherry ${p}Banana ${p}apple" ] || fail_check "title desc order '${got}', expected cherry Banana apple"
}

check_BR_20() {
  create_todo '{"title":"Survives a restart"}'
  [ -n "${ID}" ] || return 0
  local api_cid ip_before ip_after start_ts up=0
  api_cid="$(cd "${APP}" && docker compose -p "${PROJECT}" ps -q api)"
  ip_before="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${api_cid}" 2>/dev/null || echo unknown)"
  (cd "${APP}" && docker compose -p "${PROJECT}" restart db api > /dev/null 2>&1) || harness_fail "restart of db/api failed"
  ip_after="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${api_cid}" 2>/dev/null || echo unknown)"
  start_ts="$(date +%s)"
  for _ in $(seq 1 90); do
    if curl -fsS --max-time 3 "${BASE}/api/health" > /dev/null 2>&1; then up=1; break; fi
    sleep 1
  done
  {
    printf 'api container: %s\n' "${api_cid}"
    printf 'api container IP before restart: %s\n' "${ip_before}"
    printf 'api container IP after restart: %s\n' "${ip_after}"
    if [ "${up}" = 1 ]; then
      printf 'seconds until /api/health was 200 again: %s\n' "$(( $(date +%s) - start_ts ))"
    else
      printf 'seconds until /api/health was 200 again: did not recover within 90s\n'
    fi
  } >> "${TRANSCRIPT}"
  if [ "${up}" != 1 ]; then
    (cd "${APP}" && docker compose -p "${PROJECT}" logs --no-color) > "${TRANSCRIPT%.txt}.logs.txt" 2>&1 || true
    fail_check "app not healthy 90 s after restarting db and api — see ${TRANSCRIPT%.txt}.logs.txt"
    # The front end's own proxy does not recover on its own (see the finding above);
    # restart it so BR-21 and later checks run against a working stack.
    (cd "${APP}" && docker compose -p "${PROJECT}" restart web > /dev/null 2>&1) || true
    local recovered=0
    for _ in $(seq 1 60); do
      if curl -fsS --max-time 3 "${BASE}/api/health" > /dev/null 2>&1; then recovered=1; break; fi
      sleep 1
    done
    echo "NOTE: web was restarted to recover the stack so the run could continue past BR-20." >> "${TRANSCRIPT}"
    [ "${recovered}" = 1 ] || harness_fail "web still not healthy 60 s after restarting it to recover from BR-20"
    return
  fi
  req GET "/api/todos/${ID}"
  expect_status 200
  expect_json .title 'Survives a restart'
}

check_BR_21() {
  req GET /
  expect_status 200
  expect_header Content-Type '^text/html'
  req GET /some/deep/link
  expect_status 200
  expect_header Content-Type '^text/html'
}
