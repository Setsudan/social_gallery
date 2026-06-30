# Social Gallery Windows MSI

Builds an MSI installer from the Flutter Windows release output using the [WiX Toolset](https://wixtoolset.org/).

## Prerequisites

1. Flutter Windows desktop toolchain (`flutter doctor`)
2. WiX Toolset **v3.11+** (MSI packaging)

### Install WiX

```powershell
winget install --id WiXToolset.WiXToolset --accept-package-agreements --accept-source-agreements
```

Run from an **elevated** (admin) PowerShell if prompted for .NET Framework 3.5 (`NetFx3`).

Then open a **new** terminal so `candle`, `light`, and `heat` are on `PATH`, or set:

```powershell
$env:WIX = "${env:ProgramFiles(x86)}\WiX Toolset v3.14\bin"
```

## Build

From the repository root:

```powershell
.\installer\windows\build_msi.ps1
```

Options:

| Flag | Description |
|------|-------------|
| `-SkipFlutterBuild` | Reuse existing `build/windows/x64/runner/Release` |
| `-Version "1.2.3.4"` | Override version (default: parsed from `pubspec.yaml`) |

Output: `build/windows/installer/SocialGallery-<version>.msi`

## What the installer does

- Installs to `Program Files\Social Gallery`
- Adds a Start Menu shortcut
- Supports upgrade via fixed `UpgradeCode` (same family replaces older MSI)
- Packages the full Release folder (exe, DLLs, `data/` assets)

## Troubleshooting

- **WiX not found**: Install WiX and restart the shell, or set `$env:WIX` to the `bin` folder containing `heat.exe`.
- **Missing Release build**: Run `flutter build windows --release` first, or omit `-SkipFlutterBuild`.
- **Firewall**: The app may prompt for LAN access when using desktop backup receive mode.
