.PHONY: login pull %-chain

SHELL := /bin/bash

NS_LOCAL := ribose-local
NS_REMOTE ?= metanorma

include ./VERSION.mak

DOCKER_RUN := docker run
DOCKER_EXEC := docker exec

# On Jenkins we won't be on any branch, use the CONTAINER_BRANCH environment
# variable to set it
CONTAINER_BRANCH ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))
ifeq ($(CONTAINER_BRANCH),HEAD)
CONTAINER_BRANCH := main
endif
CONTAINER_COMMIT ?= $(shell git rev-parse --short HEAD)
REPO_GIT_NAME ?= $(shell git config --get remote.origin.url)

ITEMS       ?= 1 2 3 4
IMAGE_TYPES ?= metanorma metanorma-ubuntu mn mn-ubuntu
VERSIONS    ?= $(IMAGE_VERSION) $(IMAGE_VERSION) $(IMAGE_VERSION) $(IMAGE_VERSION)
ROOT_PLATFORMS ?= ruby ubuntu ruby ubuntu

# Getters
GET_IMAGE_TYPE = $(word $1,$(IMAGE_TYPES))
GET_VERSION = $(word $1,$(VERSIONS))
GET_ROOT_PLATFORM = $(word $1,$(ROOT_PLATFORMS))

DOCKER_LOGIN_USERNAME ?=
DOCKER_LOGIN_PASSWORD ?=
DOCKER_LOGIN_CMD ?= "echo \"$(DOCKER_LOGIN_PASSWORD)\" | docker login docker.io --username=$(DOCKER_LOGIN_USERNAME) --password-stdin"

TEST_FLAVOR ?= iso

login:
	eval $(DOCKER_LOGIN_CMD)

define PULL_TASKS
pull-build-$(1):	login
	docker pull $(3); \
	docker pull $(NS_REMOTE)/$(1):$(2);
endef

$(foreach i,$(ITEMS),$(eval $(call PULL_TASKS,$(call GET_IMAGE_TYPE,$i),$(call GET_VERSION,$i),$(call GET_ROOT_PLATFORM,$i))))


## Basic Containers
define ROOT_PLATFORM_TASKS

# All */Dockerfiles are intermediate files, removed after using
# Comment this out when debugging
.INTERMEDIATE: $(3)/Gemfile $(3)/Dockerfile

.PHONY: build-$(3) clean-local-$(3) kill-$(3) rm-$(3) \
	rmf-$(3) tag-$(3) push-$(3) \
	tp-$(3) btp-$(3) bt-$(3) \
	clean-remote-$(3) run-$(3) \
	latest-tag-$(3) latest-push-$(3) latest-tp-$(3)

$(eval CONTAINER_LOCAL_NAME := $(NS_LOCAL)/$(3):$(1))
$(eval CONTAINER_REMOTE_NAME := $(NS_REMOTE)/$(3):$(1))
$(eval CONTAINER_LATEST_NAME := $(NS_REMOTE)/$(3):latest)

# Only the first line is eval'ed by bash

clean-$(3):
	rm -f $(3)/Gemfile $(3)/Dockerfile

$(3)/Gemfile:
	export METANORMA_VERSION=$(1); \
	envsubst '$$$${METANORMA_VERSION}' < $$@.in > $$@

$(3)/Gemfile.lock: $(3)/Gemfile
	pushd $(3); \
	bundle; \
	popd

$(3)/Dockerfile: Dockerfile.$(2).in
	export ROOT_PLATFORM=$(2); \
	export METANORMA_IMAGE_NAME=$(3); \
	envsubst '$$$${METANORMA_IMAGE_NAME}' < $$< > $$@

build-$(3): $(3)/Gemfile $(3)/Dockerfile
	docker build --squash --rm \
		-t $(CONTAINER_LOCAL_NAME) \
		-f $(3)/Dockerfile \
		--label metanorma-container-root=$(2) \
		--label metanorma-container-source=$(REPO_GIT_NAME)/$(3) \
		--label metanorma-container=$(CONTAINER_LOCAL_NAME) \
		--label metanorma-container-remote=$(CONTAINER_REMOTE_NAME) \
		--label metanorma-container-version=$(1) \
		--label metanorma-container-commit=$(CONTAINER_COMMIT) \
		--label metanorma-container-commit-branch=$(CONTAINER_BRANCH) \
		--secret id=bundle_rubygems__pkg__github__com,src=${HOME}/.bundle/config \
		.;\

	$$(MAKE) clean-$(3)

clean-local-$(3):
	docker rmi -f $(CONTAINER_LOCAL_NAME)

clean-remote-$(3):
	docker rmi -f $(CONTAINER_REMOTE_NAME)

run-$(3):
	$(DOCKER_RUN) -it --name=test-$(3) --entrypoint="" $(CONTAINER_REMOTE_NAME) /bin/bash; \

test-$(3):
	$(DOCKER_RUN) $(CONTAINER_LOCAL_NAME) metanorma help; \
	TEST_FLAVORS="iso cc iec ogc un iho"; \
	parallel --gnu --halt 0 -j+0 --joblog parallel.log --eta make test-flavor-$(3) TEST_FLAVOR={} "&>" test_{}.log ::: $$$${TEST_FLAVORS} || \
	(parallel --gnu -j+0 --joblog parallel.log --resume-failed 'echo ---- {} ----; cat test_{}.log; echo ---- --- ----' ::: $$$${TEST_FLAVORS} && exit 1)

test-flavor-$(3):
	[[ -d mn-samples-$(TEST_FLAVOR) ]] || git clone --recurse-submodules https://${GITHUB_CREDENTIALS}@github.com/metanorma/mn-samples-${TEST_FLAVOR}; \
	$(DOCKER_RUN) -v $(shell pwd)/mn-samples-$(TEST_FLAVOR):/metanorma/ $(CONTAINER_LOCAL_NAME) metanorma site generate --agree-to-terms .

kill-$(3):
	docker kill test-$(3)

rm-$(3):
	docker rm test-$(3)

rmf-$(3):
	-docker rm -f test-$(3)

tag-$(3):
	CONTAINER_ID=`docker images -q $(CONTAINER_LOCAL_NAME)`; \
	if [ "$$$${CONTAINER_ID}" == "" ]; then \
		echo "Container non-existant, check 'docker images'."; \
		exit 1; \
	fi; \
	docker tag $$$${CONTAINER_ID} $(CONTAINER_REMOTE_NAME) \
		&& $(MAKE) clean-local-$(3)

push-$(3): login
	docker push $(CONTAINER_REMOTE_NAME)

tp-$(3):
	$(MAKE) tag-$(3) push-$(3)

btp-$(3):
	$(MAKE) build-$(3) tp-$(3)

bt-$(3):
	$(MAKE) build-$(3) tag-$(3)

latest-tag-$(3):
	docker tag $(CONTAINER_REMOTE_NAME) $(CONTAINER_LATEST_NAME)

latest-push-$(3): login
	docker push $(CONTAINER_LATEST_NAME)

latest-tp-$(3):
	$(MAKE) latest-tag-$(3) latest-push-$(3)

print-local-name-$(3):
	@echo $(CONTAINER_LOCAL_NAME)

print-remote-name-$(3):
	@echo $(CONTAINER_REMOTE_NAME)

print-latest-name-$(3):
	@echo $(CONTAINER_LATEST_NAME)

endef

$(foreach i,$(ITEMS),$(eval $(call ROOT_PLATFORM_TASKS,$(call GET_VERSION,$i),$(call GET_ROOT_PLATFORM,$i),$(call GET_IMAGE_TYPE,$i),$(CONTAINER_TYPE))))

build: $(addprefix build-, $(notdir $(IMAGE_TYPES)))
test: $(addprefix test-, $(notdir $(IMAGE_TYPES))) $(addprefix test-flavor-, $(notdir $(IMAGE_TYPES)))
tp: $(addprefix tp-, $(notdir $(IMAGE_TYPES)))
clean: $(addprefix clean-, $(notdir $(IMAGE_TYPES)))
latest-tp: $(addprefix latest-tp-, $(notdir $(IMAGE_TYPES)))
