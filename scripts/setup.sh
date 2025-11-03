#!/bin/bash

# Omarchy Dotfiles Setup Script
# Automated deployment with hardware detection

set -e  # Exit on error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    rm -rf "$target"
    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    info "Linked $source -> $target"
}

echo "======================================"
echo "  Omarchy Dotfiles Setup"
echo "======================================"
echo ""

# Run hardware detection
if [ -f "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
    info "Running hardware detection..."
    "$DOTFILES_DIR/scripts/detect-hardware.sh"
    source /tmp/hardware-profile.env
    echo ""
else
    warn "Hardware detection script not found"
    HARDWARE_PROFILE="generic"
fi

# Run hardware-specific pre-setup if needed
if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    warn "T420s detected! Running hardware-specific adjustments..."
    echo ""

    if [ -f "$DOTFILES_DIR/hardware/t420s/pre-setup.sh" ]; then
        read -p "Run T420s pre-setup script to adjust configs? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            "$DOTFILES_DIR/hardware/t420s/pre-setup.sh"
            echo ""
        fi
    else
        warn "T420s pre-setup script not found"
        warn "You may need to manually adjust configs for T420s hardware"
        echo ""
    fi
fi

# Confirm before proceeding
read -p "This will symlink dotfiles from $DOTFILES_DIR. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    error "Setup cancelled"
    exit 1
fi

echo ""

# Link Hyprland configs
info "Setting up Hyprland configurations..."
create_symlink "$DOTFILES_DIR/.config/hypr" "$HOME/.config/hypr"

# Link Waybar configs
info "Setting up Waybar configurations..."
create_symlink "$DOTFILES_DIR/.config/waybar" "$HOME/.config/waybar"

# Link Omarchy configs
info "Setting up Omarchy configurations..."
create_symlink "$DOTFILES_DIR/.config/omarchy" "$HOME/.config/omarchy"

# Link .bashrc (with aliases and MCP functions)
info "Setting up .bashrc with custom aliases..."
create_symlink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"

# Link custom scripts
info "Setting up custom scripts..."
mkdir -p "$HOME/.local/bin"
if [ -d "$DOTFILES_DIR/scripts/local-bin" ]; then
    for script in "$DOTFILES_DIR/scripts/local-bin"/*; do
        if [ -f "$script" ]; then
            script_name=$(basename "$script")
            create_symlink "$script" "$HOME/.local/bin/$script_name"
            chmod +x "$HOME/.local/bin/$script_name"
        fi
    done
fi

echo ""
info "Dotfiles setup complete!"
if [ -d "$BACKUP_DIR" ]; then
    info "Backups saved to: $BACKUP_DIR"
fi

echo ""

# Ask about AI Development environment
echo "======================================"
echo "  Optional: AI Development Bundle"
echo "======================================"
echo ""
echo "The AI Development bundle includes:"
echo "  • Conda (miniconda3) for environment management"
echo "  • CUDA, cuDNN for GPU acceleration"
echo "  • Jupyter Notebook for interactive development"
echo "  • Python ML libraries (numpy, pandas, matplotlib, scipy, scikit-learn, etc.)"
echo "  • AI development aliases (ai-env, ai-workspace, jupyter-ai, etc.)"
echo ""
echo "This bundle adds ~18 packages and requires ~5GB disk space."
echo ""

read -p "Enable AI Development bundle? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Enabling AI Development environment..."

    # Create config file to enable AI-dev
    mkdir -p "$HOME/.config"
    echo "AI_DEV_ENABLED=true" > "$HOME/.config/omarchy-dotfiles.conf"

    # Link AI-dev bashrc
    create_symlink "$DOTFILES_DIR/.bashrc-ai-dev" "$HOME/.bashrc-ai-dev"

    info "✓ AI Development environment enabled"
    echo ""
    echo "AI-dev will be loaded on next shell session."
    echo "To load now: source ~/.bashrc"
    echo ""
else
    info "Skipping AI Development bundle"
    echo "You can enable it later by running:"
    echo "  echo 'AI_DEV_ENABLED=true' > ~/.config/omarchy-dotfiles.conf"
    echo "  ln -sf $DOTFILES_DIR/.bashrc-ai-dev ~/.bashrc-ai-dev"
    echo ""
fi

echo ""
echo "======================================"
echo "  Next Steps"
echo "======================================"

# Hardware-specific recommendations
if [ "$HARDWARE_PROFILE" = "surface" ]; then
    info "Surface Laptop Studio detected"
    echo ""
    echo "Recommended actions:"
    echo "  1. Install packages: $DOTFILES_DIR/scripts/install-packages.sh"
    echo "  2. Deploy MCP servers: $DOTFILES_DIR/scripts/deploy-mcp.sh"
    echo "  3. Enable iptsd: sudo systemctl enable --now iptsd@dev-hidraw7.service"
    echo "  4. Restart Hyprland (logout/login or Super+Shift+Q)"
    echo ""

elif [ "$HARDWARE_PROFILE" = "t420s" ]; then
    info "Lenovo T420s detected"
    echo ""
    echo "Recommended actions:"
    echo "  1. Review adjusted configs in ~/.config/"
    echo "  2. Install packages: $DOTFILES_DIR/scripts/install-packages.sh"
    echo "     (Will use T420s-specific package list)"
    echo "  3. Deploy MCP servers: $DOTFILES_DIR/scripts/deploy-mcp.sh"
    echo "     (GPU containers will be disabled automatically)"
    if [ "$HAS_NVIDIA" = true ]; then
        echo "  4. Install NVIDIA drivers: $NVIDIA_DRIVER"
    fi
    echo "  5. Enable TLP: sudo systemctl enable --now tlp.service"
    echo "  6. Enable thermald: sudo systemctl enable --now thermald.service"
    echo "  7. Restart Hyprland (logout/login)"
    echo ""

else
    echo "Recommended actions:"
    echo "  1. Review configurations in ~/.config/"
    echo "  2. Adjust for your hardware if needed"
    echo "  3. Install packages: $DOTFILES_DIR/scripts/install-packages.sh"
    echo "  4. Deploy MCP servers: $DOTFILES_DIR/scripts/deploy-mcp.sh"
    echo "  5. Restart Hyprland or log out/in"
    echo ""
fi

# Offer to continue with automation
echo ""
read -p "Would you like to continue with automated setup? (install packages + MCP) (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    info "Continuing with automated setup..."
    echo ""

    # Install packages
    if [ -f "$DOTFILES_DIR/scripts/install-packages.sh" ]; then
        info "Starting package installation..."
        "$DOTFILES_DIR/scripts/install-packages.sh"
    else
        warn "Package installer not found, skipping..."
    fi

    echo ""

    # Deploy MCP
    if [ -f "$DOTFILES_DIR/scripts/deploy-mcp.sh" ]; then
        read -p "Deploy MCP containers? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$DOTFILES_DIR/scripts/deploy-mcp.sh"
        fi
    fi

    echo ""
    info "Automated setup complete!"

    # System update
    echo ""
    read -p "Update Omarchy system packages? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Updating system..."
        sudo pacman -Syu --noconfirm
        info "✓ System updated"
    else
        info "Skipping system update"
    fi

else
    info "You can run the scripts manually when ready"
fi

# Offer to reboot
echo ""
echo "======================================"
read -p "Reboot system to apply all changes? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Rebooting in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    sudo reboot
else
    echo ""
    echo "======================================"
    info "Setup finished! Enjoy your dotfiles!"
    echo "======================================"
    echo ""
    warn "Remember to restart Hyprland or log out/in to apply changes"
    echo ""
fi
echo ""
