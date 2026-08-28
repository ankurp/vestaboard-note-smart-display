#!/usr/bin/env bash
#
# Installs the Vestaboard display as a per-user LaunchAgent so it starts at
# login and stays running. Safe to re-run to update the configuration.

set -euo pipefail

LABEL="com.vestaboard.display"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_DEST="$AGENTS_DIR/$LABEL.plist"

NODE_BIN="$(command -v node || true)"
if [ -z "$NODE_BIN" ]; then
  echo "Error: 'node' was not found in PATH. Install Node.js first." >&2
  exit 1
fi

if [ ! -f "$REPO_DIR/.env" ]; then
  echo "Warning: $REPO_DIR/.env not found. Copy .env.example to .env and configure it." >&2
fi

mkdir -p "$AGENTS_DIR" "$REPO_DIR/logs"

# Build a PATH launchd can use to find node and Homebrew tools.
NODE_DIR="$(dirname "$NODE_BIN")"
LAUNCH_PATH="$NODE_DIR:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"

sed \
  -e "s|__NODE__|$NODE_BIN|g" \
  -e "s|__WORKDIR__|$REPO_DIR|g" \
  -e "s|__PATH__|$LAUNCH_PATH|g" \
  "$SCRIPT_DIR/com.vestaboard.display.plist" > "$PLIST_DEST"
echo "Wrote $PLIST_DEST"

# Reload if it was already installed, then start it.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl enable "gui/$(id -u)/$LABEL"

echo "Installed and started '$LABEL'. It will now run at every login."
echo "Logs: $REPO_DIR/logs/board.log"
