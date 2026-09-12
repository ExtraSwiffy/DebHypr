#!/usr/bin/env bash
# Install DebHypr on Debian 13 (Trixie). Hyprland itself must already be installed.
set -Eeuo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
backup_dir="$HOME/.config-backup-debhypr-$(date +%Y%m%d-%H%M%S)"
packages=(
  sudo
  firefox
  ghostty
  fastfetch
  starship
  hyprpaper
  waybar
  bluez
  brightnessctl
  fzf
  network-manager
  libnotify-bin
  playerctl
  fonts-jetbrains-mono
  fonts-noto-color-emoji
  fontconfig
)

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run this script as your normal user, not as root." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer is for Debian/apt systems." >&2
  exit 1
fi

echo "Installing applications and command-line tools..."
sudo apt-get update
sudo apt-get install -y "${packages[@]}"

mkdir -p "$config_dir"
for app in hypr ghostty fastfetch waybar; do
  target="$config_dir/$app"
  source="$repo_dir/config/$app"
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$backup_dir"
    mv "$target" "$backup_dir/$app"
    echo "Backed up $target"
  fi
  cp -a "$source" "$target"
done

starship_target="$config_dir/starship.toml"
if [[ -e "$starship_target" || -L "$starship_target" ]]; then
  mkdir -p "$backup_dir"
  mv "$starship_target" "$backup_dir/starship.toml"
  echo "Backed up $starship_target"
fi
cp "$repo_dir/config/starship.toml" "$starship_target"

font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
mkdir -p "$font_dir"

if [[ -d "$repo_dir/assets/fonts/GoogleSansCode" ]]; then
  cp -a "$repo_dir/assets/fonts/GoogleSansCode" "$font_dir/"
  fc-cache -f "$font_dir"
  echo "Installed Google Sans Code Nerd Font."
fi

wallpaper_dir="${XDG_DATA_HOME:-$HOME/.local/share}/backgrounds/DebHypr"
mkdir -p "$wallpaper_dir"
cp "$repo_dir/assets/wallpapers/after-sunset-minimal-4k-zm-3840x2160.jpg" "$wallpaper_dir/"

local_bin="$HOME/.local/bin"
mkdir -p "$local_bin"
for script in start-console-after-hyprland desktop-to-console console-mode-session; do
  cp "$repo_dir/scripts/local/bin/$script" "$local_bin/$script"
  chmod 0755 "$local_bin/$script"
done

# This helper is referenced by the SUPER+TAB keybinding in hyprland.conf.
# It requires sudoers configuration because Hyprland runs it with sudo -n.
system_script="/usr/local/sbin/reboot-to-windows"
if sudo test -e "$system_script"; then
  sudo cp -p "$system_script" "$system_script.debhypr-backup-$(date +%Y%m%d-%H%M%S)"
  echo "Backed up $system_script"
fi
sudo install -m 0755 "$repo_dir/scripts/sbin/reboot-to-windows" "$system_script"

sudoers_file="/etc/sudoers.d/debhypr-reboot-to-windows"
printf '%s\n' "$USER ALL=(root) NOPASSWD: $system_script" | sudo tee "$sudoers_file" >/dev/null
sudo chmod 0440 "$sudoers_file"

if ! sudo visudo -cf "$sudoers_file" >/dev/null; then
  echo "ERROR: Generated sudoers file is invalid." >&2
  sudo rm -f "$sudoers_file"
  exit 1
fi

echo
printf '%s\n' "DebHypr is installed. Existing configs, if any, are in: $backup_dir"
printf '%s\n' "Installed the wallpaper to: $wallpaper_dir"
printf '%s\n' "Installed console-mode scripts to: $local_bin"
printf '%s\n' "The reboot-to-Windows helper was installed to: $system_script"
printf '%s\n' "To enable Starship in Bash, add this to ~/.bashrc if it is not already there:"
printf '%s\n' 'eval "$(starship init bash)"'
printf '%s\n' "Start or reload Hyprland to use the new Hyprland config."
