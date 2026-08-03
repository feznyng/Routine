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

    # Chrome publishing is optional: without these the recipe still writes
    # chrome.zip for a manual upload to the Developer Dashboard.
    CWS_PUBLISH=1
    for var in CWS_CLIENT_ID CWS_CLIENT_SECRET CWS_REFRESH_TOKEN CWS_EXTENSION_ID; do
        if [ -z "${!var:-}" ]; then CWS_PUBLISH=0; fi
    done

    # AMO rejects a version number that has already been signed, so catch it here
    # rather than after a full build. Only sees versions still present locally -
    # old builds get pruned below, so AMO remains the source of truth.
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

    # Zip from inside each directory so manifest.json sits at the archive root -
    # stores require it there, and a nested folder is rejected on upload.
    rm -f "$BUILD_DIR/firefox.zip" "$BUILD_DIR/chrome.zip"
    (cd "$BUILD_DIR/firefox" && zip -qr ../firefox.zip . -x '*.DS_Store')
    (cd "$BUILD_DIR/chrome" && zip -qr ../chrome.zip . -x '*.DS_Store')

    # Chrome first: an upload failure here (bad credentials, wrong item id,
    # duplicate version) leaves AMO untouched, so a retry after the fix does not
    # burn a version number on the Firefox side.
    if [ "$CWS_PUBLISH" = 1 ]; then
        echo "Publishing Chrome extension..."

        # Access tokens last an hour; the refresh token is the long-lived secret.
        CWS_TOKEN=$(curl -sf -X POST https://oauth2.googleapis.com/token \
            -d "client_id=$CWS_CLIENT_ID" \
            -d "client_secret=$CWS_CLIENT_SECRET" \
            -d "refresh_token=$CWS_REFRESH_TOKEN" \
            -d "grant_type=refresh_token" | jq -er .access_token)

        # The API reports upload failures in the body with HTTP 200, so check
        # uploadState rather than relying on curl's exit status.
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

        # Publishing only submits for review; the version goes live once Google
        # approves it, which is typically slower than AMO.
        PUBLISH=$(curl -sf -X POST \
            -H "Authorization: Bearer $CWS_TOKEN" \
            -H "x-goog-api-version: 2" \
            -H "Content-Length: 0" \
            "https://www.googleapis.com/chromewebstore/v1.1/items/$CWS_EXTENSION_ID/publish")
        echo "Chrome Web Store status: $(jq -r '.status | join(", ")' <<< "$PUBLISH")"
    else
        echo "Skipping Chrome publish - set CWS_CLIENT_ID, CWS_CLIENT_SECRET, CWS_REFRESH_TOKEN and CWS_EXTENSION_ID to enable"
    fi

    # Listed channel: AMO hosts the add-on and handles auto-updates, matching how
    # the Chrome Web Store distributes the Chrome build.
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
