#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/release/lib.sh"
cd "$REPO_ROOT"

TARGET="${1:-iPhone 17 Pro Max}"
APPEARANCE="${2:-light}"
DIR="${3:-docs/screenshots}"

udid() {
  local out
  out="$(xcrun simctl list devices available -j \
      | jq -r --arg name "$1" \
          '.devices | to_entries[] | .value[] | select(.name == $name) | .udid' \
      | head -n1)"

  if [[ -z "$out" ]]; then
    echo "Available:" >&2
    xcrun simctl list devices available | grep -E '^ +(iPhone|iPad)' >&2
    die "no available simulator named '$1'"
  fi
  echo "$out"
}

case "$TARGET" in
  macos|linux)
    DEVICE="$TARGET"
    SLUG="$TARGET"
    ;;
  windows)
    die "build Windows from a Windows host - it needs the firebase-strip dance"
    ;;
  *)
    command -v jq >/dev/null || die "jq is not installed — 'brew install jq'"
    DEVICE="$(udid "$TARGET")"
    SLUG="$(echo "$TARGET" | tr '[:upper:] ' '[:lower:]-')"

    xcrun simctl bootstatus "$DEVICE" -b
    open -a Simulator

    xcrun simctl ui "$DEVICE" appearance "$APPEARANCE"

    xcrun simctl status_bar "$DEVICE" override \
        --time "9:41" \
        --batteryState charged --batteryLevel 100 \
        --cellularMode active --cellularBars 4 \
        --wifiMode active --wifiBars 3
    ;;
esac

mkdir -p "$DIR"
PIDFILE="$(mktemp -t routine-flutter-pid)"

flutter run -d "$DEVICE" --dart-define=DEMO_MODE=true --pid-file "$PIDFILE" < /dev/null &
FLUTTER=$!
trap 'kill "$FLUTTER" 2>/dev/null || true; rm -f "$PIDFILE"' EXIT

WINDOW_ID=""
resolve() {
  [[ "$SLUG" == macos ]] || return 0
  [[ -z "$WINDOW_ID" ]] || return 0
  WINDOW_ID="$(swift scripts/window_id.swift Routine)"
}

shoot() {
  local err
  if [[ "$SLUG" == macos ]]; then
    err="$(screencapture -o -l"$WINDOW_ID" "$1" 2>&1)" || { echo "$err" >&2; return 1; }
  elif [[ "$SLUG" == linux ]]; then
    echo "no Linux capture here - screencapture is macOS only" >&2
    return 1
  else
    err="$(xcrun simctl io "$DEVICE" screenshot "$1" 2>&1)" || { echo "$err" >&2; return 1; }
  fi
}

signal() {
  [[ -s "$PIDFILE" ]] || { echo "not ready yet" >&2; return 1; }
  kill "-$1" "$(cat "$PIDFILE")"
}

echo
echo "s save a shot into $DIR/   r hot reload   R hot restart   q quit"
echo

n=0
while IFS= read -rsn1 key; do
  case "$key" in
    s)
      n=$((n + 1))
      while [[ -e "$DIR/$SLUG-$(printf '%02d' $n).png" ]]; do n=$((n + 1)); done
      OUT="$DIR/$SLUG-$(printf '%02d' $n).png"

      if resolve && shoot "$OUT"; then
        echo "saved $OUT"
      else
        rm -f "$OUT"
        echo "capture failed - is the app up yet?" >&2
      fi
      ;;
    r) signal USR1 || true ;;
    R) signal USR2 || true ;;
    q) exit 0 ;;
  esac
done
