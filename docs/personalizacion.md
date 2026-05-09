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
BAR_FONT="JetBrainsMono Nerd Font:size=10"
```

## Ajustar la barra

La barra se genera desde `scripts/bar.sh`. Para extenderla:

1. Añade una función o reutiliza `scripts/network.sh`.
2. Inserta un nuevo segmento en `render_line`.
3. Mantén el refresco ligero evitando comandos costosos dentro del bucle.

## Shell y productividad

La lógica de `TARGET` y funciones de uso diario está en:

- `config/zsh/.zshrc`
- `scripts/target.sh`

Mantén `~/.config/target` como única fuente de verdad para evitar inconsistencias.
