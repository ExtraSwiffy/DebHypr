# DebHypr

My Debian 13 (Trixie) Hyprland dotfiles and a one-command restore installer.

It installs only the applications I use:

- Firefox
- Ghostty

It also installs and restores configuration for Hyprland, Fastfetch, and Starship, plus my Hyprland console-mode and reboot helper scripts. Hyprland is intentionally **not** installed because this repository is meant for a new Debian system where Hyprland is already installed.

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
| `scripts/local/bin/start-console-after-hyprland` | `~/.local/bin/start-console-after-hyprland` |
| `scripts/local/bin/desktop-to-console` | `~/.local/bin/desktop-to-console` |
| `scripts/local/bin/console-mode-session` | `~/.local/bin/console-mode-session` |
| `scripts/sbin/reboot-to-windows` | `/usr/local/sbin/reboot-to-windows` |

## Shell setup

If needed, add the following to `~/.bashrc` to enable the prompt:

```bash
eval "$(starship init bash)"
```

## Hyprland keybindings and scripts

All current Hyprland keybindings are kept exactly as they are in `hyprland.conf`, including:

- `SUPER + DELETE`: switch to the Steam/Gamescope console session.
- `SUPER + TAB`: reboot to Windows.

The console session scripts require Gamescope and Steam. They are restored but deliberately not installed by this repository, because the selected application list is Firefox and Ghostty only.

The Windows reboot helper contains the exact GRUB menu ID from this machine: `osprober-efi-24E5-3B1F`. On another computer or after changing the Windows EFI partition, update that value in `scripts/sbin/reboot-to-windows` before running the installer. The `SUPER + TAB` binding uses `sudo -n`, so it also needs a deliberate passwordless-sudo rule for that single helper; the installer does not create sudoers rules.

Other optional keybindings refer to Dolphin, Hyprlauncher, Steam, Spotify, and WirePlumber (`wpctl`). Their bindings are preserved but their apps are not installed.
