#!/usr/bin/env bash
#
# Builds the vestaboard executable in release mode and code-signs it with the
# Calendar entitlement so it can read events via EventKit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_DIR"

echo "Building (release)..."
swift build -c release

BIN="$(swift build -c release --show-bin-path)/vestaboard"

echo "Code-signing $BIN with Calendar entitlement..."
codesign --force --sign - --entitlements "$REPO_DIR/entitlements.plist" "$BIN"

echo "Done. Binary: $BIN"
