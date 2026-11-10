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

mkdir -p "$(dirname -- "$ZED_SETTINGS_TARGET")"
if [[ -e "$ZED_SETTINGS_TARGET" || -L "$ZED_SETTINGS_TARGET" ]]; then
  if cmp -s "$ZED_SETTINGS_SOURCE" "$ZED_SETTINGS_TARGET"; then
    printf 'Zed settings are already up to date.\n'
  else
    ZED_SETTINGS_BACKUP="${ZED_SETTINGS_TARGET}.backup-$(date +%Y%m%d-%H%M%S)-$$"
    mv "$ZED_SETTINGS_TARGET" "$ZED_SETTINGS_BACKUP"
    printf 'Backed up existing settings to %s\n' "$ZED_SETTINGS_BACKUP"
    install -m 600 "$ZED_SETTINGS_SOURCE" "$ZED_SETTINGS_TARGET"
    printf 'Installed Zed settings.\n'
  fi
else
  install -m 600 "$ZED_SETTINGS_SOURCE" "$ZED_SETTINGS_TARGET"
  printf 'Installed Zed settings.\n'
fi

# Install panel shortcut overrides alongside settings.
ZED_KEYMAP_SOURCE="$ZED_SCRIPT_DIR/keymap.json"
ZED_KEYMAP_TARGET="$HOME/.config/zed/keymap.json"
if ! cmp -s "$ZED_KEYMAP_SOURCE" "$ZED_KEYMAP_TARGET"; then
  if [[ -e "$ZED_KEYMAP_TARGET" || -L "$ZED_KEYMAP_TARGET" ]]; then
    ZED_KEYMAP_BACKUP="${ZED_KEYMAP_TARGET}.backup-$(date +%Y%m%d-%H%M%S)-$$"
    mv "$ZED_KEYMAP_TARGET" "$ZED_KEYMAP_BACKUP"
    printf 'Backed up existing keymap to %s\n' "$ZED_KEYMAP_BACKUP"
  fi
  install -m 600 "$ZED_KEYMAP_SOURCE" "$ZED_KEYMAP_TARGET"
  printf 'Installed Zed keymap.\n'
fi

if open -a Zed; then
  printf 'Zed is ready. It will install JetBrains Icons from the extension gallery.\n'
else
  printf 'Open Zed to finish installing JetBrains Icons.\n'
fi
