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

if ! command -v swift >/dev/null 2>&1; then
  echo "Error: 'swift' was not found in PATH. Install the Xcode command line tools first." >&2
  exit 1
fi

if [ ! -f "$REPO_DIR/.env" ]; then
  echo "Warning: $REPO_DIR/.env not found. Copy .env.example to .env and configure it." >&2
fi

# Build and code-sign the release binary (with the Calendar entitlement).
"$SCRIPT_DIR/../Scripts/build.sh"
BINARY="$(cd "$REPO_DIR" && swift build -c release --show-bin-path)/vestaboard"

mkdir -p "$AGENTS_DIR" "$REPO_DIR/logs"

# A PATH launchd can use to find Homebrew tools.
LAUNCH_PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"

sed \
  -e "s|__BINARY__|$BINARY|g" \
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
