# DebHypr

My Debian 13 (Trixie) Hyprland dotfiles and a one-command restore installer.

It installs only the applications I use:

- Firefox
- Ghostty

It also installs and restores configuration for Hyprland, Fastfetch, and Starship. Hyprland is intentionally **not** installed because this repository is meant for a new Debian system where Hyprland is already installed.

## Install

```bash
git clone https://github.com/YOUR-GITHUB-USERNAME/DebHypr.git
cd DebHypr
chmod +x install.sh
./install.sh
```

The installer needs `sudo` only to install packages. Before replacing a config, it saves the existing version in a timestamped directory such as `~/.config-backup-debhypr-20260911-120000`.

## What gets installed

| Repository file | Installed location |
| --- | --- |
| `config/hypr/hyprland.conf` | `~/.config/hypr/hyprland.conf` |
| `config/ghostty/config.ghostty` | `~/.config/ghostty/config.ghostty` |
| `config/fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` |
| `config/starship.toml` | `~/.config/starship.toml` |

## Shell setup

If needed, add the following to `~/.bashrc` to enable the prompt:

```bash
eval "$(starship init bash)"
```

Your Hyprland config currently has optional bindings for Dolphin, Hyprlauncher, Steam, Spotify, and two local scripts. Those are preserved as part of your configuration, but this installer does not install them.
