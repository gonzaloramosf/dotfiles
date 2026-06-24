#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"

info() {
  printf '\n==> %s\n' "$1"
}

warn() {
  printf 'Warning: %s\n' "$1" >&2
}

run_step() {
  local description="$1"
  shift

  info "$description"
  "$@"
}

install_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$source" "$target"; then
    printf 'Already up to date: %s\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.backup-${BACKUP_TIMESTAMP}"
    mv "$target" "$backup"
    printf 'Backed up %s to %s\n' "$target" "$backup"
  fi

  cp "$source" "$target"
  printf 'Installed %s\n' "$target"
}

archive_legacy_file() {
  local target="$1"

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.backup-${BACKUP_TIMESTAMP}"
    mv "$target" "$backup"
    printf 'Archived legacy config %s to %s\n' "$target" "$backup"
  fi
}

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

  info "Installing Homebrew"
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

install_homebrew_packages() {
  load_homebrew
  brew bundle --file "$DOTFILES_DIR/brew.sh"
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

install_no_sleep_speaker() {
  local source_dir="$DOTFILES_DIR/no-sleep-speaker"
  local install_dir="$HOME/.local/no-sleep-speaker"
  local agent_dir="$HOME/Library/LaunchAgents"
  local agent="$agent_dir/com.no-sleep-speaker.plist"
  local domain="gui/$(id -u)"

  mkdir -p "$install_dir" "$agent_dir"
  cp "$source_dir/no-sleep-speaker.wav" "$install_dir/no-sleep-speaker.wav"
  cp "$source_dir/no-sleep-speaker.sh" "$install_dir/no-sleep-speaker.sh"
  chmod +x "$install_dir/no-sleep-speaker.sh"

  # The checked-in script documents the original path. Make the installed
  # copy point to its portable location under the current user's home.
  sed -i '' \
    "s|^/usr/bin/afplay .*|/usr/bin/afplay \"$install_dir/no-sleep-speaker.wav\"|" \
    "$install_dir/no-sleep-speaker.sh"

  cp "$source_dir/com.no-sleep-speaker.plist" "$agent"
  /usr/libexec/PlistBuddy -c \
    "Set :ProgramArguments:0 $install_dir/no-sleep-speaker.sh" "$agent"

  launchctl bootout "$domain" "$agent" >/dev/null 2>&1 || true
  if launchctl bootstrap "$domain" "$agent"; then
    launchctl enable "$domain/com.no-sleep-speaker"
    launchctl kickstart -k "$domain/com.no-sleep-speaker"
  else
    warn "Could not load the no-sleep-speaker LaunchAgent."
  fi
}

start_window_services() {
  if command -v yabai >/dev/null 2>&1; then
    yabai --start-service >/dev/null 2>&1 \
      || yabai --restart-service >/dev/null 2>&1 \
      || warn "yabai could not start; check its macOS permissions."
  fi

  if command -v skhd >/dev/null 2>&1; then
    skhd --start-service >/dev/null 2>&1 \
      || skhd --restart-service >/dev/null 2>&1 \
      || warn "skhd could not start; check its macOS permissions."
  fi
}

install_zsh_config() {
  install_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
}

install_ghostty_config() {
  install_file "$DOTFILES_DIR/config.ghostty" \
    "$HOME/.config/ghostty/config.ghostty"
  archive_legacy_file \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  archive_legacy_file \
    "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
}

install_skhd_config() {
  install_file "$DOTFILES_DIR/skhdrc" "$HOME/.config/skhd/skhdrc"
  archive_legacy_file "$HOME/.skhdrc"
}

install_yabai_config() {
  install_file "$DOTFILES_DIR/yabairc" "$HOME/.config/yabai/yabairc"
  archive_legacy_file "$HOME/.yabairc"
}

apply_macos_settings() {
  bash "$DOTFILES_DIR/.macos"
}

apply_firefox_settings() {
  bash "$DOTFILES_DIR/.firefox"
}

if [[ "$(uname -s)" != Darwin ]]; then
  printf 'This installer supports macOS only.\n' >&2
  exit 1
fi

# Installation tasks ---------------------------------------------------------
# Comment out any one line below to skip that task.

run_step "Installing Homebrew packages and applications" install_homebrew_packages
run_step "Installing JetBrainsMono Nerd Font" install_font
run_step "Installing Zsh configuration" install_zsh_config
run_step "Installing Ghostty configuration" install_ghostty_config
run_step "Installing skhd configuration" install_skhd_config
run_step "Installing yabai configuration" install_yabai_config
run_step "Installing the no-sleep-speaker LaunchAgent" install_no_sleep_speaker
run_step "Applying macOS settings" apply_macos_settings
run_step "Applying Firefox settings" apply_firefox_settings
run_step "Starting yabai and skhd" start_window_services

info "Installation complete"
printf '%s\n' \
  'Open a new terminal to load the Zsh configuration.' \
  'Some macOS settings require logging out or restarting.' \
  'Grant Accessibility permissions to yabai and skhd if macOS prompts you.'
