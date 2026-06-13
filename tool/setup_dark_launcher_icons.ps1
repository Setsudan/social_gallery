# Generates Android night-mode launcher icon resources from flutter_launcher_icons dark output.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "Restoring light launcher icons..."
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml | Out-Null

Write-Host "Generating dark launcher icon assets..."
dart run flutter_launcher_icons -f flutter_launcher_icons_dark.yaml | Out-Null

$res = Join-Path $root "android\app\src\main\res"
$densityMap = @{
    "mdpi"    = "mipmap-mdpi"
    "hdpi"    = "mipmap-hdpi"
    "xhdpi"   = "mipmap-xhdpi"
    "xxhdpi"  = "mipmap-xxhdpi"
    "xxxhdpi" = "mipmap-xxxhdpi"
}

foreach ($density in $densityMap.Keys) {
    $drawableDir = Join-Path $res "drawable-night-$density"
    $source = Join-Path $res "drawable-$density\ic_launcher_foreground.png"
    New-Item -ItemType Directory -Force -Path $drawableDir | Out-Null
    Copy-Item $source (Join-Path $drawableDir "ic_launcher_foreground.png") -Force

    $mipmapNightDir = Join-Path $res "mipmap-night-$density"
    $nightSource = Join-Path $res "$($densityMap[$density])\ic_launcher_night_gen.png"
    New-Item -ItemType Directory -Force -Path $mipmapNightDir | Out-Null
    Copy-Item $nightSource (Join-Path $mipmapNightDir "ic_launcher.png") -Force
}

$nightAdaptiveDir = Join-Path $res "mipmap-night-anydpi-v26"
New-Item -ItemType Directory -Force -Path $nightAdaptiveDir | Out-Null
@(
    "ic_launcher.xml"
) | ForEach-Object {
    Copy-Item (Join-Path $res "mipmap-anydpi-v26\$_") (Join-Path $nightAdaptiveDir $_) -Force
}

$valuesNightDir = Join-Path $res "values-night"
New-Item -ItemType Directory -Force -Path $valuesNightDir | Out-Null
@'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#000000</color>
</resources>
'@ | Set-Content (Join-Path $valuesNightDir "colors.xml") -Encoding UTF8

Write-Host "Restoring light foreground drawables and default background color..."
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml | Out-Null

Get-ChildItem -Path $res -Recurse -Filter "ic_launcher_night_gen*" | Remove-Item -Force

Write-Host "Android night launcher icons configured."
