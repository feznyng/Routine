#!/usr/bin/env bash
# Compose GitHub release notes to stdout.
#
#   VERSION_NAME                 required
#   ARTIFACT_DIR                 default: artifacts
#   TESTFLIGHT_URL PLAY_TESTING_URL   omitted rows are dropped, not left dangling
#
# TESTFLIGHT_URL defaults to the public beta link below, so `just release-notes`
# is accurate locally without exporting anything. The repo variable still wins
# when set — see docs/RELEASING.md.
#
#   VERSION_NAME=1.2.3 ./scripts/release/notes.sh > notes.md
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
resolve_version
ARTIFACT_DIR="${ARTIFACT_DIR:-artifacts}"
TESTFLIGHT_URL="${TESTFLIGHT_URL:-https://testflight.apple.com/join/MQS1bU25}"

echo "## Install"
echo
echo "| Platform | How |"
echo "|---|---|"
have TESTFLIGHT_URL   && echo "| iOS | [Join the TestFlight beta]($TESTFLIGHT_URL) |"
have PLAY_TESTING_URL && echo "| Android | [Join Play testing]($PLAY_TESTING_URL) — or sideload the APK below |"
echo "| macOS | Download the \`.dmg\` |"
echo "| Windows | Download the \`.exe\` installer |"

cat <<'EOF'

### Windows: "Windows protected your PC"

The installer is not yet code-signed, so SmartScreen shows a warning. Click
**More info** → **Run anyway**. Verify against the checksums below if you'd
like to confirm the download.

### Android: sideload vs Play

The APK here is signed with our upload key; the Play build is re-signed by
Google. The signatures differ, so **you cannot upgrade from one to the other** —
switching channels requires uninstalling first.
EOF

if [[ -d "$ARTIFACT_DIR" ]]; then
  # A pipeline subshell keeps shell functions; find -exec would not.
  sums="$(cd "$ARTIFACT_DIR" \
          && find . -type f \( -name '*.apk' -o -name '*.dmg' -o -name '*.exe' \) \
          | while IFS= read -r f; do sha256 "$f"; done \
          | sed 's|\./[^/]*/||')"
  if [[ -n "$sums" ]]; then
    printf '\n### Checksums\n\n```\n%s\n```\n' "$sums"
  fi
fi
