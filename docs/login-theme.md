# Login theme

El display manager es el servicio que muestra la pantalla de login antes de iniciar la sesión gráfica. Kali Desktop Core puede aplicar de forma opcional un fondo propio del proyecto y una configuración oscura básica al greeter de LightDM.

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

Por defecto se usa el asset:

```text
wallpapers/kdc-login-gradient.svg
```

El instalador lo copia a una ruta del sistema legible por LightDM:

```text
/usr/share/backgrounds/kali-desktop-core/kdc-login-gradient.svg
```

Esto evita problemas de permisos con rutas dentro del `HOME` del usuario. Si el asset no existe, se intenta usar `~/.config/kali-desktop-core/current-wallpaper`; si tampoco existe, se intenta usar el wallpaper del theme seleccionado.

En la sección `[greeter]` se configuran:

```ini
background=/usr/share/backgrounds/kali-desktop-core/kdc-login-gradient.svg
theme-name=Adwaita-dark
icon-theme-name=Adwaita
font-name=Sans 10
hide-user-image=true
```

Si no hay wallpaper válido, no se modifica `background`.

## Cambiar el fondo manualmente

Puedes sustituir el SVG instalado por otro fondo legible por LightDM:

```bash
sudo install -d -m 0755 /usr/share/backgrounds/kali-desktop-core
sudo install -m 0644 mi-fondo.svg /usr/share/backgrounds/kali-desktop-core/kdc-login-gradient.svg
```

También puedes editar `/etc/lightdm/lightdm-gtk-greeter.conf` y cambiar la clave `background=` por otra ruta del sistema.

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
