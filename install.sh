#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

DOTFILES_DIR="$PWD"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
FONT_DIR="$HOME/Library/Fonts"
ITERM_PLIST_SOURCE="$DOTFILES_DIR/iterm2/com.googlecode.iterm2.plist"
ITERM_PLIST_TARGET="$HOME/Library/Preferences/com.googlecode.iterm2.plist"

echo "Starting dotfiles installation..."

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Installing Homebrew packages..."
brew bundle --file "$DOTFILES_DIR/Brewfile"

echo "Linking shell config..."
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/p10k/.p10k.zsh" "$HOME/.p10k.zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "Installing Zsh plugins..."

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

echo "Installing JetBrainsMono Nerd Font..."

mkdir -p "$FONT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -L "$FONT_URL" -o "$TMP_DIR/JetBrainsMono.zip"
unzip -q "$TMP_DIR/JetBrainsMono.zip" -d "$TMP_DIR/JetBrainsMono"

find "$TMP_DIR/JetBrainsMono" \
  \( -name "*.ttf" -o -name "*.otf" \) \
  -exec cp {} "$FONT_DIR" \;

echo "JetBrainsMono Nerd Font installed."

if [ -f "$ITERM_PLIST_SOURCE" ]; then
  echo "Installing iTerm2 preferences..."

  mkdir -p "$HOME/Library/Preferences"

  if pgrep -x "iTerm2" >/dev/null; then
    echo "Closing iTerm2 before copying preferences..."
    osascript -e 'quit app "iTerm2"' || true
    sleep 2
  fi

  cp "$ITERM_PLIST_SOURCE" "$ITERM_PLIST_TARGET"

  defaults read com.googlecode.iterm2 >/dev/null 2>&1 || true

  echo "iTerm2 preferences installed."
else
  echo "Skipping iTerm2 preferences: $ITERM_PLIST_SOURCE not found."
fi

echo "Installation complete. Restart iTerm2."
