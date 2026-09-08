#!/bin/bash
set -e

APP_NAME="native_messaging_host"
OUTPUT_DIR="../assets/extension"
OUTPUT_NAME="native_linux"

if ! command -v dart &> /dev/null; then
    echo "Error: dart is not installed"
    echo "Please install dart first (it ships with the Flutter SDK)"
    exit 1
fi

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
