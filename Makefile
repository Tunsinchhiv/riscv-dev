# Makefile for RISC-V Development Environment

# Go compiler configuration
GO = go
GOOS = linux
GOARCH = riscv64
CGO_ENABLED = 0

# Build optimization flags (Go-specific)
LDFLAGS = -s -w
GCFLAGS = all=-l

# Build directory
BUILD_DIR = $(CURDIR)/bin
EXAMPLES_BUILD_DIR = $(BUILD_DIR)/examples

# Example projects
EXAMPLES = gpio-led network-server sensor-reading buildroot-app

# QEMU configuration
QEMU_USER = qemu-riscv64
QEMU_SYSTEM = qemu-system-riscv64
DEBUG_PORT = 2345

# Buildroot settings (optional)
BUILDROOT_BOARD ?= milkv-duo-sd
BUILDROOT_SDK ?= auto
SDK_DIR_V1 ?= /opt/duo-buildroot-sdk
SDK_DIR_V2 ?= /opt/duo-buildroot-sdk-v2

# Resolve SDK paths
ifeq ($(BUILDROOT_SDK),v1)
  BUILDROOT_SDK_DIR := $(SDK_DIR_V1)
  IMAGE_DIRS := $(SDK_DIR_V1)/out
else ifeq ($(BUILDROOT_SDK),v2)
  BUILDROOT_SDK_DIR := $(SDK_DIR_V2)
  IMAGE_DIRS := $(SDK_DIR_V2)/out
else
  BUILDROOT_SDK_DIR := $(SDK_DIR_V2)
  IMAGE_DIRS := $(SDK_DIR_V2)/out $(SDK_DIR_V1)/out
endif

# Find latest Buildroot image
SD_IMAGE_SRC ?= $(shell find $(IMAGE_DIRS) -name '$(BUILDROOT_BOARD)-*.img' -printf "%T@ %p\\n" 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-)

# SD Card Device (USE WITH CAUTION!)
SD_DEVICE ?= /dev/sdX # MUST be changed by the user, e.g., /dev/sdb

# Default target
all: build-examples

# Create build directories
$(EXAMPLES_BUILD_DIR):
	@mkdir -p $@

# --- Example Building Targets ---
.PHONY: build-examples $(addprefix build-example-,$(EXAMPLES)) $(addprefix run-example-,$(EXAMPLES))

# Build all examples
build-examples: $(EXAMPLES_BUILD_DIR) $(addprefix build-example-,$(EXAMPLES))
	@echo "✅ All examples built successfully in $(EXAMPLES_BUILD_DIR)"

# Build individual examples
build-example-gpio-led: $(EXAMPLES_BUILD_DIR)
	@echo "🔨 Building GPIO LED example..."
	@mkdir -p $(EXAMPLES_BUILD_DIR)/gpio-led
	@cd examples/gpio-led && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) $(GO) build -ldflags="$(LDFLAGS)" -gcflags="$(GCFLAGS)" -o $(EXAMPLES_BUILD_DIR)/gpio-led/app ./cmd/app
	@echo "✅ GPIO LED example built: $(EXAMPLES_BUILD_DIR)/gpio-led/app"

build-example-network-server: $(EXAMPLES_BUILD_DIR)
	@echo "🔨 Building Network Server example..."
	@mkdir -p $(EXAMPLES_BUILD_DIR)/network-server
	@cd examples/network-server && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) $(GO) build -ldflags="$(LDFLAGS)" -gcflags="$(GCFLAGS)" -o $(EXAMPLES_BUILD_DIR)/network-server/app ./cmd/app
	@echo "✅ Network Server example built: $(EXAMPLES_BUILD_DIR)/network-server/app"

build-example-sensor-reading: $(EXAMPLES_BUILD_DIR)
	@echo "🔨 Building Sensor Reading example..."
	@mkdir -p $(EXAMPLES_BUILD_DIR)/sensor-reading
	@cd examples/sensor-reading && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) $(GO) build -ldflags="$(LDFLAGS)" -gcflags="$(GCFLAGS)" -o $(EXAMPLES_BUILD_DIR)/sensor-reading/app ./cmd/app
	@echo "✅ Sensor Reading example built: $(EXAMPLES_BUILD_DIR)/sensor-reading/app"

build-example-buildroot-app: $(EXAMPLES_BUILD_DIR)
	@echo "🔨 Building Buildroot App example..."
	@mkdir -p $(EXAMPLES_BUILD_DIR)/buildroot-app
	@cd examples/buildroot-app && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) $(GO) build -ldflags="$(LDFLAGS)" -gcflags="$(GCFLAGS)" -o $(EXAMPLES_BUILD_DIR)/buildroot-app/app ./cmd/app
	@echo "✅ Buildroot App example built: $(EXAMPLES_BUILD_DIR)/buildroot-app/app"

# Run examples with QEMU
run-example-gpio-led: build-example-gpio-led
	@echo "🚀 Running GPIO LED example with QEMU..."
	@$(QEMU_USER) $(EXAMPLES_BUILD_DIR)/gpio-led/app

run-example-network-server: build-example-network-server
	@echo "🚀 Running Network Server example with QEMU..."
	@echo "Note: Network features may be limited in QEMU user-mode"
	@$(QEMU_USER) $(EXAMPLES_BUILD_DIR)/network-server/app

run-example-sensor-reading: build-example-sensor-reading
	@echo "🚀 Running Sensor Reading example with QEMU..."
	@$(QEMU_USER) $(EXAMPLES_BUILD_DIR)/sensor-reading/app

run-example-buildroot-app: build-example-buildroot-app
	@echo "🚀 Running Buildroot App example with QEMU..."
	@echo "Note: Web server will run on localhost:8080 inside QEMU"
	@$(QEMU_USER) $(EXAMPLES_BUILD_DIR)/buildroot-app/app

# --- Buildroot Image Target ---
.PHONY: build-image
build-image:
	@echo "  BUILDING SD CARD IMAGE for $(BUILDROOT_BOARD)"
	@echo "  BUILDROOT_SDK selection: $(BUILDROOT_SDK) (dir: $(BUILDROOT_SDK_DIR))"
	@echo "  Buildroot script path: $(BUILDROOT_SCRIPT)"
	@echo "  Candidate output directories: $(IMAGE_DIRS)"
	@if [ "$(BUILDROOT_SDK)" = "auto" ]; then \
	  if [ -d "$(SDK_DIR_V2)" ]; then \
	    echo "  [auto] Using v2 SDK at $(SDK_DIR_V2)"; \
	    (cd $(SDK_DIR_V2) && export BR2_DEFCONFIG_FRAGMENT_FILES=$(BUILDROOT_PROJECT_DIR)/buildroot_config/defconfig_fragment && ./build.sh $(BUILDROOT_BOARD)); \
	  elif [ -d "$(SDK_DIR_V1)" ]; then \
	    echo "  [auto] v2 not found, falling back to v1 at $(SDK_DIR_V1)"; \
	    (cd $(SDK_DIR_V1) && export BR2_DEFCONFIG_FRAGMENT_FILES=$(BUILDROOT_PROJECT_DIR)/buildroot_config/defconfig_fragment && ./build.sh $(BUILDROOT_BOARD)); \
	  else \
	    echo "Error: Neither v2 nor v1 SDK directories found."; exit 1; \
	  fi; \
	else \
	  (cd $(BUILDROOT_SDK_DIR) && export BR2_DEFCONFIG_FRAGMENT_FILES=$(BUILDROOT_PROJECT_DIR)/buildroot_config/defconfig_fragment && ./build.sh $(BUILDROOT_BOARD)); \
	fi
	@echo "Buildroot image generation process initiated."
	@NEWEST_IMAGE=$$(find $(IMAGE_DIRS) -name '$(BUILDROOT_BOARD)-*.img' -printf "%T@ %p\\n" 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2-); \
	 if [ -n "$$NEWEST_IMAGE" ]; then \
	   echo "Latest image found: $$NEWEST_IMAGE"; \
	 else \
	   echo "No image found matching pattern '$(BUILDROOT_BOARD)-*.img' in candidates: $(IMAGE_DIRS)."; \
	 fi

# --- QEMU System Emulation Targets ---
.PHONY: run-qemu-system run-qemu-gui run-qemu-headless

# Graphics-enabled QEMU system emulation (default GUI mode)
run-qemu-system: run-qemu-gui

# GUI-enabled QEMU system emulation with graphics acceleration
run-qemu-gui:
	@if [ -z "$(SD_IMAGE_SRC)" ] || [ ! -f "$(SD_IMAGE_SRC)" ]; then \
		echo "Error: SD Card image not found or not specified."; \
		echo "Searched for pattern '$(BUILDROOT_BOARD)-*.img' in '$(BUILT_IMAGE_OUTPUT_DIR)'."; \
		echo "Please build the image first ('make build-image') or set SD_IMAGE_SRC manually (e.g., make run-qemu-gui SD_IMAGE_SRC=/path/to/image.img)."; \
		exit 1; \
	fi
	@echo "  QEMU GUI Emulating $(SD_IMAGE_SRC) with graphics support"
	@echo "  NOTE: This uses a RISC-V 'virt' machine with graphics acceleration."
	@echo "  GUI applications will display in a separate window."
	@echo "  Console access should be on ttyS0. Network (e.g., ssh) forwarded to host port 2222."
	@echo "  Debug port forwarded to host port $(DEBUG_PORT)."
	@echo "  Graphics: VirtIO GPU with 1024x768 resolution"
	$(QEMU_SYSTEM) -M virt -m 2G \
		-bios default \
		-device virtio-gpu-pci \
		-device virtio-keyboard-pci \
		-device virtio-mouse-pci \
		-device virtio-tablet-pci \
		-drive file=$(SD_IMAGE_SRC),format=raw,id=sdcard,if=none \
		-device virtio-blk-pci,drive=sdcard \
		-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::$(DEBUG_PORT)-:$(DEBUG_PORT) \
		-device virtio-net-pci,netdev=net0 \
		-vga virtio \
		-display gtk,gl=on \
		-device ich9-intel-hda \
		-device hda-output \
		-device qemu-xhci,id=xhci \
		-device usb-tablet,bus=xhci.0 \
		-device usb-kbd,bus=xhci.0

# Headless QEMU system emulation (text-only, for CI/CD)
run-qemu-headless:
	@if [ -z "$(SD_IMAGE_SRC)" ] || [ ! -f "$(SD_IMAGE_SRC)" ]; then \
		echo "Error: SD Card image not found or not specified."; \
		echo "Searched for pattern '$(BUILDROOT_BOARD)-*.img' in '$(BUILT_IMAGE_OUTPUT_DIR)'."; \
		echo "Please build the image first ('make build-image') or set SD_IMAGE_SRC manually (e.g., make run-qemu-headless SD_IMAGE_SRC=/path/to/image.img)."; \
		exit 1; \
	fi
	@echo "  QEMU HEADLESS Emulating $(SD_IMAGE_SRC) (text-only mode)"
	@echo "  NOTE: This uses a generic RISC-V 'virt' machine without graphics."
	@echo "  Console access should be on ttyS0. Network (e.g., ssh) forwarded to host port 2222."
	@echo "  Debug port forwarded to host port $(DEBUG_PORT)."
	$(QEMU_SYSTEM) -M virt -m 1G -nographic \
		-bios default \
		-drive file=$(SD_IMAGE_SRC),format=raw,id=sdcard,if=none \
		-device virtio-blk-pci,drive=sdcard \
		-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::$(DEBUG_PORT)-:$(DEBUG_PORT) \
		-device virtio-net-pci,netdev=net0

# --- Attach to QEMU (SSH) ---
.PHONY: attach-ssh
attach-ssh:
	@echo "  Attempting to SSH into the running QEMU guest via host port 2222."
	@echo "  Ensure 'make run-qemu-system' is running in another terminal."
	@echo "  Ensure the guest OS has fully booted and an SSH server (e.g., Dropbear, OpenSSH) is running and configured."
	@echo "  Common users for embedded images are 'root' or a user configured in your Buildroot image."
	@echo "  If password authentication is required, this command may hang waiting for input not visible via 'make'."
	@echo "  Command: ssh -vvv -o ConnectTimeout=30 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost"
	@echo "  Trying with user 'root' as an example. You may need to change this."
	@sleep 15 # Give QEMU guest time to boot SSH server
	@ssh -vvv -o ConnectTimeout=30 -o ConnectionAttempts=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost

# --- Write to SD Card Target ---
.PHONY: write-sd-image
write-sd-image:
	@if [ -z "$(SD_IMAGE_SRC)" ] || [ ! -f "$(SD_IMAGE_SRC)" ]; then \
		echo "Error: SD Card image not found or not specified."; \
		echo "Searched for pattern '$(BUILDROOT_BOARD)-*.img' in '$(BUILT_IMAGE_OUTPUT_DIR)'."; \
		echo "Please build the image first ('make build-image') or set SD_IMAGE_SRC manually."; \
		exit 1; \
	fi
	@if [ "$(SD_DEVICE)" = "/dev/sdX" ]; then \
		echo "Error: SD_DEVICE is set to /dev/sdX. Please specify the correct device."; \
		echo "Example: make write-sd-image SD_DEVICE=/dev/sdb"; \
		echo "WARNING: This operation will overwrite the target device."; \
		exit 1; \
	fi
	@echo "  WRITING $(SD_IMAGE_SRC) to $(SD_DEVICE)"
	@echo "  !!! WARNING: THIS WILL OVERWRITE ALL DATA ON $(SD_DEVICE) !!!"
	@read -p "Verify target device is $(SD_DEVICE). Are you absolutely sure? (yes/N): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@sudo dd if=$(SD_IMAGE_SRC) of=$(SD_DEVICE) bs=4M conv=fsync status=progress

# --- Test Target ---
.PHONY: test
test: build-go-apps
	@echo "  TESTING..."
	@echo "  Running Go tests for jetecu/linux/golang..."
	@(cd $(CURDIR)/jetecu/linux/golang && $(GO) test ./...)
	@echo "  Placeholder for other tests (e.g., integration, performance)."
	# Add commands to run other tests here, e.g.:
	# @(cd $(CURDIR)/jetecu/tests/integration && ./run_tests.sh)

# --- Clean Target ---
.PHONY: clean
clean:
	@echo "  CLEANING Go application build artifacts..."
	@rm -rf $(GO_APPS_BUILD_DIR)
	@echo "  Go application build artifacts cleaned from $(GO_APPS_BUILD_DIR)."
	@echo "  To clean Buildroot build outputs, you typically need to run 'make clean'"
	@echo "  within the specific Buildroot output directory (e.g., /duo-buildroot-sdk/build/buildroot-milkv-duo-sd_cv1800b_sophgo_riscv64_musl_riscv64_sd_normal)."
	@echo "  Alternatively, your build.sh script might support a 'clean' argument: (cd $(BUILDROOT_PROJECT_DIR) && ./build.sh clean)"

# --- Help Target ---
.PHONY: help
help:
	@echo "Makefile for RISC-V Development Environment"
	@echo ""
	@echo "Usage: make [target] [VARIABLE=value]"
	@echo ""
	@echo "Main Targets:"
	@echo "  all (default)           - Build all example projects"
	@echo "  build-examples          - Build all example projects"
	@echo "  build-image             - Build Buildroot SD card image (if SDK available)"
	@echo "  run-qemu-system         - Run QEMU system emulation with GUI"
	@echo "  run-qemu-headless       - Run QEMU system emulation (text-only)"
	@echo "  test                    - Run Go tests for all examples"
	@echo "  clean                   - Clean build artifacts"
	@echo "  help                    - Show this help message"
	@echo ""
	@echo "Example Building:"
	@echo "  build-example-gpio-led      - Build GPIO LED example"
	@echo "  build-example-network-server - Build network server example"
	@echo "  build-example-sensor-reading - Build sensor reading example"
	@echo "  build-example-buildroot-app  - Build Buildroot app example"
	@echo ""
	@echo "Example Running:"
	@echo "  run-example-gpio-led        - Run GPIO LED example in QEMU"
	@echo "  run-example-network-server  - Run network server example in QEMU"
	@echo "  run-example-sensor-reading  - Run sensor reading example in QEMU"
	@echo "  run-example-buildroot-app   - Run Buildroot app example in QEMU"
	@echo ""
	@echo "Variables to Override:"
	@echo "  GOOS=linux GOARCH=riscv64   - Target platform (default)"
	@echo "  CGO_ENABLED=0               - Disable CGO for static linking"
	@echo "  BUILDROOT_SDK=auto          - SDK version (auto/v2/v1)"
	@echo "  BUILDROOT_BOARD=milkv-duo-sd - Target board"
	@echo "  SD_IMAGE_SRC=/path/to/image - Specific SD image"
	@echo "  SD_DEVICE=/dev/sdX          - Target device for flashing"
	@echo ""
	@echo "Example Workflows:"
	@echo "  1. Build all examples: make"
	@echo "  2. Build and run GPIO example: make run-example-gpio-led"
	@echo "  3. Build for debugging: make build-example-gpio-led LDFLAGS='-s -w'"
	@echo "  4. Test all examples: make test"
	@echo "  5. Clean everything: make clean"
	@echo ""
	@echo "Development Tips:"
	@echo "  - Use 'make build-example-<name>' to build individual examples"
	@echo "  - Use 'make run-example-<name>' to test with QEMU"
	@echo "  - Examples are built in ./bin/examples/"
	@echo "  - Cross-compilation targets RISC-V 64-bit Linux"

# --- Test Target ---
.PHONY: test
test: build-examples
	@echo "🧪 Running tests for all examples..."
	@for example in $(EXAMPLES); do \
		echo "Testing $$example..."; \
		if [ -f "examples/$$example/go.mod" ]; then \
			(cd examples/$$example && $(GO) test ./...); \
		else \
			echo "No tests found for $$example"; \
		fi; \
	done
	@echo "✅ All tests completed"

# --- Clean Target ---
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "✅ Build directory cleaned: $(BUILD_DIR)"
	@if [ -d "$(BUILDROOT_SDK_DIR)" ]; then \
		echo "💡 To clean Buildroot build artifacts:"; \
		echo "   cd $(BUILDROOT_SDK_DIR) && make clean"; \
	fi

# Phony targets
.PHONY: all build-examples $(addprefix build-example-,$(EXAMPLES)) $(addprefix run-example-,$(EXAMPLES)) build-image run-qemu-system run-qemu-gui run-qemu-headless test clean help
