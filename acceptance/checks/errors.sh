#!/usr/bin/env bash
# Error contract (catalogue section "Error contract").

check_EC_01() {
  post_json /api/todos '{"title":""}'
  expect_problem 400 /problems/validation-error
  expect_jq '.errors | type == "array"'
  expect_jq '.errors | length > 0'
  expect_jq '.errors[0] | has("field") and has("message")'
}

check_EC_02() {
  req GET /api/todos/00000000-0000-4000-8000-000000000000
  expect_problem 404 /problems/not-found
}

check_EC_03() {
  req GET /api/todos/abc
  expect_field_error id
}

check_EC_04() {
  create_todo '{"title":"stale patch"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"bump"}' -H 'If-Match: "1"'
  expect_status 200
  patch_json "/api/todos/${ID}" '{"title":"stale"}' -H 'If-Match: "1"'
  expect_problem 412 /problems/version-conflict
}

check_EC_05() {
  create_todo '{"title":"no if-match patch"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"x"}'
  expect_problem 428 /problems/precondition-required
}

check_EC_06() {
  create_todo '{"title":"no if-match delete"}'
  [ -n "${ID}" ] || return 0
  req DELETE "/api/todos/${ID}"
  expect_problem 428 /problems/precondition-required
}

check_EC_07() {
  create_todo '{"title":"stale delete"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"bump"}' -H 'If-Match: "1"'
  expect_status 200
  req DELETE "/api/todos/${ID}" -H 'If-Match: "1"'
  expect_problem 412 /problems/version-conflict
}

check_EC_08() {
  create_todo '{"title":"wildcard if-match"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"x"}' -H 'If-Match: *'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_EC_09() {
  create_todo '{"title":"weak if-match"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"x"}' -H 'If-Match: W/"1"'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_EC_10() {
  create_todo '{"title":"precedence 400 428"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":123}'
  expect_field_error title
}

check_EC_11() {
  patch_json /api/todos/00000000-0000-4000-8000-000000000000 '{"title":"x"}'
  expect_problem 428 /problems/precondition-required
}

check_EC_12() {
  patch_json /api/todos/00000000-0000-4000-8000-000000000000 '{"title":"x"}' -H 'If-Match: "1"'
  expect_problem 404 /problems/not-found
}

check_EC_13() {
  req POST /api/todos -H 'Content-Type: application/json; charset=latin1' --data-binary '{"title":"x"}'
  expect_status 415
  expect_header Content-Type '^application/problem\+json'
}

check_EC_14() {
  create_todo '{"title":"charset patch"}'
  [ -n "${ID}" ] || return 0
  req PATCH "/api/todos/${ID}" -H 'Content-Type: application/json; charset=latin1' -H 'If-Match: "1"' --data-binary '{"title":"y"}'
  expect_status 415
  expect_header Content-Type '^application/problem\+json'
}

check_EC_15() {
  req GET /api/nope
  expect_problem 404 /problems/not-found
}

check_EC_16() {
  local id=00000000-0000-4000-8000-000000000000
  req POST "/api/todos/${id}/complete"
  expect_problem 404 /problems/not-found
  req POST "/api/todos/${id}/incomplete"
  expect_problem 404 /problems/not-found
  req DELETE "/api/todos/${id}" -H 'If-Match: "1"'
  expect_problem 404 /problems/not-found
}

check_EC_17() {
  local desc
  desc="$(printf 'a%.0s' $(seq 1 17000))"
  post_json /api/todos "{\"title\":\"x\",\"description\":\"${desc}\"}"
  expect_problem 413 /problems/payload-too-large
}
