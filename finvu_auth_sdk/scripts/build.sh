#!/usr/bin/env bash
#
# Build / verify / publish helper for the finvu_authentication_sdk package.
#
# Usage:
#   ./scripts/build.sh verify      # codegen check + analyze + test + publish dry-run
#   ./scripts/build.sh android     # build the example app for Android
#   ./scripts/build.sh ios         # build the example app for iOS (macOS only)
#   ./scripts/build.sh publish     # publish to pub.dev (needs credentials / PUB_TOKEN)
#   ./scripts/build.sh all         # verify + android + ios
#
# Native dependencies are resolved at build time, exactly like the React Native
# wrapper does:
#   * Android — io.github.cookiejar-technologies:finvuauthenticationsdk from
#     Maven Central (see android/build.gradle). No credentials needed.
#   * iOS — the FinvuAuthenticationSDK.xcframework is downloaded and untarred by
#     the podspec's prepare_command from the finvu-auth-sdk-ios GitHub tag
#     (see ios/finvu_authentication_sdk.podspec).
# Neither artifact is checked into this repo.

set -euo pipefail

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PKG_DIR"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

pkg_version() {
  grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*//'
}

deps() {
  log "Fetching package dependencies"
  flutter pub get
  log "Fetching example dependencies"
  (cd example && flutter pub get)
}

# Regenerates the Pigeon bindings and fails if the checked-in generated files
# are out of date with pigeons/native_finvu_auth_wrapper.dart.
codegen_check() {
  log "Checking Pigeon generated code is up to date"
  local tmp
  tmp="$(mktemp -d)"
  cp lib/src/generated/native_finvu_auth_wrapper.g.dart "$tmp/dart.g"
  cp android/src/main/kotlin/com/finvu/finvu_auth_sdk/generated/NativeFinvuAuthWrapper.g.kt "$tmp/kotlin.g"
  cp ios/Classes/generated/NativeFinvuAuthWrapper.g.swift "$tmp/swift.g"

  dart run pigeon --input pigeons/native_finvu_auth_wrapper.dart

  # Pigeon does not run the formatter on its Dart output; do it here so the
  # checked-in file stays `dart format` clean for pub.dev's analysis.
  dart format --output=write lib/src/generated >/dev/null

  local stale=0
  diff -q "$tmp/dart.g"   lib/src/generated/native_finvu_auth_wrapper.g.dart >/dev/null || stale=1
  diff -q "$tmp/kotlin.g" android/src/main/kotlin/com/finvu/finvu_auth_sdk/generated/NativeFinvuAuthWrapper.g.kt >/dev/null || stale=1
  diff -q "$tmp/swift.g"  ios/Classes/generated/NativeFinvuAuthWrapper.g.swift >/dev/null || stale=1
  rm -rf "$tmp"

  if [[ "$stale" -eq 1 ]]; then
    echo "ERROR: Pigeon generated files are out of date." >&2
    echo "Run: dart run pigeon --input pigeons/native_finvu_auth_wrapper.dart" >&2
    echo "and commit the regenerated files." >&2
    exit 1
  fi
  echo "Generated code is up to date."
}

verify() {
  deps
  codegen_check

  log "Checking formatting (lib, pigeons)"
  dart format --output=none --set-exit-if-changed lib pigeons

  log "Analyzing"
  flutter analyze

  log "Running example tests"
  (cd example && flutter test)

  log "Publish dry run"
  flutter pub publish --dry-run
}

build_android() {
  deps
  log "Building example APK (resolves the Android SDK from Maven Central)"
  (cd example && flutter build apk --debug)
}

build_ios() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Skipping iOS build: requires macOS." >&2
    return 0
  fi
  deps
  log "Building example iOS app (podspec downloads the xcframework)"
  (cd example && flutter build ios --no-codesign --debug)
}

publish() {
  log "Publishing finvu_authentication_sdk $(pkg_version) to pub.dev"
  flutter pub publish --force
}

case "${1:-verify}" in
  verify)  verify ;;
  android) build_android ;;
  ios)     build_ios ;;
  publish) publish ;;
  all)     verify; build_android; build_ios ;;
  *)
    echo "Unknown command: $1" >&2
    sed -n '3,20p' "${BASH_SOURCE[0]}" >&2
    exit 1
    ;;
esac
