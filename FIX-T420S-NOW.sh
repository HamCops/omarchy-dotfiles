#!/bin/bash

# Emergency Fix for T420s
# Run this on your T420s to fix all issues

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
step() { echo -e "${CYAN}[STEP]${NC} $1"; }

clear
cat << 'EOF'
╔═══════════════════════════════════════╗
║  T420s Emergency Fix Script          ║
║  Fixes: waybar, theme, symlinks      ║
╚═══════════════════════════════════════╝
EOF
echo ""

# Detect where dotfiles are
DOTFILES_DIR=""
if [ -d "$HOME/omarchy-dotfiles" ]; then
    DOTFILES_DIR="$HOME/omarchy-dotfiles"
elif [ -d "$HOME/Projects/omarchy-dotfiles" ]; then
    DOTFILES_DIR="$HOME/Projects/omarchy-dotfiles"
else
    error "Cannot find omarchy-dotfiles directory!"
    echo "Please run this from the dotfiles directory, or:"
    echo "  cd ~/omarchy-dotfiles && bash FIX-T420S-NOW.sh"
    exit 1
fi

info "Found dotfiles at: $DOTFILES_DIR"
BACKUP_DIR="$HOME/.dotfiles-backup-EMERGENCY-$(date +%Y%m%d-%H%M%S)"
echo ""

# STEP 1: Fix symlinks
step "1/5 - Fixing Config Symlinks"
echo ""

# Backup and symlink hypr
if [ -d "$HOME/.config/hypr" ] && [ ! -L "$HOME/.config/hypr" ]; then
    warn "Backing up existing hypr config"
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.config/hypr" "$BACKUP_DIR/"
fi
ln -sf "$DOTFILES_DIR/.config/hypr" "$HOME/.config/hypr"
info "✓ hypr symlinked"

# Backup and symlink waybar
if [ -d "$HOME/.config/waybar" ] && [ ! -L "$HOME/.config/waybar" ]; then
    warn "Backing up existing waybar config"
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.config/waybar" "$BACKUP_DIR/"
fi
ln -sf "$DOTFILES_DIR/.config/waybar" "$HOME/.config/waybar"
info "✓ waybar symlinked"

# Backup and symlink omarchy (might already be linked to wrong path)
if [ -L "$HOME/.config/omarchy" ]; then
    current_target=$(readlink "$HOME/.config/omarchy")
    if [ "$current_target" != "$DOTFILES_DIR/.config/omarchy" ]; then
        warn "Fixing omarchy symlink (wrong path)"
        rm "$HOME/.config/omarchy"
        ln -sf "$DOTFILES_DIR/.config/omarchy" "$HOME/.config/omarchy"
        info "✓ omarchy re-symlinked to correct path"
    else
        info "✓ omarchy already correctly symlinked"
    fi
elif [ -d "$HOME/.config/omarchy" ]; then
    warn "Backing up existing omarchy config"
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.config/omarchy" "$BACKUP_DIR/"
    ln -sf "$DOTFILES_DIR/.config/omarchy" "$HOME/.config/omarchy"
    info "✓ omarchy symlinked"
else
    ln -sf "$DOTFILES_DIR/.config/omarchy" "$HOME/.config/omarchy"
    info "✓ omarchy symlinked"
fi

echo ""

# STEP 2: Fix theme symlinks
step "2/5 - Fixing Theme Symlinks"
echo ""

mkdir -p "$HOME/.config/omarchy/current"
cd "$HOME/.config/omarchy/current"
rm -f theme background
ln -sf ../themes/reverie theme
ln -sf theme/backgrounds/1.jpg background
info "✓ Theme symlinks created"
echo ""

# STEP 3: Fix monitor config
step "3/5 - Fixing Monitor Configuration"
echo ""

cat > "$HOME/.config/hypr/monitors.conf" << 'EOF'
# T420s Monitor Configuration
# T420s uses LVDS-1 for built-in display

# Built-in display
monitor=LVDS-1,preferred,auto,1

# External monitors
monitor=HDMI-1,preferred,auto,1
monitor=VGA-1,preferred,auto,1
monitor=DP-1,preferred,auto,1

# Fallback
monitor=,preferred,auto,1
EOF
info "✓ Monitor config fixed (LVDS-1)"
echo ""

# STEP 4: Ensure waybar in autostart
step "4/5 - Ensuring Waybar in Autostart"
echo ""

if ! grep -q "waybar" "$HOME/.config/hypr/autostart.conf" 2>/dev/null; then
    cat >> "$HOME/.config/hypr/autostart.conf" << 'EOF'

# Waybar status bar
exec-once = waybar &
EOF
    info "✓ Added waybar to autostart"
else
    info "✓ Waybar already in autostart"
fi
echo ""

# STEP 5: Install missing packages
step "5/5 - Checking Packages"
echo ""

MISSING=()
for pkg in waybar mako hypridle hyprlock networkmanager; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    warn "Missing packages: ${MISSING[*]}"
    read -p "Install missing packages? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        sudo pacman -S --noconfirm "${MISSING[@]}"
        info "✓ Packages installed"
    fi
else
    info "✓ All packages installed"
fi
echo ""

# Enable NetworkManager
if ! systemctl is-enabled NetworkManager &>/dev/null; then
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
    info "✓ NetworkManager enabled"
fi

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  FIX COMPLETE!                        ║"
echo "╚═══════════════════════════════════════╝"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    info "Backups saved to: $BACKUP_DIR"
    echo ""
fi

echo "Summary:"
echo "  ✓ hypr, waybar, omarchy symlinked to $DOTFILES_DIR"
echo "  ✓ Theme symlinks fixed (relative paths)"
echo "  ✓ Monitor config uses LVDS-1"
echo "  ✓ Waybar in autostart"
echo "  ✓ Packages verified"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Start waybar now:"
echo "   waybar &"
echo ""
echo "2. Reload Hyprland config:"
echo "   hyprctl reload"
echo ""
echo "3. OR restart Hyprland completely:"
echo "   Press Super+Shift+Q"
echo "   (or log out and log back in)"
echo ""
echo "4. To use network manager:"
echo "   nmtui"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
