# T420s Post-Installation Fixes

If you installed on your T420s and are experiencing issues, run the quick fix script:

```bash
cd ~/Projects/omarchy-dotfiles
./scripts/fix-t420s.sh
```

## Issues Fixed

### 1. Monitor Configuration Errors ❌ → ✅
**Problem:** Hyprland shows errors, display not working
**Cause:** Config used Surface monitor names (eDP-1) instead of T420s (LVDS-1)
**Fix:** Uses correct `LVDS-1` for T420s built-in display

### 2. No Waybar (Status Bar) ❌ → ✅
**Problem:** No status bar at top of screen
**Cause:** Waybar not in autostart or requires uwsm which isn't configured
**Fix:** Adds `waybar &` to autostart.conf

### 3. Theme Not Loading ❌ → ✅
**Problem:** Theme looks broken or missing
**Cause:** Theme symlinks missing or broken
**Fix:** Creates proper symlinks to Reverie theme

### 4. Network Manager TUI Not Working ❌ → ✅
**Problem:** `nmtui` command not found
**Cause:** NetworkManager not installed
**Fix:** Installs NetworkManager, network-manager-applet, nm-connection-editor

## Manual Fixes

If you prefer to fix manually:

### Fix Monitor Config
```bash
cat > ~/.config/hypr/monitors.conf << 'EOF'
# T420s uses LVDS-1 (not eDP-1)
monitor=LVDS-1,preferred,auto,1
monitor=HDMI-1,preferred,auto,1
monitor=VGA-1,preferred,auto,1
monitor=DP-1,preferred,auto,1
monitor=,preferred,auto,1
EOF
```

### Fix Waybar
```bash
# Add to autostart
echo "exec-once = waybar &" >> ~/.config/hypr/autostart.conf

# Start waybar now
pkill waybar 2>/dev/null
waybar &
```

### Install NetworkManager
```bash
sudo pacman -S networkmanager network-manager-applet nm-connection-editor
sudo systemctl enable --now NetworkManager

# Use network TUI
nmtui
```

### Fix Theme
```bash
cd ~/Projects/omarchy-dotfiles
mkdir -p ~/.config/omarchy/current
ln -sf "$PWD/.config/omarchy/themes/reverie" ~/.config/omarchy/current/theme
ln -sf ~/.config/omarchy/current/theme/backgrounds/1.jpg ~/.config/omarchy/current/background
```

## After Fixes

1. **Reload Hyprland:** Super+Shift+Q (or log out/in)
2. **Check monitors:** `hyprctl monitors`
3. **Check waybar:** Should see status bar at top
4. **Check network:** `nmtui` should open network manager

## Verify Everything Works

```bash
# Check monitor config
hyprctl monitors
# Should show LVDS-1 with your resolution

# Check waybar running
pgrep waybar
# Should return a process ID

# Check theme loaded
ls -la ~/.config/omarchy/current/theme
# Should show symlink to reverie

# Check NetworkManager
systemctl status NetworkManager
# Should show "active (running)"

# Test network TUI
nmtui
# Should open network configuration interface
```

## Common Issues

### Waybar Still Not Showing
```bash
# Kill any existing waybar
pkill waybar

# Start with verbose output to see errors
waybar -l debug

# Check waybar config
waybar --config ~/.config/waybar/config.jsonc
```

### Monitors Still Wrong
```bash
# List available monitors
hyprctl monitors

# Force reload config
hyprctl reload
```

### Theme Still Broken
```bash
# Check if theme files exist
ls ~/.config/omarchy/themes/reverie/

# Re-create symlinks
rm ~/.config/omarchy/current/theme
ln -sf ~/Projects/omarchy-dotfiles/.config/omarchy/themes/reverie ~/.config/omarchy/current/theme
```

## Prevention

For future installations, these fixes are now integrated into:
- `hardware/t420s/pre-setup.sh` - Runs before installation
- `scripts/fix-t420s.sh` - Quick fix for existing installations
- `packages.txt` - Includes NetworkManager

Run the full installer with:
```bash
./install-interactive.sh
```

The T420s-specific adjustments will be applied automatically.
