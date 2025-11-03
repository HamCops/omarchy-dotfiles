#!/bin/bash

# Package Installation Script for Omarchy Dotfiles
# Installs packages with hardware detection and optional interactive selection

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
SELECTION_FILE="$DOTFILES_DIR/package-selection.txt"

# Parse arguments
USE_SELECTION=false
INTERACTIVE=false

for arg in "$@"; do
    case $arg in
        --use-selection)
            USE_SELECTION=true
            ;;
        --interactive|-i)
            INTERACTIVE=true
            ;;
    esac
done

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

# Launch interactive selector if requested
if [ "$INTERACTIVE" = true ]; then
    if [ -f "$DOTFILES_DIR/scripts/select-packages.sh" ]; then
        "$DOTFILES_DIR/scripts/select-packages.sh"
        exit $?
    else
        warn "Package selector not found. Proceeding with default installation."
    fi
fi

# Run hardware detection
if [ -f "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
    info "Detecting hardware..."
    "$DOTFILES_DIR/scripts/detect-hardware.sh"
    source /tmp/hardware-profile.env
else
    warn "Hardware detection not available. Using default package list."
    HARDWARE_PROFILE="generic"
fi

# Check if using custom selection
if [ "$USE_SELECTION" = true ] && [ -f "$SELECTION_FILE" ]; then
    info "Using custom package selection"
    PACKAGES_FILE="$SELECTION_FILE"
# Check if selection file exists (from previous run)
elif [ ! "$USE_SELECTION" = true ] && [ -f "$SELECTION_FILE" ]; then
    warn "Found existing package selection file"
    read -p "Use previous package selection? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        PACKAGES_FILE="$SELECTION_FILE"
    fi
fi

# Ask about interactive selection if not already set
if [ "$PACKAGES_FILE" = "$DOTFILES_DIR/packages.txt" ] && [ "$USE_SELECTION" = false ]; then
    echo ""
    echo "Package installation options:"
    echo "  1. Install all packages (default) - 219 packages"
    echo "  2. Interactive selection (choose which packages)"
    echo ""
    read -p "Choose option (1/2) [1]: " pkg_option

    if [ "$pkg_option" = "2" ]; then
        if [ -f "$DOTFILES_DIR/scripts/select-packages.sh" ]; then
            "$DOTFILES_DIR/scripts/select-packages.sh"
            exit $?
        else
            warn "Package selector not found. Installing all packages."
        fi
    fi
fi

# Determine which package list to use (hardware-specific)
if [ "$PACKAGES_FILE" = "$DOTFILES_DIR/packages.txt" ]; then
    if [ "$HARDWARE_PROFILE" = "t420s" ]; then
        T420S_PACKAGES="$DOTFILES_DIR/hardware/t420s/packages-t420s.txt"
        if [ -f "$T420S_PACKAGES" ]; then
            info "Using T420s-specific package list"
            PACKAGES_FILE="$T420S_PACKAGES"
        else
            warn "T420s package list not found. Using default (may include incompatible packages)"
        fi
    fi
fi

if [ ! -f "$PACKAGES_FILE" ]; then
    error "Package list not found at $PACKAGES_FILE"
    exit 1
fi

# Check if AI Development bundle is enabled
AI_DEV_ENABLED=false
if [ -f "$HOME/.config/omarchy-dotfiles.conf" ]; then
    source "$HOME/.config/omarchy-dotfiles.conf"
fi

# Create temporary combined package list if AI-dev is enabled
if [ "$AI_DEV_ENABLED" = "true" ] && [ -f "$DOTFILES_DIR/packages-ai-dev.txt" ]; then
    info "AI Development bundle is enabled"
    TEMP_PACKAGES="$(mktemp)"
    cat "$PACKAGES_FILE" > "$TEMP_PACKAGES"
    cat "$DOTFILES_DIR/packages-ai-dev.txt" >> "$TEMP_PACKAGES"
    PACKAGES_FILE="$TEMP_PACKAGES"
    AI_DEV_TEMP_FILE="$TEMP_PACKAGES"
fi

# Count packages
TOTAL_PACKAGES=$(wc -l < "$PACKAGES_FILE")
info "Found $TOTAL_PACKAGES packages to install"
if [ "$AI_DEV_ENABLED" = "true" ]; then
    info "  (Includes 18 AI/ML development packages)"
fi
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

# Clean up temporary file if created
if [ -n "$AI_DEV_TEMP_FILE" ] && [ -f "$AI_DEV_TEMP_FILE" ]; then
    rm "$AI_DEV_TEMP_FILE"
fi

echo ""
info "Installation complete!"
