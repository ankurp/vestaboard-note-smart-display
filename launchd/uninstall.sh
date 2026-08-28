#!/usr/bin/env bash
#
# Stops and removes the Vestaboard display LaunchAgent.

set -euo pipefail

LABEL="com.vestaboard.display"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$PLIST"

echo "Removed '$LABEL'."
