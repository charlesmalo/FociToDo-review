#!/usr/bin/env bash
# Image vulnerabilities (Trivy), Dockerfile lint (Hadolint), dependency audit (npm).
set -euo pipefail
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
EVIDENCE="evidence/${STAMP}/scans"
APP="work/app"
TRIVY_CACHE="work/trivy-cache"
mkdir -p "${EVIDENCE}" "${TRIVY_CACHE}" work
[ -d "${APP}" ] || git clone --quiet "${APP_REPO}" "${APP}"
git -C "${APP}" fetch --quiet && git -C "${APP}" checkout --quiet "${APP_REF}"

(cd "${APP}" && docker compose -p review-scan build api web >/dev/null)

for image in review-scan-api review-scan-web; do
  docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${HOST_DIR}/${TRIVY_CACHE}:/root/.cache/" \
    aquasec/trivy:0.75.0 \
    image --quiet --severity HIGH,CRITICAL --ignore-unfixed "${image}" \
    | tee "${EVIDENCE}/trivy-${image}.txt"
done

# Every Dockerfile the shipped images (api, web) are built from — one evidence file each.
# (The app ships a single multi-stage Dockerfile; both the api and web targets build from it.)
docker run --rm -i hadolint/hadolint:v2.15.1 < "${APP}/Dockerfile" \
  | tee "${EVIDENCE}/hadolint-Dockerfile.txt" || true

docker run --rm -v "${HOST_DIR}/${APP}:/app" -w /app node:24.21-alpine \
  npm audit --omit=dev --audit-level=high | tee "${EVIDENCE}/npm-audit.txt" || true
