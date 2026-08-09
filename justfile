# just defaults to `sh`, which Windows doesn't ship, so recipes are split with
# [unix]/[windows] or kept valid in both shells. No bash/git-bash needed.
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

# Firebase can't build for Windows (firebase_core's CMake step downloads the
# C++ SDK), and pub deps can't be platform-conditional, so the deps and their
# call sites are commented out for the build - each tagged WINDOWS:REMOVE.
#
# The try/finally above restores the tree on failure. Both recipes are
# idempotent: run `just firebase-restore` by hand if a build is killed hard.
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

# Build both extension zips, sign the Firefox build on AMO, publish Chrome to the CWS
[unix]
build-ext:
    #!/usr/bin/env bash
    set -euo pipefail

    EXT_DIR="browser/extension"
    BUILD_DIR="browser/web-ext-artifacts"

    if ! command -v web-ext &> /dev/null; then
        echo "Error: web-ext is not installed. Please install it using 'npm install -g web-ext'" >&2
        exit 1
    fi

    # jq derives the per-browser manifests below
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install it using 'brew install jq'" >&2
        exit 1
    fi

    if [ -z "${AMO_JWT_ISSUER:-}" ] || [ -z "${AMO_JWT_SECRET:-}" ]; then
        echo "Error: AMO_JWT_ISSUER and AMO_JWT_SECRET environment variables must be set" >&2
        echo "Please set them with:" >&2
        echo "export AMO_JWT_ISSUER=your-jwt-issuer" >&2
        echo "export AMO_JWT_SECRET=your-jwt-secret" >&2
        exit 1
    fi

    # Optional: without these the recipe still writes chrome.zip for manual upload.
    CWS_PUBLISH=1
    for var in CWS_CLIENT_ID CWS_CLIENT_SECRET CWS_REFRESH_TOKEN CWS_EXTENSION_ID; do
        if [ -z "${!var:-}" ]; then CWS_PUBLISH=0; fi
    done

    # AMO rejects an already-signed version, so catch it before a full build.
    # Only sees versions still on disk (pruned below), so AMO stays the truth.
    VERSION=$(jq -r .version "$EXT_DIR/manifest.json")
    if [ -n "$(find "$BUILD_DIR" -maxdepth 1 -name "*-$VERSION.xpi" -print -quit)" ]; then
        echo "Error: version $VERSION has already been signed (found *-$VERSION.xpi)" >&2
        echo "Bump \"version\" in $EXT_DIR/manifest.json before signing again." >&2
        exit 1
    fi

    mkdir -p "$BUILD_DIR/firefox" "$BUILD_DIR/chrome"

    # Firefox uses background.scripts (service_worker is unsupported) and ignores Chrome's "key"
    echo "Building Firefox version..."
    cp -r "$EXT_DIR/icons" "$EXT_DIR/background.js" "$BUILD_DIR/firefox/"
    jq 'del(.background.service_worker) | del(.key)' \
        "$EXT_DIR/manifest.json" > "$BUILD_DIR/firefox/manifest.json"

    # Chrome uses background.service_worker and warns on Firefox-only keys
    echo "Building Chrome version..."
    cp -r "$EXT_DIR/icons" "$EXT_DIR/background.js" "$BUILD_DIR/chrome/"
    jq 'del(.background.scripts) | del(.browser_specific_settings)' \
        "$EXT_DIR/manifest.json" > "$BUILD_DIR/chrome/manifest.json"

    # Zip from inside each dir so manifest.json sits at the archive root -
    # stores reject a nested folder.
    rm -f "$BUILD_DIR/firefox.zip" "$BUILD_DIR/chrome.zip"
    (cd "$BUILD_DIR/firefox" && zip -qr ../firefox.zip . -x '*.DS_Store')
    (cd "$BUILD_DIR/chrome" && zip -qr ../chrome.zip . -x '*.DS_Store')

    # Chrome first: a failure here leaves AMO untouched, so a retry does not
    # burn a version number on the Firefox side.
    if [ "$CWS_PUBLISH" = 1 ]; then
        echo "Publishing Chrome extension..."

        # Access tokens last an hour; the refresh token is the long-lived secret.
        CWS_TOKEN=$(curl -sf -X POST https://oauth2.googleapis.com/token \
            -d "client_id=$CWS_CLIENT_ID" \
            -d "client_secret=$CWS_CLIENT_SECRET" \
            -d "refresh_token=$CWS_REFRESH_TOKEN" \
            -d "grant_type=refresh_token" | jq -er .access_token)

        # Upload failures come back in the body with HTTP 200, so check
        # uploadState rather than curl's exit status.
        UPLOAD=$(curl -sf -X PUT \
            -H "Authorization: Bearer $CWS_TOKEN" \
            -H "x-goog-api-version: 2" \
            -T "$BUILD_DIR/chrome.zip" \
            "https://www.googleapis.com/upload/chromewebstore/v1.1/items/$CWS_EXTENSION_ID")
        if [ "$(jq -r .uploadState <<< "$UPLOAD")" != "SUCCESS" ]; then
            echo "Error: Chrome Web Store upload failed" >&2
            jq -r '.itemError[]?.error_detail // .' <<< "$UPLOAD" >&2
            exit 1
        fi

        # Only submits for review; goes live on Google's approval, slower than AMO.
        PUBLISH=$(curl -sf -X POST \
            -H "Authorization: Bearer $CWS_TOKEN" \
            -H "x-goog-api-version: 2" \
            -H "Content-Length: 0" \
            "https://www.googleapis.com/chromewebstore/v1.1/items/$CWS_EXTENSION_ID/publish")
        echo "Chrome Web Store status: $(jq -r '.status | join(", ")' <<< "$PUBLISH")"
    else
        echo "Skipping Chrome publish - set CWS_CLIENT_ID, CWS_CLIENT_SECRET, CWS_REFRESH_TOKEN and CWS_EXTENSION_ID to enable"
    fi

    # Listed channel: AMO hosts the add-on and handles auto-updates, like the CWS.
    echo "Signing Firefox extension..."
    web-ext sign \
        --source-dir="$BUILD_DIR/firefox" \
        --artifacts-dir="$BUILD_DIR" \
        --api-key="$AMO_JWT_ISSUER" \
        --api-secret="$AMO_JWT_SECRET" \
        --amo-metadata="browser/amo-metadata.json" \
        --channel listed

    echo "Cleaning up build directories..."
    rm -rf "$BUILD_DIR/firefox" "$BUILD_DIR/chrome"

    echo "Build complete!"
    echo "Firefox extension: $BUILD_DIR/firefox.zip"
    echo "Chrome extension: $BUILD_DIR/chrome.zip"
    echo "Signed Firefox extension can be found in $BUILD_DIR"
    if [ "$CWS_PUBLISH" != 1 ]; then
        echo "Chrome build was NOT published - upload chrome.zip manually"
    fi

    # Clean up old builds
    find "$BUILD_DIR" -name "*.xpi" -mtime +30 -delete

# Resolve a simulator name to its udid, or fail with the list of what is available
[unix]
_udid target:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install it using 'brew install jq'" >&2
        exit 1
    fi

    UDID=$(xcrun simctl list devices available -j \
        | jq -r --arg name "{{target}}" \
            '.devices | to_entries[] | .value[] | select(.name == $name) | .udid' \
        | head -n1)

    if [ -z "$UDID" ]; then
        echo "Error: no available simulator named '{{target}}'" >&2
        echo "Available:" >&2
        xcrun simctl list devices available | grep -E '^ +(iPhone|iPad)' >&2
        exit 1
    fi

    echo "$UDID"


# Takes over the keyboard so a shot is one keypress:
#
#     s   save the next numbered shot into ./screenshots
#     r   hot reload          R   hot restart
#     q   quit
#
#     just screenshots                            # iPhone, light
#     just screenshots "iPhone 17 Pro Max" dark
#     just screenshots macos
#
# flutter gets /dev/null for stdin so it doesn't fight this loop for the
# terminal; reload/restart use the signals it documents for that case
# (--pid-file, SIGUSR1, SIGUSR2), so nothing is lost.
#
# iOS shots come from simctl. Desktop captures the window by id, which keeps
# the rounded corners transparent (so keep PNG); it needs Screen Recording
# permission and picks the largest window if several copies run.
#
# App Store Connect only needs the 6.9" iPhone set (1320x2868) - it scales that
# down. An iPad set is only needed if TARGETED_DEVICE_FAMILY returns to "1,2".
#
# appearance pins light or dark so a set isn't half and half. Simulators only -
# desktop follows the host setting, and opens at 1280x800 not 800x600.
#
# The iOS build is debug because Flutter only builds debug for the simulator;
# fine here, the banner is off and a still frame doesn't care about jank.
#
# Demo mode points drift at routine_db_demo and disables sync, so this can't
# touch the real routines on this machine or the account.
#
# Run the app with seeded demo routines and capture on a keypress (target: simulator name|macos|linux)
[unix]
screenshots target="iPhone 17 Pro Max" appearance="light" dir="screenshots":
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "{{dir}}"
    PIDFILE=$(mktemp -t routine-flutter-pid)

    case "{{target}}" in
      macos|linux)
        DEVICE="{{target}}"
        SLUG="{{target}}"
        ;;
      windows)
        echo "Error: build Windows from a Windows host - it needs the firebase-strip dance" >&2
        exit 1
        ;;
      *)
        DEVICE=$({{just_executable()}} _udid "{{target}}")
        SLUG=$(echo "{{target}}" | tr '[:upper:] ' '[:lower:]-')

        # -b boots the device and blocks until ready. Booting by hand then
        # opening Simulator.app races: an already-running app can shut this
        # device back down, and xcodebuild then finds no matching destination.
        xcrun simctl bootstatus "$DEVICE" -b
        open -a Simulator

        xcrun simctl ui "$DEVICE" appearance "{{appearance}}"

        # Apple's marketing clock, full bars, no carrier text. Dropped on
        # reboot, so reapplied every run.
        xcrun simctl status_bar "$DEVICE" override \
            --time "9:41" \
            --batteryState charged --batteryLevel 100 \
            --cellularMode active --cellularBars 4 \
            --wifiMode active --wifiBars 3
        ;;
    esac

    flutter run -d "$DEVICE" --dart-define=DEMO_MODE=true --pid-file "$PIDFILE" < /dev/null &
    FLUTTER=$!
    trap 'kill "$FLUTTER" 2>/dev/null || true; rm -f "$PIDFILE"' EXIT

    # Resolved on the first shot: the desktop window doesn't exist until the
    # app has started.
    WINDOW_ID=""
    resolve() {
      [ "$SLUG" = macos ] || return 0
      [ -z "$WINDOW_ID" ] || return 0
      WINDOW_ID=$(swift scripts/window_id.swift Routine)
    }

    # Both tools narrate to stderr on success, so output is held back and
    # replayed only if the capture failed.
    shoot() {
      local err
      if [ "$SLUG" = macos ]; then
        err=$(screencapture -o -l"$WINDOW_ID" "$1" 2>&1) || { echo "$err" >&2; return 1; }
      elif [ "$SLUG" = linux ]; then
        echo "no Linux capture here - screencapture is macOS only" >&2
        return 1
      else
        err=$(xcrun simctl io "$DEVICE" screenshot "$1" 2>&1) || { echo "$err" >&2; return 1; }
      fi
    }

    signal() {
      [ -s "$PIDFILE" ] || { echo "not ready yet" >&2; return 1; }
      kill "-$1" "$(cat "$PIDFILE")"
    }

    echo
    echo "s save a shot into {{dir}}/   r hot reload   R hot restart   q quit"
    echo

    n=0
    while IFS= read -rsn1 key; do
      case "$key" in
        s)
          # Skip names already on disk so a later session doesn't overwrite an
          # earlier set.
          n=$((n + 1))
          while [ -e "{{dir}}/$SLUG-$(printf '%02d' $n).png" ]; do n=$((n + 1)); done
          OUT="{{dir}}/$SLUG-$(printf '%02d' $n).png"

          # A failed capture leaves an empty file behind, and shouldn't take
          # the session down with it.
          if resolve && shoot "$OUT"; then
            echo "saved $OUT"
          else
            rm -f "$OUT"
            echo "capture failed - is the app up yet?" >&2
          fi
          ;;
        r) signal USR1 || true ;;
        R) signal USR2 || true ;;
        q) exit 0 ;;
      esac
    done
