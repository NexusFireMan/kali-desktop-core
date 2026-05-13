# Seguridad

Kali Desktop Core está pensado para entornos propios o autorizados. Úsalo de forma responsable y únicamente en sistemas donde tengas permiso para instalar, modificar configuración y ejecutar herramientas de seguridad.

## Reportar problemas sensibles

No abras issues públicos si el reporte incluye:

- credenciales
- tokens
- rutas privadas
- datos personales
- logs con información sensible
- bugs explotables de forma peligrosa
- capturas con IPs, nombres de cliente o información privada

Para problemas sensibles, contacta con el maintainer por un canal privado disponible en el perfil de GitHub de NexusFireMan. Incluye una descripción mínima, impacto, pasos de reproducción y versión afectada, evitando datos que no sean necesarios.

## Alcance

El alcance de seguridad del proyecto incluye:

- `install.sh`
- `uninstall.sh`
- `scripts/*.sh`
- manejo de backups
- manipulación de `PATH`
- escritura en `~/.config`
- integración con `gomap` y APT
- ejecución de comandos externos desde scripts del entorno

## Fuera de alcance

Quedan fuera del alcance:

- vulnerabilidades de paquetes del sistema instalados por Kali/Debian
- herramientas externas no mantenidas en este repositorio
- cambios locales no reproducibles
- uso contra sistemas no autorizados

## Uso responsable

Este proyecto facilita un entorno de trabajo para pentesting y laboratorios. No autoriza ni justifica actividad ofensiva contra sistemas de terceros sin permiso explícito.
