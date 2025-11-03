# Quick Start Guide

## Fresh Installation (T420s or any new machine)

### One-Command Setup

```bash
git clone https://github.com/YOUR_USERNAME/omarchy-dotfiles.git ~/Projects/omarchy-dotfiles
cd ~/Projects/omarchy-dotfiles
./scripts/setup.sh
```

That's it! The setup script will:
1. ✅ Detect your hardware (Surface, T420s, or generic)
2. ✅ Run hardware-specific adjustments if needed
3. ✅ Backup your existing configs
4. ✅ Link dotfiles to ~/.config/
5. ✅ Offer to install packages automatically
6. ✅ Offer to deploy MCP containers

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

## Manual Commands (if you prefer step-by-step)

### 1. Hardware Detection Only
```bash
./scripts/detect-hardware.sh
```

### 2. T420s Pre-Setup (run BEFORE setup.sh)
```bash
./hardware/t420s/pre-setup.sh
```

### 3. Link Dotfiles
```bash
./scripts/setup.sh
```

### 4. Install Packages
```bash
./scripts/install-packages.sh
```
Automatically uses T420s package list if T420s detected.

### 5. Deploy MCP Containers
```bash
./scripts/deploy-mcp.sh
```
Automatically disables GPU containers on T420s.

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
├── scripts/
│   ├── setup.sh              # Main setup (run this first)
│   ├── detect-hardware.sh    # Hardware detection
│   ├── install-packages.sh   # Package installer
│   └── deploy-mcp.sh         # MCP container deployment
├── hardware/
│   ├── t420s/
│   │   └── pre-setup.sh      # T420s config adjuster
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

- **Always run `./scripts/setup.sh` first** - it handles everything
- **Answer 'y' to automation prompts** if you want hands-off setup
- **On T420s**: Answer 'Y' when asked about pre-setup adjustments
- **Backups are automatic** - check ~/.dotfiles-backup-* if you need to restore

---

Ready to deploy to your T420s? Just clone and run `./scripts/setup.sh`!
