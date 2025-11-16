# Makefile for muOS Collection Manager

# Project configuration
PROJECT_NAME := game-vault
VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo 0.1.0)
DIST_NAME := $(PROJECT_NAME)-$(VERSION)
CONTENT_DIR := GameVault
DIST_DIR := dist
ZIP_FILE := $(DIST_DIR)/$(DIST_NAME).muxapp
DISTIGNORE := .distignore

# Device configuration (for deployment)
DEVICE_IP := 192.168.1.23

.PHONY: all dist clean deploy help

all: clean dist

# Create distribution package
dist:
	@echo "Creating distribution for muOS..."
	@echo "Version: $(VERSION)"
	@rm -rf $(DIST_DIR)
	@mkdir -p $(DIST_DIR)

	# Check for Love2D binary and libraries
	@if [ -f "love" ] && [ -d "libs" ] && [ -f "libs/liblove-11.5.so" ] && [ -f "libs/libluajit-5.1.so.2" ]; then \
		echo "✅ Found Love2D binary and libraries"; \
	else \
		echo "⚠️  Missing Love2D binary or libraries"; \
		echo "  - love (ARM64 binary)"; \
		echo "  - libs/liblove-11.5.so"; \
		echo "  - libs/libluajit-5.1.so.2"; \
		echo ""; \
		exit 1; \
	fi

	# Copy files excluding ignored patterns
	@rsync -a . $(DIST_DIR)/$(CONTENT_DIR) \
		--exclude-from=$(DISTIGNORE) \
		--exclude=$(DIST_DIR) \
		--delete-excluded

	# Create glyph directory for muOS launcher icon
	@mkdir -p $(DIST_DIR)/glyph/muxapp
	@if [ -f "assets/icon.png" ]; then \
		cp assets/icon.png $(DIST_DIR)/glyph/game-vault.png; \
	elif [ -f "assets/images/icons/app.png" ]; then \
		cp assets/images/icons/app.png $(DIST_DIR)/glyph/game-vault.png; \
	elif [ -f "assets/images/icons/icon.png" ]; then \
		cp assets/images/icons/icon.png $(DIST_DIR)/glyph/game-vault.png; \
	else \
		echo "Warning: app icon not found (expected assets/icon.png or assets/images/icons/{app.png,icon.png}), skipping icon"; \
	fi

	# Create .muxapp archive (muOS application format)
	@cd $(DIST_DIR) && zip -r $(DIST_NAME).muxapp .
	@rm -rf $(DIST_DIR)/$(CONTENT_DIR) $(DIST_DIR)/glyph
	@echo "✅ Created $(ZIP_FILE)"
	@echo ""
	@echo "Installation instructions:"
	@echo "1. Copy $(DIST_NAME).muxapp to your SD card's /ARCHIVE folder"
	@echo "2. Use muOS Archive Manager to extract the application"
	@echo "3. Launch from Applications menu"

# Clean build artifacts
clean:
	rm -rf $(DIST_DIR)
	@echo "✅ Cleaned build artifacts"

# Deploy to device over network (requires sshpass)
deploy:
	@if ! command -v sshpass >/dev/null 2>&1; then \
		echo "Error: sshpass is required for deployment"; \
		echo "Install: brew install hudochenkov/sshpass/sshpass (macOS)"; \
		exit 1; \
	fi
	@sshpass -p 'root' scp $(ZIP_FILE) root@$(DEVICE_IP):/mnt/mmc/ARCHIVE
	@echo "✅ Deployed to $(DEVICE_IP):/mnt/mmc/ARCHIVE"
	@echo "Use Archive Manager on device to extract"

# Show help
help:
	@echo "muOS Collection Manager - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make dist          - Create .muxapp distribution package"
	@echo "  make clean         - Remove build artifacts"
	@echo "  make deploy        - Deploy to device (set DEVICE_IP=x.x.x.x)"
	@echo "  make all           - Clean and build (default)"
	@echo "  make help          - Show this message"
	@echo ""
	@echo "Variables:"
	@echo "  VERSION=$(VERSION)"
	@echo "  DEVICE_IP=$(DEVICE_IP)"