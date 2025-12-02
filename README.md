# xSnow for macOS

A modern macOS implementation of the classic xSnow program. Display beautiful falling snow on your desktop!

![xSnow Screenshot](screenshot.png)

## Features

- 🌨️ **Native macOS App** - Built with Swift and AppKit for optimal performance
- ❄️ **Realistic Snow Physics** - Particles fall with varying speeds and sizes
- 🪟 **Snow Piles on Windows** - Snow visibly accumulates and builds up on top of your windows with realistic mounding (up to 80px high!)
- 🎿 **Beautiful Snow Mounds** - Snow piles render as smooth, curved shapes that look like real snow accumulation
- 💨 **Wind Effect** - Gentle wind simulation for natural movement
- ⚙️ **Customizable** - Adjust snow intensity (Light, Medium, Heavy) and toggle snow settling
- 🎨 **Transparent Overlay** - Non-intrusive design that works with any desktop
- 📍 **Menu Bar Control** - Easy access to settings from the status bar
- 🖱️ **Mouse Pass-through** - Snow doesn't interfere with your work
- ⏱️ **Auto-melting** - Settled snow gradually disappears over 60 seconds

## Requirements

- macOS 11.0 (Big Sur) or later
- Xcode Command Line Tools (for building from source)

## Installation

### Option 1: Build from Source

```bash
# Clone or download this repository
cd xsnow

# Build the application
make

# Install to Applications folder
make install
```

### Option 2: Quick Run

```bash
# Build and run without installing
make run
```

## Usage

1. Launch xSnow from your Applications folder or Spotlight
2. The app runs in the background with a snowflake icon in the menu bar
3. Click the snowflake icon to access settings:
   - **Light/Medium/Heavy** - Adjust snow intensity
   - **Wind Effect** - Toggle wind simulation on/off
   - **Snow Settling on Windows** - Toggle snow accumulation on window tops (enabled by default)
   - **Quit** - Stop the snow

## Building

The project uses a simple Makefile for building:

```bash
make          # Build the app
make clean    # Clean build artifacts
make run      # Build and run
make install  # Install to /Applications
make uninstall # Remove from /Applications
```

### Manual Build

If you prefer to build manually:

```bash
# Create bundle structure
mkdir -p build/xSnow.app/Contents/MacOS
mkdir -p build/xSnow.app/Contents/Resources

# Compile Swift sources
swiftc -O -whole-module-optimization \
    main.swift AppDelegate.swift SnowWindow.swift SnowView.swift \
    -o build/xSnow.app/Contents/MacOS/xSnow

# Copy Info.plist
cp Info.plist build/xSnow.app/Contents/

# Run the app
open build/xSnow.app
```

## Customization

### Adjusting Snow Parameters

You can modify the snow behavior by editing the source files:

**SnowView.swift:**
- **Particle count**: Edit the `particleCount` property in `SnowIntensity` enum
- **Fall speed**: Adjust the range in `createRandomParticle()` method
- **Particle size**: Modify the size range (currently 2-6 pixels)
- **Wind strength**: Change the multiplier in `updateParticles()` wind effect calculation

**SettledSnow.swift:**
- **Max pile height**: Adjust `maxSnowHeight` (currently 80 pixels)
- **Melt rate**: Modify `meltRate` (currently 0.005)
- **Pile lifetime**: Change `maxAge` in SnowPile struct (currently 60 seconds)
- **Column width**: Adjust `columnWidth` in SnowPile (currently 8 pixels for smooth piles)

### Window Level

The snow window floats above most windows by default. To change this, modify the `level` property in `SnowWindow.swift`:

```swift
self.level = .floating  // Change to .normal, .statusBar, etc.
```

## Architecture

- **main.swift** - Application entry point
- **AppDelegate.swift** - Menu bar interface and app lifecycle
- **SnowWindow.swift** - Transparent overlay window management
- **SnowView.swift** - Snow particle system and rendering
- **WindowDetector.swift** - Detects visible windows using Core Graphics API
- **SettledSnow.swift** - Manages snow accumulation and melting on window tops
- **Info.plist** - App bundle configuration
- **Makefile** - Build automation

## Troubleshooting

### App doesn't appear in menu bar
- Make sure the app is running (check Activity Monitor)
- Try quitting and restarting the app

### Snow appears behind windows
- This is intentional for a non-intrusive experience
- To change this, modify the window level in `SnowWindow.swift`

### Performance issues
- Try reducing snow intensity to "Light"
- Check if other resource-intensive apps are running

### Build errors
- Ensure you have Xcode Command Line Tools installed:
  ```bash
  xcode-select --install
  ```
- Make sure you're on macOS 11.0 or later

## Credits

Inspired by the classic xSnow program for X11 systems, originally created by Rick Jansen.

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

---

**Enjoy the snow!** ❄️
