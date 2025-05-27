#!/bin/bash

# Exit on error
set -e

# Script to build and sign the browser extension using web-ext

# Check if web-ext is installed
if ! command -v web-ext &> /dev/null; then
    echo "Error: web-ext is not installed. Please install it using 'npm install -g web-ext'"
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

# Create build directories
mkdir -p "$BUILD_DIR"/firefox
mkdir -p "$BUILD_DIR"/chrome

# Build Firefox version
echo "Building Firefox version..."
cp -r "$EXT_DIR/icons" "$EXT_DIR/blocked.html" "$EXT_DIR/background.js" "$BUILD_DIR"/firefox/
cp "$EXT_DIR/manifest.json" "$BUILD_DIR"/firefox/manifest.json

# Build Chrome version
echo "Building Chrome version..."
cp -r "$EXT_DIR/icons" "$EXT_DIR/blocked.html" "$EXT_DIR/background.js" "$BUILD_DIR"/chrome/
cp "$EXT_DIR/manifest.json" "$BUILD_DIR"/chrome/

# Create zip files
cd "$BUILD_DIR"
zip -r firefox.zip firefox/*
zip -r chrome.zip chrome/*
cd - > /dev/null

# Sign Firefox extension if credentials are available
if [ -n "$AMO_JWT_ISSUER" ] && [ -n "$AMO_JWT_SECRET" ]; then
    echo "Signing Firefox extension..."
    web-ext sign \
        --source-dir="$BUILD_DIR/firefox" \
        --artifacts-dir="$BUILD_DIR" \
        --api-key="$AMO_JWT_ISSUER" \
        --api-secret="$AMO_JWT_SECRET" \
        --channel unlisted
    
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
