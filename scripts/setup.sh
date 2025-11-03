#!/bin/bash

# Omarchy Dotfiles Setup Script
# This script helps deploy your dotfiles to a new Omarchy installation

set -e  # Exit on error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup existing config
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ]; then
        info "Backing up existing $target"
        mkdir -p "$BACKUP_DIR"
        cp -r "$target" "$BACKUP_DIR/"
    fi
}

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"

    backup_if_exists "$target"

    # Remove existing file/link
    rm -rf "$target"

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Create symlink
    ln -sf "$source" "$target"
    info "Linked $source -> $target"
}

echo "======================================"
echo "  Omarchy Dotfiles Setup"
echo "======================================"
echo ""

# Confirm before proceeding
read -p "This will symlink dotfiles from $DOTFILES_DIR. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Setup cancelled"
    exit 1
fi

# Link Hyprland configs
info "Setting up Hyprland configurations..."
create_symlink "$DOTFILES_DIR/.config/hypr" "$HOME/.config/hypr"

# Link Waybar configs
info "Setting up Waybar configurations..."
create_symlink "$DOTFILES_DIR/.config/waybar" "$HOME/.config/waybar"

# Link Omarchy configs
info "Setting up Omarchy configurations..."
create_symlink "$DOTFILES_DIR/.config/omarchy" "$HOME/.config/omarchy"

echo ""
info "Dotfiles setup complete!"
if [ -d "$BACKUP_DIR" ]; then
    info "Backups saved to: $BACKUP_DIR"
fi

echo ""
echo "Next steps:"
echo "  1. Review your configurations in ~/.config/"
echo "  2. Install packages: ./scripts/install-packages.sh"
echo "  3. Restart Hyprland or log out/in"
echo ""
