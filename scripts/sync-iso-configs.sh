#!/bin/bash

set -e

PROJECT_DIR="$HOME/DebHypr"
LIVE="$HOME/.config"
MAIN="$PROJECT_DIR/config"

echo "==> Syncing live desktop configs to DebHypr main..."
echo

# Hyprland
mkdir -p "$MAIN/hypr"
cp "$LIVE/hypr/hyprland.conf" "$MAIN/hypr/hyprland.conf"
cp "$LIVE/hypr/hyprpaper.conf" "$MAIN/hypr/hyprpaper.conf"
echo "✓ Hyprland"

# Quickshell
mkdir -p "$MAIN/quickshell"
cp "$LIVE/quickshell/shell.qml" "$MAIN/quickshell/shell.qml"
echo "✓ Quickshell"

# Ghostty
mkdir -p "$MAIN/ghostty"
cp "$LIVE/ghostty/config.ghostty" "$MAIN/ghostty/config.ghostty"
echo "✓ Ghostty"

# Fastfetch
mkdir -p "$MAIN/fastfetch"
cp "$LIVE/fastfetch/config.jsonc" "$MAIN/fastfetch/config.jsonc"
echo "✓ Fastfetch"

# Starship
cp "$LIVE/starship.toml" "$MAIN/starship.toml"
echo "✓ Starship"

echo
echo "==> Live → main sync complete."
echo
echo "Run 'git status' to review the changes."
