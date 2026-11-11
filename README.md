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

Running the installer replaces destination configuration files with the repository
versions without creating backups.

After installation, open a new terminal. Log out or restart macOS for settings
that do not take effect immediately.

## Manual macOS permissions

macOS may require manual Accessibility permissions for yabai and skhd. Open:

```text
System Settings → Privacy & Security → Accessibility
```

Enable yabai and skhd there. Depending on the macOS version and the yabai
features you use, yabai may require additional security configuration.
