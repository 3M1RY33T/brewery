# Brewery

Brewery is a native SwiftUI macOS client for managing local Homebrew formulae and casks. It detects an existing Homebrew installation, loads installed packages, shows outdated status, displays dependency/dependent relationships, and runs package actions only after confirmation.

## Requirements

- macOS 12 or newer
- Swift 5.9 or newer
- Homebrew installed at `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`, or discoverable from a sanitized login shell `PATH`

## Run

```sh
Scripts/run-app.sh
```

SwiftPM can compile the app with `swift run Brewery`, but macOS GUI apps need an `.app` bundle for a normal LaunchServices run. `Scripts/run-app.sh` builds `.build/Brewery.app` and opens it.

To build the app bundle without opening it:

```sh
Scripts/build-app.sh
```

The build script also generates `BreweryIcon.icns` from `brewery-logo.png` for the local app bundle.

## Test

```sh
swift test
```

## Features

- Detect an existing Homebrew installation.
- Load installed formulae and casks with `brew info --json=v2 --installed`.
- Show outdated packages with `brew outdated --json=v2`.
- Confirm before running mutating commands: update, install, upgrade, uninstall, and cleanup.
- Stream command output into an in-app log.
- Show basic diagnostics from `brew --version`, `brew config`, and `brew doctor`.
- Build an in-memory dependency graph from Homebrew JSON instead of running per-package dependency commands.
- Show direct dependencies and dependents in the package detail pane.
- Browse official Homebrew formulae and casks with an App Store-style catalog view.
- Cache the browse catalog locally and use cached data when network refresh fails.
- Provide sidebar filters for all packages, formulae, casks, outdated packages, pinned packages, and diagnostics.
- Keep the package detail pane at a stable width with a manual resize handle.

## Project Layout

- `Sources/BreweryCore`: Homebrew detection, command execution, JSON decoding, package state, and dependency graph logic.
- `Sources/Brewery`: SwiftUI macOS app views and local resources.
- `Tests/BreweryCoreTests`: fixtures and unit tests for decoding, command construction, graph traversal, and package filtering.
- `Scripts`: local build and launch helpers for the source-only app bundle.

## Notes

Brewery does not install Homebrew automatically.
