# Quick Start Guide

## Fresh Installation (T420s or any new machine)

### Interactive TUI Setup (Recommended)

```bash
git clone https://github.com/YOUR_USERNAME/omarchy-dotfiles.git ~/Projects/omarchy-dotfiles
cd ~/Projects/omarchy-dotfiles
./install-interactive.sh
```

**Features:**
- 🎨 Beautiful dialog-based interface
- 📦 Select packages with checkboxes
- 🐳 Choose Docker containers interactively
- 🔍 Hardware-aware (hides incompatible options for T420s)
- 📊 Shows disk space and time estimates
- 3 installation modes: Full Auto, Custom, Manual

📖 **See [QUICK-START-TUI.md](QUICK-START-TUI.md) for detailed TUI guide**

### Fully Automated Setup (No Prompts)

```bash
git clone https://github.com/YOUR_USERNAME/omarchy-dotfiles.git ~/Projects/omarchy-dotfiles
cd ~/Projects/omarchy-dotfiles
./install.sh
```

Installs everything automatically without interaction.

### What Happens on T420s

When the script detects a T420s, it will:
- Remove NVIDIA GPU monitoring widgets from Waybar
- Adjust idle timeouts for better battery life (5/10/15 min instead of 15/20/25)
- Set Intel GPU environment variables
- Create T420s-specific monitor config
- Filter out incompatible packages (CUDA, iptsd, Surface kernel, etc.)
- Disable GPU-dependent Docker containers

### What Happens on Surface

When the script detects a Surface:
- Uses configs as-is (already optimized for Surface)
- Keeps all GPU monitoring features
- Enables all MCP containers including GPU optimizer
- Uses full package list

---

## Manual Step-by-Step (Advanced Users Only)

If you prefer to run each step manually:

### 1. Hardware Detection Only
```bash
./scripts/detect-hardware.sh
```

### 2. T420s Pre-Setup (run BEFORE linking)
```bash
./hardware/t420s/pre-setup.sh
```

### 3. Link Dotfiles Only
```bash
./scripts/setup.sh
```

### 4. Install Packages Only
```bash
./scripts/install-packages.sh
```

### 5. Deploy MCP Containers Only
```bash
./scripts/deploy-mcp.sh
```

**Note:** The unified `install.sh` handles all of this automatically. Use manual steps only if you need granular control.

---

## Current Machine (Surface)

Your current setup is already deployed. To push to GitHub:

```bash
cd ~/Projects/omarchy-dotfiles
git remote add origin https://github.com/YOUR_USERNAME/omarchy-dotfiles.git
git push -u origin main
```

---

## Updating on Any Machine

```bash
cd ~/Projects/omarchy-dotfiles
git pull
```

Configs update automatically (they're symlinked).

---

## Common Tasks

### Export New Package List
```bash
pacman -Qe > ~/Projects/omarchy-dotfiles/packages.txt
cd ~/Projects/omarchy-dotfiles
git add packages.txt
git commit -m "Update package list"
git push
```

### Restart MCP Containers
```bash
cd ~/Projects/omarchy-dotfiles/docker
docker compose down
docker compose up -d
```

### Check Container Status
```bash
cd ~/Projects/omarchy-dotfiles/docker
docker compose ps
docker compose logs -f
```

### Re-run Hardware Detection
```bash
cd ~/Projects/omarchy-dotfiles
./scripts/detect-hardware.sh
cat /tmp/hardware-profile.env
```

---

## Troubleshooting

### "My configs didn't update after git pull"
Configs are symlinked, so they update automatically. Try:
```bash
ls -la ~/.config/hypr  # Should show symlink
```

### "Waybar shows errors about GPU"
You're probably on T420s but didn't run the pre-setup script:
```bash
cd ~/Projects/omarchy-dotfiles
./hardware/t420s/pre-setup.sh
pkill waybar && waybar &
```

### "Docker containers won't start"
Check if Docker is running:
```bash
sudo systemctl status docker
sudo systemctl start docker
```

### "Package installation failed"
Check if yay is installed:
```bash
sudo pacman -S yay
```

---

## Files Overview

```
omarchy-dotfiles/
├── install.sh                # 🌟 UNIFIED INSTALLER - RUN THIS!
├── scripts/
│   ├── setup.sh              # Dotfiles linking only (used by install.sh)
│   ├── detect-hardware.sh    # Hardware detection (used by install.sh)
│   ├── install-packages.sh   # Package installer (used by install.sh)
│   └── deploy-mcp.sh         # MCP deployment (used by install.sh)
├── hardware/
│   ├── t420s/
│   │   └── pre-setup.sh      # T420s config adjuster (used by install.sh)
│   └── surface/
│       └── README.md         # Surface-specific notes
├── docker/
│   └── docker-compose.yml    # All MCP containers
├── .config/
│   ├── hypr/                 # Hyprland configs
│   ├── waybar/               # Waybar configs
│   └── omarchy/              # Omarchy themes
└── packages.txt              # Package list
```

---

## Quick Tips

- **Just run `./install.sh`** - Everything is automated!
- **On T420s**: The installer automatically detects and adjusts configs
- **Backups are automatic** - check ~/.dotfiles-backup-* if you need to restore
- **No prompts for core setup** - Only asks about AI Development bundle and reboot

---

Ready to deploy to your T420s? Just clone and run `./install.sh`!
