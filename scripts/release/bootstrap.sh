#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$REPO_ROOT"

placeholders=0

install_config() {
  local target="$1" example="$2" var="$3"
  if [[ -s "$target" ]]; then
    log "$target already present — leaving it alone"
  elif have "$var"; then
    mkdir -p "$(dirname "$target")"
    printf '%s' "${!var}" > "$target"
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
