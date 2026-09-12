#!/bin/bash
#
# Installs OpenCode v2 plus a boot-persistent serve service and an Omarchy web app.
# Idempotent: safe to re-run. Usage: ./install.sh
#
set -euo pipefail

APP_NAME="OpenCode"
PORT=4096
URL="http://127.0.0.1:${PORT}"
BIN_DIR="$HOME/.opencode/bin"
BIN="$BIN_DIR/opencode"
UNIT_DIR="$HOME/.config/systemd/user"
UNIT="$UNIT_DIR/opencode-serve.service"
DESKTOP="$HOME/.local/share/applications/${APP_NAME}.desktop"
ICON_URL="https://opencode.ai/apple-touch-icon-v3.png"

export PATH="$BIN_DIR:$PATH"

step() { printf '\n==> %s\n' "$1"; }

step "OpenCode v2 binary"
if [[ -x $BIN ]] && "$BIN" --version 2>/dev/null | grep -q "v2\."; then
  echo "Present: $("$BIN" --version)"
else
  curl -fsSL https://opencode.ai/v2/install | bash
fi

step "Server password"
if [[ -f $UNIT ]] && grep -q "OPENCODE_SERVER_PASSWORD=" "$UNIT"; then
  PASSWORD=$(grep -oP 'OPENCODE_SERVER_PASSWORD=\K.*' "$UNIT")
  echo "Reusing existing password."
else
  PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
  echo "Generated new password."
fi

step "systemd service"
mkdir -p "$UNIT_DIR"
cat >"$UNIT" <<EOF
[Unit]
Description=OpenCode v2 API and web server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$BIN serve --hostname 127.0.0.1 --port $PORT
Environment=OPENCODE_SERVER_PASSWORD=$PASSWORD
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
chmod 600 "$UNIT"
systemctl --user daemon-reload
systemctl --user enable --now opencode-serve.service

step "Waiting for server"
for (( i = 0; i < 30; i++ )); do
  if curl -fs -u "opencode:$PASSWORD" "$URL/api/health" >/dev/null 2>&1; then
    echo "Healthy: $(curl -s -u "opencode:$PASSWORD" "$URL/api/health")"
    break
  fi
  sleep 1
  if (( i == 29 )); then
    echo "Server did not become healthy. Check: journalctl --user -u opencode-serve.service" >&2
    exit 1
  fi
done

step "Omarchy web app"
if [[ -f $DESKTOP ]]; then
  echo "Present: $DESKTOP"
else
  omarchy-webapp-install "$APP_NAME" "$URL" "$ICON_URL"
fi

cat <<EOF

Done.
- Server: $URL (localhost only, no LAN exposure)
- Login user: opencode
- Password: stored in $UNIT (mode 600). Show it with:
    grep -oP 'OPENCODE_SERVER_PASSWORD=\K.*' $UNIT
- Open the app: SUPER + SPACE, type $APP_NAME
- For start at boot without login, run:
    ! sudo loginctl enable-linger $USER
EOF
