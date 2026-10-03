#!/usr/bin/env bash
# Concurrency surface (catalogue section "Concurrency surface").

check_CS_01() {
  create_todo '{"title":"complete twice"}'
  [ -n "${ID}" ] || return 0
  req POST "/api/todos/${ID}/complete"
  expect_status 200
  local v1
  v1="$(json .version)"
  req POST "/api/todos/${ID}/complete"
  expect_status 200
  expect_json .version "${v1}"
}

check_CS_02() {
  create_todo '{"title":"incomplete twice"}'
  [ -n "${ID}" ] || return 0
  req POST "/api/todos/${ID}/incomplete"
  expect_status 200
  local v1
  v1="$(json .version)"
  req POST "/api/todos/${ID}/incomplete"
  expect_status 200
  expect_json .version "${v1}"
}

check_CS_03() {
  local p key
  p="$(prefix CS03)"
  key="acc-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  post_json /api/todos "{\"title\":\"${p}once\"}" -H "Idempotency-Key: ${key}"
  expect_status 201
  local first
  first="$(json .id)"
  post_json /api/todos "{\"title\":\"${p}once\"}" -H "Idempotency-Key: ${key}"
  expect_status 201
  expect_header Idempotent-Replayed '^true$'
  expect_json .id "${first}"
  req GET /api/todos
  [ "$(mine "${p}")" = "${p}once" ] || fail_check "expected exactly one '${p}once', got '$(mine "${p}")'"
}

check_CS_04() {
  local p key
  p="$(prefix CS04)"
  key="acc-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  post_json /api/todos "{\"title\":\"${p}a\"}" -H "Idempotency-Key: ${key}"
  expect_status 201
  post_json /api/todos "{\"title\":\"${p}b\"}" -H "Idempotency-Key: ${key}"
  expect_problem 422 /problems/idempotency-key-reuse
}

check_CS_05() {
  post_json /api/todos '{"title":"bad key space"}' -H 'Idempotency-Key: has space'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
  local key
  key="$(printf 'a%.0s' $(seq 1 256))"
  post_json /api/todos '{"title":"bad key long"}' -H "Idempotency-Key: ${key}"
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_CS_06() {
  create_todo '{"title":"no lost update"}'
  [ -n "${ID}" ] || return 0
  req POST "/api/todos/${ID}/complete"
  expect_status 200
  patch_json "/api/todos/${ID}" '{"title":"stale after complete"}' -H 'If-Match: "1"'
  expect_problem 412 /problems/version-conflict
}

check_CS_07() {
  local key
  key="acc-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  post_json /api/todos '{"title":"first create with key"}' -H "Idempotency-Key: ${key}"
  expect_status 201
  expect_no_header Idempotent-Replayed
}
