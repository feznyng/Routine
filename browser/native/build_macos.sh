#!/bin/bash
set -e

# Configuration
APP_NAME="native"
DEVELOPER_ID="$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | awk -F '"' '{print $2}')"
TEAM_ID="$APPLE_TEAM_ID"
NOTARIZATION_APPLE_ID="$APPLE_ID" # Set this via environment variable
NOTARIZATION_PASSWORD="$APPLE_APP_PASSWORD" # Set this via environment variable or keychain
OUTPUT_DIR="../../assets/extension"
ENTITLEMENTS_FILE="$(pwd)/native.entitlements"

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

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Build function
build_and_process() {
    local arch=$1
    local target=$2
    local output_name=$3
    local temp_dir=$(mktemp -d)
    local binary_path="$temp_dir/$APP_NAME"
    
    echo "Building for $arch..."
    RUSTFLAGS="-C link-arg=-s" cargo build --release --target "$target"
    
    # Copy binary to temp directory
    cp "../../target/$target/release/$APP_NAME" "$binary_path"
    
    echo "Signing binary for $arch with entitlements..."
    codesign --force --options runtime --entitlements "$ENTITLEMENTS_FILE" --sign "$DEVELOPER_ID" "$binary_path"
    
    echo "Verifying signature..."
    codesign --verify --verbose "$binary_path"
    
    echo "Copying final binary to assets directory..."
    cp "$binary_path" "$OUTPUT_DIR/$output_name"
    
    echo "Cleaning up temporary files..."
    rm -rf "$temp_dir"
    
    echo "Build for $arch completed successfully!"
}

# Build for arm64
build_and_process "arm64" "aarch64-apple-darwin" "native_macos_arm64"

# Build for x86_64
build_and_process "x86_64" "x86_64-apple-darwin" "native_macos_x86_64"

echo "All builds completed successfully!"
echo "Binaries are available in $OUTPUT_DIR:"
ls -la "$OUTPUT_DIR/native_macos_"*
