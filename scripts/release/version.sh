#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

pubspec_version() { grep '^version:' "$REPO_ROOT/pubspec.yaml" | sed 's/version: *//'; }

name="${VERSION_NAME:-}"
if [[ -z "$name" ]]; then
  ref="${GITHUB_REF:-$(git -C "$REPO_ROOT" describe --tags --exact-match 2>/dev/null || true)}"
  case "$ref" in
    refs/tags/v*) name="${ref#refs/tags/v}" ;;
    v*)           name="${ref#v}" ;;
    *)            name="$(pubspec_version | sed 's/+.*//')" ;;
  esac
fi

build="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-}}"
[[ -z "$build" ]] && build="$(pubspec_version | sed 's/.*+//')"

[[ "$name"  =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]] || die "version name '$name' is not semver-ish"
[[ "$build" =~ ^[0-9]+$ ]]                 || die "build number '$build' is not an integer"

emit name  "$name"
emit build "$build"
