#!/bin/bash
#
# Removes the OpenCode serve service and web app.
# Keeps the v2 binary (~/.opencode/bin) and config (~/.config/opencode).
# Usage: ./uninstall.sh
#
set -euo pipefail

systemctl --user disable --now opencode-serve.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/opencode-serve.service"
systemctl --user daemon-reload
omarchy-webapp-remove "OpenCode" 2>/dev/null || true
echo "Removed. Binary and config kept."
