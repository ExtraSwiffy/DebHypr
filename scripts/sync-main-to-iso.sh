#!/bin/bash

set -e

PROJECT_DIR="$HOME/DebHypr"
ISO="$PROJECT_DIR/iso/config/includes.chroot/etc/skel/.config"
MAIN_BRANCH="main"

echo "==> Syncing DebHypr main configs to ISO build tree..."
echo "    Source: Git branch '$MAIN_BRANCH'"
echo

# Make sure we're inside the DebHypr repository
cd "$PROJECT_DIR"

# Make sure main exists locally
git rev-parse --verify "$MAIN_BRANCH" >/dev/null 2>&1 || {
    echo "ERROR: Git branch '$MAIN_BRANCH' was not found."
    exit 1
}

sync_file() {
    local source="$1"
    local destination="$2"

    mkdir -p "$(dirname "$destination")"
    git show "$MAIN_BRANCH:$source" > "$destination"

    echo "✓ $source"
}

# Hyprland
sync_file "config/hypr/hyprland.conf" \
    "$ISO/hypr/hyprland.conf"

sync_file "config/hypr/hyprpaper.conf" \
    "$ISO/hypr/hyprpaper.conf"

# Quickshell
sync_file "config/quickshell/shell.qml" \
    "$ISO/quickshell/shell.qml"

# Ghostty
sync_file "config/ghostty/config.ghostty" \
    "$ISO/ghostty/config.ghostty"

# Fastfetch
sync_file "config/fastfetch/config.jsonc" \
    "$ISO/fastfetch/config.jsonc"

# Starship
sync_file "config/starship.toml" \
    "$ISO/starship.toml"

echo
echo "==> Main → ISO sync complete."
echo
echo "The ISO tree now contains the committed configs from '$MAIN_BRANCH'."
echo
echo "Run 'git status' to review the ISO changes."
