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
  expect_problem 404 /problems/not-found
}

check_AD_03() {
  req GET /api/docs/
  expect_problem 404 /problems/not-found
}
