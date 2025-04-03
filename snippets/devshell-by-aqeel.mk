# ---------------------------------------
# https://github.com/admiralakber/enchanted-makefile
# 🪄 Snippet: Container Dev Shell with GUI/Audio Forwarding
# For a distrobox like experience but just for your repo / image.
# ✨ Originally contributed by: Aqeel | GitHub: @admiralakber
# ---------------------------------------

# Uncomment and define or just use Enchanted Makefile base:
# OS                ?= $(shell uname)
# CONTAINER_RUNTIME ?= podman
# CONTAINER_HOME    ?= /home/dev
# IMAGE_BASE        ?= your-namespace/your-image

# ------------------------------------------------------------------------------
# GUI/Audio Forwarding Configuration
# ------------------------------------------------------------------------------
DISPLAY_MOUNT :=
DISPLAY_ENV   :=
PULSE_MOUNT   :=
PULSE_ENV     :=
RUNTIME_MOUNTS :=
RUNTIME_ENVS   :=

ifeq ($(OS),Linux)
	# Attempt to get user's runtime dir, fallback if needed
	XDG_RUNTIME_DIR_HOST := $(firstword $(XDG_RUNTIME_DIR) $(shell echo /run/user/$(shell id -u)))
	# Ensure DISPLAY is set, default to :0 if not found in environment
	DISPLAY_HOST := $(firstword $(DISPLAY) :0)

	# Detect Wayland socket within the runtime dir
	WAYLAND_SOCKET := $(firstword $(shell find $(XDG_RUNTIME_DIR_HOST) -maxdepth 1 -type s -name 'wayland-*' 2>/dev/null))
	# Detect Pulse/PipeWire socket
	PULSE_SOCKET := $(firstword $(shell find $(XDG_RUNTIME_DIR_HOST) -maxdepth 1 -type s \( -name 'pipewire-0' -o -name 'pulse/native' \) 2>/dev/null | tr -d '\n'))
	# D-Bus socket path
	DBUS_SOCKET_PATH := $(XDG_RUNTIME_DIR_HOST)/bus

	# Display Server Setup
	ifeq ($(strip $(WAYLAND_SOCKET)),)
		# X11 Fallback
		X11_SOCKET_PATH := /tmp/.X11-unix
		ifneq ($(wildcard $(X11_SOCKET_PATH)),)
			DISPLAY_MOUNT := -v "$(X11_SOCKET_PATH):$(X11_SOCKET_PATH)"
			DISPLAY_ENV := -e DISPLAY=$(DISPLAY_HOST)
		else
			$(warning "WARNING: Could not find Wayland or X11 socket. GUI may fail.")
		endif
	else
		# Wayland Primary
		WAYLAND_DISPLAY_NAME := $(notdir $(WAYLAND_SOCKET))
		DISPLAY_MOUNT := -v "$(WAYLAND_SOCKET):$(WAYLAND_SOCKET)"
		DISPLAY_ENV := -e DISPLAY=$(DISPLAY_HOST) -e WAYLAND_DISPLAY=$(WAYLAND_DISPLAY_NAME)
	endif

	# Audio Server Setup
	ifneq ($(strip $(PULSE_SOCKET)),)
		PULSE_MOUNT := -v "$(PULSE_SOCKET):$(PULSE_SOCKET)"
		PULSE_ENV := -e PULSE_SERVER=unix:$(PULSE_SOCKET)
	endif

	# D-Bus Setup
	ifneq ($(wildcard $(DBUS_SOCKET_PATH)),)
		RUNTIME_MOUNTS += -v "$(DBUS_SOCKET_PATH):$(DBUS_SOCKET_PATH)"
		RUNTIME_ENVS += -e XDG_RUNTIME_DIR=$(XDG_RUNTIME_DIR_HOST)
		RUNTIME_ENVS += -e DBUS_SESSION_BUS_ADDRESS=unix:path=$(DBUS_SOCKET_PATH)
	else
		$(warning "WARNING: Could not find D-Bus socket at $(DBUS_SOCKET_PATH). Desktop integration may be limited.")
	endif
else
	# Non-Linux (macOS, Windows/WSL) - Rely on Docker Desktop/Podman Desktop
endif

# ------------------------------------------------------------------------------
# Container Arguments
# ------------------------------------------------------------------------------
LINUX_FLAGS :=
ifeq ($(OS),Linux)
	LINUX_FLAGS += --device /dev/kvm             # for emulator/VM tasks
	LINUX_FLAGS += --userns=keep-id              # helps with host volume permissions
	LINUX_FLAGS += --security-opt label=disable  # helps with SELinux volume access
endif

CONTAINER_ARGS_BASE := --rm -it --init --network host \
					   -v "$(PWD):/app" \
					   -w /app

CONTAINER_ARGS := $(CONTAINER_ARGS_BASE) \
				  $(DISPLAY_MOUNT) \
				  $(PULSE_MOUNT) \
				  $(RUNTIME_MOUNTS) \
				  $(DISPLAY_ENV) \
				  $(PULSE_ENV) \
				  $(RUNTIME_ENVS) \
				  $(LINUX_FLAGS)

# ------------------------------------------------------------------------------
# Dev Namespace
# ------------------------------------------------------------------------------
dev/shell: ## Open an interactive dev container shell (GUI/Audio support)
	$(CONTAINER_RUNTIME) run $(CONTAINER_ARGS) \
		$(IMAGE_BASE) bash
