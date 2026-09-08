#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BUILD_NUMBER_PINNED="${BUILD_NUMBER:-}"

resolve_version
cd "$REPO_ROOT"
TMP="${RUNNER_TEMP:-$(mktemp -d)}"

if have ASC_KEY_ID; then
  need ASC_ISSUER_ID
  load_asc_key
  export APP_STORE_CONNECT_API_KEY_KEY_ID="$ASC_KEY_ID"
  export APP_STORE_CONNECT_API_KEY_ISSUER_ID="$ASC_ISSUER_ID"
  export APP_STORE_CONNECT_API_KEY_KEY="$ASC_PRIVATE_KEY"
fi

if ! have BUILD_NUMBER_PINNED && have ASC_KEY_ID; then
  log "Asking App Store Connect for the next build number"
  (cd ios && BUILD_NUMBER_OUT="$TMP/build_number" bundle exec fastlane next_build_number)
  BUILD_NUMBER="$(cat "$TMP/build_number")"
  export BUILD_NUMBER
  log "Releasing $VERSION_NAME (build $BUILD_NUMBER)"
fi

log "Building Flutter artifacts"
flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER"

if ! have ASC_KEY_ID; then
  warn "No ASC_KEY_ID — built the app but skipped archive and upload."
  warn "Set ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY and the IOS_CERT_* vars to publish."
  exit 0
fi

if have IOS_CERT_P12_B64; then
  need IOS_CERT_PASSWORD
  base64 -d <<< "$IOS_CERT_P12_B64" > "$TMP/ios_cert.p12"
  export IOS_CERT_P12_PATH="$TMP/ios_cert.p12"
else
  warn "No IOS_CERT_P12_B64 — signing with the login keychain."
fi

log "Archiving and uploading to TestFlight"
cd ios
bundle exec fastlane ci_beta

log "Uploaded $VERSION_NAME ($BUILD_NUMBER)"
