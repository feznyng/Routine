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
  if have APP_STORE_CONNECT_API_KEY_KEY_FILEPATH; then
    [[ -r "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH" ]] \
      || die "\$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH is not readable: $APP_STORE_CONNECT_API_KEY_KEY_FILEPATH"
  else
    need APP_STORE_CONNECT_API_KEY_KEY
    APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="${RUNNER_TEMP:-$(mktemp -d)}/app_store_connect.p8"
    printf '%s' "$APP_STORE_CONNECT_API_KEY_KEY" > "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH"
    chmod 600 "$APP_STORE_CONNECT_API_KEY_KEY_FILEPATH"
  fi
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
