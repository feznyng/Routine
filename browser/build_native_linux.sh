#!/bin/bash
set -e

# Builds the native messaging host for Linux and places it where the desktop
# bundle's install() step (linux/CMakeLists.txt) picks it up. Unlike macOS there
# is no codesigning/notarization step on Linux.

APP_NAME="native_messaging_host"
OUTPUT_DIR="../assets/extension"
OUTPUT_NAME="native_linux"

# Check if dart is installed
if ! command -v dart &> /dev/null; then
    echo "Error: dart is not installed"
    echo "Please install dart first (it ships with the Flutter SDK)"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Building native messaging host for Linux..."
cd native
dart pub get
dart compile exe src/main.dart --target-os linux --output "../$OUTPUT_DIR/$OUTPUT_NAME"
cd ..

chmod +x "$OUTPUT_DIR/$OUTPUT_NAME"

echo "Build completed successfully!"
echo "Binary is available at:"
ls -la "$OUTPUT_DIR/$OUTPUT_NAME"
