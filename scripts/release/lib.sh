#!/usr/bin/env bash
set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }

have() { [[ -n "${!1:-}" ]]; }

need() { for v in "$@"; do have "$v" || die "\$$v is required"; done; }

publishing() { [[ "${PUBLISH:-}" == true ]]; }

need_for_publish() {
  publishing || return 0
  local missing=() v
  for v in "$@"; do have "$v" || missing+=("$v"); done
  (( ${#missing[@]} == 0 )) && return 0
  die "PUBLISH=true but these are empty: ${missing[*]}. Add them as GitHub secrets (see docs/RELEASING.md#secrets)."
}

emit() {
  printf '%s=%s\n' "$1" "$2"
  [[ -n "${GITHUB_OUTPUT:-}" ]] && printf '%s=%s\n' "$1" "$2" >> "$GITHUB_OUTPUT"
  return 0
}

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$@"
  else shasum -a 256 "$@"; fi
}

load_app_store_connect_key() {
  APP_STORE_CONNECT_API_KEY_KEY_ID="$(tr -d '[:space:]' <<< "$APP_STORE_CONNECT_API_KEY_KEY_ID")"
  APP_STORE_CONNECT_API_KEY_ISSUER_ID="$(tr -d '[:space:]' <<< "$APP_STORE_CONNECT_API_KEY_ISSUER_ID")"
  export APP_STORE_CONNECT_API_KEY_KEY_ID APP_STORE_CONNECT_API_KEY_ISSUER_ID
  [[ "$APP_STORE_CONNECT_API_KEY_KEY_ID" =~ ^[A-Z0-9]{10}$ ]] \
    || die "\$APP_STORE_CONNECT_API_KEY_KEY_ID should be 10 uppercase letters/digits (got ${#APP_STORE_CONNECT_API_KEY_KEY_ID} characters)"
  [[ "$APP_STORE_CONNECT_API_KEY_ISSUER_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] \
    || die "\$APP_STORE_CONNECT_API_KEY_ISSUER_ID should be a lowercase UUID (got ${#APP_STORE_CONNECT_API_KEY_ISSUER_ID} characters)"

  if have APP_STORE_CONNECT_API_KEY_KEY_FILEPATH; then
    [[ -r "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH" ]] \
      || die "\$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH is not readable: $APP_STORE_CONNECT_API_KEY_KEY_FILEPATH"
  else
    need APP_STORE_CONNECT_API_KEY_KEY
    APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="${RUNNER_TEMP:-$(mktemp -d)}/app_store_connect.p8"
    printf '%s\n' "$APP_STORE_CONNECT_API_KEY_KEY" | tr -d '\r' > "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH"
    chmod 600 "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH"
  fi
  [[ "$(head -1 "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH")" == "-----BEGIN PRIVATE KEY-----" ]] \
    || die "The App Store Connect key should be the .p8 file's contents, starting with its own -----BEGIN PRIVATE KEY----- line"
  openssl pkey -in "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH" -noout 2>/dev/null \
    || die "The App Store Connect key isn't a readable private key. Re-set it from the .p8 file: gh secret set APP_STORE_CONNECT_API_KEY_KEY < AuthKey_XXXX.p8"
  unset APP_STORE_CONNECT_API_KEY_KEY
  export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT

resolve_version() {
  local out
  out="$(GITHUB_OUTPUT= "$REPO_ROOT/scripts/release/version.sh")"
  have VERSION_NAME || VERSION_NAME="$(sed -n 's/^name=//p' <<< "$out")"
  have BUILD_NUMBER || BUILD_NUMBER="$(sed -n 's/^build=//p' <<< "$out")"
  export VERSION_NAME BUILD_NUMBER
  log "Releasing $VERSION_NAME (build $BUILD_NUMBER)"
}
