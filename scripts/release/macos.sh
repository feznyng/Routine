#!/usr/bin/env bash
# Build, sign, package and notarize the macOS app into dist/.
#
# Degrades gracefully: with no certificate it still produces an unsigned DMG, so
# you can iterate on packaging locally without credentials. With a certificate in
# your login keychain, set MACOS_SIGNING_IDENTITY only — the p12 import is for CI.
#
#   VERSION_NAME BUILD_NUMBER           required
#   MACOS_SIGNING_IDENTITY              e.g. "Developer ID Application: … (TEAMID)"
#   MACOS_CERT_P12_B64 MACOS_CERT_PASSWORD   CI only; imports to a temp keychain
#   ASC_KEY_ID ASC_ISSUER_ID                 enables notarization, with the
#   ASC_PRIVATE_KEY or ASC_PRIVATE_KEY_PATH  .p8 as contents or as a path
#
#   VERSION_NAME=1.2.3 BUILD_NUMBER=42 ./scripts/release/macos.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
resolve_version
cd "$REPO_ROOT"

TMP="${RUNNER_TEMP:-$(mktemp -d)}"

# The certificate must be in the keychain BEFORE the build: `just build macos`
# builds the native messaging host first, and browser/build_native_macos.sh signs
# it with its own entitlements (app-sandbox=false). Without an identity that
# script falls back to an ad-hoc signature, which is fine locally but not for
# anything you ship — hence importing here, ahead of the build.
if have MACOS_CERT_P12_B64; then
  need MACOS_CERT_PASSWORD
  log "Importing certificate into a temporary keychain"
  KEYCHAIN="$TMP/build.keychain"
  security create-keychain -p actions "$KEYCHAIN"
  security set-keychain-settings -lut 21600 "$KEYCHAIN"
  security unlock-keychain -p actions "$KEYCHAIN"
  base64 -d <<< "$MACOS_CERT_P12_B64" > "$TMP/cert.p12"
  security import "$TMP/cert.p12" -k "$KEYCHAIN" -P "$MACOS_CERT_PASSWORD" \
    -T /usr/bin/codesign -T /usr/bin/security
  security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k actions "$KEYCHAIN"
  # shellcheck disable=SC2046
  security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')
fi

# `just build macos` = build-nmh macos + flutter build macos --release.
# Going straight to `flutter build` would produce an app with no native messaging
# host — the Xcode copy phase only warns, so the build stays green and browser
# blocking is silently dead in the shipped artifact.
log "Building (with native messaging host)"
just build macos --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER"

APP="$(ls -d build/macos/Build/Products/Release/*.app | head -1)"
[[ -d "$APP" ]] || die "no .app produced"

if have MACOS_SIGNING_IDENTITY; then
  log "Signing (hardened runtime, inner bundles first)"
  # --deep is deprecated by Apple and mis-signs Flutter's Frameworks directory.
  while IFS= read -r -d '' f; do
    codesign --force --timestamp --options runtime \
      --sign "$MACOS_SIGNING_IDENTITY" "$f"
  done < <(find "$APP/Contents/Frameworks" -maxdepth 1 \
             \( -name '*.framework' -o -name '*.dylib' \) -print0 2>/dev/null)

  codesign --force --timestamp --options runtime \
    --entitlements macos/Runner/Release.entitlements \
    --sign "$MACOS_SIGNING_IDENTITY" "$APP"
  codesign --verify --strict --verbose=2 "$APP"
else
  warn "No MACOS_SIGNING_IDENTITY — unsigned build, Gatekeeper will block it."
fi

log "Building DMG"
DMG="dist/Routine.dmg"
rm -rf dist/stage "$DMG"; mkdir -p dist/stage
cp -R "$APP" dist/stage/
ln -s /Applications dist/stage/Applications
hdiutil create -volname "Routine" -srcfolder dist/stage -ov -format UDZO "$DMG"
rm -rf dist/stage

if have MACOS_SIGNING_IDENTITY && have ASC_KEY_ID; then
  need ASC_ISSUER_ID
  load_asc_key
  log "Signing and notarizing DMG (this waits on Apple)"
  codesign --force --timestamp --sign "$MACOS_SIGNING_IDENTITY" "$DMG"
  xcrun notarytool submit "$DMG" --wait \
    --key "$ASC_KEY_FILE" --key-id "$ASC_KEY_ID" --issuer "$ASC_ISSUER_ID"
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
else
  warn "Skipping notarization — DMG will trip Gatekeeper."
fi

log "$DMG"
