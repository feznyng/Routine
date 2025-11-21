#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: build_windows.sh must be run inside a git repository" >&2
  exit 1
fi

cleanup() {
  git reset --hard >/dev/null 2>&1 || true
  git stash pop >/dev/null 2>&1 || true
  git stash pop >/dev/null 2>&1 || true
}

trap cleanup EXIT

# Stash current work (tracked, then tracked+untracked). These may be no-ops.
git stash >/dev/null 2>&1 || true
git stash -u >/dev/null 2>&1 || true

# For every Dart file, remove any line containing MARK:REMOVE
find . -type f -name "*.dart" -print0 | while IFS= read -r -d '' file; do
  if grep -q 'MARK:REMOVE' "$file"; then
    tmp_file="${file}.tmp.$$"
    awk '
      /MARK:REMOVE/ { next }
      { print }
    ' "$file" > "$tmp_file"
    mv "$tmp_file" "$file"
  fi
done

# Also process pubspec.yaml: remove any line containing MARK:REMOVE
if [ -f pubspec.yaml ]; then
  tmp_file="pubspec.yaml.tmp.$$"
  awk '
    /MARK:REMOVE/ { next }
    { print }
  ' pubspec.yaml > "$tmp_file"
  mv "$tmp_file" pubspec.yaml
fi

flutter build windows --release
