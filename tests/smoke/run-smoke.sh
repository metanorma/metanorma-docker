#!/usr/bin/env bash
# Smoke gate: prove a built image actually runs Metanorma before it is
# published. Compiles tests/smoke/sample.adoc to XML + HTML + PDF inside
# the container — the PDF leg exercises the spawned Java subsystem, the
# SVG figure exercises the graphics chain.
#
# Usage: tests/smoke/run-smoke.sh <image-ref>
set -euo pipefail

IMAGE="${1:?usage: run-smoke.sh <image-ref>}"
FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ":: ${IMAGE} — metanorma version"
docker run --rm "${IMAGE}" metanorma version

echo ":: ${IMAGE} — compiling sample.adoc (xml, html, pdf)"
docker run --rm \
  -v "${FIXTURE_DIR}:/src:ro" \
  -w /tmp \
  --entrypoint /bin/bash \
  "${IMAGE}" \
  -c '
    set -euo pipefail
    cp /src/sample.adoc /src/figure.svg /tmp/
    metanorma compile --type iso --agree-to-terms sample.adoc
    for f in sample.xml sample.html sample.pdf; do
      if [ ! -s "$f" ]; then
        echo "smoke FAILED: $f missing or empty" >&2
        exit 1
      fi
      echo "smoke artifact: $f ($(wc -c < "$f") bytes)"
    done
  '

echo "smoke PASS: ${IMAGE}"
