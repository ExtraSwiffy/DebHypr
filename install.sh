#!/usr/bin/env bash
# Install DebHypr on Debian 13 (Trixie). Hyprland itself must already be installed.
set -Eeuo pipefail

repo_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
backup_dir="$HOME/.config-backup-debhypr-$(date +%Y%m%d-%H%M%S)"
packages=(firefox ghostty fastfetch starship)

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
for app in hypr ghostty fastfetch; do
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

echo
printf '%s\n' "DebHypr is installed. Existing configs, if any, are in: $backup_dir"
printf '%s\n' "Installed console-mode scripts to: $local_bin"
printf '%s\n' "The reboot-to-Windows helper was installed to: $system_script"
printf '%s\n' "To enable Starship in Bash, add this to ~/.bashrc if it is not already there:"
printf '%s\n' 'eval "$(starship init bash)"'
printf '%s\n' "Start or reload Hyprland to use the new Hyprland config."
