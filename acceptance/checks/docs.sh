#!/usr/bin/env bash
# API documentation and health (catalogue section "API documentation and health").

check_AD_01() {
  req GET /api/health
  expect_status 200
  expect_json .status ok
  expect_json .db up
}

check_AD_02() {
  req GET /api/openapi.json
  expect_status 200
  expect_jq '.openapi | startswith("3.1")'
  local p
  for p in /api/todos '/api/todos/{id}' '/api/todos/{id}/complete' '/api/todos/{id}/incomplete' /api/health; do
    jq -e --arg p "${p}" '.paths | has($p)' "${B}" >/dev/null 2>&1 || fail_check "openapi.json has no path ${p}"
  done
}

check_AD_03() {
  req GET /api/docs
  expect_status 200
  expect_header Content-Type '^text/html'
}
