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

# Check if required environment variables are set
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
    echo "Error: APPLE_ID and APPLE_APP_PASSWORD environment variables must be set"
    echo "Example usage: APPLE_ID=your.email@example.com APPLE_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx ./build_macos.sh"
    exit 1
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
