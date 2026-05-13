# Roadmap

Este roadmap describe direcciones posibles para Kali Desktop Core. No implica fechas ni compromisos cerrados.

## Validación y CI

- Mejorar validaciones automáticas de shell.
- Añadir comprobaciones de regresión para `--dry-run`.
- Revisar casos de instalación parcial y actualización con `--configs`.
- Mantener ShellCheck como línea base mínima.

## Diagnóstico

- Mejorar `kdc-doctor` con mensajes más accionables.
- Añadir comprobaciones más claras para i3, lemonbar, PATH y theme activo.
- Diferenciar mejor warnings esperables de errores que bloquean el entorno.

## Documentación

- Ampliar documentación de themes y variables de barra.
- Mejorar documentación de `uninstall` y rollback.
- Documentar escenarios de VM, HTB y bug bounty con ejemplos concretos.
- Mantener capturas representativas de instalación y uso real.

## Flujo de pentesting

- Explorar integraciones opcionales con `gomap` y flujos de reconocimiento.
- Mejorar ejemplos de TARGET, VPN, Docker y refresco de barra.
- Mantener las integraciones como opt-in cuando añadan peso o dependencias.

## Límites del proyecto

- No añadir bloat.
- No añadir efectos visuales pesados.
- No convertir el entorno en un instalador generalista multi-desktop.
- No priorizar estética sobre rendimiento, foco y bajo consumo.
