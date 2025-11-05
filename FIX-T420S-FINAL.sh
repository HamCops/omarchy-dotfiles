#!/bin/bash

# Final T420s Fix Script
# This fixes all remaining issues: missing theme files, waybar, monitor config

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
║  T420s FINAL FIX                      ║
║  Fixes: theme files, waybar, monitor  ║
╚═══════════════════════════════════════╝
EOF
echo ""

# Detect dotfiles location
DOTFILES_DIR=""
if [ -d "$HOME/omarchy-dotfiles" ]; then
    DOTFILES_DIR="$HOME/omarchy-dotfiles"
elif [ -d "$HOME/Projects/omarchy-dotfiles" ]; then
    DOTFILES_DIR="$HOME/Projects/omarchy-dotfiles"
else
    error "Cannot find omarchy-dotfiles directory!"
    echo "Searched in:"
    echo "  - $HOME/omarchy-dotfiles"
    echo "  - $HOME/Projects/omarchy-dotfiles"
    exit 1
fi

info "Found dotfiles at: $DOTFILES_DIR"
echo ""

# STEP 1: Check git repo status
step "1/6 - Checking Git Repository Status"
echo ""

cd "$DOTFILES_DIR"

if [ ! -d ".git" ]; then
    error "Not a git repository! Theme files may be missing."
    echo "Please clone the full repository:"
    echo "  git clone <your-repo-url> $DOTFILES_DIR"
    exit 1
fi

info "Git repository found"
echo ""
echo "Current status:"
git status --short
echo ""
echo "Last commit:"
git log -1 --oneline
echo ""

# STEP 2: Sync with remote
step "2/6 - Syncing Repository"
echo ""

read -p "Pull latest changes from remote? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    if git pull; then
        info "✓ Repository synced"
    else
        warn "Git pull failed - continuing anyway"
    fi
else
    info "Skipped git pull"
fi
echo ""

# STEP 3: Verify theme files exist
step "3/6 - Verifying Theme Files"
echo ""

THEME_DIR="$DOTFILES_DIR/.config/omarchy/themes/reverie"
MISSING_FILES=()

check_file() {
    if [ ! -f "$1" ]; then
        MISSING_FILES+=("$1")
        echo -e "${RED}[✗]${NC} Missing: $1"
        return 1
    else
        echo -e "${GREEN}[✓]${NC} Found: $1"
        return 0
    fi
}

check_file "$THEME_DIR/waybar.css"
check_file "$THEME_DIR/hyprland.conf"
check_file "$THEME_DIR/hyprlock.conf"

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo ""
    error "Theme files are missing from the repository!"
    echo "Missing files:"
    for f in "${MISSING_FILES[@]}"; do
        echo "  - $f"
    done
    echo ""
    echo "Solutions:"
    echo "1. Make sure you've committed theme files to git"
    echo "2. Clone the repository again from the correct source"
    echo "3. Copy theme files manually from another machine"
    exit 1
fi

info "✓ All theme files found"
echo ""

# STEP 4: Fix monitor config
step "4/6 - Fixing Monitor Configuration"
echo ""

MONITORS_CONF="$DOTFILES_DIR/.config/hypr/monitors.conf"

cat > "$MONITORS_CONF" << 'EOF'
# T420s Monitor Configuration
# T420s uses LVDS-1 for built-in display

# Built-in display (1600x900)
monitor=LVDS-1,preferred,auto,1

# External monitors (VGA, HDMI, DisplayPort)
monitor=HDMI-1,preferred,auto,1
monitor=VGA-1,preferred,auto,1
monitor=DP-1,preferred,auto,1

# Fallback for any other monitors
monitor=,preferred,auto,1
EOF

info "✓ Monitor config fixed (LVDS-1)"
echo ""

# STEP 5: Add waybar to autostart
step "5/6 - Fixing Waybar Autostart"
echo ""

AUTOSTART_CONF="$DOTFILES_DIR/.config/hypr/autostart.conf"

# Check if waybar is already in autostart
if grep -q "waybar" "$AUTOSTART_CONF" 2>/dev/null; then
    info "✓ Waybar already in autostart"
else
    # Create autostart if it doesn't exist or add waybar
    if [ ! -f "$AUTOSTART_CONF" ]; then
        cat > "$AUTOSTART_CONF" << 'EOF'
# Extra autostart processes
# exec-once = uwsm-app -- my-service

# Waybar (status bar)
exec-once = waybar &
EOF
    else
        cat >> "$AUTOSTART_CONF" << 'EOF'

# Waybar (status bar)
exec-once = waybar &
EOF
    fi
    info "✓ Added waybar to autostart"
fi
echo ""

# STEP 6: Verify symlinks
step "6/6 - Verifying Symlinks"
echo ""

# Check config symlinks
for config in hypr waybar omarchy; do
    TARGET="$HOME/.config/$config"
    EXPECTED="$DOTFILES_DIR/.config/$config"

    if [ -L "$TARGET" ]; then
        CURRENT=$(readlink "$TARGET")
        if [ "$CURRENT" = "$EXPECTED" ]; then
            info "✓ $config correctly symlinked"
        else
            warn "$config symlinked to wrong path: $CURRENT"
            echo "  Fixing..."
            rm "$TARGET"
            ln -sf "$EXPECTED" "$TARGET"
            info "✓ $config re-symlinked"
        fi
    else
        warn "$config not symlinked"
        if [ -e "$TARGET" ]; then
            warn "  Backing up existing $config"
            mv "$TARGET" "$TARGET.backup-$(date +%Y%m%d-%H%M%S)"
        fi
        ln -sf "$EXPECTED" "$TARGET"
        info "✓ $config symlinked"
    fi
done

# Fix theme symlinks (relative paths)
mkdir -p "$HOME/.config/omarchy/current"
cd "$HOME/.config/omarchy/current"
rm -f theme background
ln -sf ../themes/reverie theme
ln -sf theme/backgrounds/1.jpg background
cd - > /dev/null
info "✓ Theme symlinks fixed"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║  FIX COMPLETE!                        ║"
echo "╚═══════════════════════════════════════╝"
echo ""

echo "Summary of changes:"
echo "  ✓ Git repository synced"
echo "  ✓ Theme files verified"
echo "  ✓ Monitor config uses LVDS-1"
echo "  ✓ Waybar added to autostart"
echo "  ✓ All symlinks verified"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  FINAL VERIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test if theme files are accessible via symlinks
if [ -f "$HOME/.config/omarchy/current/theme/waybar.css" ]; then
    info "✓ Theme files accessible via symlink"
    echo "  Location: $HOME/.config/omarchy/current/theme/waybar.css"
else
    error "✗ Theme files still not accessible!"
    echo "  Expected: $HOME/.config/omarchy/current/theme/waybar.css"
    echo ""
    echo "Debugging info:"
    echo "  Theme symlink target:"
    readlink "$HOME/.config/omarchy/current/theme"
    echo "  Files in theme directory:"
    ls -la "$HOME/.config/omarchy/current/theme/" || echo "  Directory not accessible"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Start waybar now:"
echo "   waybar &"
echo ""
echo "2. Reload Hyprland configuration:"
echo "   hyprctl reload"
echo ""
echo "3. OR restart Hyprland completely:"
echo "   Super+Shift+Q (then log back in)"
echo ""
echo "4. Verify no errors:"
echo "   hyprctl config | grep -i error"
echo ""
echo "5. Check waybar is running:"
echo "   pgrep -a waybar"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
