$ErrorActionPreference = 'Stop'

# Builds the native messaging host for Windows and places it where the desktop
# bundle's install() step (windows/CMakeLists.txt) picks it up.

Set-Location -Path $PSScriptRoot

$outputDir = '../assets/extension'

Push-Location native
dart pub get
Pop-Location

# assets/extension is gitignored, so it is absent on a fresh checkout and
# `dart compile exe` will not create the parent directory for its --output.
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

dart compile exe native/src/main.dart --target-os windows --output "$outputDir/native_windows.exe"
