#!/usr/bin/env bash
# Verify that the Trivy release-blocking gate fails (non-zero exit) on a
# deliberately vulnerable base image using the same flags as build-push.yml
# and trivy.yml.
set -euo pipefail

VULNERABLE_IMAGE="${1:-alpine:3.14}"
TRIVY_SEVERITY="${TRIVY_SEVERITY:-CRITICAL,HIGH}"

echo "Verifying Trivy gate rejects vulnerable image: ${VULNERABLE_IMAGE} (severity=${TRIVY_SEVERITY})"

docker info >/dev/null 2>&1 || {
  echo "ERROR: Docker daemon is not running; cannot run aquasec/trivy container" >&2
  exit 2
}

set +e
docker run --rm aquasec/trivy:latest image \
  --scanners vuln \
  --severity "${TRIVY_SEVERITY}" \
  --ignore-unfixed \
  --exit-code 42 \
  --format table \
  "${VULNERABLE_IMAGE}"
status=$?
set -e

if [ "${status}" -ne 42 ]; then
  echo "FAIL: Expected Trivy vulnerability exit code 42 on ${VULNERABLE_IMAGE}, got ${status}" >&2
  exit 1
fi

echo "PASS: Trivy gate blocked ${VULNERABLE_IMAGE} with vulnerability exit code ${status}"
