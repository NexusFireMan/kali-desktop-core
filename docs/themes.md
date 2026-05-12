# Themes

## Objetivo

El sistema de themes separa la identidad visual de la lógica del entorno. Así puedes ajustar colores y matices sin tocar scripts ni reescribir configuraciones enteras.

## Componentes tematizables

Cada theme controla:

- colores de `lemonbar`
- indicador central de workspaces de `lemonbar`
- colores de `kitty`
- acentos visuales
- wallpaper real aplicado por `feh`

## Themes incluidos

### default

Base equilibrada con tonos fríos, buena legibilidad y contraste moderado.

### kali-zen

Tema relajado con azul grisáceo. Adecuado para sesiones largas, debugging y documentación.

### katana

Tema más austero y profundo, con acentos cálidos apagados para mantener la interfaz sobria.

## Buenas prácticas

- No usar `#FFFFFF`.
- Evitar contrastes agresivos.
- Mantener fondos estables entre `#090b0d` y `#101319`.
- Reservar el color de alerta para eventos importantes.

## Workspaces en la barra

El indicador central de workspaces usa estas claves opcionales en `theme.conf`:

```bash
BAR_WS_ACTIVE="$BAR_ALERT"
BAR_WS_INACTIVE="$BAR_MUTED"
BAR_WS_COUNT=5
BAR_WS_STYLE="numbers"
BAR_WS_SYMBOL="•"
BAR_WS_SEPARATOR=" "
```

Si no se definen, `scripts/bar.sh` aplica valores por defecto basados en la paleta del theme. Por defecto se muestran números (`1 2 3 4 5`) para mantener visibilidad en una Kali limpia; `BAR_WS_STYLE="dots"` permite volver al modo de símbolos.

La fuente de barra incluida en los themes es `fixed`, una fuente X11 básica que `lemonbar` carga de forma fiable. Las Nerd Fonts pueden usarse como personalización opcional, pero no son necesarias para que workspaces y `PWR` sean visibles.

## Seguridad

Los themes son archivos de configuración en formato Bash que son leídos por los scripts del proyecto. Revisa themes de terceros antes de instalarlos.
