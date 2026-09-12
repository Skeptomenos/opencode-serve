<p align="center">
  <img src="assets/opencode.png" width="120" alt="OpenCode logo">
</p>

<h1 align="center">opencode-serve</h1>

<p align="center">
  Run <strong>OpenCode v2</strong> as a persistent local web app on Omarchy.<br>
  One script. Boot-persistent server. Launcher entry. Done.
</p>

<p align="center">
  <a href="https://opencode.ai"><img src="https://img.shields.io/badge/OpenCode-v2-black" alt="OpenCode v2"></a>
  <img src="https://img.shields.io/badge/Omarchy-Quattro-blueviolet" alt="Omarchy Quattro">
  <img src="https://img.shields.io/badge/systemd-user_service-lightgrey" alt="systemd user service">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license">
</p>

---

## What this is

`install.sh` turns a fresh Omarchy machine into an OpenCode workstation:

| Step | What happens |
|------|--------------|
| 📦 Binary | Installs the OpenCode v2 binary to `~/.opencode/bin` (official installer) |
| 🔐 Password | Sets one stable server password (V2 mandates auth; without it you get a random password every boot) |
| ⚙️ Service | Writes and enables a systemd user service: `opencode serve` on `127.0.0.1:4096`, localhost only, restarts on failure |
| 🚀 Web app | Creates an `OpenCode` launcher entry (Chromium app mode, official icon) |

Everything is idempotent. Re-run `install.sh` any time; it detects what exists, reuses the stored password, and never rotates it.

## Install

```bash
git clone https://github.com/Skeptomenos/opencode-serve.git
cd opencode-serve
./install.sh
```

Then open the app with <kbd>Super</kbd> + <kbd>Space</kbd>, type `OpenCode`.

## Login

The server uses HTTP Basic auth. The browser asks once and saves it.

- User: `opencode`
- Password: stored in the unit file (mode `600`):

```bash
grep -oP 'OPENCODE_SERVER_PASSWORD=\K.*' ~/.config/systemd/user/opencode-serve.service
```

## Boot behavior

The enabled user service starts at graphical login, which covers every normal boot since Omarchy auto-logs in. For start without any login session:

```bash
! sudo loginctl enable-linger david
```

## Files created

| Path | What |
|------|------|
| `~/.opencode/bin/opencode` | OpenCode v2 binary (official installer) |
| `~/.config/systemd/user/opencode-serve.service` | Boot service, localhost-only |
| `~/.local/share/applications/OpenCode.desktop` | Launcher entry |
| `~/.local/share/icons/hicolor/256x256/apps/opencode.png` | App icon |

## Logs and status

```bash
systemctl --user status opencode-serve.service
journalctl --user -u opencode-serve.service
curl -u opencode:<password> http://127.0.0.1:4096/api/health
```

## Uninstall

```bash
./uninstall.sh
```

Removes the service and the web app. Keeps the binary and your OpenCode config.

## Security notes

- The server binds `127.0.0.1` only. No LAN exposure. Verified with `ss -ltn`.
- The password cannot be removed: OpenCode v2 requires a server password. This repo pins one stable password instead of a random one per boot.
- The unit file holds the password and is `chmod 600`. The password never appears in logs.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `install.sh` reports unhealthy server | `journalctl --user -u opencode-serve.service`, check port `4096` is free: `ss -ltn \| grep ':4096'` |
| Browser login fails | Re-read the password from the unit file (see Login) |
| Launcher entry missing | Log out and back in, or run `update-desktop-database ~/.local/share/applications` |

---

## Attribution

**OpenCode is built by the [OpenCode team](https://opencode.ai).** The binary, the API and web server, the web UI, and the logo are all their work. Docs: [opencode.ai/v2/docs](https://opencode.ai/v2/docs).

This repository is an **unofficial setup wrapper** and is not affiliated with or endorsed by the OpenCode team. All credit for OpenCode itself belongs to them.

## License

MIT. See [LICENSE](LICENSE).
