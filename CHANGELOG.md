# Changelog

## [Unreleased]

### Added

- Soporte opcional inicial para tema de login LightDM.

## [v0.1.0] - 2026-05-12

### Added

- Entorno i3 minimalista para Kali Linux.
- Barra `lemonbar` con LAN, TUN/VPN, Docker, TARGET, estado VPN, hora, workspaces y botón PWR.
- Indicador central de workspaces configurable.
- Menú de sesión/power con `dmenu`.
- TARGET persistente compartido entre shell, scripts y barra.
- Instalador con:
   - plan previo
   - `--dry-run`
   - modo interactivo
   - perfiles `minimal`, `vm`, `htb`, `bugbounty`, `custom`
   - backups automáticos
- Extras opcionales:
   - `gomap`
   - Docker
   - Starship
- Diagnóstico con `kdc-doctor`.
- Refresco manual de barra con `kdc-refresh`, `refreshbar` y alias `rb`.
- Temas `default`, `kali-zen` y `katana`.
- Capturas reales de instalación y uso.
- Workflow de ShellCheck en GitHub Actions.

### Tested

- Kali Linux virtualizado.
- Sesión X11.
- Perfil `htb`.
- Tema `kali-zen`.
- Instalación con `--dry-run`.
- Instalación completa.
- Actualización con `--configs`.
- Barra lemonbar, TARGET, VPN, Docker, workspaces y PWR.
- `kdc-doctor`.
- `gomap`.

### Notes

- `starship`, `gomap` y Docker son extras opcionales.
- La barra usa la fuente X11 `fixed` por defecto para maximizar compatibilidad en instalaciones limpias.
- Los iconos Nerd Font no son requeridos.
- Los themes son archivos Bash leídos por los scripts del proyecto; revisar themes de terceros antes de instalarlos.
