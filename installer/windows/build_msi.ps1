# Builds Social Gallery Windows MSI from the Flutter release output.
param(
    [switch]$SkipFlutterBuild,
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$InstallerDir = $PSScriptRoot
$RepoRoot = Resolve-Path (Join-Path $InstallerDir "..\..")
$ReleaseDir = Join-Path $RepoRoot "build\windows\x64\runner\Release"
$OutputDir = Join-Path $RepoRoot "build\windows\installer"
$ProductWxs = Join-Path $InstallerDir "Product.wxs"
$AppFilesWxs = Join-Path $InstallerDir "AppFiles.wxs"

function Get-ProductVersion {
    param([string]$Override)
    if ($Override -ne "") {
        return $Override
    }

    $pubspec = Get-Content (Join-Path $RepoRoot "pubspec.yaml") -Raw
    if ($pubspec -match '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
        return "$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
    }
    if ($pubspec -match '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)') {
        return "$($Matches[1]).$($Matches[2]).$($Matches[3]).0"
    }
    throw "Could not parse version from pubspec.yaml"
}

function Find-WixV3 {
    $candidates = @()

    if ($env:WIX) {
        $candidates += Join-Path $env:WIX "heat.exe"
    }

    $programFilesX86 = ${env:ProgramFiles(x86)}
    if ($programFilesX86) {
        $candidates += @(
            (Join-Path $programFilesX86 "WiX Toolset v3.14\bin\heat.exe"),
            (Join-Path $programFilesX86 "WiX Toolset v3.11\bin\heat.exe")
        )
    }

    foreach ($heat in $candidates) {
        if (Test-Path $heat) {
            $bin = Split-Path $heat -Parent
            return @{
                Heat = $heat
                Candle = Join-Path $bin "candle.exe"
                Light = Join-Path $bin "light.exe"
            }
        }
    }

    $heatCmd = Get-Command heat.exe -ErrorAction SilentlyContinue
    if ($heatCmd) {
        $bin = $heatCmd.Source | Split-Path -Parent
        return @{
            Heat = $heatCmd.Source
            Candle = Join-Path $bin "candle.exe"
            Light = Join-Path $bin "light.exe"
        }
    }

    return $null
}

function Build-WithWixV3 {
    param(
        $Tools,
        [string]$ProductVersion,
        [string]$MsiPath
    )

    if (-not (Test-Path $Tools.Candle)) { throw "candle.exe not found next to heat.exe" }
    if (-not (Test-Path $Tools.Light)) { throw "light.exe not found next to heat.exe" }

    if (Test-Path $AppFilesWxs) {
        Remove-Item $AppFilesWxs -Force
    }

    Write-Host "Harvesting release files with heat..."
    & $Tools.Heat dir $ReleaseDir `
        -cg AppFiles `
        -dr INSTALLFOLDER `
        -gg `
        -sfrag `
        -srd `
        -var var.ReleaseDir `
        -out $AppFilesWxs
    if ($LASTEXITCODE -ne 0) { throw "heat failed with exit code $LASTEXITCODE" }

    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

    $candleArgs = @(
        "-nologo",
        "-arch", "x64",
        "-dProductVersion=$ProductVersion",
        "-dReleaseDir=$ReleaseDir",
        "-dRepoRoot=$RepoRoot",
        "-dInstallerDir=$InstallerDir",
        "-out", (Join-Path $OutputDir "\"),
        $ProductWxs,
        $AppFilesWxs
    )

    Write-Host "Compiling WiX sources..."
    & $Tools.Candle @candleArgs
    if ($LASTEXITCODE -ne 0) { throw "candle failed with exit code $LASTEXITCODE" }

    $wixObjs = Get-ChildItem $OutputDir -Filter "*.wixobj" | ForEach-Object { $_.FullName }

    Write-Host "Linking MSI..."
    & $Tools.Light `
        -nologo `
        -ext WixUIExtension `
        -cultures:en-us `
        -out $MsiPath `
        @wixObjs
    if ($LASTEXITCODE -ne 0) { throw "light failed with exit code $LASTEXITCODE" }
}

$productVersion = Get-ProductVersion -Override $Version
$msiName = "SocialGallery-$productVersion.msi"
$msiPath = Join-Path $OutputDir $msiName

Write-Host "Social Gallery MSI build"
Write-Host "  Version: $productVersion"
Write-Host "  Release: $ReleaseDir"
Write-Host "  Output:  $msiPath"

if (-not $SkipFlutterBuild) {
    Write-Host "Building Flutter Windows release..."
    Push-Location $RepoRoot
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        throw "flutter build windows failed"
    }
    Pop-Location
}

if (-not (Test-Path (Join-Path $ReleaseDir "social_gallery.exe"))) {
    throw "Release build not found at $ReleaseDir. Run without -SkipFlutterBuild."
}

$wixV3 = Find-WixV3

if ($wixV3) {
    Write-Host "Using WiX v3 at $(Split-Path $wixV3.Heat -Parent)"
    Build-WithWixV3 -Tools $wixV3 -ProductVersion $productVersion -MsiPath $msiPath
}
else {
    throw @"
WiX Toolset v3 not found.

Install (admin PowerShell):
  winget install --id WiXToolset.WiXToolset --accept-package-agreements --accept-source-agreements

Then open a new terminal and run this script again.

See installer/windows/README.md for details.
"@
}

Write-Host ""
Write-Host "Done: $msiPath"
