#!/usr/bin/env bash
# Materialise the gitignored config files a build needs.
#
# For each file: write it from its secret if that secret is set, otherwise copy
# the checked-in example. Examples let the workflow compile without credentials
# (forks, smoke tests); the resulting app builds but cannot reach Firebase or
# Supabase, so never ship one.
#
#   DOTENV                     contents of .env
#   FIREBASE_OPTIONS_DART      contents of lib/firebase_options.dart
#   GOOGLE_SERVICES_JSON       contents of android/app/google-services.json
#   GOOGLE_SERVICE_INFO_PLIST  contents of ios/Runner/GoogleService-Info.plist
#
#   ./scripts/release/bootstrap.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

placeholders=0

# install <target> <example> <env-var-name>
install_config() {
  local target="$1" example="$2" var="$3"
  if [[ -s "$target" ]]; then
    log "$target already present — leaving it alone"
  elif have "$var"; then
    mkdir -p "$(dirname "$target")"
    printf '%s' "${!var}" > "$target"
    # Secrets often arrive without a trailing newline; add one if missing.
    [[ -n "$(tail -c1 "$target")" ]] && printf '\n' >> "$target"
    log "$target written from \$$var"
  elif [[ -f "$example" ]]; then
    mkdir -p "$(dirname "$target")"
    cp "$example" "$target"
    warn "$target copied from $example — placeholder values"
    placeholders=1
  else
    die "$target missing, \$$var unset, and no example at $example"
  fi
}

install_config .env \
               .env.example                              DOTENV
install_config lib/firebase_options.dart \
               lib/firebase_options.example.dart         FIREBASE_OPTIONS_DART
install_config android/app/google-services.json \
               android/app/google-services.example.json  GOOGLE_SERVICES_JSON
install_config ios/Runner/GoogleService-Info.plist \
               ios/Runner/GoogleService-Info.example.plist GOOGLE_SERVICE_INFO_PLIST

if (( placeholders )); then
  warn "One or more configs are placeholders. This build is NOT distributable."
fi
