export ZDOTDIR="${HOME}"
export STARSHIP_CONFIG="${HOME}/.config/starship.toml"
export PATH="${HOME}/.local/bin:${PATH}"

source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

# TARGET global persistente para flujos de pentesting.
TARGET_FILE="${HOME}/.config/target"

if [[ -s "$TARGET_FILE" ]]; then
  export TARGET="$(<"$TARGET_FILE")"
fi

settarget() {
  if [[ -z "${1:-}" ]]; then
    echo "Uso: settarget <valor>"
    return 1
  fi

  mkdir -p "$(dirname "$TARGET_FILE")"
  printf '%s\n' "$1" > "$TARGET_FILE"
  export TARGET="$1"
  kdc-refresh 2>/dev/null || true
  echo "TARGET establecido: $TARGET"
}

cleartarget() {
  mkdir -p "$(dirname "$TARGET_FILE")"
  : > "$TARGET_FILE"
  unset TARGET
  kdc-refresh 2>/dev/null || true
  echo "TARGET limpiado"
}

showtarget() {
  if [[ -z "${TARGET:-}" ]]; then
    echo "TARGET no establecido"
  else
    echo "TARGET = $TARGET"
  fi
}

refreshbar() {
  kdc-refresh 2>/dev/null || true
}

extractPorts() {
  if [[ $# -lt 1 ]]; then
    echo "Uso: extractPorts <archivo_nmap>"
    return 1
  fi

  local file="$1"
  [[ -f "$file" ]] || { echo "Archivo no encontrado: $file"; return 1; }

  local ports
  ports="$(grep -Eo '[0-9]+/tcp[[:space:]]+open|[0-9]+/udp[[:space:]]+open' "$file" | cut -d/ -f1 | paste -sd, -)"

  if [[ -z "$ports" ]]; then
    echo "No se encontraron puertos abiertos en $file"
    return 1
  fi

  printf '%s' "$ports" | xclip -selection clipboard 2>/dev/null || true
  echo "Puertos copiados: $ports"
}

alias ll='ls -lah --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ipbrief='ip -br a'
alias ports='ss -tulpn'
alias tshow='showtarget'
alias rb='refreshbar'

scan() {
  if [[ -z "${TARGET:-}" ]]; then
    echo "TARGET no establecido. Usa: settarget <ip|host>"
    return 1
  fi

  if ! command -v gomap >/dev/null 2>&1; then
    echo "gomap no está instalado. Ejecuta: kdc-gomap"
    return 1
  fi

  gomap -s "$TARGET"
}

source_if_exists /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source_if_exists /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%F{blue}%~%f %# '
fi
