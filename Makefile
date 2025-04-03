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
CMD ?= bash  # Default command for oci/run
# ==============================================================================

# ------------------------------------------------------------------------------
# Derived – no need to edit unless you're hacking the system
# ------------------------------------------------------------------------------
BUILDER_RUNTIME     ?= $(if $(filter $(CONTAINER_RUNTIME),docker),docker,buildah)
GIT_COMMIT          := $(strip $(shell git rev-parse --short HEAD))
GIT_BRANCH          := $(shell git rev-parse --abbrev-ref HEAD)
WORKTREE_DIRTY      := $(shell test -n "$$(git status --porcelain)" && echo "yes" || echo "no")
CONTAINERFILE_DIRTY := $(shell git status --porcelain $(CONTAINERFILE) | grep -q . && echo "yes" || echo "no")
GIT_REMOTE_URL      := $(shell git remote get-url origin 2>/dev/null || echo "N/A")

IMAGE_BASE          := $(strip $(REGISTRY))/$(strip $(IMAGE_NAMESPACE))/$(strip $(IMAGE_NAME))
CONTAINER_HOME      := /home/dev
OS                  := $(shell uname)
GIT_REPO_PATH       := $(shell git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/.]+)(\.git)?$$#\1#')

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
# Check if a container image exists (param: image tag)
define check_image_exists
	@if ! $(CONTAINER_RUNTIME) image exists $(IMAGE_BASE):$(1) 2>/dev/null; then \
		echo "❌ Image $(IMAGE_BASE):$(1) not found"; \
		exit 1; \
	fi
endef

# Check if git worktree is dirty, with optional confirmation prompt
# Params: (1) message - custom message to display (optional)
define check_dirty_worktree
	@if [ "$(WORKTREE_DIRTY)" = "yes" ]; then \
		echo "⚠️  $(if $(1),$(1),Warning: Working with dirty git tree)"; \
		read -p "Continue? [y/N] " confirm; \
		[ "$${confirm:-N}" = "y" ] || exit 1; \
	fi
endef

# Ensure git worktree is clean, exit if dirty 
# Params: (1) message - custom error message to display (optional)
define ensure_clean_worktree
	@if [ "$(WORKTREE_DIRTY)" = "yes" ]; then \
		echo "❌ $(if $(1),$(1),Cannot proceed with dirty worktree)"; \
		exit 1; \
	fi
endef

# Sanitize a string for use as a container tag
# Usage: $(call sanitize_string,$(SOME_STRING))
# Returns: sanitized string
define sanitize_string
	$(shell echo "$(1)" | sed -e 's/[^a-zA-Z0-9_.-]/-/g' -e 's/^[-.]//');
endef

# ------------------------------------------------------------------------------
# Help System
# ------------------------------------------------------------------------------
default: help

help: ## Display available make targets with descriptions and project info
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
	@echo "🖼  Image:     $(IMAGE_BASE):$(GIT_COMMIT)"
	@echo
	@echo "Commands:"
	@grep -E '^[a-zA-Z0-9/_-]+:.*?##' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; \
		{ printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 }'
	@echo "-----------------------------------------"

# ------------------------------------------------------------------------------
# OCI (Container) Namespace
# ------------------------------------------------------------------------------
oci/build: ## Build image with current git commit hash tag (warns if dirty)
	$(call check_dirty_worktree,Warning: Building image from dirty worktree)
	$(BUILDER_RUNTIME) bud --pull --layers -f $(CONTAINERFILE) -t $(IMAGE_BASE):$(GIT_COMMIT) .
	@echo "✅ Built: $(IMAGE_BASE):$(GIT_COMMIT)"

oci/tag-latest: ## Tag commit-hash image as 'latest'
	$(call check_image_exists,$(GIT_COMMIT))
	$(CONTAINER_RUNTIME) tag $(IMAGE_BASE):$(GIT_COMMIT) $(IMAGE_BASE):latest
	@echo "✅ Tagged as latest"

oci/list: ## List all local images for this project with timestamps
	@$(CONTAINER_RUNTIME) images --format "table {{.Tag}}\t{{.CreatedAt}}" $(IMAGE_BASE)

oci/tag-branch: ## Tag commit-hash image with sanitized git branch name
	$(call check_image_exists,$(GIT_COMMIT))
	@SAFE_BRANCH=$(call sanitize_string,$(GIT_BRANCH)); \
	$(CONTAINER_RUNTIME) tag $(IMAGE_BASE):$(GIT_COMMIT) $(IMAGE_BASE):$$SAFE_BRANCH; \
	echo "✅ Tagged as: $$SAFE_BRANCH"

oci/push: ## Push commit-hash image to registry (requires clean worktree)
	$(call ensure_clean_worktree,Cannot push image with dirty worktree)
	$(CONTAINER_RUNTIME) login $(REGISTRY)
	$(CONTAINER_RUNTIME) push $(IMAGE_BASE):$(GIT_COMMIT)

oci/push-latest: oci/push oci/tag-latest ## Push commit-hash and 'latest' tags
	$(CONTAINER_RUNTIME) push $(IMAGE_BASE):latest

oci/run: ## Run container with specified command (default: bash). Usage: make oci/run [CMD=...]
	$(call check_image_exists,$(GIT_COMMIT))
	$(CONTAINER_RUNTIME) run -it --rm $(IMAGE_BASE):$(GIT_COMMIT) $(CMD)

# ------------------------------------------------------------------------------
# ✨ Aqeel's Enchanted Makefile ✨
# 🪄 Magic: Use '##' to auto-document targets (see: make help)
# Example:
# dev/shell: ## Open dev shell
#     $(CONTAINER_RUNTIME) run $(CONTAINER_ARGS) $(IMAGE_BASE) bash
# For licence and snippets visit:
# 📖 github.com/admiralakber/enchanted-makefile
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Declare phony targets
# ------------------------------------------------------------------------------
.PHONY: default help oci/build oci/tag-latest oci/push oci/push-latest oci/list oci/tag-branch oci/run
