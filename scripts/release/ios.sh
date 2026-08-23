#!/usr/bin/env bash
# Build, sign and upload the iOS app to TestFlight.
#
# Degrades gracefully like the other platform scripts: with no App Store Connect
# key it still runs the Flutter build so you can check the app compiles, then
# stops before archiving and says so. Nothing is uploaded without credentials.
#
# Unlike macOS there is no native messaging host and no dist/ artifact — the
# deliverable is a build on App Store Connect, not a file on disk. That is why
# this goes through fastlane rather than `just build ios`.
#
#   VERSION_NAME                           defaults to the tag, else pubspec
#   BUILD_NUMBER                           defaults to whatever TestFlight has
#                                          not used yet; set it to pin one
#   ASC_KEY_ID ASC_ISSUER_ID               enables archive + upload, with the
#   ASC_PRIVATE_KEY or ASC_PRIVATE_KEY_PATH   .p8 as contents or as a path
#   IOS_CERT_P12_B64 IOS_CERT_PASSWORD     Apple Distribution cert; CI only, the
#                                          login keychain is used without them
#
#   VERSION_NAME=1.2.3 ./scripts/release/ios.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Whether the caller pinned a build number, captured before resolve_version
# fills one in from pubspec. An explicit value always wins over App Store
# Connect below — that is how CI stays deterministic and how you force a
# specific number by hand.
BUILD_NUMBER_PINNED="${BUILD_NUMBER:-}"

resolve_version
cd "$REPO_ROOT"
TMP="${RUNNER_TEMP:-$(mktemp -d)}"

# The Fastfile reads Apple's own variable names; the rest of scripts/release/
# and the workflow use the shorter ASC_* spelling (macos.sh notarization takes
# the same three). Map them here so there is one spelling to remember. This
# happens before the build because the build number can come from App Store
# Connect, and that query needs the key.
if have ASC_KEY_ID; then
  need ASC_ISSUER_ID
  load_asc_key
  export APP_STORE_CONNECT_API_KEY_KEY_ID="$ASC_KEY_ID"
  export APP_STORE_CONNECT_API_KEY_ISSUER_ID="$ASC_ISSUER_ID"
  export APP_STORE_CONNECT_API_KEY_KEY="$ASC_PRIVATE_KEY"
fi

# Build numbers must be unique per version string, and pubspec's +N goes stale
# the moment you ship — it knows nothing about what TestFlight has already
# accepted. Ask Apple instead of trusting local state. The lane writes to a file
# rather than stdout: fastlane's output is too chatty to parse.
if ! have BUILD_NUMBER_PINNED && have ASC_KEY_ID; then
  log "Asking App Store Connect for the next build number"
  (cd ios && BUILD_NUMBER_OUT="$TMP/build_number" bundle exec fastlane next_build_number)
  BUILD_NUMBER="$(cat "$TMP/build_number")"
  export BUILD_NUMBER
  log "Releasing $VERSION_NAME (build $BUILD_NUMBER)"
fi

# fastlane's build_app only archives what Xcode can see; the Dart AOT snapshot
# and Generated.xcconfig come from here. Skipping this archives a stale build
# number, because Runner/Info.plist reads CFBundleVersion from
# $(FLUTTER_BUILD_NUMBER), which this step writes.
log "Building Flutter artifacts"
flutter build ios --release --no-codesign \
  --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER"

if ! have ASC_KEY_ID; then
  warn "No ASC_KEY_ID — built the app but skipped archive and upload."
  warn "Set ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY and the IOS_CERT_* vars to publish."
  exit 0
fi

# Same shape as macos.sh: the p12 lives in a secret and is decoded to a file for
# the duration of the job. The Fastfile imports it into the keychain setup_ci
# makes; without it fastlane falls back to whatever is in your login keychain,
# which is what you want when running this by hand.
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

log "Uploaded $VERSION_NAME ($BUILD_NUMBER) — Apple processes it before it appears"
