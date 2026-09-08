#!/usr/bin/env bash
set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }

have() { [[ -n "${!1:-}" ]]; }

need() { for v in "$@"; do have "$v" || die "\$$v is required"; done; }

emit() {
  printf '%s=%s\n' "$1" "$2"
  [[ -n "${GITHUB_OUTPUT:-}" ]] && printf '%s=%s\n' "$1" "$2" >> "$GITHUB_OUTPUT"
  return 0
}

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$@"
  else shasum -a 256 "$@"; fi
}

load_asc_key() {
  if have ASC_PRIVATE_KEY_PATH; then
    [[ -r "$ASC_PRIVATE_KEY_PATH" ]] \
      || die "\$ASC_PRIVATE_KEY_PATH is not readable: $ASC_PRIVATE_KEY_PATH"
    ASC_KEY_FILE="$ASC_PRIVATE_KEY_PATH"
    ASC_PRIVATE_KEY="$(cat "$ASC_KEY_FILE")"
  else
    need ASC_PRIVATE_KEY
    ASC_KEY_FILE="${RUNNER_TEMP:-$(mktemp -d)}/asc.p8"
    printf '%s' "$ASC_PRIVATE_KEY" > "$ASC_KEY_FILE"
    chmod 600 "$ASC_KEY_FILE"
  fi
  export ASC_PRIVATE_KEY ASC_KEY_FILE
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
