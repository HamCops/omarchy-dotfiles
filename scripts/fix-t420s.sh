#!/bin/bash

# Quick Fix Script for T420s Issues
# Run this on your T420s to fix monitor, waybar, theme, and network issues

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
echo "  T420s Quick Fix Script"
echo "======================================"
echo ""

# 1. Fix Monitor Configuration
info "Fixing monitor configuration..."
cat > "$HOME/.config/hypr/monitors.conf" << 'EOF'
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
info "✓ Monitor config fixed (using LVDS-1)"

# 2. Fix Waybar Autostart
info "Fixing waybar autostart..."
if ! grep -q "exec-once.*waybar" "$HOME/.config/hypr/autostart.conf" 2>/dev/null; then
    cat >> "$HOME/.config/hypr/autostart.conf" << 'EOF'

# Waybar (status bar)
exec-once = waybar &
EOF
    info "✓ Added waybar to autostart"
else
    info "✓ Waybar already in autostart"
fi

# 3. Install NetworkManager if missing
info "Checking NetworkManager..."
if ! pacman -Q networkmanager &>/dev/null; then
    warn "NetworkManager not installed"
    read -p "Install NetworkManager? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo pacman -S --noconfirm networkmanager network-manager-applet nm-connection-editor
        sudo systemctl enable NetworkManager
        sudo systemctl start NetworkManager
        info "✓ NetworkManager installed and enabled"
    fi
else
    info "✓ NetworkManager already installed"

    # Make sure it's enabled
    if ! systemctl is-enabled NetworkManager &>/dev/null; then
        sudo systemctl enable NetworkManager
        sudo systemctl start NetworkManager
        info "✓ NetworkManager enabled"
    fi
fi

# 4. Fix Theme Symlinks
info "Checking theme symlinks..."
if [ ! -L "$HOME/.config/omarchy/current/theme" ]; then
    warn "Theme symlink missing, creating..."
    mkdir -p "$HOME/.config/omarchy/current"
    ln -sf "$DOTFILES_DIR/.config/omarchy/themes/reverie" "$HOME/.config/omarchy/current/theme"
    ln -sf "$HOME/.config/omarchy/current/theme/backgrounds/1.jpg" "$HOME/.config/omarchy/current/background"
    info "✓ Theme symlinks created"
else
    info "✓ Theme symlinks OK"
fi

# 5. Check for missing packages
echo ""
info "Checking for critical packages..."
MISSING=()

for pkg in waybar mako hypridle hyprlock networkmanager; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    warn "Missing packages: ${MISSING[*]}"
    echo ""
    read -p "Install missing packages? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        for pkg in "${MISSING[@]}"; do
            info "Installing $pkg..."
            sudo pacman -S --noconfirm "$pkg" || warn "Failed to install $pkg"
        done
    fi
fi

echo ""
echo "======================================"
info "Fix Complete!"
echo "======================================"
echo ""
echo "Changes made:"
echo "  ✓ Monitor config uses LVDS-1 (T420s display)"
echo "  ✓ Waybar added to autostart"
echo "  ✓ NetworkManager installed and enabled"
echo "  ✓ Theme symlinks verified"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (or reload Hyprland)"
echo "  2. To reload Hyprland: Super+Shift+Q"
echo "  3. To check monitors: hyprctl monitors"
echo "  4. To start NetworkManager TUI: nmtui"
echo ""
echo "If waybar doesn't show:"
echo "  pkill waybar && waybar &"
echo ""
