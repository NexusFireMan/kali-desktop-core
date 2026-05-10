# Kali Desktop Core

Entorno de escritorio minimalista para Kali Linux orientado a pentesting real, máquinas virtuales y sesiones largas de trabajo sin fatiga visual.

## Filosofía

Kali Desktop Core no busca verse bien en una captura. Busca sentirse sólido después de ocho horas de reconocimiento, pivoteo, debugging y terminales abiertas.

Principios del proyecto:

- rendimiento real sobre efectos visuales
- foco y reducción de distracciones
- contraste cómodo y sin blancos puros
- modularidad para adaptar temas, scripts y flujo de trabajo
- integración práctica con laboratorios, HTB y bug bounty

## Stack

- Window Manager: i3
- Launcher: dmenu
- Barra: lemonbar
- Terminal: kitty
- Shell: zsh
- Prompt: starship
- Compositor: ninguno

## Estructura

```text
.
├── README.md
├── LICENSE
├── install.sh
├── uninstall.sh
├── config/
│   ├── kitty/
│   ├── dmenu/
│   ├── i3/
│   ├── starship/
│   └── zsh/
├── docs/
│   ├── screenshots/
│   ├── flujo_trabajo.md
│   ├── personalizacion.md
│   └── themes.md
├── scripts/
│   ├── bar.sh
│   ├── gomap.sh
│   ├── network.sh
│   ├── target.sh
│   ├── dmenu.sh
│   └── utils.sh
├── themes/
│   ├── default/
│   ├── kali-zen/
│   └── katana/
└── wallpapers/
```

## Características

- Barra ligera en `lemonbar` con IP local, VPN, Docker, TARGET, estado VPN y hora.
- TARGET persistente compartido entre shell y barra.
- Alias y funciones útiles para flujos de pentesting.
- Temas intercambiables sin rehacer toda la configuración.
- Instalación modular con backups automáticos.
- Configuración pensada para VMs y equipos modestos.

## Dependencias principales

Paquetes usados por defecto en Debian/Kali:

- `i3-wm`
- `i3lock`
- `dmenu`
- `lemonbar`
- `kitty`
- `zsh`
- `feh`
- `iproute2`
- `procps`
- `x11-xserver-utils`
- `xclip`
- `curl`
- `git`
- `gnupg`
- `mawk`
- `sed`
- `grep`

`gomap` y `starship` se pueden instalar como extras explícitos con `--with-gomap` y `--with-starship`. En perfiles `htb` y `bugbounty`, `gomap` se activa por defecto salvo que uses `--without-gomap`.

## Instalación

Clona el repositorio y ejecuta una instalación completa la primera vez:

```bash
git clone https://github.com/nexusfireman/kali-desktop-core.git
cd kali-desktop-core
chmod +x install.sh uninstall.sh scripts/*.sh
./install.sh
```

Sin argumentos, `./install.sh` equivale a `./install.sh --full`: instala dependencias, copia configuraciones, instala scripts y aplica el tema `default`.

Para hacer la primera instalación con otro tema:

```bash
./install.sh --full --theme kali-zen
./install.sh --full --theme katana
```

Después de una instalación base ya puedes cambiar solo el tema:

```bash
./install.sh --theme kali-zen
./install.sh --theme katana
```

Opciones útiles:

```bash
./install.sh --help
./install.sh --configs
./install.sh --interactive
./install.sh --dry-run --full --theme kali-zen
./install.sh --full --profile htb --theme kali-zen
```

## Actualización

Para actualizar una instalación existente:

```bash
git pull
./install.sh --configs
./install.sh --theme kali-zen
```

Si `git pull` se aborta por cambios locales, revisa primero qué ha cambiado:

```bash
git status --short
git diff -- scripts/bar.sh
```

Si no quieres conservar esos cambios locales, restaura el archivo afectado y repite la actualización:

```bash
git restore scripts/bar.sh
git pull
./install.sh --configs
```

La barra escribe errores de arranque en `~/.cache/kdc-bar.log`.

## Uso básico

### TARGET persistente

```bash
settarget 10.10.11.24
showtarget
cleartarget
```

El valor se guarda en `~/.config/target` y se integra con:

- la barra
- alias y funciones de `zsh`
- scripts de reconocimiento

### Flujo de pentesting

```bash
settarget 10.10.11.24
scan
```

La función `scan` valida que haya un TARGET activo y ejecuta:

```bash
gomap -s "$TARGET"
```

La función `extractPorts` parsea un resultado de `nmap`, copia los puertos al portapapeles y los imprime listos para reutilizar.

## Keybindings principales de i3

- `Mod+Return`: abrir terminal
- `Mod+d`: abrir dmenu
- `Mod+Shift+r`: recargar i3
- `Mod+Shift+q`: cerrar ventana
- `Mod+Shift+e`: salir de la sesión
- `Mod+Ctrl+l`: bloquear sesión
- `Mod+h/j/k/l`: mover foco
- `Mod+Shift+flechas`: mover ventanas
- `Mod+1..9`: cambiar workspace

## Temas

Incluye tres temas listos:

- `default`: base oscura equilibrada y legible
- `kali-zen`: gris azulado suave para sesiones largas
- `katana`: ultra oscuro con acentos rojos apagados

Cada tema define:

- paleta de colores
- aspecto de barra
- colores de terminal
- wallpaper incluido

Consulta [themes.md](docs/themes.md).

## Personalización

Documentación adicional:

- [Personalización](docs/personalizacion.md)
- [Temas](docs/themes.md)
- [Flujo de trabajo](docs/flujo_trabajo.md)

## Capturas

Rutas sugeridas para capturas:

- `docs/screenshots/desktop-overview.png`
- `docs/screenshots/workspaces-terminal.png`
- `docs/screenshots/target-workflow.png`

Puedes reemplazarlas por capturas reales del tema activo.

## Contribuir

Las contribuciones son bienvenidas si respetan la filosofía del proyecto:

- evitar bloat
- priorizar rendimiento
- mantener bajo consumo
- no añadir transparencias ni efectos innecesarios
- documentar cualquier cambio de flujo

Proceso recomendado:

1. Crear una rama por cambio.
2. Mantener scripts POSIX/Bash claros y comentados.
3. Probar en Kali Linux o Debian compatible.
4. Abrir un PR con contexto, impacto y capturas si aplica.
