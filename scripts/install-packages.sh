#!/bin/bash

# Package Installation Script for Omarchy Dotfiles
# Installs all packages from packages.txt

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"

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

if [ ! -f "$PACKAGES_FILE" ]; then
    error "packages.txt not found at $PACKAGES_FILE"
    exit 1
fi

echo "======================================"
echo "  Package Installation"
echo "======================================"
echo ""

# Count packages
TOTAL_PACKAGES=$(wc -l < "$PACKAGES_FILE")
info "Found $TOTAL_PACKAGES packages to install"

# Confirm
read -p "Install all packages? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Installation cancelled"
    exit 1
fi

# Update system first
info "Updating system..."
sudo pacman -Syu --noconfirm

# Extract just package names (remove versions)
PACKAGE_NAMES=$(awk '{print $1}' "$PACKAGES_FILE")

# Install packages
info "Installing packages..."
echo "$PACKAGE_NAMES" | while read -r package; do
    if pacman -Qi "$package" &>/dev/null; then
        warn "$package already installed, skipping..."
    else
        info "Installing $package..."
        if yay -S --noconfirm "$package" 2>/dev/null; then
            info "✓ Installed $package"
        else
            warn "Failed to install $package (may need manual installation)"
        fi
    fi
done

echo ""
info "Package installation complete!"
info "Some packages may have failed. Review the output above."
echo ""
