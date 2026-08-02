# just runs recipes under `sh` by default, which Windows doesn't ship. Recipes
# below are either split per-OS with [unix]/[windows] or written to be valid in
# both shells; nothing here relies on bash or git-bash being installed.
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

# Start the Flutter app
[unix]
app:
    flutter run

# Start the Flutter app
[windows]
app: firebase-strip
    try { flutter run } finally { & '{{just_executable()}}' firebase-restore }

# Build the native messaging host, then the release desktop app (platform: macos|linux)
[unix]
release platform: (build-nmh platform)
    flutter build {{platform}} --release

# Build the native messaging host, then the release desktop app (platform: windows)
[windows]
release platform: (build-nmh platform) firebase-strip
    try { flutter build {{platform}} --release } finally { & '{{just_executable()}}' firebase-restore }

# Firebase can't build for Windows: firebase_core ships a Windows plugin whose
# CMake step downloads the Firebase C++ SDK, and firebase_messaging pulls
# firebase_core in transitively, so both have to go. pub has no way to make a
# dependency platform-conditional, so the deps in pubspec.yaml and the imports
# and call sites that would fail to resolve without them are commented out for
# the duration of a Windows build (every such line is tagged WINDOWS:REMOVE).
#
# The `try/finally` above restores the tree even if the build fails or is
# interrupted. Both recipes are idempotent, so run `just firebase-restore` by
# hand if a build is killed hard enough to skip the finally.
#
# Comment out the Firebase deps and their call sites
[windows]
firebase-strip:
    powershell -ExecutionPolicy Bypass -File clean_windows.ps1
    flutter pub get

# Restore the Firebase deps and their call sites
[windows]
firebase-restore:
    powershell -ExecutionPolicy Bypass -File clean_windows.ps1 -Uncomment
    flutter pub get

# The desktop build injects this binary into the app bundle; it is not a pubspec
# asset, so it never ships in the iOS/Android app.
#
# Build the native messaging host for the given platform (macos|linux)
[unix]
build-nmh platform:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{platform}}" in
      macos)   (cd browser && bash ./build_native_macos.sh) ;;
      linux)   (cd browser && bash ./build_native_linux.sh) ;;
      *) echo "error: cannot build '{{platform}}' here (expected macos|linux)" >&2; exit 1 ;;
    esac

# Build the native messaging host (platform: windows)
[windows]
build-nmh platform:
    if ("{{platform}}" -ne "windows") { Write-Error "cannot build '{{platform}}' here (expected windows)"; exit 1 }
    powershell -ExecutionPolicy Bypass -File browser/build_windows.ps1
