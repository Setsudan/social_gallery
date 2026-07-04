# Social Gallery (beta)

A local-first, social-style photo gallery for Android and iOS. Browse your device library through a feed, stories, and albums — all indexed and stored on-device. No cloud account required.

**Version:** 0.0.11+1

## Highlights

- Social-style **Home feed** and **Stories** from folders you choose
- **Gallery view mode** with pinch-to-zoom timeline grouping (day / month / year)
- **Biometric-locked folders** for private albums
- **Organize** workflow (swipe to keep, favorite, trash, or move)
- **Discover** tools: duplicates, similar photos, low-quality review, compression, shooting stats
- **Travel mode** to auto-sort photos from trips into a folder
- Fully **on-device** indexing and analysis (SQLite via Drift)

## Screenshots

<!-- Add screenshots here -->

## Features

### Navigation

Three main tabs (labels change in Gallery view mode):

| Default mode | Gallery view mode |
|--------------|-------------------|
| Home | Gallery |
| Explore | Albums |
| Discover | Discover |

Settings opens from the menu button in the bottom nav (or sidebar on wide screens).

### Home feed

- Scrollable feed of recent media from folders set to **Home Feed**
- **Stories** row at the top — tap a folder bubble to view recent shots full-screen
- **Account-only** folders shown as cards (locked folders require biometrics)
- Favorite (double-tap), share, and open folder from each post
- Pull to refresh; infinite scroll pagination

### Explore and search

- Full-screen search with **recent searches**
- Search matches folder names, media metadata, **detected objects/animals**, and **dominant color**
- Object chips (cat, dog, bottle, etc.) and color filters for quick discovery
- Background indexing tags photos automatically after library sync
- Folder suggestions above results; tap to open folder profile
- Grid or mosaic layout (mosaic on desktop / Windows)
- Multi-select: move, trash, favorite, create album and move

### Gallery and albums

Enable **Gallery view mode** in Settings to swap Home/Explore for Gallery/Albums.

**Gallery**

- All photos and videos in a scrollable grid
- Pinch to change grouping: **Years → Months → Days**
- Multi-select bulk actions
- Tap a photo for post detail (metadata, share, trash, folder)

**Albums**

- Grid of device albums/folders (excluding locked account folders)
- Tap to open folder profile

**Locked albums**

- In Gallery view mode, **long-press the Albums tab** in the bottom nav to open locked albums
- Albums marked **Account only (locked)** require biometrics to view

### Folder management

Settings → **Manage content**

- Set folder visibility:
  - **Home Feed** — appears in feed and stories
  - **Account only** — shown on Home as account cards, not in main feed
  - **Account only (locked)** — account card + biometric gate
  - **Hidden** — excluded from feed and explore
- Toggle biometric lock per folder
- Bulk visibility changes via multi-select

Each folder profile supports custom cover, optional bio, visibility changes, and media bulk actions.

### Organize

Discover → **Organize** — swipe through unprocessed photos in batches:

| Gesture | Action |
|---------|--------|
| Swipe left | Mark for trash |
| Swipe right | Favorite |
| Swipe up | Keep |
| Swipe down | Move to folder |

Trash is reviewed before deletion. Filter by folder, media type, or month. Undo supported.

Configure batch size and queue order (random / chronological) in Settings.

### Discover and cleanup

**Deep organize** (on-device scan, Android/iOS):

- Perceptual hashing, blur/exposure analysis
- ML Kit face detection and image labeling
- **Similar photos** — review groups, keep best, delete rest
- **Low quality** — review flagged shots
- **Compression** — shrink large JPEGs in place (mobile only)

**Duplicates** — background scan for near-identical photos; notification when complete

**Shooting stats** — monthly breakdown of photos, videos, screenshots, favorites, and activity

**Likes review** — browse photos you favorited via Organize or the feed

**Coming soon** (placeholder screens): Bursts, Smart suggestions, Locations

### Travel mode

Settings → **Travel mode**

Create a trip with name, date range, and destination folder. While active, new media in that period can be auto-organized into the trip folder.

### Trash

Items moved to trash are kept for a configurable period (default set in Settings), then permanently removed. Background cleanup runs daily on Android.

Settings → **Deleted items** to restore or permanently delete.

### Settings

- **Appearance:** theme (System / Light / Solar / Dark / Dark OLED), accent color, font size, animation speed
- **Gallery view mode:** switch Home/Explore to Gallery/Albums layout
- **Desktop backup:** pair phone with desktop on same Wi-Fi; automatic backup when desktop app is running (mobile). On desktop, enable **Receive backups** and use the pairing PIN/QR.
- **Organize:** batch size, queue order, release kept photos back to queue
- **Storage:** trash retention, cache size/limit, auto-clear on close
- **About:** version, privacy policy, open-source licenses, share app

## Privacy

All library indexing, organization state, and ML analysis run **on your device**. Media stays in your system gallery; Social Gallery reads and optionally moves/deletes files you explicitly action. Locked folders use your device's biometric APIs.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible with Dart ^3.11.5
- Android Studio / Xcode for mobile builds
- For Android release builds: JDK 17+

### Clone and install

```bash
git clone <repository-url>
cd social_gallery
flutter pub get
```

### Code generation (only if you change Drift schema)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (e.g. `app_database.g.dart`) are already committed.

### Run

```bash
# Android (device or emulator)
flutter run

# iOS (macOS required)
flutter run -d ios

# Windows (experimental desktop support)
flutter run -d windows
```

On first launch, complete onboarding: grant photo access, and on Android 11+ optionally grant **All files access** for move/delete across albums. On Windows, pick a root gallery folder.

### Release builds

Android APK and Windows MSI are **separate artifacts** — build only the platform you need. This keeps each output smaller than packaging everything together.

#### Android APK (split per CPU architecture)

Build one APK per ABI instead of a single universal (fat) APK:

```bash
flutter build apk --release --split-per-abi
```

Outputs in `build/app/outputs/flutter-apk/`:

| File | Typical use |
|------|-------------|
| `app-arm64-v8a-release.apk` | Most phones and tablets (2017+) |
| `app-armeabi-v7a-release.apk` | Older 32-bit ARM devices |
| `app-x86_64-release.apk` | Emulators and rare x86 devices |

Install the APK that matches the target device. Each file is much smaller than `app-release.apk` (all ABIs in one package).

To build for a single architecture only:

```bash
flutter build apk --release --target-platform android-arm64
```

#### Windows MSI installer

Requires [WiX Toolset](https://wixtoolset.org/) v3.11+ (see `installer/windows/README.md`). Independent of the Android build.

```powershell
.\installer\windows\build_msi.ps1
```

Output: `build/windows/installer/SocialGallery-<version>.msi`

Use `-SkipFlutterBuild` to package an existing Windows release without rebuilding Flutter.

### Build iOS

```bash
flutter build ios --release
```

Open `ios/Runner.xcworkspace` in Xcode to archive and sign.

## Platform notes

| Feature | Android | iOS | Windows |
|---------|---------|-----|---------|
| Feed, albums, organize | Yes | Yes | Yes |
| Move/delete across albums | All-files access recommended | System photo APIs | Filesystem |
| Biometric locked folders | Yes | Face ID / Touch ID | No |
| ML deep organize scan | Yes | Yes | Limited |
| Image compression | Yes | Yes | Not supported |
| Duplicate scan notifications | Yes | Yes | No |
| LAN backup to desktop | Yes | Yes | Receive + browse/stream |
| Background trash cleanup | Workmanager | Limited | No |

## Developer documentation

Architecture, data flow, routing, and conventions are documented with Dart doc comments on classes and public APIs under `lib/`. Run `dart doc` or read sources directly (start with `lib/main.dart`, `lib/app/providers.dart`, and `lib/app/router.dart`).

## Architecture

- **UI:** Flutter + Material 3 (One UI-inspired components)
- **State:** flutter_riverpod
- **Routing:** go_router (shell routes + full-screen modals)
- **Database:** Drift (SQLite) for folders, media index, travel modes, analysis cache
- **Media access:** photo_manager (mobile), filesystem scan (Windows)

### Desktop backup (LAN)

Mobile and desktop must be on the same Wi-Fi. On desktop: Settings → **Receive backups** → show pairing code. On mobile: Settings → **Desktop backup** → pair with PIN, then enable automatic backup. Backup only starts after a successful health check (desktop running and reachable). Cellular networks are never used for backup.

**Protocol v2** adds two capabilities:

- **Vault sync:** media from biometric-locked albums is encrypted at rest on the desktop as password-protected AES-256 zip archives. Set the vault password on mobile when prompted during the first locked-album backup.
- **Browse/stream:** on mobile, open **Browse home archive** in Desktop backup settings to view photos and videos stored on the desktop over Wi-Fi without importing them to the phone.

**Windows:** allow the app through the firewall when prompted on first backup receive.

**iOS:** local network permission is required for discovery and backup.

## License

See open-source licenses in the app (Settings → Open-source licenses).
