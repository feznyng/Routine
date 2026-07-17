#!/bin/bash
set -e

# Configuration
APP_NAME="native_messaging_host"
DEVELOPER_ID="$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F '"' '{print $2}')"
TEAM_ID="$APPLE_TEAM_ID"
NOTARIZATION_APPLE_ID="$APPLE_ID" # Set this via environment variable
NOTARIZATION_PASSWORD="$APPLE_APP_PASSWORD" # Set this via environment variable or keychain
OUTPUT_DIR="../assets/extension"
ENTITLEMENTS_FILE="$(pwd)/native/entitlements.plist"

# APPLE_ID / APPLE_APP_PASSWORD are only needed if a notarization step is added
# later; the codesigning below does not use them. Warn but don't fail, so this
# script can run unattended from the Xcode "Copy Native Messaging Host" phase.
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
    echo "Warning: APPLE_ID / APPLE_APP_PASSWORD not set (only needed for notarization)."
fi

# Check if developer identity is available
if [ -z "$DEVELOPER_ID" ]; then
    echo "Error: No Developer ID Application certificate found in keychain"
    echo "Please ensure you have a valid Developer ID Application certificate installed"
    exit 1
fi

# Check if dart is installed
if ! command -v dart &> /dev/null; then
    echo "Error: dart is not installed"
    echo "Please install dart first using: brew install dart"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build function
build_and_process() {
    local arch=$1
    local output_name=$2
    local temp_dir=$(mktemp -d)
    local binary_path="$temp_dir/$APP_NAME"
    
    echo "Building for $arch..."
    cd native
    dart pub get
    
    # Compile native executable
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

# Build for both architectures (Dart produces a universal binary)
build_and_process "universal" "native_macos"

echo "All builds completed successfully!"
echo "Binary is available in $OUTPUT_DIR:"
ls -la "$OUTPUT_DIR/native_macos"
