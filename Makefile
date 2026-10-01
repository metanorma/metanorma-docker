.PHONY: login build test tp clean latest-tp

SHELL := /bin/bash

NS_LOCAL := ribose-local
NS_REMOTE ?= metanorma

# Versions and digests: VERSION.mak is the single source of truth.
include ./VERSION.mak

# On Jenkins we won't be on any branch, use the CONTAINER_BRANCH environment
# variable to set it
CONTAINER_BRANCH ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))
ifeq ($(CONTAINER_BRANCH),HEAD)
CONTAINER_BRANCH := main
endif
CONTAINER_COMMIT ?= $(shell git rev-parse --short HEAD)
REPO_GIT_NAME ?= $(shell git config --get remote.origin.url)

# Image variants:
#  metanorma-debian — the main variant (unprefixed tags on Docker
#    Hub/GHCR): gem-based build on ruby:4.0.7-slim, multi-arch.
#  metanorma-alpine — same gem-based build path on ruby:3.3.7-alpine,
#    smallest footprint.
IMAGE_TYPES ?= metanorma-debian metanorma-alpine

GET_PLATFORM = $(patsubst metanorma-%,%,$(1))

DOCKER_LOGIN_USERNAME ?=
DOCKER_LOGIN_PASSWORD ?=
DOCKER_LOGIN_CMD ?= "echo \"$(DOCKER_LOGIN_PASSWORD)\" | docker login docker.io --username=$(DOCKER_LOGIN_USERNAME) --password-stdin"

login:
	eval $(DOCKER_LOGIN_CMD)

define IMAGE_TASKS

.PHONY: build-$(1) test-$(1) run-$(1) kill-$(1) rm-$(1) rmf-$(1) tag-$(1) push-$(1) tp-$(1) btp-$(1) bt-$(1) \
	clean-local-$(1) clean-remote-$(1) latest-tag-$(1) latest-push-$(1) latest-tp-$(1)

$(eval CONTAINER_LOCAL_NAME := $(NS_LOCAL)/$(1):latest)
$(eval CONTAINER_REMOTE_NAME := $(NS_REMOTE)/$(1):$(IMAGE_VERSION))
$(eval CONTAINER_LATEST_NAME := $(NS_REMOTE)/$(1):latest)

build-$(1):
	docker build --rm \
		-t $(CONTAINER_LOCAL_NAME) \
		-f Dockerfile.$(call GET_PLATFORM,$(1)) \
		--platform linux/amd64 \
		--build-arg RUBY_VERSION=$(RUBY_VERSION) \
		--build-arg ALPINE_RUBY_VERSION=$(ALPINE_RUBY_VERSION) \
		--label metanorma-container-root=$(call GET_PLATFORM,$(1)) \
		--label metanorma-container-source=$(REPO_GIT_NAME)/$(1) \
		--label metanorma-container=$(CONTAINER_LOCAL_NAME) \
		--label metanorma-container-remote=$(CONTAINER_REMOTE_NAME) \
		--label metanorma-container-version=$(IMAGE_VERSION) \
		--label metanorma-container-commit=$(CONTAINER_COMMIT) \
		--label metanorma-container-commit-branch=$(CONTAINER_BRANCH) \
		.

# Smoke gate: `metanorma version` + a real document compile (xml, html,
# pdf — the PDF leg exercises the spawned Java subsystem).
test-$(1):
	tests/smoke/run-smoke.sh $(CONTAINER_LOCAL_NAME)

run-$(1):
	docker run -it --name=test-$(1) --entrypoint="" $(CONTAINER_LOCAL_NAME) /bin/bash

kill-$(1):
	docker kill test-$(1)

rm-$(1):
	docker rm test-$(1)

rmf-$(1):
	docker rm -f test-$(1)

tag-$(1):
	CONTAINER_ID=`docker images -q $(CONTAINER_LOCAL_NAME)`; \
	if [ "$$$${CONTAINER_ID}" == "" ]; then \
		echo "Container non-existent, check 'docker images'."; \
		exit 1; \
	fi; \
	docker tag $$$${CONTAINER_ID} $(CONTAINER_REMOTE_NAME)

push-$(1): login
	docker push $(CONTAINER_REMOTE_NAME)

tp-$(1): tag-$(1) push-$(1)

btp-$(1): build-$(1) tp-$(1)

bt-$(1): build-$(1) tag-$(1)

clean-local-$(1):
	docker rmi -f $(CONTAINER_LOCAL_NAME)

clean-remote-$(1):
	docker rmi -f $(CONTAINER_REMOTE_NAME)

latest-tag-$(1):
	docker tag $(CONTAINER_REMOTE_NAME) $(CONTAINER_LATEST_NAME)

latest-push-$(1): login
	docker push $(CONTAINER_LATEST_NAME)

latest-tp-$(1): latest-tag-$(1) latest-push-$(1)

endef

$(foreach t,$(IMAGE_TYPES),$(eval $(call IMAGE_TASKS,$(t))))

build: $(addprefix build-, $(IMAGE_TYPES))
test: $(addprefix test-, $(IMAGE_TYPES))
tp: $(addprefix tp-, $(IMAGE_TYPES))
latest-tp: $(addprefix latest-tp-, $(IMAGE_TYPES))
