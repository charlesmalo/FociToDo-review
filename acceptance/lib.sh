#!/usr/bin/env bash
# Black-box HTTP checks against the app under review, sourced by scripts/acceptance.sh.
# Written only from the allowed sources — the brief, the design spec, docs/api.md, the
# README, the committed apps/api/openapi.json and the 2026-10-03 spec — never from the app's own tests. See the
# Independence section at the top of acceptance/expectations.md.

BASE="${BASE:-http://web:8080}"
SCRATCH="$(mktemp -d)"
H="${SCRATCH}/headers"
B="${SCRATCH}/body"
STATUS=""
TRANSCRIPT=/dev/null
FAILS=()
ID=""
VERSION=""

harness_fail() {
  echo "acceptance.sh: harness error: $*" >&2
  exit 2
}

# req METHOD PATH [curl args...]: sends one request, records it in the transcript.
req() {
  local method="$1" path="$2"
  shift 2
  : > "$H"
  : > "$B"
  STATUS="$(curl -sS --max-time 15 -o "$B" -D "$H" -w '%{http_code}' -X "$method" "${BASE}${path}" "$@")" \
    || harness_fail "curl transport error on ${method} ${path}"
  {
    printf '>>> %s %s' "$method" "$path"
    [ "$#" -gt 0 ] && printf ' %q' "$@"
    printf '\n'
    tr -d '\r' < "$H"
    head -c 4000 "$B"
    printf '\n\n'
  } >> "$TRANSCRIPT"
}

post_json() { local path="$1" body="$2"; shift 2; req POST "$path" -H 'Content-Type: application/json' --data-binary "$body" "$@"; }
patch_json() { local path="$1" body="$2"; shift 2; req PATCH "$path" -H 'Content-Type: application/json' --data-binary "$body" "$@"; }

# header NAME: value of the first response header NAME (case-insensitive), '' if absent.
header() {
  tr -d '\r' < "$H" | awk -v n="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" \
    'index(tolower($0), n ": ") == 1 { print substr($0, length(n) + 3); exit }'
}

# json FILTER: jq -r FILTER on the body, or '<not-json>' when the body is not JSON.
json() { jq -r "$1" "$B" 2>/dev/null || printf '<not-json>'; }

fail_check() { FAILS+=("$*"); }
expect_status() { [ "$STATUS" = "$1" ] || fail_check "status ${STATUS}, expected $1"; }
expect_4xx() { [[ "$STATUS" =~ ^4[0-9][0-9]$ ]] || fail_check "status ${STATUS}, expected a 4xx (never 5xx)"; }
expect_header() { local v; v="$(header "$1")"; [[ "$v" =~ $2 ]] || fail_check "header $1='${v}' does not match /$2/"; }
expect_no_header() { [ -z "$(header "$1")" ] || fail_check "unexpected header $1='$(header "$1")'"; }
expect_json() { local v; v="$(json "$1")"; [ "$v" = "$2" ] || fail_check "$1 = '${v}', expected '$2'"; }
expect_jq() { jq -e "$1" "$B" > /dev/null 2>&1 || fail_check "body does not satisfy: $1"; }

# expect_problem STATUS TYPE: RFC 9457 problem details of the given status and type.
expect_problem() {
  expect_status "$1"
  expect_header Content-Type '^application/problem\+json'
  expect_json .type "$2"
  expect_json .status "$1"
  expect_jq '.title | type == "string"'
}

# expect_field_error FIELD: a validation problem whose errors[] names FIELD.
expect_field_error() {
  expect_problem 400 /problems/validation-error
  jq -e --arg f "$1" '.errors | any(.field == $f)' "$B" > /dev/null 2>&1 \
    || fail_check "errors[] has no entry for field '$1'"
}

# create_todo JSON: POST it; sets ID and VERSION ('' and a recorded failure if not 201).
create_todo() {
  post_json /api/todos "$1"
  if [ "$STATUS" = 201 ]; then
    ID="$(json .id)"
    VERSION="$(json .version)"
  else
    fail_check "setup: create returned ${STATUS}"
    ID=""
    VERSION=""
  fi
}

# prefix NAME: a unique title prefix for one check's data.
prefix() { printf 'acc-%s-%s-' "$1" "$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n')"; }

# mine PREFIX: from a list response, the titles of todos whose title starts with PREFIX, in order
# ('' when the body is not a JSON array — never aborts the run).
mine() {
  { jq -r --arg p "$1" '.[] | select(.title | startswith($p)) | .title' "$B" 2> /dev/null || true; } \
    | tr '\n' ' ' | sed 's/ $//'
}

# utc_at WHEN: an instant relative to now (GNU date syntax, e.g. '+2 hours') as RFC 3339 UTC.
utc_at() { date -u -d "$1" +%Y-%m-%dT%H:%M:%SZ; }

# at_offset WHEN OFFSET: the same instant as utc_at, written with a numeric offset such as +14:00 or -12:00.
at_offset() {
  local epoch sign secs
  epoch="$(date -u -d "$1" +%s)"
  sign="${2:0:1}"
  secs=$(( 10#${2:1:2} * 3600 + 10#${2:4:2} * 60 ))
  [ "${sign}" = '-' ] && secs=$(( -secs ))
  printf '%s%s\n' "$(date -u -d "@$(( epoch + secs ))" +%Y-%m-%dT%H:%M:%S)" "$2"
}
