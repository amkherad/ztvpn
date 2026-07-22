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

echo "Fetching dependencies..."
flutter pub get

echo "Regenerating platform files..."
flutter create . \
  --project-name zero_trust_client \
  --org com.zerotrust \
  --platforms=linux,windows,macos,android,ios,web

echo "Done. Run: flutter run -d linux"
