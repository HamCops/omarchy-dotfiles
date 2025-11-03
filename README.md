# Omarchy Dotfiles

My personal Omarchy (Arch Linux) configuration for Hyprland, optimized for Microsoft Surface Laptop Studio and Lenovo T420s.

## System Overview

This dotfiles repository contains configurations for:
- **Window Manager:** Hyprland (Wayland)
- **Status Bar:** Waybar
- **Distribution:** Omarchy (Arch Linux variant)
- **Display Manager:** SDDM
- **Terminal:** Alacritty
- **Shell:** Bash

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
├── packages.txt       # List of installed packages (219 explicit)
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

### Installation

#### 1. Clone this repository

```bash
cd ~/Projects  # or your preferred location
git clone https://github.com/YOUR_USERNAME/omarchy-dotfiles.git
cd omarchy-dotfiles
```

#### 2. Review and customize (IMPORTANT!)

Before running setup, review and adjust for your hardware:

```bash
# Check hardware-specific notes
cat hardware/HARDWARE_DIFFERENCES.md

# For T420s, remove incompatible packages from packages.txt:
# - nvidia-open-dkms (use nvidia-390xx-dkms if you have discrete GPU)
# - cuda, cudnn (not supported on old GPUs)
# - iptsd (no touch support)

# Edit packages.txt to remove unwanted packages:
nano packages.txt
```

#### 3. Run the setup script

```bash
./scripts/setup.sh
```

This will:
- Backup your existing configs to `~/.dotfiles-backup-<timestamp>`
- Create symlinks from this repo to `~/.config/`
- Preserve your original files

#### 4. Install packages (optional)

```bash
./scripts/install-packages.sh
```

**Warning:** This will install 200+ packages. Review `packages.txt` first and remove packages you don't want.

#### 5. Log out and log back in

Restart your session to apply all changes.

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
