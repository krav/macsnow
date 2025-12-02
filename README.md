# xsnow for MacOS

Vibe coded holiday nostalgia for the Apple operating system.

![MacSnow Screenshot](screenshot.png)

## Features

- Snow
- Santa

## Requirements

- macOS 11.0 (Big Sur) or later
- Xcode Command Line Tools (for building from source)

## Installation

### Option 1: Download Pre-built Release

1. Go to [Releases](../../releases) and download the latest `MacSnow.zip`
2. Unzip the file
3. Move `MacSnow.app` to your Applications folder
4. Right-click on `MacSnow.app` and select "Open" on first launch (macOS security requirement)

### Option 2: Build from Source

```bash
# Build the application
make

# Run without installing
make run

# Install to Applications folder
make install
```

