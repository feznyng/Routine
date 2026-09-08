#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
resolve_version
cd "$REPO_ROOT"

if have ANDROID_KEYSTORE_B64; then
  need ANDROID_STORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD
  log "Restoring upload keystore"
  base64 -d <<< "$ANDROID_KEYSTORE_B64" > android/app/upload-keystore.jks
  cat > android/key.properties <<EOF
storeFile=upload-keystore.jks
storePassword=$ANDROID_STORE_PASSWORD
keyAlias=$ANDROID_KEY_ALIAS
keyPassword=$ANDROID_KEY_PASSWORD
EOF
else
  warn "No ANDROID_KEYSTORE_B64 — building debug-signed. Not distributable."
  rm -f android/key.properties
fi

args=(--release --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER")

log "Building app bundle"
flutter build appbundle "${args[@]}"
log "Building APK"
flutter build apk "${args[@]}"

mkdir -p dist
cp build/app/outputs/bundle/release/app-release.aab "dist/Routine.aab"
cp build/app/outputs/flutter-apk/app-release.apk    "dist/Routine.apk"

if have ANDROID_KEYSTORE_B64 && command -v apksigner >/dev/null; then
  log "Verifying APK signature"
  apksigner verify --print-certs "dist/Routine.apk" | head -4
fi

log "dist/Routine.{aab,apk}"
