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
  req GET /api/docs -L
  expect_status 200
  # -L follows the redirect to /api/docs/, so $H holds one header block per hop; take the
  # *last* occurrence of Content-Type — the final (200) response's, not the 301's.
  local content_type
  content_type="$(tr -d '\r' < "${H}" | awk -F': ' 'tolower($1) == "content-type" { v = $2 } END { print v }')"
  [[ "${content_type}" =~ ^text/html ]] || fail_check "final content-type='${content_type}', expected text/html"
  grep -qi 'swagger-ui' "${B}" || fail_check "body does not contain swagger-ui"
}
