#!/usr/bin/env bash
set -euo pipefail

# Build helper for ZeroTrustClient on Linux.
# Installs nothing automatically; prints missing deps when needed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ -z "${FLUTTER_STORAGE_BASE_URL:-}" ]]; then
  export FLUTTER_STORAGE_BASE_URL="https://pub-azs.ir"
fi
if [[ -z "${PUB_HOSTED_URL:-}" ]]; then
  export PUB_HOSTED_URL="https://pub-azs.ir"
fi

missing=()
command -v flutter >/dev/null || missing+=("flutter")
command -v cmake >/dev/null || missing+=("cmake")
command -v ninja >/dev/null || missing+=("ninja-build")
command -v pkg-config >/dev/null || missing+=("pkg-config")
pkg-config --exists gtk+-3.0 2>/dev/null || missing+=("libgtk-3-dev")

if ! command -v clang++ >/dev/null; then
  mkdir -p .local-bin
  ln -sf "$(command -v g++)" .local-bin/clang++
  ln -sf "$(command -v gcc)" .local-bin/clang
  export PATH="${SCRIPT_DIR}/.local-bin:${PATH}"
fi

if ((${#missing[@]} > 0)); then
  echo "Missing dependencies: ${missing[*]}"
  echo
  echo "Install on Ubuntu/Debian:"
  echo "  sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev"
  exit 1
fi

flutter pub get
flutter analyze
flutter test
flutter build linux --release

echo
echo "Built: build/linux/x64/release/bundle/zero_trust_client"
