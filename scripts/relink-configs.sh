#!/bin/bash

# Relink Dotfiles Script
# This properly symlinks all config directories from dotfiles to ~/.config/

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "======================================"
echo "  Relinking Dotfiles to ~/.config/"
echo "======================================"
echo ""

info "Dotfiles directory: $DOTFILES_DIR"
info "Backup directory: $BACKUP_DIR"
echo ""

# Function to backup and create symlink
relink() {
    local source="$1"
    local target="$2"
    local name="$3"

    if [ ! -e "$source" ]; then
        error "Source does not exist: $source"
        return 1
    fi

    # Backup existing if it's not already a symlink to our dotfiles
    if [ -e "$target" ]; then
        if [ -L "$target" ]; then
            local current_link=$(readlink -f "$target")
            if [ "$current_link" = "$source" ]; then
                info "$name already correctly symlinked, skipping"
                return 0
            else
                warn "$name is symlinked to wrong location: $current_link"
            fi
        fi

        warn "Backing up existing $name"
        mkdir -p "$BACKUP_DIR"
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
    fi

    # Create symlink
    ln -sf "$source" "$target"
    info "✓ Linked $name: $target -> $source"
}

# Relink all configs
relink "$DOTFILES_DIR/.config/hypr" "$HOME/.config/hypr" "Hyprland config"
relink "$DOTFILES_DIR/.config/waybar" "$HOME/.config/waybar" "Waybar config"
relink "$DOTFILES_DIR/.config/omarchy" "$HOME/.config/omarchy" "Omarchy config"
relink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc" ".bashrc"

# Fix theme symlinks (relative paths)
info "Fixing theme symlinks..."
mkdir -p "$HOME/.config/omarchy/current"
cd "$HOME/.config/omarchy/current"
rm -f theme background
ln -sf ../themes/reverie theme
ln -sf theme/backgrounds/1.jpg background
cd - > /dev/null
info "✓ Theme symlinks created"

# Link custom scripts
info "Linking custom scripts..."
mkdir -p "$HOME/.local/bin"
if [ -d "$DOTFILES_DIR/scripts/local-bin" ]; then
    for script in "$DOTFILES_DIR/scripts/local-bin"/*; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            ln -sf "$script" "$HOME/.local/bin/$script_name"
            chmod +x "$HOME/.local/bin/$script_name"
            info "✓ Linked script: $script_name"
        fi
    done
fi

echo ""
echo "======================================"
info "Relinking Complete!"
echo "======================================"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    info "Your old configs were backed up to:"
    echo "  $BACKUP_DIR"
    echo ""
fi

echo "Symlinks created:"
echo "  ~/.config/hypr -> $DOTFILES_DIR/.config/hypr"
echo "  ~/.config/waybar -> $DOTFILES_DIR/.config/waybar"
echo "  ~/.config/omarchy -> $DOTFILES_DIR/.config/omarchy"
echo "  ~/.bashrc -> $DOTFILES_DIR/.bashrc"
echo ""
echo "Next steps:"
echo "  1. Reload Hyprland: Super+Shift+Q (or log out/in)"
echo "  2. Or reload config: hyprctl reload"
echo "  3. Check for errors: hyprctl config"
echo ""
