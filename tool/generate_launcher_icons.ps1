# Generates light and dark launcher icons for Android and iOS.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "Configuring Android light and night launcher icons..."
powershell -ExecutionPolicy Bypass -File "$root\tool\setup_dark_launcher_icons.ps1"

Write-Host "Generating iOS dark appearance icons..."
dart run tool/generate_ios_dark_icons.dart

Write-Host "Generating Windows and macOS launcher icons..."
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml

Write-Host "Launcher icon generation complete."
