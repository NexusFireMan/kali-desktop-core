# Personalización

## Themes

El theme activo se guarda en:

```bash
~/.config/kali-desktop-core/theme.conf
```

Puedes cambiarlo reinstalando solo el theme:

```bash
./install.sh --theme kali-zen
```

## Añadir un nuevo theme

Cada theme vive en su propia carpeta dentro de `themes/` y define como mínimo:

- `theme.conf`
- `kitty.theme.conf`
- una imagen de wallpaper

Ejemplo de claves en `theme.conf`:

```bash
THEME_NAME="mi-theme"
WALLPAPER="mi-fondo.jpg"
BAR_BG="#0d0f12"
BAR_FG="#d0d0d0"
BAR_MUTED="#7f8792"
BAR_ACCENT="#8fb7ff"
BAR_ALERT="#c75b65"
BAR_FONT="fixed"
BAR_HEIGHT=24
BAR_MARGIN_X=6
BAR_OFFSET_Y=0
BAR_WS_ACTIVE="$BAR_ALERT"
BAR_WS_INACTIVE="$BAR_MUTED"
BAR_WS_COUNT=5
BAR_WS_STYLE="numbers"
BAR_WS_SYMBOL="•"
BAR_WS_SEPARATOR=" "
BAR_POWER_ICON="PWR"
BAR_POWER_COLOR="$BAR_ALERT"
BAR_BAT_LOW_THRESHOLD=20
BAR_BAT_LABEL="BAT"
BAR_BAT_CHARGING_SUFFIX="+"
```

## Ajustar la barra

La barra se genera desde `scripts/bar.sh`. Para extenderla:

1. Añade una función o reutiliza `scripts/network.sh`.
2. Inserta un nuevo segmento en `render_line`.
3. Mantén el refresco ligero evitando comandos costosos dentro del bucle.

Variables principales de barra:

- `BAR_FONT`: fuente usada por `lemonbar`.
- `BAR_HEIGHT`: altura de la barra.
- `BAR_MARGIN_X`: margen horizontal.
- `BAR_OFFSET_Y`: desplazamiento vertical.
- `BAR_WS_STYLE`: estilo del indicador central, `numbers` o `dots`.
- `BAR_WS_ACTIVE`: color del workspace activo.
- `BAR_WS_INACTIVE`: color de los workspaces inactivos.
- `BAR_POWER_ICON`: texto del botón de sesión.
- `BAR_POWER_COLOR`: color del botón de sesión.

El indicador central de workspaces muestra números por defecto (`1 2 3 4 5`) para no depender de fuentes con símbolos especiales. Puedes ajustar `BAR_WS_ACTIVE`, `BAR_WS_INACTIVE`, `BAR_WS_COUNT` y `BAR_WS_STYLE`. Si defines `BAR_WS_STYLE="dots"`, usa `BAR_WS_SYMBOL` y `BAR_WS_SEPARATOR`.

La fuente por defecto de `lemonbar` es `fixed` por compatibilidad con instalaciones limpias. Puedes cambiar `BAR_FONT` si tienes otra fuente compatible disponible.

La geometría de `lemonbar` se controla con `BAR_HEIGHT`, `BAR_MARGIN_X` y `BAR_OFFSET_Y`. El margen horizontal por defecto es `6`, de modo que la barra no toca los bordes y encaja mejor con los gaps de i3.

El icono de sesión de la derecha usa `kdc-power-menu`. Puedes ajustar `BAR_POWER_ICON` y `BAR_POWER_COLOR` desde el theme.

El segmento de batería aparece solo si existe `/sys/class/power_supply/BAT*`. Puedes ajustar `BAR_BAT_LOW_THRESHOLD`, `BAR_BAT_LABEL` y `BAR_BAT_CHARGING_SUFFIX` desde el theme.

## Shell y productividad

La lógica de `TARGET` y funciones de uso diario está en:

- `config/zsh/.zshrc`
- `scripts/target.sh`

Mantén `~/.config/target` como única fuente de verdad para evitar inconsistencias.
