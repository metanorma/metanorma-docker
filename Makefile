.PHONY: login pull %-chain docker-squash-exists

SHELL := /bin/bash

NS_LOCAL := ribose-local
NS_REMOTE ?= ribose

DOCKER_RUN := docker run
DOCKER_EXEC := docker exec

DOCKER_SQUASH_IMG := $(NS_REMOTE)/docker-squash:latest
DOCKER_SQUASH_CMD := $(DOCKER_RUN) --rm \
  -v $(shell which docker):/usr/bin/docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /docker_tmp $(DOCKER_SQUASH_IMG)

# On Jenkins we won't be on any branch, use the CONTAINER_BRANCH environment
# variable to set it
CONTAINER_BRANCH ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))
ifeq ($(CONTAINER_BRANCH),HEAD)
CONTAINER_BRANCH := master
endif
CONTAINER_COMMIT ?= $(shell git rev-parse --short HEAD)
REPO_GIT_NAME ?= $(shell git config --get remote.origin.url)

ITEMS       ?= 1 2
IMAGE_TYPES ?= metanorma mn
VERSIONS		?= 20190109 20190109
ROOT_IMAGES ?= ubuntu:18.04 ubuntu:18.04
RUBY_VER = 2.5.1

# Getters
GET_IMAGE_TYPE = $(word $1,$(IMAGE_TYPES))
GET_VERSION = $(word $1,$(VERSIONS))
GET_ROOT_IMAGE = $(word $1,$(ROOT_IMAGES))

DOCKER_LOGIN_USERNAME ?=
DOCKER_LOGIN_PASSWORD ?=
DOCKER_LOGIN_CMD ?= "docker login --username=$(DOCKER_LOGIN_USERNAME) --password=\"$(DOCKER_LOGIN_PASSWORD)\""

login:
	eval $(DOCKER_LOGIN_CMD)

docker-squash-exists:
	if [ -z "$$(docker history -q $(DOCKER_SQUASH_IMG))" ]; then \
		docker pull $(DOCKER_SQUASH_IMG); \
	fi

define PULL_TASKS
pull-build-$(1):	login
	docker pull $(3); \
	docker pull $(NS_REMOTE)/$(1):$(2).$(CONTAINER_BRANCH);
endef

$(foreach i,$(ITEMS),$(eval $(call PULL_TASKS,$(call GET_IMAGE_TYPE,$i),$(call GET_VERSION,$i),$(call GET_ROOT_IMAGE,$i))))


## Basic Containers
define ROOT_IMAGE_TASKS

# All */Dockerfiles are intermediate files, removed after using
# Comment this out when debugging
.INTERMEDIATE: $(3)/Dockerfile

.PHONY: build-$(3) clean-local-$(3) kill-$(3) rm-$(3) \
	rmf-$(3) squash-$(3) tag-$(3) push-$(3) sp-$(3) \
	bsp-$(3) tp-$(3) btp-$(3) bt-$(3) bs-$(3) \
	clean-remote-$(3) run-$(3) \
	latest-tag-$(3) latest-push-$(3) latest-tp-$(3)

$(eval CONTAINER_LOCAL_NAME := $(NS_LOCAL)/$(3):$(1).$(CONTAINER_BRANCH))
$(eval CONTAINER_REMOTE_NAME := $(NS_REMOTE)/$(3):$(1).$(CONTAINER_BRANCH))
$(eval CONTAINER_LATEST_NAME := $(NS_REMOTE)/$(3):latest)

# Only the first line is eval'ed by bash
$(3)/Dockerfile:
	VERSION=$(1); \
	ROOT_IMAGE=$(2); \
	CONTAINER_BRANCH=$(CONTAINER_BRANCH); \
	FROM_LINE=`head -1 $$@.in`; \
	FROM_LINE_EVALED=`eval "echo \"$$$${FROM_LINE}\""`; \
		echo "$$$${FROM_LINE_EVALED}" > $$@; \
		sed '1d' $$@.in >> $$@

build-$(3):	$(3)/Dockerfile
	docker build --rm \
		-t $(CONTAINER_LOCAL_NAME) \
		-f $(3)/Dockerfile \
		--label metanorma-container-root=$(2) \
		--label metanorma-container-source=$(REPO_GIT_NAME)/$(3) \
		--label metanorma-container=$(CONTAINER_LOCAL_NAME) \
		--label metanorma-container-remote=$(CONTAINER_REMOTE_NAME) \
		--label metanorma-container-version=$(1) \
		--label metanorma-container-commit=$(CONTAINER_COMMIT) \
		--label metanorma-container-commit-branch=$(CONTAINER_BRANCH) \
		.

clean-local-$(3):
	docker rmi -f $(CONTAINER_LOCAL_NAME)

clean-remote-$(3):
	docker rmi -f $(CONTAINER_REMOTE_NAME)

run-$(3):
	$(DOCKER_RUN) -it --name=test-$(3) --entrypoint="" $(CONTAINER_REMOTE_NAME) /bin/bash; \

test-$(3):
	$(DOCKER_RUN) $(CONTAINER_REMOTE_NAME) /bin/bash 'metanorma -h'

kill-$(3):
	docker kill test-$(3)

rm-$(3):
	docker rm test-$(3)

rmf-$(3):
	-docker rm -f test-$(3)

squash-$(3):	docker-squash-exists $(3)/Dockerfile
	FROM_IMAGE=`head -1 $(3)/Dockerfile | cut -f 2 -d ' '`; \
	$(DOCKER_SQUASH_CMD) -t $(CONTAINER_REMOTE_NAME) \
		-f $$$${FROM_IMAGE} \
		$(CONTAINER_LOCAL_NAME) \
		&& $(MAKE) clean-local-$(3)

tag-$(3):
	CONTAINER_ID=`docker images -q $(CONTAINER_LOCAL_NAME)`; \
	if [ "$$$${CONTAINER_ID}" == "" ]; then \
		echo "Container non-existant, check 'docker images'."; \
		exit 1; \
	fi; \
	docker tag $$$${CONTAINER_ID} $(CONTAINER_REMOTE_NAME) \
		&& $(MAKE) clean-local-$(3)

push-$(3):	login
	docker push $(CONTAINER_REMOTE_NAME)

sp-$(3):
	$(MAKE) squash-$(3) push-$(3)

bsp-$(3):
	$(MAKE) build-$(3) sp-$(3)

tp-$(3):
	$(MAKE) tag-$(3) push-$(3)

btp-$(3):
	$(MAKE) build-$(3) tp-$(3)

bt-$(3):
	$(MAKE) build-$(3) tag-$(3)

bs-$(3):
	$(MAKE) build-$(3) squash-$(3)

latest-tag-$(3):
	docker tag $(CONTAINER_REMOTE_NAME) $(CONTAINER_LATEST_NAME)

latest-push-$(3):
	docker push $(CONTAINER_LATEST_NAME)

latest-tp-$(3):
	$(MAKE) latest-tag-$(3) latest-push-$(3)

endef

$(foreach i,$(ITEMS),$(eval $(call ROOT_IMAGE_TASKS,$(call GET_VERSION,$i),$(call GET_ROOT_IMAGE,$i),$(call GET_IMAGE_TYPE,$i),$(CONTAINER_TYPE))))

build: $(addprefix build-, $(notdir $(IMAGE_TYPES)))
test: $(addprefix test-, $(notdir $(IMAGE_TYPES)))
tp: $(addprefix tp-, $(notdir $(IMAGE_TYPES)))