# Login theme

El display manager es el servicio que muestra la pantalla de login antes de iniciar la sesión gráfica. Kali Desktop Core puede aplicar de forma opcional el wallpaper del theme activo y una configuración oscura básica al greeter de LightDM.

Por ahora solo se soporta LightDM. Si el sistema usa `gdm3`, `sddm`, `lxdm` o no se puede detectar el display manager, el instalador muestra un aviso y no modifica nada.

## Comprobar LightDM

```bash
cat /etc/X11/default-display-manager
systemctl status lightdm --no-pager
```

Un sistema compatible debería mostrar `/usr/sbin/lightdm` y el servicio `lightdm` activo.

## Probar sin cambios

```bash
./install.sh --dry-run --login-theme
```

El dry-run muestra el display manager detectado, el archivo que se modificaría, el backup que se crearía y las claves que se establecerían.

## Aplicar

```bash
./install.sh --login-theme
```

También puede aplicarse junto con una instalación completa:

```bash
./install.sh --full --theme kali-zen --login-theme
```

El cambio es opt-in. `./install.sh --full` no aplica el tema de login automáticamente.

## Qué modifica

El soporte inicial trabaja sobre:

```text
/etc/lightdm/lightdm-gtk-greeter.conf
```

Si existe un wallpaper válido en `~/.config/kali-desktop-core/current-wallpaper`, se usa ese. Si no existe, se intenta usar el wallpaper del theme seleccionado.

En la sección `[greeter]` se configuran:

```ini
background=<wallpaper>
theme-name=Adwaita-dark
icon-theme-name=Adwaita
font-name=Sans 10
hide-user-image=true
```

Si no hay wallpaper válido, no se modifica `background`.

## Revertir

Antes de modificar el archivo, el instalador crea un backup con timestamp:

```text
/etc/lightdm/lightdm-gtk-greeter.conf.kdc-backup-YYYYMMDD-HHMMSS
```

Para revertir:

```bash
sudo cp -a /etc/lightdm/lightdm-gtk-greeter.conf.kdc-backup-YYYYMMDD-HHMMSS /etc/lightdm/lightdm-gtk-greeter.conf
sudo systemctl restart lightdm
```

Reiniciar LightDM cerrará la sesión gráfica actual.

## Seguridad

Esta opción toca archivos del sistema y requiere `sudo`. Prueba primero con `--dry-run` y, si estás en una máquina de trabajo, usa una VM o snapshot antes de aplicarlo.
