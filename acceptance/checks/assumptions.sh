#!/usr/bin/env bash
# README assumptions (catalogue section "README assumptions").

check_RA_01() {
  req GET /api/todos
  expect_status 200
  expect_no_header WWW-Authenticate
}

check_RA_02() {
  create_todo "{\"title\":\"overdue 2 days\",\"dueDate\":\"$(utc_date '-2 days')\"}"
  expect_json .isOverdue true
  create_todo "{\"title\":\"future 2 days\",\"dueDate\":\"$(utc_date '+2 days')\"}"
  expect_json .isOverdue false
}

check_RA_03() {
  create_todo '{"title":"past on create","dueDate":"2001-01-01"}'
  expect_status 201
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"dueDate":"1999-12-31"}' -H 'If-Match: "1"'
  expect_status 200
  expect_json .dueDate 1999-12-31
}

check_RA_04() {
  create_todo '{"title":"clear desc","description":"to be cleared"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"description":null}' -H 'If-Match: "1"'
  expect_status 200
  expect_json .description null
}

check_RA_05() {
  create_todo '{"title":"clear due","dueDate":"2030-01-01"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"dueDate":null}' -H 'If-Match: "1"'
  expect_status 200
  expect_json .dueDate null
}

check_RA_06() {
  create_todo '{"title":"cannot clear title"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":null}' -H 'If-Match: "1"'
  expect_field_error title
}

check_RA_07() {
  create_todo '{"title":"only sent fields","description":"keep desc","dueDate":"2030-03-03"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"renamed"}' -H 'If-Match: "1"'
  expect_status 200
  expect_json .title renamed
  expect_json .description 'keep desc'
  expect_json .dueDate 2030-03-03
}

check_RA_08() {
  create_todo '{"title":"no if-match needed"}'
  [ -n "${ID}" ] || return 0
  req POST "/api/todos/${ID}/complete"
  expect_status 200
  req POST "/api/todos/${ID}/incomplete"
  expect_status 200
}

check_RA_09() {
  local p
  p="$(prefix RA09)"
  create_todo "{\"title\":\"${p}gone\"}"
  [ -n "${ID}" ] || return 0
  req DELETE "/api/todos/${ID}" -H 'If-Match: "1"'
  expect_status 204
  req GET /api/todos
  [ "$(mine "${p}")" = "" ] || fail_check "deleted todo still in list: $(mine "${p}")"
  req GET "/api/todos/${ID}"
  expect_problem 404 /problems/not-found
  req DELETE "/api/todos/${ID}" -H 'If-Match: "1"'
  expect_problem 404 /problems/not-found
}

check_RA_10() {
  local p i
  p="$(prefix RA10)"
  for i in $(seq 1 60); do
    create_todo "{\"title\":\"${p}${i}\"}"
  done
  req GET /api/todos
  expect_status 200
  local count
  count="$(jq --arg p "${p}" '[.[] | select(.title | startswith($p))] | length' "${B}" 2>/dev/null || echo 0)"
  [ "${count}" = 60 ] || fail_check "expected 60 todos with prefix ${p}, got ${count}"
  req GET '/api/todos?page=2'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_RA_11() {
  create_todo '{"title":"patch key ignored"}'
  [ -n "${ID}" ] || return 0
  local key
  key="acc-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  patch_json "/api/todos/${ID}" '{"title":"first patch"}' -H 'If-Match: "1"' -H "Idempotency-Key: ${key}"
  expect_status 200
  expect_json .title 'first patch'
  expect_json .version 2
  patch_json "/api/todos/${ID}" '{"title":"second patch"}' -H 'If-Match: "2"' -H "Idempotency-Key: ${key}"
  expect_status 200
  expect_json .title 'second patch'
  expect_json .version 3
}

check_RA_12() {
  create_todo '{"title":"due date exact","dueDate":"2030-07-15"}'
  expect_json .dueDate 2030-07-15
  expect_jq '.createdAt | endswith("Z")'
}

check_RA_13() {
  local p
  p="$(prefix RA13)"
  create_todo "{\"title\":\"${p}cherry\"}"
  create_todo "{\"title\":\"${p}apple\"}"
  create_todo "{\"title\":\"${p}Banana\"}"
  req GET '/api/todos?sort=title&order=asc'
  expect_status 200
  local got
  got="$(mine "${p}")"
  [ "${got}" = "${p}apple ${p}Banana ${p}cherry" ] || fail_check "order '${got}', expected apple Banana cherry"
}

check_RA_14() {
  local p
  p="$(prefix RA14)"
  create_todo "{\"title\":\"${p}with-date\",\"dueDate\":\"2030-01-01\"}"
  create_todo "{\"title\":\"${p}no-date\"}"
  req GET '/api/todos?sort=dueDate&order=asc'
  expect_status 200
  local got
  got="$(mine "${p}")"
  [ "${got}" = "${p}with-date ${p}no-date" ] || fail_check "asc order '${got}', expected with-date before no-date"
  req GET '/api/todos?sort=dueDate&order=desc'
  expect_status 200
  got="$(mine "${p}")"
  [ "${got}" = "${p}with-date ${p}no-date" ] || fail_check "desc order '${got}', expected with-date before no-date (no-date last)"
}
