#!/bin/bash
#
# Removes the OpenCode serve service, web app, and session PATH wiring.
# Keeps the v2 binary (~/.opencode/bin) and config (~/.config/opencode).
# Usage: ./uninstall.sh
#
set -euo pipefail

systemctl --user disable --now opencode-serve.service 2>/dev/null || true
rm -f "$HOME/.config/systemd/user/opencode-serve.service"
systemctl --user daemon-reload
omarchy-webapp-remove "OpenCode" 2>/dev/null || true
rm -f "$HOME/.config/uwsm/env.d/50-opencode-v2"
echo "Removed service, web app, and session PATH wiring. Binary and config kept."
echo "Log out and back in (or run: omarchy restart shell) to drop the live PATH change."
