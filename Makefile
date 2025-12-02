# MacSnow for macOS - Makefile

APP_NAME = MacSnow
BUNDLE_NAME = $(APP_NAME).app
BUNDLE_DIR = build/$(BUNDLE_NAME)
CONTENTS_DIR = $(BUNDLE_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

SOURCES = main.swift AppDelegate.swift SnowWindow.swift SnowView.swift WindowDetector.swift SettledSnow.swift SantaSleigh.swift XPMLoader.swift
SWIFT_FLAGS = -O -whole-module-optimization

.PHONY: all clean run install

all: $(BUNDLE_DIR)

$(BUNDLE_DIR): $(SOURCES)
	@echo "Building MacSnow..."
	@mkdir -p $(MACOS_DIR)
	@mkdir -p $(RESOURCES_DIR)
	@mkdir -p $(RESOURCES_DIR)/pixmaps
	
	swiftc $(SWIFT_FLAGS) $(SOURCES) -o $(MACOS_DIR)/$(APP_NAME)
	
	cp Info.plist $(CONTENTS_DIR)/
	cp -r pixmaps/* $(RESOURCES_DIR)/pixmaps/
	
	@echo "Build complete: $(BUNDLE_DIR)"

clean:
	rm -rf build

run: all
	open $(BUNDLE_DIR)

install: all
	@echo "Installing to /Applications..."
	cp -r $(BUNDLE_DIR) /Applications/
	@echo "Installation complete!"

uninstall:
	rm -rf /Applications/$(BUNDLE_NAME)
	@echo "Uninstalled."
