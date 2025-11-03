#!/bin/bash

# Diagnostic script for T420s
# Run this and share ALL the output

echo "======================================"
echo "T420s Diagnostic Output"
echo "======================================"
echo ""

echo "1. Dotfiles location:"
ls -ld ~/omarchy-dotfiles ~/Projects/omarchy-dotfiles 2>&1
echo ""

echo "2. Config symlinks:"
ls -ld ~/.config/hypr ~/.config/waybar ~/.config/omarchy 2>&1
echo ""

echo "3. Omarchy symlink target:"
readlink ~/.config/omarchy 2>&1
echo ""

echo "4. Theme symlinks:"
ls -la ~/.config/omarchy/current/ 2>&1
echo ""

echo "5. Theme files exist:"
ls ~/.config/omarchy/themes/reverie/*.conf 2>&1
echo ""

echo "6. Waybar running:"
pgrep -a waybar 2>&1 || echo "NOT RUNNING"
echo ""

echo "7. Autostart contents:"
cat ~/.config/hypr/autostart.conf 2>&1
echo ""

echo "8. Monitor config:"
cat ~/.config/hypr/monitors.conf 2>&1
echo ""

echo "9. Hyprland errors:"
hyprctl config 2>&1 | grep -i error || echo "No errors"
echo ""

echo "10. Packages installed:"
pacman -Q waybar mako hypridle hyprlock 2>&1
echo ""

echo "======================================"
echo "END DIAGNOSTIC"
echo "======================================"
