# Contribuir

Gracias por considerar una contribución a Kali Desktop Core. Este proyecto busca ser un entorno de trabajo diario para seguridad ofensiva, no una colección general de herramientas.

## Filosofía

Las contribuciones deben respetar estos criterios:

- minimalismo antes que acumulación de opciones
- rendimiento real y bajo consumo
- estabilidad para sesiones largas
- integración práctica con flujos de pentesting
- evitar bloat, efectos visuales pesados y dependencias innecesarias
- mantener el entorno entendible y fácil de auditar

## Flujo recomendado

1. Abre un issue o comenta uno existente para explicar el cambio.
2. Crea una rama pequeña y enfocada.
3. Implementa el cambio con el menor alcance razonable.
4. Ejecuta las validaciones locales.
5. Abre un pull request con contexto, pruebas y capturas si cambia la UI.
6. Espera revisión antes de hacer merge.

## Convenciones de ramas

Usa nombres descriptivos y cortos:

- `docs/<descripcion>`
- `fix/<descripcion>`
- `ci/<descripcion>`
- `feat/<descripcion>`

## Convenciones de commits

Prefiere mensajes claros con estos prefijos:

- `docs:`
- `fix:`
- `ci:`
- `test:`
- `feat:`
- `chore:`

## Validaciones locales

Antes de abrir un PR, ejecuta:

```bash
bash -n install.sh uninstall.sh scripts/*.sh
shellcheck install.sh uninstall.sh scripts/*.sh
```

Si cambias la experiencia visual, prueba el resultado en una VM antes de aplicarlo en tu sistema principal.

## Seguridad y privacidad

No subas:

- binarios generados
- credenciales
- tokens
- logs privados
- rutas personales sensibles
- capturas con IPs sensibles, nombres de cliente o información de laboratorio no publicable

Si el cambio afecta a instalación, backups, PATH, APT o ejecución de comandos, describe el riesgo y cómo lo has probado.
