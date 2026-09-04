#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter is required but was not found on PATH.' >&2
  exit 1
fi

flutter create --platforms=android,web --project-name=rc_sow_connected --org=org.jamaicaredcross .
flutter pub get
dart format lib test
flutter analyze
flutter test
