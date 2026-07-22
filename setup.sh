#!/usr/bin/env bash
set -euo pipefail

# Regenerates Flutter platform boilerplate while preserving lib/ source.
# Run this once after cloning if platform folders are incomplete.

if ! command -v flutter &>/dev/null; then
  echo "Error: Flutter SDK not found. Install from https://flutter.dev"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ -z "${FLUTTER_STORAGE_BASE_URL:-}" ]]; then
  export FLUTTER_STORAGE_BASE_URL="https://pub-azs.ir"
fi
if [[ -z "${PUB_HOSTED_URL:-}" ]]; then
  export PUB_HOSTED_URL="https://pub-azs.ir"
fi

echo "Fetching dependencies..."
flutter pub get

echo "Regenerating platform files..."
flutter create . \
  --project-name zero_trust_client \
  --org com.zerotrust \
  --platforms=linux,windows,macos,android,ios,web

echo
echo "Linux build dependencies (Ubuntu/Debian):"
echo "  sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev"
echo
echo "Done. Run: ./build.sh"
