<p align="center">
  <img src="assets/opencode.png" width="120" alt="OpenCode logo">
</p>

<h1 align="center">opencode-serve</h1>

<p align="center">
  Run <strong>OpenCode v2</strong> as a persistent local web app on Omarchy.<br>
  One script. Boot-persistent server. Launcher entry. Default agent. Shell status service. Done.
</p>

<p align="center">
  <a href="https://opencode.ai"><img src="https://img.shields.io/badge/OpenCode-v2-black" alt="OpenCode v2"></a>
  <img src="https://img.shields.io/badge/Omarchy-Quattro-blueviolet" alt="Omarchy Quattro">
  <img src="https://img.shields.io/badge/systemd-user_service-lightgrey" alt="systemd user service">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license">
</p>

---

## What this is

Two parts that work together:

**Setup scripts** turn a fresh Omarchy machine into an OpenCode workstation:

| Step | What happens |
|------|--------------|
| 📦 Binary | Installs the OpenCode v2 binary to `~/.opencode/bin` (official installer) |
| 🔐 Password | Sets one stable server password (V2 mandates auth; without it you get a random password every boot) |
| ⚙️ Service | Writes and enables a systemd user service: `opencode serve` on `127.0.0.1:4096`, localhost only, restarts on failure |
| 🚀 Web app | Creates an `OpenCode` launcher entry (Chromium app mode, official icon) |
| 🧭 Default agent | Prepends `~/.opencode/bin` to the Omarchy session PATH, so the launcher and the Agent keybinding run v2 instead of another `opencode` (for example a mise-managed v1) |

Everything is idempotent. Re-run `install.sh` any time; it detects what exists, reuses the stored password, and never rotates it.

**Shell plugin** (`david.opencode`, kind `service`) reports the local server status to the Omarchy shell. It polls the health endpoint without credentials: any HTTP answer means up, refused connection means down. No password needed.

## Install

```bash
git clone https://github.com/Skeptomenos/opencode-serve.git
cd opencode-serve
./install.sh
```

Then open the app with <kbd>Super</kbd> + <kbd>Space</kbd>, type `OpenCode`.

Add the shell status service:

```bash
omarchy plugin add https://github.com/Skeptomenos/opencode-serve.git --enable
```

## Login

The server uses HTTP Basic auth. The browser asks once and saves it.

- User: `opencode`
- Password: stored in the unit file (mode `600`):

```bash
grep -oP 'OPENCODE_SERVER_PASSWORD=\K.*' ~/.config/systemd/user/opencode-serve.service
```

## Default agent

The script points the Omarchy session PATH at `~/.opencode/bin`, so `opencode` means v2 in the launcher and in the <kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>Ctrl</kbd>+<kbd>A</kbd> Agent keybinding. Those run with the session PATH, not your interactive shell's PATH.

- The running session is updated at install time where possible.
- Everything is active after one log out and back in. The launcher menu needs that, or run `omarchy restart shell`.

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
| `~/.config/uwsm/env.d/50-opencode-v2` | Session PATH wiring for the default agent |

## Logs and status

```bash
systemctl --user status opencode-serve.service
journalctl --user -u opencode-serve.service
curl -u opencode:<password> http://127.0.0.1:4096/api/health
omarchy plugin list | grep opencode
```

## Uninstall

```bash
./uninstall.sh
omarchy plugin remove david.opencode
```

Removes the service, the web app, the shell plugin, and the session PATH wiring. Keeps the binary and your OpenCode config.

## Security notes

- The server binds `127.0.0.1` only. No LAN exposure. Verified with `ss -ltn`.
- The password cannot be removed: OpenCode v2 requires a server password. This repo pins one stable password instead of a random one per boot.
- The unit file holds the password and is `chmod 600`. The password never appears in logs.
- The shell plugin polls without credentials and runs no install hooks.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `install.sh` reports unhealthy server | `journalctl --user -u opencode-serve.service`, check port `4096` is free: `ss -ltn \| grep ':4096'` |
| Browser login fails | Re-read the password from the unit file (see Login) |
| Launcher entry missing | Log out and back in, or run `update-desktop-database ~/.local/share/applications` |

---

## Attribution

**OpenCode is built by [Anomaly](https://anoma.ly/)** — the makers of [OpenCode](https://opencode.ai). The binary, the API and web server, the web UI, and the logo are all their work. Docs: [opencode.ai/v2/docs](https://opencode.ai/v2/docs).

This repository is an **unofficial setup wrapper** and is not affiliated with or endorsed by Anomaly. All credit for OpenCode itself belongs to them.

## License

MIT. See [LICENSE](LICENSE).
