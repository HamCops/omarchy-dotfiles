#!/bin/bash

# Package Installation Script for Omarchy Dotfiles
# Installs packages with hardware detection

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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
echo "  Package Installation"
echo "======================================"
echo ""

# Run hardware detection
if [ -f "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
    info "Detecting hardware..."
    "$DOTFILES_DIR/scripts/detect-hardware.sh"
    source /tmp/hardware-profile.env
else
    warn "Hardware detection not available. Using default package list."
    HARDWARE_PROFILE="generic"
fi

# Determine which package list to use
if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    T420S_PACKAGES="$DOTFILES_DIR/hardware/t420s/packages-t420s.txt"
    if [ -f "$T420S_PACKAGES" ]; then
        info "Using T420s-specific package list"
        PACKAGES_FILE="$T420S_PACKAGES"
    else
        warn "T420s package list not found. Using default (may include incompatible packages)"
    fi
fi

if [ ! -f "$PACKAGES_FILE" ]; then
    error "Package list not found at $PACKAGES_FILE"
    exit 1
fi

# Count packages
TOTAL_PACKAGES=$(wc -l < "$PACKAGES_FILE")
info "Found $TOTAL_PACKAGES packages to install"
echo ""

# Show hardware-specific warnings
if [ "$HARDWARE_PROFILE" = "t420s" ] && [ "$HAS_NVIDIA" = true ]; then
    warn "T420s with NVIDIA GPU detected"
    if [ "$NVIDIA_DRIVER" = "nvidia-390xx-dkms" ]; then
        warn "Your GPU requires legacy NVIDIA drivers (nvidia-390xx-dkms)"
        warn "Make sure this package is in your package list"
    fi
fi

if [ "$RAM_GB" -lt 16 ]; then
    warn "System has ${RAM_GB}GB RAM. Some containers may struggle."
    warn "Consider disabling heavy containers (Ollama, Kali Tools) if performance is poor."
fi

echo ""

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

# Create array for tracking
INSTALLED=0
SKIPPED=0
FAILED=0
FAILED_PACKAGES=()

# Install packages
info "Installing packages..."
echo ""

while IFS= read -r package; do
    # Skip empty lines
    [ -z "$package" ] && continue

    if pacman -Qi "$package" &>/dev/null; then
        echo -e "${BLUE}[SKIP]${NC} $package (already installed)"
        ((SKIPPED++))
    else
        echo -e "${BLUE}[INSTALL]${NC} $package..."
        if yay -S --noconfirm "$package" 2>/dev/null; then
            echo -e "${GREEN}[✓]${NC} $package installed successfully"
            ((INSTALLED++))
        else
            echo -e "${RED}[✗]${NC} $package failed to install"
            FAILED_PACKAGES+=("$package")
            ((FAILED++))
        fi
    fi
done <<< "$PACKAGE_NAMES"

echo ""
echo "======================================"
echo "  Installation Summary"
echo "======================================"
info "Installed: $INSTALLED packages"
warn "Skipped: $SKIPPED packages (already installed)"

if [ $FAILED -gt 0 ]; then
    error "Failed: $FAILED packages"
    echo ""
    echo "Failed packages:"
    for pkg in "${FAILED_PACKAGES[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    warn "You may need to install these manually or from AUR"
else
    info "All packages installed successfully!"
fi

echo "======================================"
echo ""

# Hardware-specific post-install notes
if [ "$HARDWARE_PROFILE" = "surface" ]; then
    info "Surface-specific notes:"
    echo "  - Enable iptsd: sudo systemctl enable --now iptsd@dev-hidraw7.service"
    echo "  - Reboot to load Surface kernel modules"
fi

if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    info "T420s-specific notes:"
    echo "  - Enable TLP: sudo systemctl enable --now tlp.service"
    echo "  - Enable thermald: sudo systemctl enable --now thermald.service"
    if [ "$HAS_NVIDIA" = true ]; then
        echo "  - Configure NVIDIA Optimus if you have discrete GPU"
    fi
fi

echo ""
info "Installation complete!"
