#!/usr/bin/env bash
# Data rules (catalogue section "Data rules").

check_DR_01() {
  post_json /api/todos '{"title":"client id","id":"11111111-1111-4111-8111-111111111111"}'
  expect_field_error id
}

check_DR_02() {
  create_todo '{"title":"createdAt check"}'
  [ -n "${ID}" ] || return 0
  expect_jq '.createdAt | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]+)?Z$")'
  local created then now diff
  created="$(json .createdAt)"
  now="$(date -u +%s)"
  then="$(date -u -d "${created}" +%s 2>/dev/null || echo 0)"
  diff=$((now - then))
  if ((diff < 0)); then diff=$((-diff)); fi
  [ "${diff}" -le 60 ] || fail_check "createdAt ${created} not within a minute of now (diff ${diff}s)"
}

check_DR_03() {
  create_todo '{"title":"  hi  "}'
  expect_json .title hi
}

check_DR_04() {
  local title
  title="$(printf 'a%.0s' $(seq 1 200))"
  create_todo "{\"title\":\"${title}\"}"
  expect_status 201
  expect_json .title "${title}"
}

check_DR_05() {
  local title
  title="$(printf 'a%.0s' $(seq 1 201))"
  post_json /api/todos "{\"title\":\"${title}\"}"
  expect_field_error title
}

check_DR_06() {
  post_json /api/todos '{"title":""}'
  expect_field_error title
}

check_DR_07() {
  post_json /api/todos '{"title":"   "}'
  expect_field_error title
}

check_DR_08() {
  local desc
  desc="$(printf 'a%.0s' $(seq 1 2000))"
  create_todo "{\"title\":\"desc 2000\",\"description\":\"${desc}\"}"
  expect_status 201
  expect_json .description "${desc}"
}

check_DR_09() {
  local desc
  desc="$(printf 'a%.0s' $(seq 1 2001))"
  post_json /api/todos "{\"title\":\"desc 2001\",\"description\":\"${desc}\"}"
  expect_field_error description
}

check_DR_10() {
  create_todo '{"title":"empty desc","description":""}'
  expect_json .description null
}

check_DR_11() {
  post_json /api/todos '{"title":"bad date","dueAt":"2026-02-30T10:00:00Z"}'
  expect_field_error dueAt
  jq -e '[.errors[] | select(.field == "dueAt")] | length == 1' "$B" > /dev/null 2>&1 \
    || fail_check "errors[] has not exactly one entry for dueAt"
}

check_DR_12() {
  post_json /api/todos '{"title":"bare date","dueAt":"2026-10-05"}'
  expect_field_error dueAt
  post_json /api/todos '{"title":"no offset","dueAt":"2026-10-05T10:00:00"}'
  expect_field_error dueAt
}

check_DR_13() {
  create_todo '{"title":"past offset","dueAt":"2001-01-01T10:00:00+02:00"}'
  expect_status 201
  expect_json .dueAt 2001-01-01T08:00:00.000Z
  create_todo '{"title":"past z","dueAt":"2001-01-01T10:00:00.5Z"}'
  expect_status 201
  expect_json .dueAt 2001-01-01T10:00:00.500Z
}

check_DR_14() {
  create_todo '{"title":"earliest instant","dueAt":"0001-01-01T00:00:00Z"}'
  expect_status 201
  expect_json .dueAt 0001-01-01T00:00:00.000Z
}

check_DR_15() {
  post_json /api/todos '{"title":"year zero","dueAt":"0000-01-01T00:00:00Z"}'
  expect_field_error dueAt
  post_json /api/todos '{"title":"year 10000","dueAt":"10000-01-01T00:00:00Z"}'
  expect_field_error dueAt
}

check_DR_16() {
  create_todo '{"title":"default completed"}'
  expect_json .isCompleted false
  post_json /api/todos '{"title":"set completed","isCompleted":true}'
  expect_field_error isCompleted
}

check_DR_17() {
  create_todo '{"title":"version readonly"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"version":5}' -H 'If-Match: "1"'
  expect_field_error version
}

check_DR_18() {
  local past ahead
  past="$(utc_at '-10 seconds')"
  ahead="$(utc_at '+5 minutes')"
  printf 'instants used: past=%s ahead=%s (UTC)\n' "${past}" "${ahead}" >>"${TRANSCRIPT}"
  create_todo "{\"title\":\"due seconds ago\",\"dueAt\":\"${past}\"}"
  expect_json .isOverdue true
  local overdue_id="${ID}"
  create_todo "{\"title\":\"due in minutes\",\"dueAt\":\"${ahead}\"}"
  expect_json .isOverdue false
  [ -n "${overdue_id}" ] || return 0
  req POST "/api/todos/${overdue_id}/complete"
  expect_json .isOverdue false
}

check_DR_19() {
  create_todo '{"title":"etag check"}'
  [ -n "${ID}" ] || return 0
  expect_header ETag '^"1"$'
  req GET "/api/todos/${ID}"
  expect_header ETag '^"1"$'
  patch_json "/api/todos/${ID}" '{"title":"etag check 2"}' -H 'If-Match: "1"'
  expect_header ETag '^"2"$'
  req POST "/api/todos/${ID}/complete"
  expect_header ETag '^"3"$'
  req POST "/api/todos/${ID}/incomplete"
  expect_header ETag '^"4"$'
}

check_DR_20() {
  local key
  key="acc-$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  post_json /api/todos '{"title":"same instant","dueAt":"2030-06-01T12:00:00Z"}' -H "Idempotency-Key: ${key}"
  expect_status 201
  local first
  first="$(json .id)"
  post_json /api/todos '{"title":"same instant","dueAt":"2030-06-01T14:00:00+02:00"}' -H "Idempotency-Key: ${key}"
  expect_status 201
  expect_header Idempotent-Replayed '^true$'
  expect_json .id "${first}"
  expect_json .dueAt 2030-06-01T12:00:00.000Z
  post_json /api/todos '{"title":"same instant","dueAt":"2030-06-01T12:00:01Z"}' -H "Idempotency-Key: ${key}"
  expect_problem 422 /problems/idempotency-key-reuse
}
