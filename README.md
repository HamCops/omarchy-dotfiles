# Omarchy Dotfiles

My personal Omarchy (Arch Linux) configuration for Hyprland, optimized for Microsoft Surface Laptop Studio and Lenovo T420s.

---

## 🚀 **NEW: Unified One-Command Installer**

```bash
./install.sh
```

**Everything is now automated!** No more juggling multiple scripts. Just run `./install.sh` and it handles hardware detection, config adjustments, package installation, Docker deployment, and system setup automatically.

---

## System Overview

This dotfiles repository contains configurations for:
- **Window Manager:** Hyprland (Wayland)
- **Status Bar:** Waybar
- **Distribution:** Omarchy (Arch Linux variant)
- **Display Manager:** SDDM
- **Terminal:** Alacritty
- **Shell:** Bash
- **Theme:** Reverie (dark, elegant theme for deep focus)

📖 **See [THEME_AND_KEYBINDINGS.md](THEME_AND_KEYBINDINGS.md) for complete theme details and keybinding reference**

## What's Included

```
omarchy-dotfiles/
├── .config/
│   ├── hypr/          # Hyprland configurations
│   ├── waybar/        # Waybar status bar config
│   └── omarchy/       # Omarchy themes and settings
├── scripts/
│   ├── setup.sh       # Main dotfiles deployment script
│   └── install-packages.sh  # Package installation script
├── hardware/
│   ├── HARDWARE_DIFFERENCES.md  # Hardware-specific notes
│   ├── surface/       # Surface-specific configs
│   └── t420s/         # T420s-specific configs
├── docker/            # Docker/MCP container configs
├── scripts/
│   ├── local-bin/     # Custom scripts (monitor-switch, etc.)
│   └── *.sh           # Setup and deployment scripts
├── packages.txt       # Core additional packages (40 packages)
├── packages-ai-dev.txt  # Optional AI/ML development packages (18 packages)
├── omarchy-base-packages.txt  # Reference: base Omarchy packages (161 packages)
├── .bashrc            # Bash configuration with aliases and MCP functions
├── .bashrc-ai-dev     # Optional AI development aliases (conda, jupyter, etc.)
├── THEME_AND_KEYBINDINGS.md   # Theme and keybinding documentation
├── MCP_GATEWAY_SETUP.md       # MCP bridge/gateway documentation
├── AI_DEV_BUNDLE.md           # Optional AI/ML development bundle documentation
└── README.md          # This file
```

## Hardware Configurations

### Primary System: Microsoft Surface Laptop Studio
- **CPU:** Intel Core i7-11370H (11th Gen)
- **GPU:** NVIDIA RTX 3050 Ti + Intel Iris Xe
- **RAM:** 32 GB
- **Display:** High-DPI touchscreen with pen support
- **Special:** Surface Pen, hybrid graphics, iptsd daemon

### Secondary System: Lenovo T420s
- **CPU:** Intel Core i5/i7 (2nd Gen)
- **GPU:** Intel HD 3000 (+ optional NVIDIA NVS 4200M)
- **RAM:** 8-16 GB
- **Display:** 1600x900 standard DPI
- **Special:** TrackPoint, classic keyboard

See [hardware/HARDWARE_DIFFERENCES.md](hardware/HARDWARE_DIFFERENCES.md) for detailed differences and adjustments needed.

## Quick Start

### Prerequisites

1. Fresh Omarchy installation
2. Internet connection
3. Git installed: `sudo pacman -S git`
4. (Optional) yay AUR helper: `sudo pacman -S yay`

### Installation - ONE COMMAND!

```bash
# Clone the repository
cd ~/Projects  # or your preferred location
git clone https://github.com/YOUR_USERNAME/omarchy-dotfiles.git
cd omarchy-dotfiles

# Run the unified installer
./install.sh
```

**That's it!** The unified installer handles EVERYTHING:
- ✅ Detects your hardware (Surface, T420s, or generic)
- ✅ Runs hardware-specific adjustments automatically
- ✅ Backs up existing configs to `~/.dotfiles-backup-<timestamp>`
- ✅ Symlinks all dotfiles to `~/.config/`
- ✅ Installs ALL packages automatically
- ✅ Deploys Docker & MCP containers
- ✅ Updates system packages
- ✅ Configures services (TLP, thermald, etc.)
- ✅ Offers optional reboot

The script only asks you about:
- AI Development Bundle (optional ~18 packages, ~5GB)
- System reboot at the end

**No more running multiple scripts!** Everything is connected and runs in sequence.

### What Gets Installed

**Package counts:**
- Core packages: 40 (containers, editors, tools, etc.)
- AI-dev packages: 18 (if you enable the AI Development Bundle)
- Base Omarchy: 161 (already installed in base system)

**AI Development Bundle** (optional):
- During installation, you'll be asked if you want AI/ML development tools
- Adds: CUDA, Jupyter, conda, ML libraries (~5GB)
- Includes convenient aliases: `ai-env`, `jupyter-ai`, `gpu-monitor`
- 📖 See [AI_DEV_BUNDLE.md](AI_DEV_BUNDLE.md) for complete details

### Advanced: Manual Step-by-Step

If you prefer to run individual scripts manually, see [QUICKSTART.md](QUICKSTART.md) for step-by-step instructions.

**Note:** The old `./scripts/setup.sh` workflow is still available for advanced users who need granular control, but most users should use the unified `./install.sh`.

## Package Management

### Understanding the Package Lists

This repository uses a **filtered package approach** to avoid redundancy:

- **`omarchy-base-packages.txt`** (161 packages) - Reference list of packages included in base Omarchy installation
  - These are already installed when you install Omarchy
  - This file is for documentation purposes only

- **`packages.txt`** (58 packages) - **Additional packages** you need to install
  - Only contains packages beyond base Omarchy
  - Includes development tools, AI/ML libraries, containers, etc.
  - This is what `install-packages.sh` installs

### Regenerating the Package List

If you add more packages to your system and want to update `packages.txt`:

```bash
# Export currently installed packages
pacman -Qe > packages-new.txt

# Filter out base Omarchy packages
python3 scripts/filter-base-packages.py

# Review and replace
mv packages.txt packages.txt.backup
mv packages-additional.txt packages.txt
```

The filter script automatically excludes all base Omarchy packages, keeping only the additional ones you installed.

## Custom Scripts and Aliases

This repository includes custom bash scripts and aliases to enhance productivity.

### Custom Scripts

**Location:** `scripts/local-bin/`

All scripts are automatically linked to `~/.local/bin/` by the setup script.

#### monitor-switch

Monitor configuration switcher for different setups:

```bash
# Switch to work setup (external monitors, laptop disabled)
monitor-switch work

# Switch to home setup (laptop only)
monitor-switch home

# Switch to TV setup (4K external display)
monitor-switch tv

# Check current configuration
monitor-switch status
```

See `scripts/local-bin/monitor-switch` for details.

### Bash Aliases and Functions

**Location:** `.bashrc` and `.bashrc-ai-dev` (optional)

The repository includes a comprehensive `.bashrc` with:

#### AI Development Aliases (Optional)

**Note:** These aliases are only available if you enable the AI Development Bundle during setup.

**Location:** `.bashrc-ai-dev`

```bash
ai-env              # Activate conda ai-dev environment
ai-workspace        # cd ~/ai-workspace
ai-projects         # cd ~/ai-workspace/projects
jupyter-ai          # Launch Jupyter Lab
gpu-monitor         # Watch nvidia-smi
# ... and 10+ more AI development aliases
```

📖 **See [AI_DEV_BUNDLE.md](AI_DEV_BUNDLE.md) for complete AI-dev documentation**

#### MCP Bridge Management

```bash
mcp-start           # Start ollama-mcp-bridge
mcp-stop            # Stop the bridge
mcp-restart         # Restart the bridge
mcp-status          # Check if running
mcp-log             # View real-time logs
```

📖 **See [MCP_GATEWAY_SETUP.md](MCP_GATEWAY_SETUP.md) for complete MCP bridge documentation**

### Adding Custom Scripts

To add your own scripts:

1. Place scripts in `scripts/local-bin/`
2. Make executable: `chmod +x scripts/local-bin/my-script`
3. Run setup: `./scripts/setup.sh`
4. Script will be symlinked to `~/.local/bin/my-script`

## Manual Setup

If you prefer manual setup:

### Link configs individually:

```bash
ln -sf ~/Projects/omarchy-dotfiles/.config/hypr ~/.config/hypr
ln -sf ~/Projects/omarchy-dotfiles/.config/waybar ~/.config/waybar
ln -sf ~/Projects/omarchy-dotfiles/.config/omarchy ~/.config/omarchy
```

### Install specific packages:

```bash
# Core packages
sudo pacman -S hyprland waybar sddm alacritty

# For Surface
sudo pacman -S iptsd nvidia-open-dkms nvidia-utils

# For T420s
sudo pacman -S mesa vulkan-intel xf86-video-intel
```

## Customization

### Hyprland

Main config: `.config/hypr/hyprland.conf`

This sources multiple config files:
- `monitors.conf` - Display configuration (adjust for your resolution!)
- `input.conf` - Keyboard/mouse settings
- `bindings.conf` - Custom keybindings
- `envs.conf` - Environment variables
- `looknfeel.conf` - Visual settings
- `autostart.conf` - Auto-start applications
- `hypridle.conf` - Idle/lock timings
- `hyprlock.conf` - Lock screen appearance

### Waybar

Config: `.config/waybar/config.jsonc`
Styles: `.config/waybar/style.css`

**Note for T420s:** Remove or modify GPU monitoring widgets (they use nvidia-smi).

### Omarchy Themes

Current theme: `.config/omarchy/current/`
Available themes: `.config/omarchy/themes/`

Switch themes with the Omarchy theme manager.

## Key Features

### Hyprland Configuration
- 15 min idle → screensaver
- 20 min idle → lock session
- 25 min idle → screen off
- Fingerprint authentication enabled (hyprlock)
- Custom keybindings (see `bindings.conf`)

### Waybar Modules
- GPU temperature & VRAM monitoring (Surface only)
- Network bandwidth tracking
- Weather widget (Versailles, Ohio)
- Battery status with time estimates
- Bluetooth device counter
- System resource monitoring

### Development Environment
- Docker + Docker Compose
- 12 MCP (Model Context Protocol) servers
- Full CUDA 13.0 stack (Surface only)
- Python ML libraries (NumPy, Pandas, PyTorch tools)
- Neovim, Zed, Claude Code

## Docker Containers

See `docker/` directory for container configurations.

Active containers (Surface):
- ollama (LLM inference)
- open-webui (Web interface)
- 9x MCP servers (filesystem, docker-manager, obsidian, etc.)
- phoneinfoga (OSINT tool)

**Note:** T420s may struggle with all 12 containers. Consider disabling GPU-dependent ones.

## Troubleshooting

### Display issues
Check `monitors.conf` and adjust resolution:
```bash
# List available outputs
hyprctl monitors

# Edit monitors.conf
nano ~/.config/hypr/monitors.conf
```

### NVIDIA not working
```bash
# Check driver loaded
lspci -k | grep -A 2 -i nvidia

# Check nvidia-smi
nvidia-smi

# Reinstall driver
sudo pacman -S nvidia-open-dkms nvidia-utils
```

### Waybar not showing
```bash
# Restart waybar
pkill waybar && waybar &

# Check logs
journalctl --user -u waybar
```

### Hypridle not working
```bash
# Restart hypridle
pkill hypridle && hypridle &

# Check config
cat ~/.config/hypr/hypridle.conf
```

## Updating

### Pull latest changes:

```bash
cd ~/Projects/omarchy-dotfiles
git pull
```

Configs will update automatically (since they're symlinked).

### Export new package list:

```bash
pacman -Qe > ~/Projects/omarchy-dotfiles/packages.txt
git add packages.txt
git commit -m "Update package list"
git push
```

## Backing Up

Your original configs are backed up to `~/.dotfiles-backup-<timestamp>` when you run `setup.sh`.

To manually backup:
```bash
cp -r ~/.config/hypr ~/.config/hypr.backup
cp -r ~/.config/waybar ~/.config/waybar.backup
```

## Hardware-Specific Notes

### Surface Laptop Studio
- GPU switching handled automatically by Hyprland
- Touch/pen support via iptsd daemon
- Uses surface-optimized kernel (6.17.1-arch1-1-surface)
- Supports fingerprint authentication

### Lenovo T420s
- Intel-only graphics recommended (NVS 4200M is very old)
- Remove NVIDIA/CUDA packages if not using discrete GPU
- Adjust Waybar to remove GPU widgets
- Consider reducing idle timeouts for battery life
- May need to reduce Docker containers (less RAM)

See [hardware/HARDWARE_DIFFERENCES.md](hardware/HARDWARE_DIFFERENCES.md) for complete details.

## Contributing

This is a personal dotfiles repo, but feel free to:
- Fork it for your own use
- Submit issues if you find bugs
- Suggest improvements via pull requests

## License

MIT License - Feel free to use and modify.

## Credits

- **Omarchy** - Amazing Arch Linux distribution with great defaults
- **Hyprland** - Beautiful Wayland compositor
- **Waybar** - Customizable status bar

## Links

- [Omarchy GitHub](https://github.com/omarchy)
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Waybar Documentation](https://github.com/Alexays/Waybar)

---

**System documented:** November 2, 2025
**Primary Machine:** Microsoft Surface Laptop Studio (OmarchySurface)
**Kernel:** 6.17.1-arch1-1-surface
**Packages:** 219 explicit, 1086 total
