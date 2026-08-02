#!/bin/bash

# Exit on error
set -e

# Script to build and sign the browser extension using web-ext

# Check if web-ext is installed
if ! command -v web-ext &> /dev/null; then
    echo "Error: web-ext is not installed. Please install it using 'npm install -g web-ext'"
    exit 1
fi

# Check if jq is installed (used to derive per-browser manifests)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it using 'brew install jq'"
    exit 1
fi

# Default values
EXT_DIR="$(dirname "$0")/extension"
BUILD_DIR="$(dirname "$0")/web-ext-artifacts"

# Check if API credentials are set
if [ -z "$AMO_JWT_ISSUER" ] || [ -z "$AMO_JWT_SECRET" ]; then
    echo "Error: AMO_JWT_ISSUER and AMO_JWT_SECRET environment variables must be set"
    echo "Please set them with:"
    echo "export AMO_JWT_ISSUER=your-jwt-issuer"
    echo "export AMO_JWT_SECRET=your-jwt-secret"
    exit 1
fi

# AMO rejects a version number that has already been signed, so catch it here
# rather than after a full build. Only sees versions still present locally -
# old builds get pruned below, so AMO remains the source of truth.
VERSION=$(jq -r .version "$EXT_DIR/manifest.json")
if [ -n "$(find "$BUILD_DIR" -maxdepth 1 -name "*-$VERSION.xpi" -print -quit)" ]; then
    echo "Error: version $VERSION has already been signed (found *-$VERSION.xpi)"
    echo "Bump \"version\" in $EXT_DIR/manifest.json before signing again."
    exit 1
fi

# Create build directories
mkdir -p "$BUILD_DIR"/firefox
mkdir -p "$BUILD_DIR"/chrome

# Build Firefox version
# Firefox uses background.scripts (service_worker is unsupported) and ignores Chrome's "key"
echo "Building Firefox version..."
cp -r "$EXT_DIR/icons" "$EXT_DIR/background.js" "$BUILD_DIR"/firefox/
jq 'del(.background.service_worker) | del(.key)' \
    "$EXT_DIR/manifest.json" > "$BUILD_DIR"/firefox/manifest.json

# Build Chrome version
# Chrome uses background.service_worker and warns on Firefox-only keys
echo "Building Chrome version..."
cp -r "$EXT_DIR/icons" "$EXT_DIR/background.js" "$BUILD_DIR"/chrome/
jq 'del(.background.scripts) | del(.browser_specific_settings)' \
    "$EXT_DIR/manifest.json" > "$BUILD_DIR"/chrome/manifest.json

# Create zip files
# Zip from inside each directory so manifest.json sits at the archive root -
# stores require it there, and a nested folder is rejected on upload.
rm -f "$BUILD_DIR/firefox.zip" "$BUILD_DIR/chrome.zip"
(cd "$BUILD_DIR/firefox" && zip -qr ../firefox.zip . -x '*.DS_Store')
(cd "$BUILD_DIR/chrome" && zip -qr ../chrome.zip . -x '*.DS_Store')

# Submit Firefox extension to AMO if credentials are available.
# Listed channel: AMO hosts the add-on and handles auto-updates, matching how
# the Chrome Web Store distributes the Chrome build.
if [ -n "$AMO_JWT_ISSUER" ] && [ -n "$AMO_JWT_SECRET" ]; then
    echo "Signing Firefox extension..."
    web-ext sign \
        --source-dir="$BUILD_DIR/firefox" \
        --artifacts-dir="$BUILD_DIR" \
        --api-key="$AMO_JWT_ISSUER" \
        --api-secret="$AMO_JWT_SECRET" \
        --amo-metadata="$(dirname "$0")/amo-metadata.json" \
        --channel listed

    # Clean up temporary files
    echo "Cleaning up temporary files..."
    rm -f "$BUILD_DIR/firefox/.amo-upload-uuid"
else
    echo "Skipping Firefox signing - no API credentials provided"
fi

# Clean up build directories
echo "Cleaning up build directories..."
rm -rf "$BUILD_DIR/firefox" "$BUILD_DIR/chrome"

echo "Build complete!"
echo "Firefox extension: $BUILD_DIR/firefox.zip"
echo "Chrome extension: $BUILD_DIR/chrome.zip"
if [ -n "$AMO_JWT_ISSUER" ] && [ -n "$AMO_JWT_SECRET" ]; then
    echo "Signed Firefox extension can be found in $BUILD_DIR"
fi

# Clean up old builds
find "$BUILD_DIR" -name "*.xpi" -mtime +30 -delete
