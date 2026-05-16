# Release checklist

## Pre-release

- [ ] Probar instalación en Kali VM limpia.
- [ ] Ejecutar `./install.sh --dry-run --full --profile htb --theme kali-zen`.
- [ ] Ejecutar instalación real.
- [ ] Ejecutar `kdc-doctor`.
- [ ] Probar `settarget`, `showtarget`, `cleartarget`.
- [ ] Probar `scan`.
- [ ] Probar VPN y refresco con `rb`.
- [ ] Probar Docker si se instala.
- [ ] Probar botón PWR.
- [ ] Probar `Mod+Shift+e`.
- [ ] Probar cambio de workspaces.
- [ ] Probar cambio de theme.
- [ ] Probar `--login-theme` solo en VM/snapshot.
- [ ] Confirmar LightDM con `/etc/X11/default-display-manager`.
- [ ] Confirmar que el fondo existe en `/usr/share/backgrounds/kali-desktop-core/`.
- [ ] Confirmar que LightDM muestra el fondo tras reiniciar.
- [ ] Confirmar que se crea backup del greeter.
- [ ] Confirmar que se puede revertir el backup del greeter.
- [ ] Revisar capturas.
- [ ] Ejecutar validación Bash/ShellCheck.

## GitHub release

- [ ] Crear tag `v0.1.0`.
- [ ] Usar contenido de `RELEASE_NOTES.md`.
- [ ] Marcar como latest release.
- [ ] Adjuntar capturas si procede.
