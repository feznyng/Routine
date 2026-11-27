#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
resolve_version
cd "$REPO_ROOT"

TMP="${RUNNER_TEMP:-$(mktemp -d)}"

need_for_publish MACOS_SIGNING_IDENTITY \
  APP_STORE_CONNECT_API_KEY_KEY_ID APP_STORE_CONNECT_API_KEY_ISSUER_ID
if have CI; then need_for_publish MACOS_CERT_P12_B64 MACOS_CERT_PASSWORD; fi

if have MACOS_SIGNING_IDENTITY; then
  have APP_STORE_CONNECT_API_KEY_KEY_ID \
    || die "Signing needs the App Store Connect key too, to fetch the Developer ID provisioning profile. Set APP_STORE_CONNECT_API_KEY_KEY_ID, _ISSUER_ID and _KEY_FILEPATH."
  need APP_STORE_CONNECT_API_KEY_ISSUER_ID
  load_app_store_connect_key
  TEAM_ID="$(sed -nE 's/.*\(([A-Z0-9]{10})\)$/\1/p' <<< "$MACOS_SIGNING_IDENTITY")"
  [[ -n "$TEAM_ID" ]] || die "\$MACOS_SIGNING_IDENTITY should end with the team ID in brackets, like \"Developer ID Application: SolidSoft LLC (5P7GGUGK9M)\""
fi

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
  security list-keychains -d user -s "$KEYCHAIN" $(security list-keychains -d user | tr -d '"')
fi

SIGNING_XCCONFIG="macos/Runner/Configs/Signing.xcconfig"
if have MACOS_SIGNING_IDENTITY; then
  printf 'CODE_SIGNING_ALLOWED = NO\nCODE_SIGNING_REQUIRED = NO\n' > "$SIGNING_XCCONFIG"
  trap 'rm -f "$REPO_ROOT/$SIGNING_XCCONFIG"' EXIT
fi

log "Building (with native messaging host)"
just build macos --build-name="$VERSION_NAME" --build-number="$BUILD_NUMBER"

APP="$(ls -d build/macos/Build/Products/Release/*.app | head -1)"
[[ -d "$APP" ]] || die "no .app produced"
NMH="$APP/Contents/Resources/extension/native_macos"
[[ -x "$NMH" ]] || die "The native messaging host is missing from the bundle ($NMH). Browser blocking would not work; check the build-nmh output above."

if have MACOS_SIGNING_IDENTITY; then
  BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")"

  log "Fetching the Developer ID provisioning profile for $BUNDLE_ID"
  PROFILE="$TMP/developer_id.mobileprovision"
  (cd ios && PROFILE_OUT="$PROFILE" bundle exec fastlane mac developer_id_profile)
  security cms -D -i "$PROFILE" > "$TMP/profile.plist"
  profile_certs=""
  for ((i = 0; ; i++)); do
    der="$(plutil -extract "DeveloperCertificates.$i" raw "$TMP/profile.plist" 2>/dev/null)" || break
    profile_certs+="$(base64 -d <<< "$der" | openssl x509 -inform der -noout -subject)"$'\n'
  done
  grep -qF "CN=$MACOS_SIGNING_IDENTITY" <<< "$profile_certs" \
    || die "The Developer ID profile doesn't include \"$MACOS_SIGNING_IDENTITY\". It lists: ${profile_certs:-nothing}. Delete the \"$BUNDLE_ID Direct\" profile in the developer portal and rerun."
  cp "$PROFILE" "$APP/Contents/embedded.provisionprofile"

  ENTITLEMENTS="$TMP/Release.entitlements"
  sed "s/\$(AppIdentifierPrefix)/$TEAM_ID./g" macos/Runner/Release.entitlements > "$ENTITLEMENTS"
  /usr/libexec/PlistBuddy \
    -c "Add :com.apple.application-identifier string $TEAM_ID.$BUNDLE_ID" \
    -c "Add :com.apple.developer.team-identifier string $TEAM_ID" \
    "$ENTITLEMENTS"

  log "Signing (hardened runtime, inner bundles first)"
  while IFS= read -r -d '' f; do
    codesign --force --timestamp --options runtime \
      --sign "$MACOS_SIGNING_IDENTITY" "$f"
  done < <(find "$APP/Contents/Frameworks" -maxdepth 1 \
             \( -name '*.framework' -o -name '*.dylib' \) -print0 2>/dev/null)

  codesign --force --timestamp --options runtime \
    --entitlements "$ENTITLEMENTS" \
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

if have MACOS_SIGNING_IDENTITY; then
  log "Signing and notarizing DMG (this waits on Apple)"
  codesign --force --timestamp --sign "$MACOS_SIGNING_IDENTITY" "$DMG"
  xcrun notarytool submit "$DMG" --wait \
    --key "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH" \
    --key-id "$APP_STORE_CONNECT_API_KEY_KEY_ID" \
    --issuer "$APP_STORE_CONNECT_API_KEY_ISSUER_ID"
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
else
  warn "Skipping notarization — DMG will trip Gatekeeper."
fi

log "$DMG"
