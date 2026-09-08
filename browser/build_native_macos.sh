#!/bin/bash
set -e

APP_NAME="native_messaging_host"
if [ -n "$MACOS_SIGNING_IDENTITY" ]; then
    DEVELOPER_ID="$MACOS_SIGNING_IDENTITY"
else
    _CERTS="$(security find-identity -v -p codesigning | grep "Developer ID Application" || true)"
    if [ "$(printf '%s' "$_CERTS" | grep -c .)" -gt 1 ]; then
        echo "Error: multiple Developer ID Application certificates found."
        echo "Set MACOS_SIGNING_IDENTITY to choose one:"
        printf '%s\n' "$_CERTS"
        exit 1
    fi
    DEVELOPER_ID="$(printf '%s' "$_CERTS" | awk -F '"' '{print $2}')"
fi
TEAM_ID="$APPLE_TEAM_ID"
NOTARIZATION_APPLE_ID="$APPLE_ID"
NOTARIZATION_PASSWORD="$APPLE_APP_PASSWORD"
OUTPUT_DIR="../assets/extension"
ENTITLEMENTS_FILE="$(pwd)/native/entitlements.plist"

if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
    echo "Warning: APPLE_ID / APPLE_APP_PASSWORD not set (only needed for notarization)."
fi

if [ -z "$DEVELOPER_ID" ]; then
    echo "Note: no Developer ID Application certificate found — signing ad-hoc."
    echo "      Fine for local builds; a distributable build needs a real identity."
    DEVELOPER_ID="-"
fi

if ! command -v dart &> /dev/null; then
    echo "Error: dart is not installed"
    echo "Please install dart first using: brew install dart"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

build_and_process() {
    local arch=$1
    local output_name=$2
    local temp_dir=$(mktemp -d)
    local binary_path="$temp_dir/$APP_NAME"
    
    echo "Building for $arch..."
    cd native
    dart pub get
    
    dart compile exe src/main.dart --target-os macos --output "$binary_path"
    cd ..
    
    echo "Signing binary with entitlements..."
    codesign --force --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$DEVELOPER_ID" "$binary_path"
    
    echo "Verifying signature..."
    codesign --verify --verbose "$binary_path"
    
    echo "Copying final binary to assets directory..."
    cp "$binary_path" "$OUTPUT_DIR/$output_name"
    
    echo "Cleaning up temporary files..."
    rm -rf "$temp_dir"
    
    echo "Build completed successfully!"
}

build_and_process "universal" "native_macos"

echo "All builds completed successfully!"
echo "Binary is available in $OUTPUT_DIR:"
ls -la "$OUTPUT_DIR/native_macos"
