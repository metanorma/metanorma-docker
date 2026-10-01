# Base image tags. The variants receive these via the RUBY_VERSION and
# ALPINE_RUBY_VERSION build-args (Makefile, build-push.yml, trivy/dockle).
RUBY_VERSION := 4.0.7
ALPINE_RUBY_VERSION := 4.0.7

# Image version: tracks the metanorma-cli release (metanorma/metanorma-cli),
# written by the release-tag workflow.
IMAGE_VERSION := 1.17.0
