#!/usr/bin/env bash
# Robustness (catalogue section "Robustness"): hostile input must be rejected cleanly,
# a 4xx with problem details, never a 5xx.

check_RB_01() {
  post_json /api/todos '{"title": '
  expect_problem 400 /problems/malformed-json
}

check_RB_02() {
  req POST /api/todos -H 'Content-Type: text/plain' --data-binary 'hello'
  expect_4xx
  expect_header Content-Type '^application/problem\+json'
}

check_RB_03() {
  req POST /api/todos -H 'Content-Type: application/json' --data-binary ''
  expect_4xx
  expect_header Content-Type '^application/problem\+json'
}

check_RB_04() {
  post_json /api/todos '[1,2,3]'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_RB_05() {
  post_json /api/todos '{"title":"x","extra":"y"}'
  expect_field_error extra
}

check_RB_06() {
  post_json /api/todos '{"title":123}'
  expect_field_error title
}

check_RB_07() {
  post_json /api/todos '{"title":"x","dueDate":20300101}'
  expect_field_error dueDate
}

check_RB_08() {
  local title
  title="$(printf 'a%.0s' $(seq 1 10000))"
  post_json /api/todos "{\"title\":\"${title}\"}"
  expect_field_error title
}

check_RB_09() {
  local title="café 你好 😀 مرحبا"
  create_todo "{\"title\":\"${title}\"}"
  expect_status 201
  expect_json .title "${title}"
  [ -n "${ID}" ] || return 0
  req GET "/api/todos/${ID}"
  expect_json .title "${title}"
}

check_RB_10() {
  post_json /api/todos '{"title":"bad\u0000title"}'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
  post_json /api/todos '{"title":"x","description":"bad\u0000desc"}'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_RB_11() {
  local index_copy="${SCRATCH}/rb11-index"
  req GET /
  cp "${B}" "${index_copy}"

  req GET '/api/todos/..%2F..%2Fetc'
  printf 'note: nginx decodes %%2F and removes dot segments before routing, so ..%%2F..%%2Fetc becomes /etc — outside /api — and is served the app'"'"'s own index.html, not the API.\n' >>"${TRANSCRIPT}"
  [[ ! "${STATUS}" =~ ^5[0-9][0-9]$ ]] || fail_check "status ${STATUS}, expected not a 5xx"
  expect_header Content-Type '^text/html'
  cmp -s "${B}" "${index_copy}" || fail_check "..%2F..%2Fetc body does not match the app's own GET / index.html byte-for-byte"

  req GET "/api/todos/$(printf 'a%.0s' $(seq 1 1000))"
  expect_4xx
  expect_header Content-Type '^application/problem\+json'

  req GET '/api/todos/%00'
  printf 'note: nginx rejects the raw NUL byte in the request line itself (Connection: close, nginx'"'"'s own error page) — the request never reaches the API, so no problem+json body is possible here.\n' >>"${TRANSCRIPT}"
  expect_4xx
}

check_RB_12() {
  req GET '/api/todos?status=bogus'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_RB_13() {
  req GET '/api/todos?bogus=1'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_RB_14() {
  create_todo '{"title":"put unsupported"}'
  [ -n "${ID}" ] || return 0
  req PUT "/api/todos/${ID}"
  expect_4xx
  expect_header Content-Type '^application/problem\+json'
}

check_RB_15() {
  create_todo '{"title":"huge if-match"}'
  [ -n "${ID}" ] || return 0
  patch_json "/api/todos/${ID}" '{"title":"x"}' -H 'If-Match: "9999999999"'
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_RB_16() {
  local body='"x"'
  local i
  for i in $(seq 1 50); do
    body="{\"a\":${body}}"
  done
  body="{\"title\":${body}}"
  post_json /api/todos "${body}"
  expect_status 400
  expect_header Content-Type '^application/problem\+json'
}

check_RB_17() {
  local p title
  p="$(prefix RB17)"
  title="${p}x'); DROP TABLE todos; --"
  create_todo "{\"title\":\"${title}\"}"
  expect_status 201
  [ -n "${ID}" ] || return 0
  expect_json .title "${title}"
  req GET /api/todos
  expect_status 200
  [ "$(mine "${p}")" = "${title}" ] || fail_check "list after SQL-looking title returned '$(mine "${p}")'"
}

check_RB_18() {
  local title='<script>alert(1)</script>'
  create_todo "{\"title\":\"${title}\"}"
  expect_status 201
  expect_json .title "${title}"
  [ -n "${ID}" ] || return 0
  req GET "/api/todos/${ID}"
  expect_json .title "${title}"
  expect_header Content-Type '^application/json'
}
