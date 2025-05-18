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

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Sign the extension
echo "Signing extension..."
web-ext sign \
    --source-dir="$EXT_DIR" \
    --artifacts-dir="$BUILD_DIR" \
    --api-key="$AMO_JWT_ISSUER" \
    --api-secret="$AMO_JWT_SECRET" \
    --channel unlisted

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -f "$EXT_DIR/.amo-upload-uuid"
rm -f "$BUILD_DIR"/*.zip

echo "Build and signing complete! Signed extension can be found in $BUILD_DIR"
