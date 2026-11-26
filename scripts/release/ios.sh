#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

BUILD_NUMBER_PINNED="${BUILD_NUMBER:-}"

resolve_version
cd "$REPO_ROOT"
TMP="${RUNNER_TEMP:-$(mktemp -d)}"

need_for_publish APP_STORE_CONNECT_API_KEY_KEY_ID APP_STORE_CONNECT_API_KEY_ISSUER_ID
if have CI; then need_for_publish IOS_CERT_P12_B64 IOS_CERT_PASSWORD; fi

if have APP_STORE_CONNECT_API_KEY_KEY_ID; then
  need APP_STORE_CONNECT_API_KEY_ISSUER_ID
  load_app_store_connect_key
fi

if ! have BUILD_NUMBER_PINNED && have APP_STORE_CONNECT_API_KEY_KEY_ID; then
  log "Asking App Store Connect for the next build number"
  (cd ios && BUILD_NUMBER_OUT="$TMP/build_number" bundle exec fastlane next_build_number)
  BUILD_NUMBER="$(cat "$TMP/build_number")"
  export BUILD_NUMBER
  log "Releasing $VERSION_NAME (build $BUILD_NUMBER)"
fi

log "Building Flutter artifacts"
flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER"

if ! have APP_STORE_CONNECT_API_KEY_KEY_ID; then
  warn "Built the app but skipped archive and upload. To publish, set:"
  printf '      %s\n' \
    "APP_STORE_CONNECT_API_KEY_KEY_ID" \
    "APP_STORE_CONNECT_API_KEY_ISSUER_ID" \
    "APP_STORE_CONNECT_API_KEY_KEY_FILEPATH   path to the .p8 (or APP_STORE_CONNECT_API_KEY_KEY with its contents)" \
    "IOS_CERT_P12_B64                         CI only; locally your login keychain is used" \
    "IOS_CERT_PASSWORD                        CI only" >&2
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
