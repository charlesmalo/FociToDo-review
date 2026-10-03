#!/usr/bin/env bash
# Deadlines as UTC instants: the due-soon flag and filter (catalogue section "Deadline status").
# Every deadline is generated from "now" and is at least an hour from the 24 h and "now" boundaries.

check_DS_01() {
  create_todo "{\"title\":\"soon\",\"dueAt\":\"$(utc_at '+2 hours')\"}"
  expect_json .isDueSoon true
  expect_json .isOverdue false
  create_todo "{\"title\":\"later\",\"dueAt\":\"$(utc_at '+25 hours')\"}"
  expect_json .isDueSoon false
  create_todo "{\"title\":\"soon but done\",\"dueAt\":\"$(utc_at '+2 hours')\"}"
  [ -n "${ID}" ] || return 0
  req POST "/api/todos/${ID}/complete"
  expect_json .isDueSoon false
  create_todo '{"title":"no deadline"}'
  expect_json .isDueSoon false
}

# _ds_fixture PREFIX: one due-soon, one later, one overdue, one completed-soon and one deadline-free todo.
_ds_fixture() {
  local p="$1"
  create_todo "{\"title\":\"${p}soon\",\"dueAt\":\"$(utc_at '+2 hours')\"}"
  create_todo "{\"title\":\"${p}later\",\"dueAt\":\"$(utc_at '+25 hours')\"}"
  create_todo "{\"title\":\"${p}overdue\",\"dueAt\":\"$(utc_at '-2 hours')\"}"
  create_todo "{\"title\":\"${p}done\",\"dueAt\":\"$(utc_at '+3 hours')\"}"
  if [ -n "${ID}" ]; then
    req POST "/api/todos/${ID}/complete"
    [ "${STATUS}" = 200 ] || fail_check "setup: complete returned ${STATUS}"
  fi
  create_todo "{\"title\":\"${p}none\"}"
}

check_DS_02() {
  local p got
  p="$(prefix DS02)"
  _ds_fixture "${p}"
  req GET '/api/todos?status=due-soon'
  expect_status 200
  got="$(mine "${p}")"
  [ "${got}" = "${p}soon" ] || fail_check "due-soon filter returned '${got}', expected '${p}soon'"
}

check_DS_03() {
  local p got
  p="$(prefix DS03)"
  _ds_fixture "${p}"
  req GET '/api/todos?status=due-soon'
  expect_status 200
  expect_jq "[.[] | select(.title | startswith(\"${p}\"))] | length > 0 and all(.isDueSoon == true and .isOverdue == false)"
  req GET '/api/todos?status=overdue'
  expect_status 200
  got="$(mine "${p}")"
  [ "${got}" = "${p}overdue" ] || fail_check "overdue filter returned '${got}', expected '${p}overdue'"
  expect_jq "[.[] | select(.title | startswith(\"${p}\"))] | length > 0 and all(.isOverdue == true and .isDueSoon == false)"
}

check_DS_04() {
  req GET '/api/todos?sort=dueDate'
  expect_field_error sort
  post_json /api/todos '{"title":"old key","dueDate":"2030-01-01"}'
  expect_field_error dueDate
}
