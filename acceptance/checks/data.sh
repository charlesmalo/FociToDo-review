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
  post_json /api/todos '{"title":"bad date","dueDate":"2026-02-30"}'
  expect_field_error dueDate
}

check_DR_12() {
  post_json /api/todos '{"title":"bad format","dueDate":"2026-1-5"}'
  expect_field_error dueDate
}

check_DR_13() {
  create_todo '{"title":"past date","dueDate":"2001-01-01"}'
  expect_status 201
  expect_json .dueDate 2001-01-01
}

check_DR_14() {
  create_todo '{"title":"earliest date","dueDate":"0001-01-01"}'
  expect_status 201
  expect_json .dueDate 0001-01-01
}

check_DR_15() {
  post_json /api/todos '{"title":"year zero","dueDate":"0000-01-01"}'
  expect_field_error dueDate
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
  local yesterday today
  yesterday="$(utc_date '-1 day')"
  today="$(utc_date 'today')"
  printf 'dates used: yesterday=%s today=%s (UTC)\n' "${yesterday}" "${today}" >>"${TRANSCRIPT}"
  create_todo "{\"title\":\"due yesterday\",\"dueDate\":\"${yesterday}\"}"
  expect_json .isOverdue true
  local overdue_id="${ID}"
  create_todo "{\"title\":\"due today\",\"dueDate\":\"${today}\"}"
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
