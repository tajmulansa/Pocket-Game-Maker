# Pocket Game Maker

A native cross-platform 2D game maker inspired by the simplicity of Playdate Pulp and the scene/component model of Godot. Build games visually, add no-code behaviors, switch to JavaScript when needed, playtest instantly, and export an HTML5 Canvas game.

## Architecture

- **Native shell/editor:** Flutter (Android, iOS, Windows, macOS)
- **Export/runtime:** standalone HTML5 Canvas JavaScript engine in `engine/`
- **Live preview:** embedded WebView rendering the generated HTML5 game
- **Project format:** JSON, with imported assets stored as base64 for portability
- **CI/CD:** GitHub Actions builds platform artifacts on push and publishes tagged releases

## Features in this MVP

- Grid/canvas scene editor
- Scene + object hierarchy
- Object presets: Player, Enemy, Platform, Coin, Tile, Text
- Asset import (PNG/JPG/GIF/SVG/audio)
- Drag-and-drop behavior blocks
- Behaviors: movement, gravity, collision, score, timer, trigger
- JavaScript code mode
- Instant in-app playtest
- HTML5 ZIP export
- Portable project JSON save/open

## Run locally

```bash
flutter create --platforms=android,ios,windows,macos .
flutter pub get
flutter run
```

For desktop, install the Flutter desktop toolchain for your platform.

## CI/CD

Pushes to `main` build Android APK/AAB, iOS, Windows, and macOS artifacts. Git tags matching `v*` additionally create a GitHub Release with packaged artifacts.

## Notes

This repository is intentionally dependency-light. Production hardening still needed for signing/notarization, richer animation/tilemap authoring, asset atlases, undo/redo history, and collaborative/versioned project storage.

## Target support

The embedded playtest uses `flutter_inappwebview`, which provides native WebView implementations for Android, iOS, macOS, and Windows. Linux can be added later with a dedicated WebKitGTK adapter. The exported HTML5 games themselves are browser-based and do not depend on Flutter.
