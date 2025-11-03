#!/bin/bash

# Omarchy Dotfiles - Interactive Installation Wrapper
# This script runs the Python TUI, then executes the installation

# Note: We don't use 'set -e' because package installation may have
# non-fatal failures that we want to handle gracefully

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

# Check for python3
if ! command -v python3 &> /dev/null; then
    error "Python 3 is not installed"
    exit 2
fi

# Check for dialog backend
if ! command -v dialog &> /dev/null; then
    warn "dialog is not installed"
    info "Installing dialog..."
    sudo pacman -S --noconfirm dialog || {
        error "Failed to install dialog"
        exit 2
    }
fi

# Check for python-dialog (pythondialog)
if ! python3 -c "import dialog" 2>/dev/null; then
    warn "python-pythondialog is not installed"

    # Check if yay is available for AUR
    if command -v yay &> /dev/null; then
        info "Installing python-pythondialog from AUR..."
        yay -S --noconfirm python-pythondialog || {
            error "Failed to install python-pythondialog from AUR"
            error "Try manually: yay -S python-pythondialog"
            exit 2
        }
        success "python-pythondialog installed successfully"
    else
        # Fallback to pipx if yay not available
        warn "yay not found, attempting pipx installation..."

        if ! command -v pipx &> /dev/null; then
            info "Installing pipx..."
            sudo pacman -S --noconfirm python-pipx || {
                error "Failed to install pipx"
                exit 2
            }
        fi

        info "Installing pythondialog via pipx..."
        pipx install pythondialog || {
            error "Failed to install pythondialog"
            error "Please install yay and run: yay -S python-pythondialog"
            exit 2
        }
        success "pythondialog installed via pipx"

        # Add pipx bin to PATH for this session
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

# Run the TUI
clear
info "Starting interactive installer..."
echo ""

python3 "$DOTFILES_DIR/install-tui.py"
TUI_EXIT=$?

# Check TUI exit code
if [ $TUI_EXIT -eq 1 ]; then
    warn "Installation cancelled by user"
    exit 0
elif [ $TUI_EXIT -eq 2 ]; then
    error "TUI error occurred"
    exit 2
elif [ $TUI_EXIT -ne 0 ]; then
    error "Unknown TUI error (exit code: $TUI_EXIT)"
    exit 2
fi

# Load configuration
if [ ! -f /tmp/installation-config.env ]; then
    error "Installation configuration not found"
    error "The TUI did not save configuration properly"
    exit 2
fi

source /tmp/installation-config.env
source /tmp/hardware-profile.env 2>/dev/null || true

clear
echo ""
info "Starting installation with your selections..."
echo ""
sleep 2

# ===========================================
# Function to backup existing config
# ===========================================
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

# ===========================================
# STEP 1: Symlink Dotfiles
# ===========================================
step "1/6 - Symlinking Configurations"
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

# Link AI dev bashrc if enabled
if [ "$AI_DEV_ENABLED" = "true" ]; then
    info "Linking AI development environment..."
    create_symlink "$DOTFILES_DIR/.bashrc-ai-dev" "$HOME/.bashrc-ai-dev"
    mkdir -p "$HOME/.config"
    echo "AI_DEV_ENABLED=true" > "$HOME/.config/omarchy-dotfiles.conf"
fi

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
# STEP 2: Hardware-Specific Pre-Setup
# ===========================================
step "2/6 - Hardware Pre-Configuration"
echo ""

if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    if [ -f "$DOTFILES_DIR/hardware/t420s/pre-setup.sh" ]; then
        info "Running T420s hardware adjustments..."
        "$DOTFILES_DIR/hardware/t420s/pre-setup.sh"
        success "T420s configurations adjusted"
    fi
else
    info "No hardware-specific adjustments needed"
fi
echo ""

# ===========================================
# STEP 3: Package Installation
# ===========================================
step "3/6 - Installing Packages"
echo ""

if [ ! -f /tmp/package-selection.txt ]; then
    warn "No packages selected, skipping..."
else
    PACKAGE_COUNT=$(wc -l < /tmp/package-selection.txt)
    info "Installing $PACKAGE_COUNT packages..."
    echo ""

    # Update system first
    info "Updating system..."
    sudo pacman -Syu --noconfirm

    # Read packages from selection file
    INSTALLED=0
    SKIPPED=0
    FAILED=0
    FAILED_PACKAGES=()

    while IFS= read -r package; do
        [ -z "$package" ] && continue

        if pacman -Qi "$package" &>/dev/null; then
            echo -e "${BLUE}[SKIP]${NC} $package (already installed)"
            ((SKIPPED++))
        else
            echo -e "${BLUE}[INSTALL]${NC} $package..."
            # Capture exit code without stopping script
            if yay -S --noconfirm "$package" 2>&1; then
                echo -e "${GREEN}[✓]${NC} $package"
                ((INSTALLED++))
            else
                echo -e "${RED}[✗]${NC} $package (failed)"
                FAILED_PACKAGES+=("$package")
                ((FAILED++))
            fi
        fi
    done < /tmp/package-selection.txt

    # Install AI dev packages if enabled
    if [ "$AI_DEV_ENABLED" = "true" ] && [ -f "$DOTFILES_DIR/packages-ai-dev.txt" ]; then
        info "Installing AI development packages..."
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            package=$(echo "$line" | awk '{print $1}')

            if pacman -Qi "$package" &>/dev/null; then
                echo -e "${BLUE}[SKIP]${NC} $package (already installed)"
                ((SKIPPED++))
            else
                echo -e "${BLUE}[INSTALL]${NC} $package..."
                # Capture exit code without stopping script
                if yay -S --noconfirm "$package" 2>&1; then
                    echo -e "${GREEN}[✓]${NC} $package"
                    ((INSTALLED++))
                else
                    echo -e "${RED}[✗]${NC} $package (failed)"
                    FAILED_PACKAGES+=("$package")
                    ((FAILED++))
                fi
            fi
        done < "$DOTFILES_DIR/packages-ai-dev.txt"
    fi

    echo ""
    success "Package installation complete"
    info "Installed: $INSTALLED | Skipped: $SKIPPED | Failed: $FAILED"

    if [ $FAILED -gt 0 ]; then
        warn "Failed packages: ${FAILED_PACKAGES[*]}"
    fi
fi
echo ""

# ===========================================
# STEP 4: Docker & MCP Deployment
# ===========================================
step "4/6 - Docker & MCP Deployment"
echo ""

if ! command -v docker &> /dev/null; then
    warn "Docker is not installed. Skipping container deployment."
    warn "Install docker/podman, then run: $DOTFILES_DIR/scripts/deploy-mcp.sh"
else
    if [ -f /tmp/container-selection.txt ]; then
        CONTAINER_COUNT=$(wc -l < /tmp/container-selection.txt)
        info "Deploying $CONTAINER_COUNT containers..."
        echo ""

        cd "$DOTFILES_DIR/docker"

        # Build custom compose command based on selections
        SELECTED_CONTAINERS=$(cat /tmp/container-selection.txt | tr '\n' ' ')

        # Pull images
        info "Pulling Docker images..."
        for container in $SELECTED_CONTAINERS; do
            if docker compose ps --services 2>/dev/null | grep -q "^$container$"; then
                echo -e "${BLUE}[PULL]${NC} $container..."
                docker compose pull "$container" 2>/dev/null || warn "Could not pull $container"
            fi
        done

        # Start services
        info "Starting containers..."
        for container in $SELECTED_CONTAINERS; do
            echo -e "${GREEN}[START]${NC} $container..."
            docker compose up -d "$container" 2>/dev/null || warn "Could not start $container"
        done

        # Wait for startup
        sleep 3

        # Check status
        echo ""
        docker compose ps
        echo ""

        success "Docker containers deployed"

        # Create Claude Desktop config
        CLAUDE_CONFIG="$HOME/.config/claude/claude_desktop_config.json"
        if [ ! -f "$CLAUDE_CONFIG" ]; then
            info "Creating Claude Desktop MCP configuration..."
            mkdir -p "$(dirname "$CLAUDE_CONFIG")"

            echo '{' > "$CLAUDE_CONFIG"
            echo '  "mcpServers": {' >> "$CLAUDE_CONFIG"

            first=true
            for container in $SELECTED_CONTAINERS; do
                if [[ "$container" == mcp-* ]]; then
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
        info "No containers selected"
    fi
fi
echo ""

# ===========================================
# STEP 5: Theme & System Services
# ===========================================
step "5/6 - Activating Theme & Services"
echo ""

# Reload shell environment
info "Reloading shell environment..."
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || warn "Could not reload .bashrc"
fi

# Hardware-specific services
if [ "$HARDWARE_PROFILE" = "surface" ]; then
    info "Surface-specific services:"
    echo "  To enable touch/pen support: sudo systemctl enable --now iptsd"
elif [ "$HARDWARE_PROFILE" = "t420s" ]; then
    info "Enabling T420s power management..."
    sudo systemctl enable tlp.service 2>/dev/null || warn "TLP not installed"
    sudo systemctl enable thermald.service 2>/dev/null || warn "thermald not installed"
    sudo systemctl start tlp.service 2>/dev/null || true
    sudo systemctl start thermald.service 2>/dev/null || true
fi

success "System services configured"
echo ""

# ===========================================
# STEP 6: Final System Update
# ===========================================
step "6/6 - Final System Update"
echo ""

info "Updating system..."
sudo pacman -Syu --noconfirm
success "System updated"
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
if [ -f /tmp/package-selection.txt ]; then
    PKG_COUNT=$(wc -l < /tmp/package-selection.txt)
    echo "✓ $PKG_COUNT system packages"
fi
if [ -f /tmp/container-selection.txt ]; then
    CNT_COUNT=$(wc -l < /tmp/container-selection.txt)
    echo "✓ $CNT_COUNT Docker containers"
fi
echo ""

echo "======================================"
echo "  Hardware Configuration"
echo "======================================"
echo ""
if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    echo "Hardware: Lenovo T420s"
    echo "  • Monitor: Auto-configured"
    echo "  • Power: TLP and thermald enabled"
    if [ "$HAS_NVIDIA" = false ]; then
        echo "  • GPU: Intel HD 3000"
    else
        echo "  • GPU: Intel + NVIDIA NVS 4200M"
    fi
elif [ "$HARDWARE_PROFILE" = "surface" ]; then
    echo "Hardware: Microsoft Surface Laptop Studio"
    echo "  • Display: 2400x1600@120Hz"
    echo "  • GPU: NVIDIA RTX + Intel Iris Xe"
fi
echo ""

echo "======================================"
echo "  Access Points"
echo "======================================"
echo ""
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^open-webui$"; then
    echo "Open WebUI:    http://localhost:8080"
fi
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^ollama$"; then
    echo "Ollama API:    http://localhost:11434"
fi
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^phoneinfoga$"; then
    echo "PhoneInfoga:   http://localhost:8081"
fi
echo ""

echo "======================================"
echo "  Next Steps"
echo "======================================"
echo ""
echo "1. Restart Hyprland (log out and log back in)"
echo "2. Verify monitor setup: hyprctl monitors"
if [ -f "$HOME/.config/claude/claude_desktop_config.json" ]; then
    echo "3. Restart Claude Desktop to use MCP servers"
fi
echo ""

# Cleanup temp files
rm -f /tmp/package-selection.txt
rm -f /tmp/container-selection.txt
rm -f /tmp/ai-dev-enabled.txt
rm -f /tmp/installation-config.env

# Offer to reboot
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
