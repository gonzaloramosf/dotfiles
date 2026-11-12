#!/usr/bin/env bash
# Shared prerequisites for the main and standalone Zed installers.
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"

load_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return
  fi

  printf 'Installing Homebrew...\n'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Homebrew was installed but could not be found.\n' >&2
    exit 1
  fi
}

install_font() {
  local font_dir="$HOME/Library/Fonts"

  mkdir -p "$font_dir"
  if [[ -n "$(find "$font_dir" -maxdepth 1 -iname 'JetBrainsMono*NerdFont*' -print -quit)" ]]; then
    printf 'JetBrainsMono Nerd Font is already installed.\n'
    return
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  curl -fsSL "$FONT_URL" -o "$temp_dir/JetBrainsMono.zip"
  unzip -q "$temp_dir/JetBrainsMono.zip" -d "$temp_dir/JetBrainsMono"
  find "$temp_dir/JetBrainsMono" -type f \
    \( -name '*.ttf' -o -name '*.otf' \) \
    -exec cp -f {} "$font_dir" \;
  rm -rf "$temp_dir"
}
