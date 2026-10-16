Birth Record is a native macOS birthday tracker built with SwiftUI and WidgetKit. Requires macOS 14 or later.

## Highlights

- English and Simplified Chinese localization for the interface, dates, app names, and accessibility text.
- Days alive, age, annual birthday progress, and a countdown to your next birthday.
- An optional life countdown based on your chosen lifespan.
- A universal DMG with native support for Apple Silicon (`arm64`) and Intel (`x86_64`). Download the same installer for either Mac.
- MIT licensed, with the original Lucide icon notices preserved.

## Install

Download `BirthdayDays-1.0-universal.dmg` below, open it, and drag the app into Applications.

This release does not use an Apple developer certificate or notarization, so macOS Gatekeeper may block the first launch. See [Apple's guidance](https://support.apple.com/en-us/102445). Desktop widgets and App Group synchronization depend on signing permissions and are not guaranteed to work in this build. The main app falls back to local storage when sharing is unavailable.

## Verify the download

Keep the DMG and its `.sha256` file in the same directory, then run:

```bash
shasum -a 256 -c BirthdayDays-1.0-universal.dmg.sha256
```

[English documentation](https://github.com/leon-su7/BirthdayDays/blob/main/README.md) · [简体中文说明](https://github.com/leon-su7/BirthdayDays/blob/main/README.zh-CN.md)
