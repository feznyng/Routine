#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

EXT_DIR="browser/extension"
BUILD_DIR="browser/web-ext-artifacts"

need_for_publish AMO_JWT_ISSUER AMO_JWT_SECRET \
  CWS_CLIENT_ID CWS_CLIENT_SECRET CWS_REFRESH_TOKEN CWS_EXTENSION_ID

command -v jq >/dev/null || die "jq is not installed - 'brew install jq'"

AMO_SIGN=1
for v in AMO_JWT_ISSUER AMO_JWT_SECRET; do
  have "$v" || AMO_SIGN=0
done
[[ "$AMO_SIGN" == 0 ]] || command -v web-ext >/dev/null \
  || die "web-ext is not installed - 'npm install -g web-ext'"

CWS_PUBLISH=1
for v in CWS_CLIENT_ID CWS_CLIENT_SECRET CWS_REFRESH_TOKEN CWS_EXTENSION_ID; do
  have "$v" || CWS_PUBLISH=0
done

mkdir -p "$BUILD_DIR"

VERSION="$(jq -r .version "$EXT_DIR/manifest.json")"
if [[ "$AMO_SIGN" == 1 && -n "$(find "$BUILD_DIR" -maxdepth 1 -name "*-$VERSION.xpi" -print -quit)" ]]; then
  die "version $VERSION has already been signed (found *-$VERSION.xpi).
Bump \"version\" in $EXT_DIR/manifest.json before signing again."
fi

mkdir -p "$BUILD_DIR/firefox" "$BUILD_DIR/chrome"

log "Building Firefox version"
cp -r "$EXT_DIR/icons" "$EXT_DIR/background.js" "$BUILD_DIR/firefox/"
jq 'del(.background.service_worker) | del(.key)' \
    "$EXT_DIR/manifest.json" > "$BUILD_DIR/firefox/manifest.json"

log "Building Chrome version"
cp -r "$EXT_DIR/icons" "$EXT_DIR/background.js" "$BUILD_DIR/chrome/"
jq 'del(.background.scripts) | del(.browser_specific_settings)' \
    "$EXT_DIR/manifest.json" > "$BUILD_DIR/chrome/manifest.json"

rm -f "$BUILD_DIR/firefox.zip" "$BUILD_DIR/chrome.zip"
(cd "$BUILD_DIR/firefox" && zip -qr ../firefox.zip . -x '*.DS_Store')
(cd "$BUILD_DIR/chrome"  && zip -qr ../chrome.zip  . -x '*.DS_Store')

if [[ "$CWS_PUBLISH" == 1 ]]; then
  log "Publishing Chrome extension"

  CWS_TOKEN="$(curl -sf -X POST https://oauth2.googleapis.com/token \
      -d "client_id=$CWS_CLIENT_ID" \
      -d "client_secret=$CWS_CLIENT_SECRET" \
      -d "refresh_token=$CWS_REFRESH_TOKEN" \
      -d "grant_type=refresh_token" | jq -er .access_token)"

  UPLOAD="$(curl -sf -X PUT \
      -H "Authorization: Bearer $CWS_TOKEN" \
      -H "x-goog-api-version: 2" \
      -T "$BUILD_DIR/chrome.zip" \
      "https://www.googleapis.com/upload/chromewebstore/v1.1/items/$CWS_EXTENSION_ID")"
  if [[ "$(jq -r .uploadState <<< "$UPLOAD")" != "SUCCESS" ]]; then
    jq -r '.itemError[]?.error_detail // .' <<< "$UPLOAD" >&2
    die "Chrome Web Store upload failed"
  fi

  PUBLISH="$(curl -sf -X POST \
      -H "Authorization: Bearer $CWS_TOKEN" \
      -H "x-goog-api-version: 2" \
      -H "Content-Length: 0" \
      "https://www.googleapis.com/chromewebstore/v1.1/items/$CWS_EXTENSION_ID/publish")"
  log "Chrome Web Store status: $(jq -r '.status | join(", ")' <<< "$PUBLISH")"
else
  warn "Skipping Chrome publish — set CWS_CLIENT_ID, CWS_CLIENT_SECRET, CWS_REFRESH_TOKEN and CWS_EXTENSION_ID to enable"
fi

if [[ "$AMO_SIGN" == 1 ]]; then
  log "Signing Firefox extension"
  web-ext sign \
      --source-dir="$BUILD_DIR/firefox" \
      --artifacts-dir="$BUILD_DIR" \
      --api-key="$AMO_JWT_ISSUER" \
      --api-secret="$AMO_JWT_SECRET" \
      --amo-metadata="browser/amo-metadata.json" \
      --channel listed
else
  warn "Skipping Firefox signing - set AMO_JWT_ISSUER and AMO_JWT_SECRET to enable"
fi

log "Cleaning up build directories"
rm -rf "$BUILD_DIR/firefox" "$BUILD_DIR/chrome"

log "$BUILD_DIR/firefox.zip, $BUILD_DIR/chrome.zip"
[[ "$CWS_PUBLISH" == 1 ]] || warn "Chrome build was NOT published - upload chrome.zip manually"
[[ "$AMO_SIGN"    == 1 ]] || warn "Firefox build was NOT signed - upload firefox.zip manually"

[[ "$AMO_SIGN" == 0 ]] || find "$BUILD_DIR" -name "*.xpi" -mtime +30 -delete
