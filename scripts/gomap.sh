#!/usr/bin/env bash
set -euo pipefail

KEYRING_URL="https://nexusfireman.github.io/gomap/gomap-archive-keyring.gpg"
KEYRING_PATH="/usr/share/keyrings/gomap-archive-keyring.gpg"
REPO_LINE="deb [signed-by=/usr/share/keyrings/gomap-archive-keyring.gpg] https://nexusfireman.github.io/gomap stable main"
REPO_FILE="/etc/apt/sources.list.d/gomap.list"

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Dependencia no encontrada: $cmd"
    exit 1
  }
}

require_command curl
require_command gpg
require_command sudo
require_command tee
require_command apt

echo "[*] Instalando keyring de gomap"
curl -fsSL "$KEYRING_URL" | sudo gpg --dearmor --yes -o "$KEYRING_PATH"

echo "[*] Registrando repositorio APT de gomap"
printf '%s\n' "$REPO_LINE" | sudo tee "$REPO_FILE" > /dev/null

echo "[*] Actualizando índices de paquetes"
sudo apt update

echo "[*] Instalando gomap"
sudo apt install -y gomap

echo "[*] gomap instalado correctamente"
