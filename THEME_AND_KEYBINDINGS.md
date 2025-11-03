# Theme and Keybindings

This document describes the current theme and custom keybindings configured in this dotfiles repository.

## Current Theme: Reverie

**Reverie** is an elegant dark theme designed for deep focus and productivity.

> "Where sky and shadow softly meet,
> the world outside makes its retreat.
> The mind, in silent reverie,
> is calmed by light it came to see,
> and finds itself completely free."

### Theme Details

- **Name:** Reverie
- **Style:** Dark, elegant, minimalist
- **Upstream:** https://github.com/bjarneo/omarchy-reverie-theme
- **Location:** `.config/omarchy/themes/reverie/`
- **Colors:**
  - Active border: `rgba(587ea8ee) rgba(7e9fcaee)` (Blue gradient)
  - Inactive border: `rgba(101c3888)` (Dark blue/gray)

### Theme Files

The Reverie theme includes customizations for:

- **Hyprland** (`hyprland.conf`) - Window borders and colors
- **Hyprlock** (`hyprlock.conf`) - Lock screen appearance
- **Waybar** (`waybar.css`) - Status bar styling
- **Alacritty** (`alacritty.toml`) - Terminal colors
- **Mako** (`mako.ini`) - Notification styling
- **Neovim** (`neovim.lua`) - Editor theme integration
- **Walker** (`walker.css`) - Application launcher
- **SwayOSD** (`swayosd.css`) - On-screen display
- **Wofi** (`wofi.css`) - Alternative launcher
- **btop** (`btop.theme`) - System monitor
- **Backgrounds** (`backgrounds/`) - Wallpapers

### Activating the Theme

The theme is already configured and active via symlink:

```bash
~/.config/omarchy/current/theme -> ~/.config/omarchy/themes/reverie
```

When deploying to a new system:

```bash
# The setup script creates the symlink automatically
./scripts/setup.sh

# Or manually:
ln -sf ~/.config/omarchy/themes/reverie ~/.config/omarchy/current/theme
```

### Neovim Theme Integration

For full theme integration in Neovim, install the companion Reverie theme:

```vim
" Using lazy.nvim
{
  "bjarneo/reverie.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd([[colorscheme reverie]])
  end,
}
```

---

## Custom Keybindings

All custom keybindings are defined in `.config/hypr/bindings.conf`.

### Application Launchers

| Keybind | Action | Command |
|---------|--------|---------|
| `SUPER + RETURN` | Terminal | Opens Alacritty in current working directory |
| `SUPER + SHIFT + F` | File Manager | Opens Nautilus |
| `SUPER + B` | Browser | Opens default browser |
| `SUPER + ALT + B` | Private Browser | Opens browser in private mode |
| `SUPER + N` | Editor | Opens default editor (Neovim) |
| `SUPER + T` | Activity Monitor | Opens btop in terminal |
| `SUPER + D` | Docker | Opens lazydocker |
| `SUPER + Z` | Zed Editor | Opens Zed IDE |
| `SUPER + M` | AI Dashboard | Opens MCP dashboard |
| `SUPER + G` | Signal | Opens Signal messenger |
| `SUPER + O` | Obsidian | Opens Obsidian notes |
| `SUPER + /` | Password Manager | Opens 1Password |

### Web Applications

| Keybind | Action | URL |
|---------|--------|-----|
| `SUPER + A` | ChatGPT | https://chatgpt.com |
| `SUPER + ALT + A` | Grok AI | https://grok.com |
| `SUPER + C` | Proton Calendar | https://calendar.proton.me/ |
| `SUPER + E` | Proton Mail | https://mail.proton.me/ |
| `SUPER + P` | Proton Pass | https://pass.proton.me/ |
| `SUPER + R` | Proton Drive | https://drive.proton.me/ |
| `SUPER + V` | Proton VPN | https://account.proton.me/u/0/vpn |
| `SUPER + Y` | YouTube | https://youtube.com/ |
| `SUPER + X` | X (Twitter) | https://x.com/ |
| `SUPER + ALT + X` | X Post Composer | https://x.com/compose/post |
| `SUPER + ALT + G` | WhatsApp Web | https://web.whatsapp.com/ |
| `SUPER + CTRL + G` | Google Messages | https://messages.google.com/web/conversations |

### Default Hyprland Bindings

In addition to custom bindings above, Hyprland includes default bindings for:

- **Window Management:** `SUPER + Q` (close), `SUPER + F` (fullscreen), `SUPER + SPACE` (float)
- **Workspace Switching:** `SUPER + 1-9` (switch), `SUPER + SHIFT + 1-9` (move window)
- **Window Focus:** `SUPER + Arrow Keys` or `SUPER + H/J/K/L`
- **Window Resizing:** `SUPER + R` then arrow keys
- **Screenshots:** `SUPER + SHIFT + S` (region), `PRINT` (fullscreen)
- **Launcher:** `SUPER + SPACE` (Omarchy menu)

For complete list of default bindings, see Omarchy documentation.

---

## Customizing Keybindings

To add or modify keybindings:

1. Edit `.config/hypr/bindings.conf`
2. Use the `bindd` directive for documented bindings:
   ```conf
   bindd = MODIFIERS, KEY, Description, exec, command
   ```
3. Example:
   ```conf
   bindd = SUPER, K, MyApp, exec, myapp
   ```
4. Reload Hyprland: `SUPER + SHIFT + R` or re-login

### Binding Syntax

- **Modifiers:** `SUPER`, `SHIFT`, `CTRL`, `ALT`
- **Multiple modifiers:** `SUPER SHIFT`, `SUPER ALT`
- **Special keys:** `RETURN`, `SPACE`, `ESCAPE`, `TAB`, `SLASH`
- **Action types:** `exec` (launch), `killactive` (close), `workspace` (switch)

### Unbinding Defaults

To override a default Omarchy binding:

```conf
unbind = SUPER, SPACE
bindd = SUPER, SPACE, My Custom Action, exec, my-command
```

---

## Theme Installation on New System

When setting up on a fresh Omarchy installation:

### Automatic Setup

```bash
# Clone and run setup script
git clone https://github.com/YOUR_USERNAME/omarchy-dotfiles.git
cd omarchy-dotfiles
./scripts/setup.sh
```

The setup script will:
1. ✅ Create symlinks to all configs (including theme)
2. ✅ Link `current/theme` to Reverie theme
3. ✅ Apply custom keybindings automatically
4. ✅ Preserve your existing configs as backups

### Manual Theme Installation

If you prefer manual setup:

```bash
# Link Omarchy configs
ln -sf ~/Projects/omarchy-dotfiles/.config/omarchy ~/.config/omarchy

# Activate Reverie theme
ln -sf ~/.config/omarchy/themes/reverie ~/.config/omarchy/current/theme

# Link Hyprland configs (includes bindings)
ln -sf ~/Projects/omarchy-dotfiles/.config/hypr ~/.config/hypr

# Link Waybar configs
ln -sf ~/Projects/omarchy-dotfiles/.config/waybar ~/.config/waybar

# Restart Hyprland
SUPER + SHIFT + R
```

---

## Verifying Theme and Bindings

After deployment:

### Check Active Theme

```bash
# Should point to reverie
readlink ~/.config/omarchy/current/theme
# Output: /home/YOUR_USERNAME/.config/omarchy/themes/reverie
```

### Check Keybindings

```bash
# View all active bindings
hyprctl binds

# Test a binding
# Press SUPER + Z (should open Zed)
# Press SUPER + A (should open ChatGPT)
```

### Reload Configurations

```bash
# Reload Hyprland config (includes bindings)
hyprctl reload

# Or restart Waybar
killall waybar
waybar &
```

---

## Troubleshooting

### Theme Not Applied

```bash
# Check symlink
ls -la ~/.config/omarchy/current/theme

# Recreate if needed
ln -sf ~/.config/omarchy/themes/reverie ~/.config/omarchy/current/theme

# Restart Hyprland
SUPER + SHIFT + R
```

### Keybindings Not Working

```bash
# Check if bindings.conf is being sourced
grep "bindings.conf" ~/.config/hypr/hyprland.conf

# Should include:
# source = ~/.config/hypr/bindings.conf

# Reload Hyprland
hyprctl reload
```

### Web App Bindings Launch Wrong Browser

Check your default browser:

```bash
# Set default browser
xdg-settings set default-web-browser brave-browser.desktop
# Or: chromium.desktop, firefox.desktop, etc.
```

---

## Theme Updates

The Reverie theme is tracked as a git submodule/subdirectory. To update:

```bash
cd ~/.config/omarchy/themes/reverie
git pull origin main

# Restart Hyprland to apply
SUPER + SHIFT + R
```

Or install a different theme:

```bash
# Browse available themes
omarchy-theme-browse

# Install a new theme
omarchy-theme-install https://github.com/author/theme-repo

# Switch themes
omarchy-theme-switch theme-name
```

---

## Neovim Theme

For the matching Neovim colorscheme:

**Repository:** https://github.com/bjarneo/reverie.nvim

**Installation:**

```lua
-- ~/.config/nvim/lua/plugins/theme.lua
return {
  "bjarneo/reverie.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd([[colorscheme reverie]])
  end,
}
```

---

## Credits

- **Reverie Theme:** Created by [bjarneo](https://github.com/bjarneo) / [@iamdothash](https://x.com/iamdothash)
- **Omarchy:** https://omarchy.org
- **Hyprland:** https://hyprland.org
