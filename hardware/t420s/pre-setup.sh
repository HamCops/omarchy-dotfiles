#!/bin/bash

# T420s Pre-Setup Script
# Adjusts configurations for Lenovo T420s hardware before main setup

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

adjust() {
    echo -e "${BLUE}[ADJUST]${NC} $1"
}

echo "======================================"
echo "  T420s Configuration Adjuster"
echo "======================================"
echo ""

info "Adjusting dotfiles for Lenovo T420s..."
echo ""

# Run hardware detection first
if [ -f "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
    info "Detecting T420s hardware configuration..."
    "$DOTFILES_DIR/scripts/detect-hardware.sh" > /dev/null 2>&1
    source /tmp/hardware-profile.env || true
else
    warn "Hardware detection not available"
    HAS_NVIDIA=false
    RAM_GB=8
fi

info "Detected: RAM=${RAM_GB}GB, NVIDIA GPU=$HAS_NVIDIA"
echo ""

# 1. Adjust Waybar config - remove NVIDIA GPU widgets ONLY if no NVIDIA
if [ "$HAS_NVIDIA" = false ]; then
    adjust "Removing NVIDIA GPU widgets from Waybar (no NVIDIA GPU detected)..."
    WAYBAR_CONFIG="$DOTFILES_DIR/.config/waybar/config.jsonc"

    if [ -f "$WAYBAR_CONFIG" ]; then
        # Create backup
        cp "$WAYBAR_CONFIG" "$WAYBAR_CONFIG.surface-backup"

        # Remove GPU temp widget
        sed -i '/"custom\/gpu-temp"/,/},/d' "$WAYBAR_CONFIG"

        # Remove GPU VRAM widget
        sed -i '/"custom\/gpu-vram"/,/},/d' "$WAYBAR_CONFIG"

        # Remove from modules-right array
        sed -i 's/"custom\/gpu-temp",//g' "$WAYBAR_CONFIG"
        sed -i 's/"custom\/gpu-vram",//g' "$WAYBAR_CONFIG"

        info "✓ Waybar config adjusted"
    else
        warn "Waybar config not found"
    fi
else
    info "Keeping NVIDIA GPU widgets (NVIDIA GPU detected: $NVIDIA_DRIVER needed)"
fi

# 2. Adjust hypridle timeouts for better battery life
adjust "Adjusting idle timeouts for battery conservation..."
HYPRIDLE_CONFIG="$DOTFILES_DIR/.config/hypr/hypridle.conf"

if [ -f "$HYPRIDLE_CONFIG" ]; then
    cp "$HYPRIDLE_CONFIG" "$HYPRIDLE_CONFIG.surface-backup"

    # Change to more aggressive timeouts for older battery
    sed -i 's/timeout = 900/timeout = 300/' "$HYPRIDLE_CONFIG"   # 5 min screensaver
    sed -i 's/timeout = 1200/timeout = 600/' "$HYPRIDLE_CONFIG"  # 10 min lock
    sed -i 's/timeout = 1500/timeout = 900/' "$HYPRIDLE_CONFIG"  # 15 min screen off

    # Update comments
    sed -i 's/# 15min/# 5min/' "$HYPRIDLE_CONFIG"
    sed -i 's/# 20min/# 10min/' "$HYPRIDLE_CONFIG"
    sed -i 's/# 25min/# 15min/' "$HYPRIDLE_CONFIG"

    info "✓ Idle timeouts adjusted for battery conservation"
else
    warn "hypridle config not found"
fi

# 3. Create T420s-specific monitor config
adjust "Creating T420s monitor configuration..."
MONITORS_CONFIG="$DOTFILES_DIR/.config/hypr/monitors.conf"

if [ -f "$MONITORS_CONFIG" ]; then
    cp "$MONITORS_CONFIG" "$MONITORS_CONFIG.surface-backup"

    cat > "$MONITORS_CONFIG" << 'EOF'
# T420s Monitor Configuration
# See https://wiki.hyprland.org/Configuring/Monitors/

# T420s uses LVDS-1 for built-in display (not eDP-1)
# Native resolutions: 1600x900 or 1366x768

# Built-in display (auto-detect resolution)
monitor=LVDS-1,preferred,auto,1

# External monitors (auto-detect when connected)
monitor=HDMI-1,preferred,auto,1
monitor=VGA-1,preferred,auto,1
monitor=DP-1,preferred,auto,1

# Fallback for any other monitors
monitor=,preferred,auto,1

# Uncomment if you need to force specific resolution:
# monitor=LVDS-1,1600x900@60,0x0,1    # For 1600x900 panel
# monitor=LVDS-1,1366x768@60,0x0,1    # For 1366x768 panel
EOF

    info "✓ Monitor config created for T420s"
else
    warn "monitors.conf not found"
fi

# 4. Adjust environment variables based on GPU
ENVS_CONFIG="$DOTFILES_DIR/.config/hypr/envs.conf"

if [ -f "$ENVS_CONFIG" ]; then
    cp "$ENVS_CONFIG" "$ENVS_CONFIG.surface-backup"

    if [ "$HAS_NVIDIA" = false ]; then
        adjust "Setting Intel GPU environment variables..."

        # Remove NVIDIA-specific variables
        sed -i '/LIBVA_DRIVER_NAME,nvidia/d' "$ENVS_CONFIG"
        sed -i '/__GLX_VENDOR_LIBRARY_NAME,nvidia/d' "$ENVS_CONFIG"
        sed -i '/WLR_DRM_DEVICES.*card1/d' "$ENVS_CONFIG"

        # Add Intel-specific variables
        cat >> "$ENVS_CONFIG" << 'EOF'

# Intel GPU settings (T420s)
env = LIBVA_DRIVER_NAME,i965
env = WLR_DRM_DEVICES,/dev/dri/card0
env = GDK_SCALE,1
env = QT_QPA_PLATFORM,wayland
EOF

        info "✓ Environment variables set for Intel GPU"
    else
        info "Keeping NVIDIA environment variables (NVIDIA GPU detected)"
        warn "Note: T420s with NVIDIA NVS 4200M needs nvidia-390xx-dkms (legacy driver)"
    fi
else
    warn "envs.conf not found"
fi

# 5. Create T420s-specific package list
adjust "Creating T420s package list..."
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
T420S_PACKAGES="$DOTFILES_DIR/hardware/t420s/packages-t420s.txt"

if [ -f "$PACKAGES_FILE" ]; then
    if [ "$HAS_NVIDIA" = false ]; then
        # Filter out Surface and NVIDIA packages (Intel-only T420s)
        info "Filtering for Intel-only configuration..."
        grep -v -E "nvidia-open-dkms|nvidia-utils|lib32-nvidia-utils|nvidia-container-toolkit|cuda|cudnn|iptsd|python-pycuda|python-cupy|libva-nvidia-driver|linux-surface|linux-surface-headers" "$PACKAGES_FILE" > "$T420S_PACKAGES"

        # Add Intel-specific packages
        cat >> "$T420S_PACKAGES" << 'EOF'
mesa
vulkan-intel
xf86-video-intel
tlp
thermald
EOF
    else
        # Keep NVIDIA but filter out modern NVIDIA drivers and Surface stuff
        info "Filtering for T420s with NVIDIA NVS 4200M..."
        grep -v -E "nvidia-open-dkms|cuda|cudnn|iptsd|python-pycuda|python-cupy|linux-surface|linux-surface-headers" "$PACKAGES_FILE" > "$T420S_PACKAGES"

        # Replace modern NVIDIA with legacy and add T420s packages
        sed -i 's/nvidia-utils/nvidia-390xx-utils/g' "$T420S_PACKAGES"
        sed -i 's/lib32-nvidia-utils/lib32-nvidia-390xx-utils/g' "$T420S_PACKAGES"

        # Add legacy NVIDIA driver and T420s packages
        cat >> "$T420S_PACKAGES" << 'EOF'
nvidia-390xx-dkms
mesa
vulkan-intel
tlp
thermald
EOF
    fi

    info "✓ T420s package list created at hardware/t420s/packages-t420s.txt"
else
    warn "packages.txt not found"
fi

# 6. Create Docker Compose override for T420s
adjust "Creating Docker Compose override (disabling GPU containers)..."
mkdir -p "$DOTFILES_DIR/docker"

cat > "$DOTFILES_DIR/docker/docker-compose.t420s.yml" << 'EOF'
version: '3.8'

# T420s Override - Disable GPU-dependent containers and reduce resource usage

services:
  # Disable GPU optimizer (needs NVIDIA)
  mcp-gpu-optimizer:
    profiles:
      - disabled

  # Disable PyTorch inspector if it uses GPU features
  mcp-pytorch-inspector:
    profiles:
      - disabled

  # Reduce Ollama resources
  ollama:
    environment:
      - OLLAMA_NUM_PARALLEL=1
      - OLLAMA_MAX_LOADED_MODELS=1
    deploy:
      resources:
        limits:
          memory: 4G
EOF

    info "✓ Docker Compose override created"

echo ""
info "T420s adjustments complete!"
echo ""
echo "Backups of original configs saved with .surface-backup extension"
echo ""
echo "Next steps:"
echo "  1. Review the changes made"
echo "  2. Run: cd $DOTFILES_DIR && ./scripts/setup.sh"
echo "  3. Install packages: ./scripts/install-packages.sh (uses T420s package list)"
echo ""
