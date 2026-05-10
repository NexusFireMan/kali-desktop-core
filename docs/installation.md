# Instalación

Esta guía documenta el instalador de Kali Desktop Core. El script está pensado para Kali Linux o Debian compatible, especialmente en máquinas virtuales y entornos de laboratorio.

Antes de empezar:

```bash
git clone https://github.com/nexusfireman/kali-desktop-core.git
cd kali-desktop-core
chmod +x install.sh uninstall.sh scripts/*.sh
```

## Instalación completa

```bash
./install.sh
```

Sin argumentos, el instalador mantiene la semántica clásica y equivale a `./install.sh --full`. Muestra un plan previo, instala paquetes base, copia configuraciones, instala scripts y aplica el tema `default`.

Para indicar el modo de forma explícita:

```bash
./install.sh --full
```

## Instalación interactiva

```bash
./install.sh --interactive
```

El modo interactivo usa preguntas simples con `read`. Permite elegir perfil, tema y extras sin depender de herramientas como `dialog`, `whiptail` o `gum`.

## Dry-run

```bash
./install.sh --dry-run --full --theme kali-zen
```

El dry-run muestra qué haría el instalador sin aplicar cambios. No ejecuta `apt-get`, no copia archivos, no crea backups, no modifica `/etc/apt` y no ejecuta instaladores externos.

Es útil para revisar el plan antes de tocar una VM o una instalación de trabajo.

## Perfil HTB con gomap

```bash
./install.sh --full --profile htb --theme kali-zen --with-gomap
```

Los perfiles disponibles son:

- `minimal`: base reducida.
- `vm`: perfil general para máquinas virtuales.
- `htb`: orientado a laboratorios tipo Hack The Box.
- `bugbounty`: orientado a sesiones largas de reconocimiento y pruebas web.
- `custom`: punto de partida manual.

En perfiles `htb` y `bugbounty`, `gomap` se activa por defecto salvo que uses `--without-gomap`.

## Reinstalar configuraciones

```bash
./install.sh --configs
```

Este modo copia configuraciones y scripts sin reinstalar dependencias APT. Crea backups con timestamp cuando encuentra archivos existentes.

## Cambiar tema

```bash
./install.sh --theme katana
```

Este modo aplica solo el tema indicado. Los temas se leen desde el directorio `themes/`, por lo que no dependen de una lista hardcodeada en el instalador.

## Diagnóstico

```bash
./install.sh --run-doctor
```

Si `kdc-doctor` ya está instalado, lo ejecuta al final. Si ejecutas `--configs` o `--full`, `scripts/doctor.sh` se instala como:

```bash
~/.local/bin/kdc-doctor
```

También puedes lanzarlo directamente:

```bash
kdc-doctor
kdc-doctor --strict
```

El modo normal permite warnings esperables, como no tener VPN activa. El modo `--strict` trata la barra y `starship` como requisitos más duros.

## Starship

```bash
./install.sh --full --with-starship
./install.sh --full --without-starship
```

Kali Desktop Core incluye una configuración para Starship, pero no ejecuta el instalador externo salvo que uses `--with-starship` o lo confirmes en modo interactivo.

Si eliges `--without-starship`, la shell sigue funcionando con un prompt básico.

## gomap

```bash
./install.sh --full --with-gomap
./install.sh --full --without-gomap
```

Con `--with-gomap`, el instalador registra el repositorio APT:

```text
https://nexusfireman.github.io/gomap
```

Después ejecuta `apt-get update` e instala el paquete `gomap`. El helper `kdc-gomap` queda disponible para reparar o reinstalar ese repositorio manualmente.

## Recomendaciones para Kali en VM

- Usa una sesión X11 para i3 y lemonbar.
- Ejecuta el instalador como usuario normal con `sudo`, no como root.
- Comprueba que `~/.local/bin` está en `PATH`.
- Prueba primero con `--dry-run` si ya tienes configuraciones personalizadas.
- Tras instalar o cambiar configs de i3, cierra sesión y vuelve a entrar o recarga i3 con `Mod+Shift+r`.
- Si la barra no aparece, revisa `~/.cache/kdc-bar.log` y ejecuta `kdc-doctor`.
