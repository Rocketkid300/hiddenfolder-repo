# Hidden Folder — Changelog

All notable changes to the **Hidden Folder** tweak (`com.bigpickle.hiddenfolder`)
and the **Hidden Vault** app (`com.bigpickle.hiddenvault`).

Format follows [Keep a Changelog](https://keepachangelog.com/) conventions. Versions are semver.

---

# Hidden Vault (app) — `com.bigpickle.hiddenvault`

## [1.2.0] — 2026-09-20

### Added
- **Apple-style unlock**: unlock the vault with **Face ID / Touch ID — or Apple's own passcode dialog** (LocalAuthentication), exactly like a system app. The 4-digit pad stays as a fallback.
- **App Library pod look**: the vault now sits in the App Library as a **normal app pod** — a dark locked-folder icon (iOS-18-style rounded card) labeled **"Hidden"**, just like the "Suggested / Recently Added" cards at the top of the Library.

### Changed
- Display name `Hidden Vault` → **`Hidden`**.

## [1.0.1] — 2026-09-20

### Added
- Initial release: 4-digit passcode (salted hash), app picker, open apps from the passcode-gated list, swipe-to-remove from vault. Rootless, `Depends: firmware (>= 15.0)` only.

---

# Hidden Folder (tweak) — `com.bigpickle.hiddenfolder`

## [1.4.0] — 2026-09-20

### Changed
- **Removed the `oldabi` dependency entirely.** This is the big one.
- The arm64e slice is now built as **new ABI** (same as every standard Dopamine repo tweak) using the **Allemande** converter (p0358/allemande — port of evelyneee's allemand).
- Result: the tweak loads natively on A12+ devices with **no `oldabi`, no `cy+cpu.arm64e` marker, no dependency chain** — exactly like tweaks from Chariz/BigBoss etc.
- Packaging now matches standard rootless repos: `Architecture: iphoneos-arm64`, `Depends: mobilesubstrate (>= 0.9.5000)` (+ `Firmware: >= 15.0`).

### Added
- Re-signed with `ldid` after conversion (`LC_CODE_SIGNATURE` present).

## [1.3.0] — 2026-09-20

### Added
- **Load-confirmation banner**: after every respring, a toast appears on the Home Screen — *"✅ Hidden Folder active — 🔒 pod in App Library (bottom-right)"* — giving instant, visible proof the tweak loaded.

## [1.2.0] — 2026-09-20

### Fixed
- **Pod placement completely rewritten.** Earlier versions tried to anchor onto guessed private class names (`PodIconListView`, `LibraryCategoryMapView`, …); if the actual internal name differed, the pod silently never appeared.
- The pod is now pinned to the App Library screen itself (bottom-right corner) — no internal-name guessing at all.
- Added retries (0.35s / 0.8s / 1.6s / 3.0s after the library appears) plus a re-check on every layout pass.

### Added
- Detailed `NSLog` diagnostics at every step (`dylib loaded`, `library appeared`, `pod installed`) for fast troubleshooting.

## [1.1.0] — 2026-09-20

### Changed
- **Removed the Settings-app page entirely.** All configuration now lives *inside* the Hidden folder via the ⚙️ gear menu: Set / Change / Remove Passcode, Lock Now, Hide Mode, How it works.
- Package slimmed to just the dylib + filter plist. Dropped `preferenceloader` and the prefs bundle.

## [1.0.0] — 2026-09-19

### Added
- Initial release:
  - Passcode-protected "Hidden" folder pod at the end of the App Library.
  - 4-digit passcode with salted hash storage.
  - **Hide Mode**: one tap on a Home Screen icon hides it into the folder.
  - Long-press inside the folder to unhide apps.
  - Settings page in the Settings app (later removed in 1.1.0).