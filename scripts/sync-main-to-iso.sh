#!/bin/bash

set -e

PROJECT_DIR="$HOME/DebHypr"
MAIN="$PROJECT_DIR/config"
ISO="$PROJECT_DIR/iso/config/includes.chroot/etc/skel/.config"

echo "==> Syncing DebHypr main configs to ISO build tree..."
echo

# Hyprland
mkdir -p "$ISO/hypr"
cp "$MAIN/hypr/hyprland.conf" "$ISO/hypr/hyprland.conf"
cp "$MAIN/hypr/hyprpaper.conf" "$ISO/hypr/hyprpaper.conf"
echo "✓ Hyprland"

# Quickshell
mkdir -p "$ISO/quickshell"
cp "$MAIN/quickshell/shell.qml" "$ISO/quickshell/shell.qml"
echo "✓ Quickshell"

# Ghostty
mkdir -p "$ISO/ghostty"
cp "$MAIN/ghostty/config.ghostty" "$ISO/ghostty/config.ghostty"
echo "✓ Ghostty"

# Fastfetch
mkdir -p "$ISO/fastfetch"
cp "$MAIN/fastfetch/config.jsonc" "$ISO/fastfetch/config.jsonc"
echo "✓ Fastfetch"

# Starship
cp "$MAIN/starship.toml" "$ISO/starship.toml"
echo "✓ Starship"

echo
echo "==> Main → ISO sync complete."
echo
echo "Run 'git status' to review the ISO changes."
