# ==============================================================================
# ✨ Aqeel's Enchanted Makefile System ✨ https://aqeelakber.com/Makefile ✨
# 🪄 For you:
# 🐈‍ This Makefile is quietly watched over by an enchanted cat.
# 🧙 Minimal Configuration – edit just these:
PROJECT_USE        = Your Project Name (Customize Me!)
IMAGE_NAMESPACE    = your-namespace     # e.g. your GitLab or GitHub username
IMAGE_NAME         = your-image-name    # logical name of your container image
REGISTRY           = registry.gitlab.com
CONTAINER_RUNTIME ?= podman             # or: make CONTAINER_RUNTIME=docker
CONTAINERFILE     ?= Containerfile
# ==============================================================================

# ------------------------------------------------------------------------------
# Derived – no need to edit unless you're hacking the system
# ------------------------------------------------------------------------------
BUILDER_RUNTIME     ?= $(if $(filter $(CONTAINER_RUNTIME),docker),docker,buildah)
GIT_COMMIT          := $(shell git rev-parse --short HEAD)
GIT_BRANCH          := $(shell git rev-parse --abbrev-ref HEAD)
WORKTREE_DIRTY      := $(shell test -n "$$(git status --porcelain)" && echo "yes" || echo "no")
CONTAINERFILE_DIRTY := $(shell git status --porcelain $(CONTAINERFILE) | grep -q . && echo "yes" || echo "no")
GIT_REMOTE_URL      := $(shell git remote get-url origin 2>/dev/null || echo "N/A")

IMAGE_TAG           := $(GIT_COMMIT)
IMAGE_BASE          := $(strip $(REGISTRY))/$(strip $(IMAGE_NAMESPACE))/$(strip $(IMAGE_NAME))
IMAGE_WITH_TAG      := $(IMAGE_BASE):$(strip $(GIT_COMMIT))
CONTAINER_HOME      := /home/dev
OS                  := $(shell uname)
GIT_REPO_PATH       := $(shell git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/.]+)(\.git)?$$#\1#')

# ------------------------------------------------------------------------------
# Help System
# ------------------------------------------------------------------------------
default: help

help: ## Show all available make targets
	@echo "✨ Welcome to Aqeel's Enchanted Makefile ✨"
	@echo "🪄 For you: $(PROJECT_USE)"
	@echo "-----------------------------------------"
	@if [ "$(WORKTREE_DIRTY)" = "yes" ]; then \
		echo "⚠ Git working directory has uncommitted changes."; \
	fi
	@echo "📂 Project:   $(GIT_REPO_PATH)"
	@echo "🌐 Remote:    $(GIT_REMOTE_URL)"
	@echo "🌿 Branch:    $(GIT_BRANCH)"
	@echo "📦 Registry:  $(REGISTRY)"
	@echo "🖼  Image:     $(IMAGE_BASE):$(IMAGE_TAG)"
	@echo
	@echo "Commands:"
	@grep -E '^[a-zA-Z0-9/_-]+:.*?##' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
		{ printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 }'
	@echo "-----------------------------------------"

# ------------------------------------------------------------------------------
# OCI (Container) Namespace
# ------------------------------------------------------------------------------
oci/build: ## Build the container image (uses buildah or docker)
	$(BUILDER_RUNTIME) bud --pull --layers -f $(CONTAINERFILE) -t $(IMAGE_WITH_TAG) .

oci/tag: ## Tag the image as :latest (only if $(CONTAINERFILE) is clean)
	@if [ "$(CONTAINERFILE_DIRTY)" = "yes" ]; then \
		echo "❌ Cannot tag as latest – $(CONTAINERFILE) has uncommitted changes."; \
		exit 1; \
	fi
	$(CONTAINER_RUNTIME) tag $(IMAGE_WITH_TAG) $(IMAGE_BASE):latest

oci/push: ## Push only the commit-tagged image
	$(CONTAINER_RUNTIME) login $(REGISTRY)
	$(CONTAINER_RUNTIME) push $(IMAGE_WITH_TAG)

oci/push-latest: oci/tag ## Push :latest (must be explicitly invoked)
	$(CONTAINER_RUNTIME) push $(IMAGE_BASE):latest

# ------------------------------------------------------------------------------
# Declare phony targets
# ------------------------------------------------------------------------------
.PHONY: default help oci/build oci/tag oci/push oci/push-latest

# ------------------------------------------------------------------------------
# ✨ Aqeel's Enchanted Makefile ✨
# 🪄 Magic: Use '##' to auto-document targets (see: make help)
# Example:
# dev/shell: ## Open dev shell
#     $(CONTAINER_RUNTIME) run $(CONTAINER_ARGS) $(IMAGE_BASE) bash
# For licence and snippets visit:
# 📖 github.com/admiralakber/enchanted-makefile
# ------------------------------------------------------------------------------
