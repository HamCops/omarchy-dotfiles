# Quick Start Guide - Interactive TUI Installer

## One-Line Install

```bash
git clone <your-repo-url> ~/omarchy-dotfiles && cd ~/omarchy-dotfiles && ./install-interactive.sh
```

## What Happens

1. **Welcome Screen** - Introduction and overview
2. **Hardware Detection** - Automatically detects your system
3. **Choose Mode**:
   - **Full Auto** → Everything installed (fastest)
   - **Custom** → Pick what you want (recommended)
   - **Manual** → Step-by-step guidance
4. **Confirmation** - Review before installing
5. **Installation** - Automated installation with progress
6. **Reboot** - Apply all changes

## Screenshots (Text-Based UI)

### Welcome Screen
```
┌─────── Omarchy Dotfiles Installer ───────┐
│                                           │
│  This installer will guide you through:  │
│                                           │
│    • Hardware detection                  │
│    • Package selection                   │
│    • Container deployment                │
│    • AI development setup                │
│                                           │
│          Press OK to continue            │
│                                           │
└───────────────────────────────────────────┘
```

### Hardware Detection
```
┌────── Hardware Detection ──────┐
│                                │
│ Profile:    Surface Laptop     │
│ RAM:        32 GB              │
│ GPU:        Intel + NVIDIA     │
│ CPU Gen:    11                 │
│                                │
│ Hardware-specific              │
│ optimizations will be applied  │
│                                │
└────────────────────────────────┘
```

### Package Selection (Custom Mode)
```
┌──────── Select Packages ────────┐
│                                  │
│ [X] act-bin                      │
│ [X] neovim                       │
│ [X] zed                          │
│ [ ] brave-bin                    │
│ [X] docker                       │
│ [X] podman                       │
│ [ ] jellyfin-media-player        │
│                                  │
│ <  OK  >      < Cancel >         │
└──────────────────────────────────┘
```

### Container Selection
```
┌──────── Select Containers ────────┐
│                                    │
│ [X] ollama (LLM Server) ~4GB       │
│ [X] open-webui (Web UI) ~500MB     │
│ [X] mcp-docker-manager ~100MB      │
│ [ ] mcp-kali-tools ~2GB            │
│ [ ] phoneinfoga ~100MB             │
│                                    │
│ <  OK  >        < Cancel >         │
└────────────────────────────────────┘
```

### Confirmation
```
┌─────── Installation Summary ───────┐
│                                    │
│ Hardware:      Surface             │
│ Mode:          Custom              │
│                                    │
│ Packages:      35 packages         │
│ Containers:    8 containers        │
│ AI Bundle:     Enabled             │
│                                    │
│ Disk Space:    ~8.5 GB             │
│ Install Time:  ~25 minutes         │
│                                    │
│ Proceed with installation?         │
│                                    │
│  < Yes >           < No >          │
└────────────────────────────────────┘
```

## Installation Modes Explained

### 🚀 Full Automatic (Recommended for Most)
**What it does**: Installs everything compatible with your hardware
**Best for**: First-time setup, quick deployments
**Time**: ~30 minutes

### ⚙️ Custom (Recommended for Power Users)
**What it does**: You choose exactly what to install
**Best for**: Minimalist setups, specific use cases
**Time**: ~5 min config + install time

### 📖 Manual Step-by-Step
**What it does**: Explains each component as you go
**Best for**: Learning, understanding the system
**Time**: ~10 min config + install time

## What Gets Installed

### Always Installed
- Hyprland configuration files
- Waybar status bar configs
- Custom bash aliases and scripts
- Omarchy theme settings

### Selected by You (or Auto)
- System packages (Docker, Neovim, etc.)
- Docker containers (Ollama, MCP servers)
- AI Development Bundle (optional)

## AI Development Bundle

**Includes**: CUDA, Jupyter, Conda, ML libraries
**Size**: ~5 GB
**Use Case**: Machine learning, AI development, GPU computing

## Hardware-Specific Features

### Surface Laptop Studio
✅ All features available
✅ GPU containers enabled
✅ Touch/pen support
✅ High DPI scaling

### ThinkPad T420s
⚠️ GPU containers disabled
✅ Power optimizations (TLP, thermald)
✅ Legacy hardware support
✅ Battery life improvements

### Generic Systems
✅ Standard installation
✅ No hardware-specific limits

## After Installation

### Access Points
- **Open WebUI**: http://localhost:8080
- **Ollama API**: http://localhost:11434
- **PhoneInfoga**: http://localhost:8081

### Next Steps
1. **Reboot** (recommended) or restart Hyprland
2. **Verify monitors**: `hyprctl monitors`
3. **Start using**: Everything is pre-configured!

### If Using Claude Desktop
Restart Claude Desktop to enable MCP servers:
- docker-manager
- filesystem
- obsidian
- pytorch-inspector
- And more...

## Troubleshooting

### Installation Failed?
```bash
# Check logs
journalctl -xe

# Re-run just the failed step
cd ~/omarchy-dotfiles
source /tmp/hardware-profile.env
# Fix the issue, then continue
```

### Wrong Hardware Detected?
```bash
# Edit hardware profile
vim /tmp/hardware-profile.env

# Or force a profile
export HARDWARE_PROFILE=surface  # or t420s, generic
./install-interactive.sh
```

### Want to Change Selections?
```bash
# Just re-run the installer
./install-interactive.sh

# Your previous configs are backed up to:
~/.dotfiles-backup-<timestamp>
```

## Advanced Usage

### Non-Interactive (Scripted)

Create selection files manually:

```bash
# Select packages
cat > /tmp/package-selection.txt << EOF
neovim
zed
docker
podman
EOF

# Select containers
cat > /tmp/container-selection.txt << EOF
ollama
open-webui
EOF

# AI bundle
echo "yes" > /tmp/ai-dev-enabled.txt

# Run original installer (skips TUI)
./install.sh
```

### Partial Installation

```bash
# Just dotfiles and configs
cd ~/omarchy-dotfiles
./scripts/setup.sh

# Just packages
./scripts/install-packages.sh

# Just containers
cd docker && docker compose up -d
```

## Tips

1. **Use Custom mode first time** - Learn what's available
2. **Enable AI Bundle if doing ML** - Saves manual setup later
3. **Check hardware detection** - Ensures optimal config
4. **Keep backups** - Automatically saved to `~/.dotfiles-backup-*/`
5. **Reboot after install** - Ensures everything loads correctly

## Getting Help

1. Read `TUI-INSTALLER-README.md` for details
2. Check `/tmp/hardware-profile.env` for detection results
3. Review Docker logs: `docker compose logs`
4. Test package installation: `yay -S <package>`

## Uninstall

```bash
# Restore from backup
BACKUP_DIR=$(ls -dt ~/.dotfiles-backup-* | head -1)
cp -r $BACKUP_DIR/.config/* ~/.config/

# Stop containers
cd ~/omarchy-dotfiles/docker
docker compose down

# Remove packages (if desired)
# yay -R <package>
```

## Time Estimates

| Mode | Config Time | Install Time | Total |
|------|-------------|--------------|-------|
| Full Auto | 2 min | 20-30 min | ~30 min |
| Custom | 5 min | 10-25 min | ~20 min |
| Manual | 10 min | 10-25 min | ~30 min |

*Times vary based on internet speed and hardware*

## Disk Space Requirements

| Component | Space Required |
|-----------|----------------|
| Core Packages | ~2 GB |
| All Packages | ~4 GB |
| Docker Containers (all) | ~8 GB |
| AI Development Bundle | ~5 GB |
| **Maximum Total** | **~17 GB** |

## Minimum Requirements

- **OS**: Arch Linux or Omarchy Linux
- **RAM**: 4 GB (8 GB+ for AI bundle)
- **Disk**: 10 GB free
- **Internet**: Broadband (downloading packages/images)
- **User**: Non-root with sudo access

---

**Questions?** See `TUI-INSTALLER-README.md` for complete documentation.
