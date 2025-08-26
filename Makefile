.PHONY: build-minimal

SHELL = bash

VERSION = 0.3.0

IMAGENAME = johnwikman/id2202

TAG_MINIMAL = $(IMAGENAME):$(VERSION)-minimal
TAG_X86 = $(IMAGENAME):$(VERSION)-x86
TAG_ARM = $(IMAGENAME):$(VERSION)-arm

LANGUAGES = ocaml scala rust java haskell
LANGUAGES_UC = $(foreach l,$(LANGUAGES),$(shell echo $(l) | tr '[:lower:]' '[:upper:]'))

CONTAINER_RUNTIME ?= podman
ifeq ($(CONTAINER_RUNTIME),podman)
CMD_BUILD           = podman build --format=docker --force-rm --file=Dockerfile
CMD_PUSH_f          = podman push $1 docker://docker.io/$1
CMD_MANIFEST        = podman manifest
CMD_MANIFEST_PUSH_f = podman manifest push --rm $1 docker://docker.io/$1
else ifeq ($(CONTAINER_RUNTIME),docker)
CMD_BUILD           = docker build --force-rm --file=Dockerfile
CMD_PUSH_f          = docker push $1
CMD_MANIFEST        = docker manifest
CMD_MANIFEST_PUSH_f = docker manifest push --purge $1
else
$(error Unsupported runtime $(CONTAINER_RUNTIME))
endif

show-variables:
	@echo -e "\e[1;33mSHELL = \e[0;38m$(SHELL)\e[0m"
	@echo -e "\e[1;33mVERSION = \e[0;38m$(VERSION)\e[0m"
	@echo -e "\e[1;33mTAG_MINIMAL = \e[0;38m$(TAG_MINIMAL)\e[0m"
	@echo -e "\e[1;33mTAG_X86 = \e[0;38m$(TAG_X86)\e[0m"
	@echo -e "\e[1;33mTAG_ARM = \e[0;38m$(TAG_ARM)\e[0m"
	@echo -e "\e[1;33mLANGUAGES = \e[0;38m$(LANGUAGES)\e[0m"
	@echo -e "\e[1;33mLANGUAGES_UC = \e[0;38m$(LANGUAGES_UC)\e[0m"
	@echo -e "\e[1;33mCONTAINER_RUNTIME = \e[0;38m$(CONTAINER_RUNTIME)\e[0m"
	@echo -e "\e[1;33mCMD_BUILD = \e[0;38m$(CMD_BUILD)\e[0m"
	@echo -e "\e[1;33mCMD_PUSH_f = \e[0;38m$(call CMD_PUSH_f,<ARG>)\e[0m"
	@echo -e "\e[1;33mCMD_MANIFEST = \e[0;38m$(CMD_MANIFEST)\e[0m"
	@echo -e "\e[1;33mCMD_MANIFEST_PUSH_f = \e[0;38m$(call CMD_MANIFEST_PUSH_f,<ARG>)\e[0m"


#▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌
#▐  ____        _ _     _   ____        _            ▌
#▐ | __ ) _   _(_) | __| | |  _ \ _   _| | ___  ___  ▌
#▐ |  _ \| | | | | |/ _` | | |_) | | | | |/ _ \/ __| ▌
#▐ | |_) | |_| | | | (_| | |  _ <| |_| | |  __/\__ \ ▌
#▐ |____/ \__,_|_|_|\__,_| |_| \_\\__,_|_|\___||___/ ▌
#▐▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌

# Minimal build script is a special case, since we will always build for the
# x86 platform.
build-minimal:
	$(CMD_BUILD) \
	    --tag "$(TAG_MINIMAL)" --target minimal \
	    --platform="linux/amd64" \
	    .

# Generic recipe for building images that can be used to compile and run
# projects. Change build configuration using the following arguments:
#  - BUILD_PLATFORM: The platform to build for. Use either linux/amd64 or
#                    linux/arm64.
#  - BUILD_TAG: The tag to be given to the built image.
#  - BUILD_LANGS: Space separated list of languages to build for. Languages
#                 must be specified using upper case letters.
_build-generic:
	$(eval EXTRA_BUILD_ARGS := $(foreach l,$(BUILD_LANGS),--build-arg="INSTALL_$(l)=y"))
	@if [ "$(BUILD_PLATFORM)" == "" ]; then echo -e "\e[1;31mBUILD_PLATFORM argument not specified\e[0m"; exit 1; fi
	@if [ "$(BUILD_TAG)" == "" ];      then echo -e "\e[1;31mBUILD_TAG argument not specified\e[0m"; exit 1; fi
	$(CMD_BUILD) \
	    --tag "$(BUILD_TAG)" --target complete \
	    --platform="$(BUILD_PLATFORM)" \
	    --build-arg="TARGETPLATFORM=$(BUILD_PLATFORM)" \
	    $(EXTRA_BUILD_ARGS) \
	    .

_build-lang-x86-%:
	$(eval LANG_LC := $*)
	$(eval LANG_UC := $(shell echo "$*" | tr '[:lower:]' '[:upper:]'))
	make _build-generic "BUILD_PLATFORM=linux/amd64" \
	    "BUILD_TAG=$(TAG_X86)-$(LANG_LC)" \
	    "BUILD_LANGS=$(LANG_UC)"

_build-lang-arm-%:
	$(eval LANG_LC := $*)
	$(eval LANG_UC := $(shell echo "$*" | tr '[:lower:]' '[:upper:]'))
	make _build-generic "BUILD_PLATFORM=linux/arm64" \
	    "BUILD_TAG=$(TAG_ARM)-$(LANG_LC)" \
	    "BUILD_LANGS=$(LANG_UC)"

build-complete-x86:
	make _build-generic "BUILD_PLATFORM=linux/amd64" \
	    "BUILD_TAG=$(TAG_X86)" \
	    "BUILD_LANGS=$(LANGUAGES_UC)"

build-complete-arm:
	make _build-generic "BUILD_PLATFORM=linux/arm64" \
	    "BUILD_TAG=$(TAG_ARM)" \
	    "BUILD_LANGS=$(LANGUAGES_UC)"

build-ocaml-x86:   _build-lang-x86-ocaml
build-scala-x86:   _build-lang-x86-scala
build-rust-x86:    _build-lang-x86-rust
build-java-x86:    _build-lang-x86-java
build-haskell-x86: _build-lang-x86-haskell

build-ocaml-arm:   _build-lang-arm-ocaml
build-scala-arm:   _build-lang-arm-scala
build-rust-arm:    _build-lang-arm-rust
build-java-arm:    _build-lang-arm-java
build-haskell-arm: _build-lang-arm-haskell


# ▐▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▌
# ▐  ____            _       ____        _            ▌
# ▐ |  _ \ _   _ ___| |__   |  _ \ _   _| | ___  ___  ▌
# ▐ | |_) | | | / __| '_ \  | |_) | | | | |/ _ \/ __| ▌
# ▐ |  __/| |_| \__ \ | | | |  _ <| |_| | |  __/\__ \ ▌
# ▐ |_|    \__,_|___/_| |_| |_| \_\\__,_|_|\___||___/ ▌
# ▐▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▌
# (only run these AFTER testing the images)
#
# Note: Make sure to first login to the repository using
# `podman login -u johnwikman docker.io`

# Specify the tag as using the PUSH_TAG argument
_push-tag:
	@if [ "$(PUSH_TAG)" == "" ]; then echo -e "\e[1;31mPUSH_TAG argument not specified\e[0m"; exit 1; fi
	$(call CMD_PUSH_f,$(PUSH_TAG))

push-minimal:; make _push-tag "PUSH_TAG=$(TAG_MINIMAL)"
push-x86:;     make _push-tag "PUSH_TAG=$(TAG_X86)"
push-arm:;     make _push-tag "PUSH_TAG=$(TAG_ARM)"

push-ocaml-x86:;   make _push-tag "PUSH_TAG=$(TAG_X86)-ocaml"
push-scala-x86:;   make _push-tag "PUSH_TAG=$(TAG_X86)-scala"
push-rust-x86:;    make _push-tag "PUSH_TAG=$(TAG_X86)-rust"
push-java-x86:;    make _push-tag "PUSH_TAG=$(TAG_X86)-java"
push-haskell-x86:; make _push-tag "PUSH_TAG=$(TAG_X86)-haskell"

push-ocaml-arm:;   make _push-tag "PUSH_TAG=$(TAG_ARM)-ocaml"
push-scala-arm:;   make _push-tag "PUSH_TAG=$(TAG_ARM)-scala"
push-rust-arm:;    make _push-tag "PUSH_TAG=$(TAG_ARM)-rust"
push-java-arm:;    make _push-tag "PUSH_TAG=$(TAG_ARM)-java"
push-haskell-arm:; make _push-tag "PUSH_TAG=$(TAG_ARM)-haskell"

push-manifest:
	@# Using the || true since there is no -f option to `manifest rm`
	$(CMD_MANIFEST) rm $(IMAGENAME):$(VERSION)         || true
	$(CMD_MANIFEST) rm $(IMAGENAME):latest             || true
	$(CMD_MANIFEST) rm $(IMAGENAME):minimal            || true
	for l in $(LANGUAGES); do \
		$(CMD_MANIFEST) rm $(IMAGENAME):$(VERSION)-$$l || true; \
		$(CMD_MANIFEST) rm $(IMAGENAME):latest-$$l || true; \
	done

	$(CMD_MANIFEST) create $(IMAGENAME):$(VERSION)         --amend "$(TAG_X86)" --amend "$(TAG_ARM)"
	$(CMD_MANIFEST) create $(IMAGENAME):latest             --amend "$(TAG_X86)" --amend "$(TAG_ARM)"
	$(CMD_MANIFEST) create $(IMAGENAME):minimal            --amend "$(TAG_MINIMAL)"
	for l in $(LANGUAGES); do \
		$(CMD_MANIFEST) create $(IMAGENAME):$(VERSION)-$$l --amend "$(TAG_X86)-$$l" --amend "$(TAG_ARM)-$$l" && \
		$(CMD_MANIFEST) create $(IMAGENAME):latest-$$l     --amend "$(TAG_X86)-$$l" --amend "$(TAG_ARM)-$$l"; \
	done

	$(call CMD_MANIFEST_PUSH_f,$(IMAGENAME):$(VERSION))
	$(call CMD_MANIFEST_PUSH_f,$(IMAGENAME):latest)
	$(call CMD_MANIFEST_PUSH_f,$(IMAGENAME):minimal)
	for l in $(LANGUAGES); do \
		$(call CMD_MANIFEST_PUSH_f,$(IMAGENAME):$(VERSION)-$$l); \
		$(call CMD_MANIFEST_PUSH_f,$(IMAGENAME):latest-$$l); \
	done
