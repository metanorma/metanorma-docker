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

# Pin fontist formulas: the container clones formulas at HEAD, and the
# source-fonts v1.3 refresh (fontist/formulas#287) broke Source Han Sans /
# Source Sans Pro installs, failing the PDF stage. Pin the clone to the
# last known-good commit until #287 is fixed.
FORMULAS_PIN="$(mktemp -d)"
git clone --quiet https://github.com/fontist/formulas.git "${FORMULAS_PIN}/Formulas"
git -C "${FORMULAS_PIN}/Formulas" checkout --quiet 74c038bf85e2393177ef303920db74a2c821740b

docker run --rm \
  -v "${FIXTURE_DIR}:/src:ro" \
  -v "${FORMULAS_PIN}:/root/.fontist/versions/v5/formulas" \
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
