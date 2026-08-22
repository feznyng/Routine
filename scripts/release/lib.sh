#!/usr/bin/env bash
# Shared helpers. Source this, don't execute it.
set -euo pipefail

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }

# have VAR — true if the env var is set and non-empty.
have() { [[ -n "${!1:-}" ]]; }

# need VAR... — die unless all are set.
need() { for v in "$@"; do have "$v" || die "\$$v is required"; done; }

# Emit key=value to GitHub Actions outputs when running in CI, stdout otherwise.
emit() {
  printf '%s=%s\n' "$1" "$2"
  [[ -n "${GITHUB_OUTPUT:-}" ]] && printf '%s=%s\n' "$1" "$2" >> "$GITHUB_OUTPUT"
  return 0
}

# Portable sha256 — sha256sum on Linux, shasum on macOS.
sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$@"
  else shasum -a 256 "$@"; fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT

# Fill in VERSION_NAME / BUILD_NUMBER from version.sh when not already set, so
# `just dist macos` works with no environment. GITHUB_OUTPUT is cleared so this
# never pollutes the calling job's outputs.
resolve_version() {
  local out
  out="$(GITHUB_OUTPUT= "$REPO_ROOT/scripts/release/version.sh")"
  have VERSION_NAME || VERSION_NAME="$(sed -n 's/^name=//p' <<< "$out")"
  have BUILD_NUMBER || BUILD_NUMBER="$(sed -n 's/^build=//p' <<< "$out")"
  export VERSION_NAME BUILD_NUMBER
  log "Releasing $VERSION_NAME (build $BUILD_NUMBER)"
}
