#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This installer is for macOS.\n' >&2
  exit 1
fi

ZED_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ZED_SETTINGS_SOURCE="$ZED_SCRIPT_DIR/settings.json"
ZED_SETTINGS_TARGET="$HOME/.config/zed/settings.json"
source "$ZED_SCRIPT_DIR/../scripts/install-common.sh"

case "${1:-}" in
  "")
    load_homebrew
    install_font
    ;;
  --skip-dependencies)
    ;;
  *)
    printf 'Usage: %s [--skip-dependencies]\n' "$0" >&2
    exit 1
    ;;
esac

if [[ ! -f "$ZED_SETTINGS_SOURCE" ]]; then
  printf 'Missing settings file: %s\n' "$ZED_SETTINGS_SOURCE" >&2
  exit 1
fi

if [[ -d /Applications/Zed.app ]] || brew list --cask zed >/dev/null 2>&1; then
  printf 'Zed is already installed.\n'
else
  brew install --cask zed
fi

install_config_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname -- "$target")"
  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$source" "$target"; then
    printf 'Already up to date: %s\n' "$target"
    return
  fi

  # Replace symlinks themselves rather than writing through to their targets.
  if [[ -e "$target" || -L "$target" ]]; then
    rm -f -- "$target"
  fi
  install -m 600 "$source" "$target"
  printf 'Installed %s\n' "$target"
}

install_config_file "$ZED_SETTINGS_SOURCE" "$ZED_SETTINGS_TARGET"
install_config_file "$ZED_SCRIPT_DIR/keymap.json" "$HOME/.config/zed/keymap.json"

if open -a Zed; then
  printf 'Zed is ready. It will install JetBrains Icons from the extension gallery.\n'
else
  printf 'Open Zed to finish installing JetBrains Icons.\n'
fi
