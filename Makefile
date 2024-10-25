.PHONY: build-minimal

VERSION = 0.1.0

IMAGENAME = docker.io/johnwikman/id2202

TAG_X86 = $(IMAGENAME):$(VERSION)-x86
TAG_ARM = $(IMAGENAME):$(VERSION)-arm
TAG_MINIMAL = $(IMAGENAME):$(VERSION)-minimal

build-minimal:
	podman build --format=docker \
	    --tag "$(TAG_MINIMAL)" \
	    --force-rm \
	    --platform="linux/amd64" \
	    --file "Dockerfile-minimal" \
	    .

build-x86:
	podman build --format=docker \
	    --tag "$(TAG_X86)" \
	    --force-rm \
	    --platform="linux/amd64" \
	    --build-arg="TARGETPLATFORM=linux/amd64" \
	    --file "Dockerfile" \
	    .

build-arm:
	podman build --format=docker \
	    --tag "$(TAG_ARM)" \
	    --force-rm \
	    --platform="linux/arm64" \
	    --build-arg="TARGETPLATFORM=linux/arm64" \
	    --file "Dockerfile" \
	    .

test-minimal:
	podman run --rm -it \
	    --platform "linux/amd64" \
	    -v "$(shell pwd -P):/mnt:ro" \
	    -w /root \
	    $(TAG_MINIMAL) \
	    bash -c "nasm -felf64 -o /root/hello.o /mnt/hello.asm \
	          && gcc-10 -z noexecstack -no-pie -o /root/a.out /root/hello.o \
	          && /root/a.out"

push-minimal:
	podman push $(TAG_MINIMAL) docker://$(TAG_MINIMAL)

push-x86:
	podman push $(TAG_X86) docker://$(TAG_X86)
