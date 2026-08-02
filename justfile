# Start the Flutter app
app:
    flutter run

# Build the native messaging host, then the release desktop app (platform: macos|windows|linux)
release platform: (build-nmh platform)
    flutter build {{platform}} --release

# The desktop build injects this binary into the app bundle; it is not a pubspec
# asset, so it never ships in the iOS/Android app.
#
# Build the native messaging host for the given platform (macos|windows|linux)
build-nmh platform:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{platform}}" in
      macos)   (cd browser && bash ./build_native_macos.sh) ;;
      linux)   (cd browser && bash ./build_native_linux.sh) ;;
      windows) powershell -ExecutionPolicy Bypass -File browser/build_windows.ps1 ;;
      *) echo "error: unknown platform '{{platform}}' (expected macos|windows|linux)" >&2; exit 1 ;;
    esac
