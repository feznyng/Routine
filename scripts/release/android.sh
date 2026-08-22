#!/usr/bin/env bash
# Build the release AAB and APK into dist/.
#
# With ANDROID_KEYSTORE_B64 set, writes android/key.properties and signs with the
# upload key. Without it, Gradle falls back to debug signing and the output is
# NOT distributable — the script says so loudly.
#
#   VERSION_NAME BUILD_NUMBER            required
#   ANDROID_KEYSTORE_B64                 base64 of upload-keystore.jks
#   ANDROID_STORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD
#
#   VERSION_NAME=1.2.3 BUILD_NUMBER=42 ./scripts/release/android.sh
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
cp build/app/outputs/bundle/release/app-release.aab "dist/routine-$VERSION_NAME.aab"
cp build/app/outputs/flutter-apk/app-release.apk    "dist/routine-$VERSION_NAME.apk"

if have ANDROID_KEYSTORE_B64 && command -v apksigner >/dev/null; then
  log "Verifying APK signature"
  apksigner verify --print-certs "dist/routine-$VERSION_NAME.apk" | head -4
fi

log "dist/routine-$VERSION_NAME.{aab,apk}"
