# Base image tags. The Debian variant receives this via the
# RUBY_VERSION build-arg (Makefile, build-push.yml, trivy/dockle).
RUBY_VERSION := 4.0.7

# Image version: tracks the metanorma-cli release (metanorma/metanorma-cli),
# written by the release-tag workflow.
IMAGE_VERSION := 1.17.0
