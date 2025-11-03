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

# 1. Adjust Waybar config - remove NVIDIA GPU widgets
adjust "Removing NVIDIA GPU widgets from Waybar..."
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
# Native resolution: 1600x900 or 1366x768

# Detect and use preferred resolution
monitor=,preferred,auto,1

# If you have specific monitor, uncomment and adjust:
# monitor=LVDS-1,1600x900@60,0x0,1    # For 1600x900 panel
# monitor=LVDS-1,1366x768@60,0x0,1    # For 1366x768 panel

# External monitor (auto-detect)
monitor=HDMI-A-1,preferred,auto,1
monitor=VGA-1,preferred,auto,1
EOF

    info "✓ Monitor config created for T420s"
else
    warn "monitors.conf not found"
fi

# 4. Adjust environment variables for Intel GPU
adjust "Setting Intel GPU environment variables..."
ENVS_CONFIG="$DOTFILES_DIR/.config/hypr/envs.conf"

if [ -f "$ENVS_CONFIG" ]; then
    cp "$ENVS_CONFIG" "$ENVS_CONFIG.surface-backup"

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
    warn "envs.conf not found"
fi

# 5. Create T420s-specific package list
adjust "Creating T420s package list..."
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
T420S_PACKAGES="$DOTFILES_DIR/hardware/t420s/packages-t420s.txt"

if [ -f "$PACKAGES_FILE" ]; then
    # Filter out Surface/NVIDIA-specific packages
    grep -v -E "nvidia-open-dkms|nvidia-utils|lib32-nvidia-utils|nvidia-container-toolkit|cuda|cudnn|iptsd|python-pycuda|python-cupy" "$PACKAGES_FILE" > "$T420S_PACKAGES"

    # Add T420s-specific packages
    cat >> "$T420S_PACKAGES" << 'EOF'
mesa
vulkan-intel
xf86-video-intel
tlp
thermald
EOF

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
