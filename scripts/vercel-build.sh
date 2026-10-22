#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.47.2"

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
else
  FLUTTER_HOME="${TMPDIR:-/tmp}/flutter-${FLUTTER_VERSION}"
  if [[ ! -x "${FLUTTER_HOME}/bin/flutter" ]]; then
    rm -rf "${FLUTTER_HOME}"
    git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git "${FLUTTER_HOME}"
  fi
  FLUTTER_BIN="${FLUTTER_HOME}/bin/flutter"
fi

"${FLUTTER_BIN}" config --no-analytics
"${FLUTTER_BIN}" precache --web
"${FLUTTER_BIN}" pub get --enforce-lockfile
"${FLUTTER_BIN}" build web --release --no-wasm-dry-run --output build/release_web
