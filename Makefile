# RunnerImages - Build, verify, and manage CI runner images
# Usage: make <target>

SHELL := /bin/bash
FLAVOUR ?= ubuntu
PLATFORM ?= linux/amd64

# --- Build ---
.PHONY: build
build: ## Build the image for FLAVOUR (default: ubuntu)
	PLATFORM=$(PLATFORM) ./scripts/build.sh $(FLAVOUR)

.PHONY: build-scan
build-scan: ## Build and run security scan
	PLATFORM=$(PLATFORM) ./scripts/build.sh $(FLAVOUR) --scan

.PHONY: build-push
build-push: ## Build and push to registry
	PLATFORM=$(PLATFORM) ./scripts/build.sh $(FLAVOUR) --push

.PHONY: build-all
build-all: ## Build all available flavours
	@for flavour in $$(ls images/ | grep -v '^shared$$'); do \
		echo "=== Building $$flavour ($(PLATFORM)) ==="; \
		PLATFORM=$(PLATFORM) ./scripts/build.sh $$flavour || exit 1; \
	done

# --- Verify ---
.PHONY: verify
verify: ## Verify the image for FLAVOUR
	PLATFORM=$(PLATFORM) ./scripts/verify.sh $(FLAVOUR)

.PHONY: verify-all
verify-all: ## Verify all built images
	@for flavour in $$(ls images/ | grep -v '^shared$$'); do \
		echo "=== Verifying $$flavour ($(PLATFORM)) ==="; \
		PLATFORM=$(PLATFORM) ./scripts/verify.sh $$flavour || exit 1; \
	done

# --- Lint ---
.PHONY: lint
lint: ## Run all linters (shellcheck, pre-commit)
	shellcheck scripts/*.sh
	pre-commit run --all-files

.PHONY: check-bu
check-bu: ## Check BU layer consistency across flavours
	./scripts/check-bu-consistency.sh

# --- Clean ---
.PHONY: clean
clean: ## Remove built images
	docker images --format '{{.Repository}}:{{.Tag}}' | grep 'runner-images' | xargs -r docker rmi

# --- Help ---
.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
