#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/scripts/install-common.sh"

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
    # Replace the destination itself, including symlinks.
    rm -f -- "$target"
  fi

  cp "$source" "$target"
  printf 'Installed %s\n' "$target"
}

install_homebrew_packages() {
  load_homebrew
  brew bundle --file "$DOTFILES_DIR/brew.sh"
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
  if [[ "${1:-all}" == all || "${1:-all}" == yabai ]] && command -v yabai >/dev/null 2>&1; then
    yabai --start-service >/dev/null 2>&1 \
      || yabai --restart-service >/dev/null 2>&1 \
      || warn "yabai could not start; check its macOS permissions."
  fi

  if [[ "${1:-all}" == all || "${1:-all}" == skhd ]] && command -v skhd >/dev/null 2>&1; then
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
}

install_skhd_config() {
  install_file "$DOTFILES_DIR/skhdrc" "$HOME/.config/skhd/skhdrc"
}

install_yabai_config() {
  install_file "$DOTFILES_DIR/yabairc" "$HOME/.config/yabai/yabairc"
}

install_zed() {
  bash "$DOTFILES_DIR/zed/install.sh" --skip-dependencies
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

# Validate every requested component
for component in "$@"; do
  case "$component" in
    homebrew|jetbrains-font|zed|zsh|ghostty|skhd|yabai|no-sleep-speaker|macos-settings|firefox-settings) ;;
    *)
      printf 'Unknown installation component: %s\n' "$component" >&2
      exit 1
      ;;
  esac
done

if [[ "$#" -eq 0 ]]; then
  run_step "Installing Homebrew packages and applications" install_homebrew_packages
  run_step "Installing JetBrainsMono Nerd Font" install_font
  run_step "Installing Zed and its configuration" install_zed
  run_step "Installing Zsh configuration" install_zsh_config
  run_step "Installing Ghostty configuration" install_ghostty_config
  run_step "Installing skhd configuration" install_skhd_config
  run_step "Installing yabai configuration" install_yabai_config
  run_step "Installing the no-sleep-speaker LaunchAgent" install_no_sleep_speaker
  run_step "Applying macOS settings" apply_macos_settings
  run_step "Applying Firefox settings" apply_firefox_settings
  run_step "Starting yabai and skhd" start_window_services
else
  for component in "$@"; do
    case "$component" in
      homebrew)
        run_step "Installing Homebrew packages and applications" install_homebrew_packages
        ;;
      jetbrains-font)
        run_step "Installing JetBrainsMono Nerd Font" install_font
        ;;
      zed)
        run_step "Installing Zed and its configuration" bash "$DOTFILES_DIR/zed/install.sh"
        ;;
      zsh)
        run_step "Installing Zsh configuration" install_zsh_config
        ;;
      ghostty)
        run_step "Installing Ghostty configuration" install_ghostty_config
        ;;
      skhd)
        run_step "Installing skhd configuration" install_skhd_config
        start_window_services skhd
        ;;
      yabai)
        run_step "Installing yabai configuration" install_yabai_config
        start_window_services yabai
        ;;
      no-sleep-speaker)
        run_step "Installing the no-sleep-speaker LaunchAgent" install_no_sleep_speaker
        ;;
      macos-settings)
        run_step "Applying macOS settings" apply_macos_settings
        ;;
      firefox-settings)
        run_step "Applying Firefox settings" apply_firefox_settings
        ;;
    esac
  done
fi

info "Installation complete"
printf '%s\n' \
  'Open a new terminal to load the Zsh configuration.' \
  'Some macOS settings require logging out or restarting.' \
  'Grant Accessibility permissions to yabai and skhd if macOS prompts you.'
