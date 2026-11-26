$ErrorActionPreference = 'Stop'

# Builds the native messaging host for Windows and places it where the desktop
# bundle's install() step (windows/CMakeLists.txt) picks it up.

Set-Location -Path $PSScriptRoot

$outputDir = '../assets/extension'

Push-Location native
dart pub get
if ($LASTEXITCODE -ne 0) { throw "dart pub get failed (exit $LASTEXITCODE)" }
Pop-Location

# assets/extension is gitignored, so it is absent on a fresh checkout and
# `dart compile exe` will not create the parent directory for its --output.
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Remove-Item -Force -ErrorAction SilentlyContinue "$outputDir/native_windows.exe"
dart compile exe native/src/main.dart --target-os windows --output "$outputDir/native_windows.exe"
if ($LASTEXITCODE -ne 0) { throw "dart compile exe failed (exit $LASTEXITCODE)" }
if (-not (Test-Path "$outputDir/native_windows.exe")) { throw "dart compile exe produced no $outputDir/native_windows.exe" }
