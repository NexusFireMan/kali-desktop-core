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
- Terminal: alacritty
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
│   ├── alacritty/
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
- `alacritty`
- `zsh`
- `starship`
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

`gomap` es opcional, pero necesario para la función `scan`. Tras instalar las configuraciones puedes registrarlo con:

```bash
kdc-gomap
```

## Instalación

Clona el repositorio y ejecuta el instalador:

```bash
git clone https://github.com/nexusfireman/kali-desktop-core.git
cd kali-desktop-core
chmod +x install.sh uninstall.sh scripts/*.sh
./install.sh
```

Modos disponibles:

```bash
./install.sh --full
./install.sh --configs
./install.sh --theme kali-zen
./install.sh --theme katana
```

Opciones útiles:

```bash
./install.sh --help
./install.sh --theme default --configs
```

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
- `Mod+h/j/k/l`: mover foco
- `Mod+Shift+h/j/k/l`: mover ventanas
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
