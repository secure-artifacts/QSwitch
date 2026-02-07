# QSwitch

**QSwitch** is a native macOS menu bar utility built with SwiftUI. It provides a unified, efficient interface for managing display resolutions and audio input/output devices, featuring a preset system for quick context switching.

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Language](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-blue)

## Features

![](https://raz1ner.com/post-images/1770486305254.png)

### 🖥 Display Management
- **Resolution Switching**: Quickly view and switch between available screen resolutions.
- **Smart Filtering**: Automatically filters and prioritizes HiDPI and high-resolution native modes to keep the list clean.
- **Active State**: Visual indicator for the currently active resolution.

### 🎧 Audio Control
- **Input & Output Control**: Separate dropdowns for microphone (Input) and speaker (Output) selection.
- **Device Discovery**: Real-time fetching of CoreAudio devices with hot-plug support logic.
- **Preset System**: 
  - Save current Input/Output device combinations as named presets (e.g., "Meeting", "Music").
  - One-click application of complex audio setups.
  - Persists presets locally.

### ⚙️ System Integration
- **Menu Bar App**: Lives in the menu bar for quick access without cluttering the Dock.
- **Launch at Login**: Integrated toggle to automatically start the app when you log in (Requires macOS 13.0+).

## Requirements

- **macOS**: 14.6 (Sonoma) or later.
- **Xcode**: 14.6+ (for building).

## Download
[Awesome Software](https://raz1ner.com/Awesome-Software/?active=QSwitch)
