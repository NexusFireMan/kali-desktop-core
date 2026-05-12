# v0.1.0 - First usable release

## Overview

`kali-desktop-core` is a minimal Kali Linux desktop workflow focused on real pentesting sessions, virtual machines and long-running lab work.

This first usable release provides a complete i3-based environment with a lightweight lemonbar status bar, persistent TARGET workflow, optional pentesting helpers and an installer designed to be reviewed before touching the system.

## Highlights

- Minimal i3 desktop for Kali Linux.
- Lightweight lemonbar with LAN, VPN/TUN, Docker, TARGET, workspace indicator, time and PWR menu.
- Persistent TARGET workflow integrated with shell and bar.
- `gomap` integration for fast scanning workflows.
- Interactive installer with dry-run planning.
- Profiles for minimal, VM, HTB, bug bounty and custom setups.
- Optional Docker, Starship and gomap installation.
- `kdc-doctor` diagnostic tool.
- Real screenshots and installation documentation.
- ShellCheck workflow.

## Quick install

```bash
git clone https://github.com/NexusFireMan/kali-desktop-core.git
cd kali-desktop-core
chmod +x install.sh uninstall.sh scripts/*.sh
./install.sh --interactive
```

## Recommended HTB/VM install

```bash
./install.sh --dry-run --full --profile htb --theme kali-zen
./install.sh --full --profile htb --theme kali-zen --with-gomap --with-docker --run-doctor
```

## Validation

```bash
bash -n install.sh uninstall.sh scripts/*.sh
shellcheck install.sh uninstall.sh scripts/*.sh
```

## Tested on

- Kali Linux virtualized.
- X11 session.
- i3.
- Theme: `kali-zen`.
- Profile: `htb`.

## Known notes

- The default lemonbar font is `fixed` for compatibility.
- Nerd Font icons are optional and not required.
- If a VPN is started manually, run `rb` to force a bar refresh.
- Docker group membership requires logging out and back in.
