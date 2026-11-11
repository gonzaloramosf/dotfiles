#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'This installer is for macOS.\n' >&2
  exit 1
fi

ZED_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ZED_SETTINGS_SOURCE="$ZED_SCRIPT_DIR/settings.json"
ZED_SETTINGS_TARGET="$HOME/.config/zed/settings.json"
ZED_FONT_FILE="$HOME/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"

if [[ ! -f "$ZED_SETTINGS_SOURCE" ]]; then
  printf 'Missing settings file: %s\n' "$ZED_SETTINGS_SOURCE" >&2
  exit 1
fi

if command -v brew >/dev/null 2>&1; then
  ZED_BREW_BIN="$(command -v brew)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  ZED_BREW_BIN=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
  ZED_BREW_BIN=/usr/local/bin/brew
else
  printf 'Installing Homebrew...\n'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    ZED_BREW_BIN=/opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    ZED_BREW_BIN=/usr/local/bin/brew
  else
    printf 'Homebrew installation finished, but brew was not found.\n' >&2
    exit 1
  fi
fi

eval "$("$ZED_BREW_BIN" shellenv)"

if [[ -d /Applications/Zed.app ]] || "$ZED_BREW_BIN" list --cask zed >/dev/null 2>&1; then
  printf 'Zed is already installed.\n'
else
  "$ZED_BREW_BIN" install --cask zed
fi

if [[ -f "$ZED_FONT_FILE" ]]; then
  printf 'JetBrainsMono Nerd Font is already installed.\n'
else
  "$ZED_BREW_BIN" install --cask font-jetbrains-mono-nerd-font
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
