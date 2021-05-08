.ONESHELL:

BINARIES ?= tpm_attestor_server tpm_attestor_agent get_tpm_pubhash
OSES ?= linux
ARCHITECTURES ?= amd64 arm64
VERSION ?= develop
DOCKER_REGISTRY ?= docker.io
BUILD_DIR ?= ./build
RELEASES_DIR ?= ./releases

BUILD_TARGETS := $(foreach binary, $(BINARIES), $(foreach os, $(OSES), $(foreach architecture, $(ARCHITECTURES), $(binary)-$(os)-$(architecture))))
RELEASE_TARGETS := $(foreach build, $(BUILD_TARGETS), $(build)-release)
DOCKER_TARGETS := $(foreach binary, $(BINARIES), $(binary)-docker)

DOCKER_PLATFORMS := $(foreach os, $(OSES), $(foreach architecture, $(ARCHITECTURES), --platform $(os)/$(architecture)))

target_words = $(subst -, ,$@)
target_binary = $(word 1, $(target_words))
target_os = $(word 2, $(target_words))
target_architecture = $(word 2, $(target_words))

target_binary_hyphens = $(subst _,-,$(target_binary))

build: $(BUILD_TARGETS)
$(BUILD_TARGETS):
	CGO_ENABLED=0 GOOS=$(target_os) GOARCH=$(target_architecture) go build -ldflags="-s -w" -o $(BUILD_DIR)/$(target_os)/$(target_architecture)/$(target_binary) cmd/$(target_binary)/main.go

test:
	go test ./...

release: $(RELEASE_TARGETS)
$(RELEASE_TARGETS):
	mkdir -p releases
	tar --owner=root --group=root -cvzf $(RELEASES_DIR)/spire_tpm_plugin_$(target_binary)_$(target_os)_$(target_architecture)_$(VERSION).tar.gz -C $(BUILD_DIR)/$(target_os)/$(target_architecture) $(target_binary)

docker: $(DOCKER_IMAGES)
$(DOCKER_IMAGES):
	docker buildx build $(DOCKER_PLATFORMS) --build-arg version=$(VERSION) --build-arg binary=$(target_docker_binary) -t $(REGISTRY)/spire-tpm-plugin-$(target_binary_hyphens):$(VERSION) .

clean:
	rm -rf build releases

.PHONY: $(BUILDS) $(RELEASES) $($(DOCKER_IMAGES)) build test release docker clean
