set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]

[unix]
app:
    flutter run

[windows]
app: firebase-strip
    try { flutter run } finally { & '{{just_executable()}}' firebase-restore }

[unix]
build platform *args: (build-nmh platform)
    flutter build {{platform}} --release {{args}}

[windows]
build platform *args: (build-nmh platform) firebase-strip
    try { flutter build {{platform}} --release {{args}} } finally { & '{{just_executable()}}' firebase-restore }

[windows]
firebase-strip:
    powershell -ExecutionPolicy Bypass -File clean_windows.ps1
    flutter pub get

[windows]
firebase-restore:
    powershell -ExecutionPolicy Bypass -File clean_windows.ps1 -Uncomment
    flutter pub get

[unix]
release platform:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{platform}}" in
      macos|android|ios) ./scripts/release/{{platform}}.sh ;;
      *) echo "error: cannot build '{{platform}}' here (expected macos|android|ios)" >&2; exit 1 ;;
    esac

[windows]
release platform:
    if ("{{platform}}" -ne "windows") { Write-Error "cannot build '{{platform}}' here (expected windows)"; exit 1 }
    powershell -ExecutionPolicy Bypass -File scripts/release/windows.ps1

[unix]
release-notes:
    ARTIFACT_DIR=dist ./scripts/release/notes.sh

[unix]
build-nmh platform:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{platform}}" in
      macos)   (cd browser && bash ./build_native_macos.sh) ;;
      linux)   (cd browser && bash ./build_native_linux.sh) ;;
      *) echo "error: cannot build '{{platform}}' here (expected macos|linux)" >&2; exit 1 ;;
    esac

[windows]
build-nmh platform:
    if ("{{platform}}" -ne "windows") { Write-Error "cannot build '{{platform}}' here (expected windows)"; exit 1 }
    powershell -ExecutionPolicy Bypass -File browser/build_windows.ps1

[unix]
build-ext:
    ./scripts/release/extension.sh

[unix]
screenshots target="iPhone 17 Pro Max" appearance="light" dir="docs/screenshots":
    ./scripts/screenshots.sh '{{target}}' '{{appearance}}' '{{dir}}'
