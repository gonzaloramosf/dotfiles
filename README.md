# macOS dotfiles

This repository configures a macOS development environment with one installer.

The installer:

- installs Homebrew when it is missing;
- installs the formulae and applications listed in `brew.sh`;
- installs JetBrainsMono Nerd Font for Ghostty;
- installs the Zsh, Ghostty, skhd, and yabai configurations;
- applies the settings in `.macos` and `.firefox`;
- installs and loads the `no-sleep-speaker` LaunchAgent; and
- starts yabai and skhd.

The Zsh configuration is vanilla and does not install or load Oh My Zsh,
Powerlevel10k, or third-party Zsh plugins.

## Requirements

- macOS
- an internet connection
- an administrator account

The script may request the administrator password for Homebrew and macOS system
settings. Homebrew may also request installation of Apple's command-line tools.

## Install

Clone the repository, enter it, and run:

```sh
./install.sh
```

### Select what runs

The bottom of `install.sh` contains one line for each installation task. Comment
out any task you do not want to run. For example, to leave Homebrew completely
unchanged:

```bash
# run_step "Installing Homebrew packages and applications" install_homebrew_packages
run_step "Installing JetBrainsMono Nerd Font" install_font
run_step "Installing Zsh configuration" install_zsh_config
```

The same applies independently to the font, each configuration file, macOS
settings, Firefox settings, the no-sleep-speaker agent, and service startup.
Commenting out the Zsh task preserves the current `~/.zshrc`; commenting out the
Firefox task prevents the installer from changing Firefox's `user.js`.

Configuration files are copied to these locations:

```text
~/.zshrc
~/.config/ghostty/config.ghostty
~/.config/skhd/skhdrc
~/.config/yabai/yabairc
```

The script can be run again safely. Files with matching content are left alone.
When a destination contains different content or a symbolic link, it is renamed
with a timestamp such as `.zshrc.backup-20260623-120000` before the repository
file is copied. Legacy Ghostty, skhd, and yabai configuration locations are also
archived so they cannot override the files under `~/.config`.

After installation, open a new terminal. Log out or restart macOS for settings
that do not take effect immediately.

## Manual macOS permissions

macOS may require manual Accessibility permissions for yabai and skhd. Open:

```text
System Settings → Privacy & Security → Accessibility
```

Enable yabai and skhd there. Depending on the macOS version and the yabai
features you use, yabai may require additional security configuration.

The Firefox script prints its remaining manual display-setting step when it
runs. Finder also prints the sidebar and toolbar steps that cannot be reliably
automated.
