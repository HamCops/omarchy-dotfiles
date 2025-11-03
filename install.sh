#!/bin/bash

# Omarchy Dotfiles - Unified Installation Script
# One script to rule them all - runs EVERYTHING automatically

set -e  # Exit on error

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
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

step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

success() {
    echo -e "${CYAN}[✓]${NC} $1"
}

# Function to backup existing config
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$target" "$BACKUP_DIR/"
        info "Backed up $target"
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

clear
cat << "EOF"
╔══════════════════════════════════════════════╗
║   Omarchy Dotfiles - Unified Installer      ║
║   One Script, Complete Setup                ║
╚══════════════════════════════════════════════╝
EOF
echo ""

info "Starting unified installation..."
echo ""

# ===========================================
# STEP 1: Hardware Detection
# ===========================================
step "1/8 - Hardware Detection"
echo ""

if [ -f "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
    "$DOTFILES_DIR/scripts/detect-hardware.sh"
    source /tmp/hardware-profile.env
    info "Detected hardware: $HARDWARE_PROFILE"

    if [ "$HARDWARE_PROFILE" = "t420s" ]; then
        warn "T420s detected - hardware-specific adjustments will be applied"
        info "  RAM: ${RAM_GB}GB"
        info "  NVIDIA GPU: $HAS_NVIDIA"
        if [ "$HAS_NVIDIA" = true ]; then
            info "  Required driver: $NVIDIA_DRIVER"
        fi
    elif [ "$HARDWARE_PROFILE" = "surface" ]; then
        info "Surface Laptop Studio detected"
    fi
else
    warn "Hardware detection script not found - using generic profile"
    HARDWARE_PROFILE="generic"
fi
echo ""

# ===========================================
# STEP 2: Hardware-Specific Pre-Setup
# ===========================================
step "2/8 - Hardware Pre-Configuration"
echo ""

if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    if [ -f "$DOTFILES_DIR/hardware/t420s/pre-setup.sh" ]; then
        info "Running T420s hardware adjustments..."
        "$DOTFILES_DIR/hardware/t420s/pre-setup.sh"
        success "T420s configurations adjusted"
    else
        warn "T420s pre-setup script not found"
    fi
else
    info "No hardware-specific adjustments needed"
fi
echo ""

# ===========================================
# STEP 3: Symlink Dotfiles
# ===========================================
step "3/8 - Symlinking Configurations"
echo ""

info "Linking Hyprland configs..."
create_symlink "$DOTFILES_DIR/.config/hypr" "$HOME/.config/hypr"

info "Linking Waybar configs..."
create_symlink "$DOTFILES_DIR/.config/waybar" "$HOME/.config/waybar"

info "Linking Omarchy configs..."
create_symlink "$DOTFILES_DIR/.config/omarchy" "$HOME/.config/omarchy"

# Fix theme symlinks (need to be relative, not absolute)
info "Setting up theme symlinks..."
mkdir -p "$HOME/.config/omarchy/current"
cd "$HOME/.config/omarchy/current"
rm -f theme background
ln -sf ../themes/reverie theme
ln -sf theme/backgrounds/1.jpg background
cd "$DOTFILES_DIR"
info "✓ Theme symlinks created"

info "Linking .bashrc..."
create_symlink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"

info "Linking custom scripts..."
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

success "All dotfiles symlinked"
echo ""

# ===========================================
# STEP 4: AI Development Bundle (Optional)
# ===========================================
step "4/8 - AI Development Bundle"
echo ""

echo "The AI Development bundle includes:"
echo "  • Conda (miniconda3) for environment management"
echo "  • CUDA, cuDNN for GPU acceleration"
echo "  • Jupyter Notebook"
echo "  • Python ML libraries (numpy, pandas, matplotlib, scikit-learn)"
echo "  • AI development aliases (ai-env, jupyter-ai, gpu-monitor)"
echo ""
echo "This adds ~18 packages and requires ~5GB disk space."
echo ""

AI_DEV_ENABLED=false
read -p "Enable AI Development bundle? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$HOME/.config"
    echo "AI_DEV_ENABLED=true" > "$HOME/.config/omarchy-dotfiles.conf"
    create_symlink "$DOTFILES_DIR/.bashrc-ai-dev" "$HOME/.bashrc-ai-dev"
    AI_DEV_ENABLED=true
    success "AI Development environment enabled"
else
    info "Skipping AI Development bundle"
fi
echo ""

# ===========================================
# STEP 5: Package Installation
# ===========================================
step "5/8 - Installing Packages"
echo ""

if [ -f "$DOTFILES_DIR/scripts/install-packages.sh" ]; then
    info "Starting package installation..."
    echo ""

    # Run package installer non-interactively
    export HARDWARE_PROFILE
    export HAS_NVIDIA
    export RAM_GB

    # Determine package file
    if [ "$HARDWARE_PROFILE" = "t420s" ]; then
        PACKAGES_FILE="$DOTFILES_DIR/hardware/t420s/packages-t420s.txt"
        if [ ! -f "$PACKAGES_FILE" ]; then
            warn "T420s package list not found, using default"
            PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
        fi
    else
        PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
    fi

    if [ ! -f "$PACKAGES_FILE" ]; then
        error "Package list not found at $PACKAGES_FILE"
    else
        # Update system first
        info "Updating system..."
        sudo pacman -Syu --noconfirm

        # Install packages
        PACKAGE_NAMES=$(awk '{print $1}' "$PACKAGES_FILE")
        INSTALLED=0
        SKIPPED=0
        FAILED=0
        FAILED_PACKAGES=()

        # Add AI-dev packages if enabled
        if [ "$AI_DEV_ENABLED" = "true" ] && [ -f "$DOTFILES_DIR/packages-ai-dev.txt" ]; then
            AI_PACKAGES=$(awk '{print $1}' "$DOTFILES_DIR/packages-ai-dev.txt")
            PACKAGE_NAMES="$PACKAGE_NAMES"$'\n'"$AI_PACKAGES"
        fi

        while IFS= read -r package; do
            [ -z "$package" ] && continue

            if pacman -Qi "$package" &>/dev/null; then
                echo -e "${BLUE}[SKIP]${NC} $package (already installed)"
                ((SKIPPED++))
            else
                echo -e "${BLUE}[INSTALL]${NC} $package..."
                if yay -S --noconfirm "$package" 2>/dev/null; then
                    echo -e "${GREEN}[✓]${NC} $package"
                    ((INSTALLED++))
                else
                    echo -e "${RED}[✗]${NC} $package (failed)"
                    FAILED_PACKAGES+=("$package")
                    ((FAILED++))
                fi
            fi
        done <<< "$PACKAGE_NAMES"

        echo ""
        success "Package installation complete"
        info "Installed: $INSTALLED | Skipped: $SKIPPED | Failed: $FAILED"

        if [ $FAILED -gt 0 ]; then
            warn "Failed packages: ${FAILED_PACKAGES[*]}"
        fi
    fi
else
    warn "Package installer not found, skipping..."
fi
echo ""

# ===========================================
# STEP 6: Docker & MCP Deployment
# ===========================================
step "6/8 - Docker & MCP Deployment"
echo ""

if ! command -v docker &> /dev/null; then
    warn "Docker is not installed. Skipping container deployment."
    warn "Install docker and docker-compose, then run: $DOTFILES_DIR/scripts/deploy-mcp.sh"
else
    if [ -f "$DOTFILES_DIR/scripts/deploy-mcp.sh" ]; then
        info "Deploying Docker containers and MCP servers..."
        echo ""

        cd "$DOTFILES_DIR/docker"

        # Determine compose files
        COMPOSE_FILES="-f docker-compose.yml"
        if [ "$HARDWARE_PROFILE" = "t420s" ] && [ -f "docker-compose.t420s.yml" ]; then
            info "Using T420s Docker overrides (GPU containers disabled)"
            COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.t420s.yml"
        fi

        # Pull images
        info "Pulling Docker images..."
        docker compose $COMPOSE_FILES pull ollama open-webui phoneinfoga 2>/dev/null || warn "Some images couldn't be pulled"

        # Start services
        info "Starting containers..."
        if [ "$HARDWARE_PROFILE" = "surface" ] && [ "$HAS_NVIDIA" = true ]; then
            docker compose $COMPOSE_FILES --profile nvidia-gpu up -d
        else
            docker compose $COMPOSE_FILES up -d
        fi

        # Wait for startup
        sleep 5

        # Check status
        echo ""
        docker compose $COMPOSE_FILES ps
        echo ""

        success "Docker containers deployed"

        # Create Claude Desktop config
        CLAUDE_CONFIG="$HOME/.config/claude/claude_desktop_config.json"
        if [ ! -f "$CLAUDE_CONFIG" ]; then
            info "Creating Claude Desktop MCP configuration..."
            mkdir -p "$(dirname "$CLAUDE_CONFIG")"

            # Generate config based on running containers
            echo '{' > "$CLAUDE_CONFIG"
            echo '  "mcpServers": {' >> "$CLAUDE_CONFIG"

            first=true
            for container in mcp-docker-manager mcp-filesystem mcp-obsidian mcp-pytorch-inspector \
                             mcp-rss-aggregator mcp-librecad mcp-gpu-optimizer mcp-kali-tools mcp-markdown-converter; do
                if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
                    if [ "$first" = false ]; then
                        echo ',' >> "$CLAUDE_CONFIG"
                    fi
                    first=false

                    config_key="${container#mcp-}"
                    echo -n "    \"$config_key\": { \"command\": \"docker\", \"args\": [\"exec\", \"-i\", \"$container\", \"node\", \"index.js\"] }" >> "$CLAUDE_CONFIG"
                fi
            done

            echo '' >> "$CLAUDE_CONFIG"
            echo '  }' >> "$CLAUDE_CONFIG"
            echo '}' >> "$CLAUDE_CONFIG"

            success "Claude Desktop config created"
        fi

        cd "$DOTFILES_DIR"
    else
        warn "MCP deployment script not found, skipping..."
    fi
fi
echo ""

# ===========================================
# STEP 7: Theme & System Services
# ===========================================
step "7/8 - Activating Theme & Services"
echo ""

# Reload shell environment
info "Reloading shell environment..."
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || warn "Could not reload .bashrc"
fi

# Hardware-specific services
if [ "$HARDWARE_PROFILE" = "surface" ]; then
    info "Surface-specific services:"
    echo "  To enable touch/pen support: sudo systemctl enable --now iptsd@dev-hidraw7.service"
elif [ "$HARDWARE_PROFILE" = "t420s" ]; then
    info "Enabling T420s power management..."
    sudo systemctl enable tlp.service 2>/dev/null || warn "TLP not installed"
    sudo systemctl enable thermald.service 2>/dev/null || warn "thermald not installed"
    sudo systemctl start tlp.service 2>/dev/null || warn "TLP failed to start"
    sudo systemctl start thermald.service 2>/dev/null || warn "thermald failed to start"
fi

success "System services configured"
echo ""

# ===========================================
# STEP 8: Final System Update
# ===========================================
step "8/8 - Final System Update"
echo ""

read -p "Update Omarchy system packages? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    info "Updating system..."
    sudo pacman -Syu --noconfirm
    success "System updated"
else
    info "Skipping system update"
fi
echo ""

# ===========================================
# Installation Complete
# ===========================================
clear
cat << "EOF"
╔══════════════════════════════════════════════╗
║   Installation Complete!                    ║
╚══════════════════════════════════════════════╝
EOF
echo ""

success "Omarchy dotfiles installed successfully"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    info "Backups saved to: $BACKUP_DIR"
fi
echo ""

echo "======================================"
echo "  What Was Installed"
echo "======================================"
echo ""
echo "✓ Hyprland, Waybar, Omarchy configurations"
echo "✓ Custom scripts and aliases"
if [ "$AI_DEV_ENABLED" = "true" ]; then
    echo "✓ AI Development Bundle (18 packages)"
fi
echo "✓ System packages"
if command -v docker &> /dev/null; then
    echo "✓ Docker containers and MCP servers"
fi
echo ""

echo "======================================"
echo "  Hardware Configuration"
echo "======================================"
echo ""
if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    echo "Hardware: Lenovo T420s"
    echo "  • Monitor: Auto-configured for 1600x900 or 1366x768"
    echo "  • Power: TLP and thermald enabled"
    echo "  • Idle timeouts: Reduced for battery life"
    if [ "$HAS_NVIDIA" = false ]; then
        echo "  • GPU: Intel HD 3000 (NVIDIA widgets removed)"
    else
        echo "  • GPU: Intel + NVIDIA NVS 4200M (legacy driver: $NVIDIA_DRIVER)"
    fi
    if [ -f "$DOTFILES_DIR/docker/docker-compose.t420s.yml" ]; then
        echo "  • Docker: GPU containers disabled, reduced resource limits"
    fi
elif [ "$HARDWARE_PROFILE" = "surface" ]; then
    echo "Hardware: Microsoft Surface Laptop Studio"
    echo "  • Display: 2400x1600@120Hz, 1.3333 scale"
    echo "  • GPU: NVIDIA RTX 3050 Ti + Intel Iris Xe"
    echo "  • Touch/Pen: iptsd service available"
fi
echo ""

echo "======================================"
echo "  Access Points"
echo "======================================"
echo ""
if docker ps --format '{{.Names}}' | grep -q "^open-webui$" 2>/dev/null; then
    echo "Open WebUI:    http://localhost:8080"
fi
if docker ps --format '{{.Names}}' | grep -q "^ollama$" 2>/dev/null; then
    echo "Ollama API:    http://localhost:11434"
fi
if docker ps --format '{{.Names}}' | grep -q "^phoneinfoga$" 2>/dev/null; then
    echo "PhoneInfoga:   http://localhost:8081"
fi
echo ""

echo "======================================"
echo "  Next Steps"
echo "======================================"
echo ""
echo "1. Restart Hyprland:"
echo "   • Log out and log back in (recommended)"
echo "   • Or: Super+Shift+Q to reload"
echo ""
echo "2. Verify monitor setup:"
echo "   • hyprctl monitors"
echo "   • Edit ~/.config/hypr/monitors.conf if needed"
echo ""
if [ -f "$HOME/.config/claude/claude_desktop_config.json" ]; then
    echo "3. Restart Claude Desktop to use MCP servers"
    echo ""
fi
echo "4. Enjoy your new setup!"
echo ""

# Offer to reboot
echo "======================================"
read -p "Reboot now to apply all changes? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    info "Rebooting in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    sudo reboot
else
    echo ""
    warn "Remember to restart Hyprland or reboot to apply all changes"
    echo ""
fi
