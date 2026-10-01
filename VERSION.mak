# Single source of truth for image-level version numbers in this
# repository. The Makefile includes this file; the Dockerfiles and CI
# workflows parse it with `cut -d' ' -f3` (keep the `KEY := value` shape).

# Image version: tracks the metanorma-cli release (metanorma/metanorma-cli),
# written by the release-tag workflow. The per-variant gem pins live in
# metanorma-debian/Gemfile and metanorma-alpine/Gemfile (kept in lockstep
# by the same workflow).
IMAGE_VERSION := 1.17.0
