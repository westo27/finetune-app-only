<img src="assets/icon.png" width="170" height="170" alt="AppMixer app icon" align="left"/>

<h3>AppMixer</h3>

Per-app audio control for macOS. Give every application its own volume, mute, up-to-4x boost and 10-band EQ from the menu bar. Audio devices are macOS's business: AppMixer leaves them alone.

<br clear="all"/>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-3a3a3c?style=for-the-badge&labelColor=1c1c1e" alt="License: GPL v3"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macOS-15%2B-3a3a3c?style=for-the-badge&labelColor=1c1c1e&logo=apple&logoColor=white" alt="macOS 15+"></a>
</p>

AppMixer is a fork of [FineTune](https://github.com/ronitsingh10/FineTune) by Ronit Singh, narrowed to app-audio mixing. The audio engine is unchanged — every app is still captured by its own Core Audio process tap and re-rendered — but the device-management surface is switched off, so the popup lists apps and nothing else.

## Quick Start

1. Build from source (below) and move `AppMixer.app` into `/Applications`
2. Grant **Screen & System Audio Recording** permission when prompted
3. Click the menu bar icon. Apps playing audio appear automatically.

## Features

### 🎚 Volume
- **Per-app volume** — Individual slider and mute for each application
- **Per-app boost** — 2x / 3x / 4x gain presets for apps that are too quiet
- **Pinned apps** — Keep an app listed when it isn't playing, so its volume and EQ can be set in advance
- **Ignored apps** — Disengage from an app entirely. The tap is torn down and the app returns to normal macOS audio
- **Scroll-wheel volume** — Hover any slider in the popup, the HUD or the EQ panel and scroll

### ⌨️ Keyboard
- **Global volume hotkeys** — Bind **App Volume Up / Down / Mute** in Settings → Shortcuts. The target is whichever app is currently making sound, falling back to the frontmost app when nothing is audible
- **Toggle the popup from anywhere** — Including from full-screen apps
- **Configurable step size** — Coarse / Normal / Fine / Extra-Fine, shared by the media keys, the hotkeys and arrow-key navigation
- **Drive the popup from the keyboard** — ↑ / ↓ move between apps, ← / → adjust volume (Shift = 2× step), **M** mutes, **Return** expands the EQ panel, **Esc** closes
- **Media keys & volume HUD** — Opt-in F10–F12 control with a Tahoe-style or Classic-style on-screen HUD

### 🎛 EQ
- **10-band EQ per app** — 20 presets across 5 categories
- **User presets** — Save, rename and manage your own EQ curves
- **Loudness compensation** — Bass and treble correction at low volume using ISO 226:2023 equal-loudness contours

### 🎨 Appearance
- **Light or Dark theme** — Follows macOS, or locks to one
- **Popup density** — Compact / Comfortable / Spacious
- **Menu bar icon** — Default, Speaker (tracks volume live), Waveform or Equalizer

## Device management

Everything device-shaped sits behind one switch: **Settings → General → Show Audio Devices**, off by default. Off, there is no device list, no device volume or mute, no input/microphone tab, no per-app output routing, no paired-Bluetooth list, no device priority ordering and no AutoEQ headphone correction. Every app follows the system default output.

Switching it on restores all of it, including any per-app routing and AutoEQ selections still saved on disk — the gate hides those features, it never deletes what you configured.

What deliberately keeps running underneath, because per-app audio depends on it: device discovery, aggregate-device construction for the taps, and reconnection handling. The media keys still adjust the system output volume, as they would without this app installed.

## Build from Source

```bash
git clone https://github.com/westo27/finetune-app-only.git
cd finetune-app-only
./scripts/build-local.sh
```

That builds Release, signs ad-hoc (no Developer ID needed) and prints the install command. The Xcode target and Swift module are still named FineTune; the built bundle is `AppMixer.app`.

Three things to know about local builds:

- **A plain `xcodebuild` is not enough.** Hardened runtime enables library validation, which requires embedded frameworks to share the main binary's Team ID. An ad-hoc signature has no Team ID, so the bundled `Sparkle.framework` fails the check and dyld kills the process at launch with *"mapping process and mapped file have different Team IDs"*. `build-local.sh` re-signs with `com.apple.security.cs.disable-library-validation` to allow it. Developer ID builds via `scripts/build-dmg.sh` are unaffected.
- **Signing changes the permission identity.** An ad-hoc signed build is a different app as far as macOS privacy is concerned, so **Screen & System Audio Recording** has to be granted again on first launch.
- **There is no update feed.** `SUFeedURL` is removed, so Sparkle cannot replace this build with an upstream FineTune release. Rebuild from source to update.

The bundle identifier is unchanged (`com.finetuneapp.FineTune`), so settings written by an existing FineTune install carry over.

## Documentation

- **[URL Schemes](guide/url-schemes.md)** — Automate volume and mute from Terminal, Shortcuts, Raycast or scripts
- **[Troubleshooting](guide/troubleshooting.md)** — Permission issues, missing apps, audio problems
- **[AutoEQ & Headphone Correction](guide/autoeq.md)** — Applies only with Show Audio Devices switched on

## Requirements

- macOS 15.0 (Sequoia) or later
- Audio capture permission (prompted on first launch)

## Credits

Upstream [FineTune](https://github.com/ronitsingh10/FineTune) is the work of [Ronit Singh](https://github.com/ronitsingh10), who deserves the credit for the audio engine this fork inherits. If it is useful to you, [tip the original author](https://ko-fi.com/ronitsingh10).

## License

[GPL v3](LICENSE), as upstream.
