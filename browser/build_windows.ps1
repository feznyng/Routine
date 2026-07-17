$ErrorActionPreference = 'Stop'

# Builds the native messaging host for Windows and places it where the desktop
# bundle's install() step (windows/CMakeLists.txt) picks it up.

Set-Location -Path $PSScriptRoot

Push-Location native
dart pub get
Pop-Location

dart compile exe native/src/main.dart --target-os windows --output ../assets/extension/native_windows.exe
