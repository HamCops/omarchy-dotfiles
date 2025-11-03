# Omarchy Dotfiles - Interactive TUI Installer

## Overview

This is a professional, dialog-based Terminal User Interface (TUI) installer for the Omarchy dotfiles system. It provides an intuitive, hardware-aware installation experience for Hyprland configurations, system packages, and Docker containers.

## Features

- **Hardware Detection**: Automatically detects system type (Surface, T420s, or generic) and configures optimally
- **Multiple Installation Modes**:
  - Full Automatic: One-click installation with sensible defaults
  - Custom: Choose specific packages and containers
  - Manual Step-by-Step: Guided installation with explanations
- **Interactive Package Selection**: Categorized package selection with descriptions
- **Container Management**: Select which Docker/MCP containers to deploy
- **AI Development Bundle**: Optional ML/AI development environment
- **Hardware-Aware Filtering**: Hides incompatible packages/containers based on hardware
- **Comprehensive Summaries**: Shows disk space, install time estimates, and confirmation

## Installation

### Prerequisites

The TUI installer requires:
- Python 3 (should already be installed on Arch/Omarchy)
- `python-dialog` package

The installer will automatically install `python-dialog` if missing.

### Usage

#### Quick Start

```bash
cd /path/to/omarchy-dotfiles
./install-interactive.sh
```

This will:
1. Launch the interactive TUI
2. Guide you through all configuration options
3. Execute the installation with your selections
4. Reboot (optional)

#### TUI Only (No Installation)

To run just the configuration TUI without installing:

```bash
python3 install-tui.py
```

This saves your selections to `/tmp/` files for later use.

#### Integration with Existing Scripts

The TUI can be integrated into existing installation workflows:

```bash
# Run TUI first
python3 install-tui.py

# Check exit code
if [ $? -eq 0 ]; then
    # Load configuration
    source /tmp/installation-config.env
    source /tmp/hardware-profile.env

    # Read selections
    PACKAGES=$(cat /tmp/package-selection.txt)
    CONTAINERS=$(cat /tmp/container-selection.txt)
    AI_DEV=$(cat /tmp/ai-dev-enabled.txt)

    # Your installation logic here
fi
```

## File Structure

```
omarchy-dotfiles/
├── install-tui.py              # Python TUI application
├── install-interactive.sh      # Bash wrapper (TUI + installation)
├── install.sh                  # Original automatic installer
├── packages.txt                # Core packages list
├── packages-ai-dev.txt         # AI development packages
├── docker/
│   └── docker-compose.yml      # Container definitions
└── scripts/
    ├── detect-hardware.sh      # Hardware detection
    └── ...
```

## Output Files

The TUI saves selections to temporary files:

### `/tmp/package-selection.txt`
List of selected packages (one per line):
```
act-bin
neovim
zed
ollama
...
```

### `/tmp/container-selection.txt`
List of selected containers (one per line):
```
ollama
open-webui
mcp-docker-manager
...
```

### `/tmp/ai-dev-enabled.txt`
AI development bundle status:
```
yes
```
or
```
no
```

### `/tmp/installation-config.env`
Installation configuration (bash-sourceable):
```bash
HARDWARE_PROFILE=surface
INSTALLATION_MODE=custom
PACKAGE_COUNT=35
CONTAINER_COUNT=8
AI_DEV_ENABLED=true
```

### `/tmp/hardware-profile.env`
Hardware detection results (created by `detect-hardware.sh`):
```bash
HARDWARE_PROFILE=surface
HAS_NVIDIA=true
HAS_INTEL_GPU=true
HAS_TOUCH_SCREEN=true
HAS_SURFACE_PEN=true
IS_LAPTOP=true
RAM_GB=32
CPU_GENERATION=11
NVIDIA_DRIVER=nvidia-open-dkms
```

## Installation Modes

### 1. Full Automatic Installation

- Installs all packages from `packages.txt`
- Deploys all compatible Docker containers
- Prompts only for AI Development Bundle
- Fastest option, recommended for most users

### 2. Custom Installation

- Interactive package selection with categories:
  - Core Packages (Docker, Git, Neovim, etc.)
  - Development Tools (Zed, Claude Code, etc.)
  - System Packages (kernel, drivers)
  - Optional Tools (browsers, media players)
- Interactive container selection
- AI Development Bundle prompt
- Full control over what gets installed

### 3. Manual Step-by-Step

- Guided installation with explanations at each step
- Yes/No prompts for each component:
  - Dotfiles symlinking
  - Package installation
  - Container deployment
  - AI development environment
- Best for learning what each component does

## Hardware Profiles

The TUI automatically adapts to your hardware:

### Microsoft Surface Laptop Studio
- Full feature set enabled
- GPU containers available (if NVIDIA GPU detected)
- Touch/pen support configurations
- High-resolution display settings

### Lenovo ThinkPad T420s
- Filters out incompatible packages
- Disables GPU-dependent containers
- Applies power management optimizations
- Adjusts display resolution settings
- Enables TLP and thermald for battery life

### Generic Systems
- Default configuration
- No hardware-specific optimizations
- All features available (if compatible)

## Package Categories

### Core Packages (Always Recommended)
- Docker/Podman ecosystem (buildah, podman, crun)
- Development tools (git, neovim, nano)
- Container utilities (nvidia-container-toolkit)

### Development Tools
- Modern editors (zed, claude-code)
- CI/CD tools (jenkins, drone)
- LLM tools (lmstudio)

### System Packages
- Linux kernel (linux-surface)
- Firmware updates (fwupd)
- Boot management (efibootmgr)
- Hardware drivers (iptsd, sof-firmware)

### Optional Tools
- Browsers (brave-bin)
- Media (jellyfin-media-player)
- Networking (tailscale, nmap)
- CAD (librecad)

## Docker Containers

### AI/LLM Infrastructure
- **ollama**: Local LLM inference server (~4GB)
- **open-webui**: Web UI for Ollama (~500MB)

### MCP Servers (Model Context Protocol)
- **mcp-docker-manager**: Docker management (~100MB)
- **mcp-filesystem**: File system access (~80MB)
- **mcp-obsidian**: Obsidian integration (~90MB)
- **mcp-rss-aggregator**: RSS feeds (~70MB)
- **mcp-markdown-converter**: Document conversion (~120MB)
- **mcp-pytorch-inspector**: ML model tools (~200MB)
- **mcp-gpu-optimizer**: GPU optimization (~150MB) *[NVIDIA only]*
- **mcp-librecad**: CAD tools (~300MB)
- **mcp-kali-tools**: Security testing (~2GB)

### Utilities
- **phoneinfoga**: OSINT phone number tool (~100MB)

## AI Development Bundle

When enabled, installs:

### Core Tools
- **miniconda3**: Conda environment manager
- **CUDA 13.0**: NVIDIA GPU computing toolkit
- **cuDNN**: Deep learning primitives
- **Jupyter Notebook**: Interactive development

### Python Libraries
- **NumPy, Pandas**: Data manipulation
- **Matplotlib, Seaborn, Plotly**: Visualization
- **Scikit-learn**: Machine learning
- **SciPy**: Scientific computing
- **CuPy, PyCUDA**: GPU-accelerated computing
- **PyTorch support**: Model training/inference

### Requirements
- **Disk Space**: ~5 GB
- **Package Count**: 18 additional packages
- **RAM**: 8 GB+ recommended
- **GPU**: NVIDIA recommended (but not required)

### Custom Aliases
When enabled, adds to `.bashrc-ai-dev`:
- `ai-env`: Activate Conda AI environment
- `jupyter-ai`: Start Jupyter with AI workspace
- `gpu-monitor`: Monitor GPU usage
- And more...

## Exit Codes

The TUI uses standard exit codes:

- **0**: Success, proceed with installation
- **1**: User cancelled (not an error)
- **2**: Error occurred (missing dependencies, etc.)

## Keyboard Navigation

### In Menus
- **Arrow Keys**: Navigate options
- **Enter**: Select/Confirm
- **Escape**: Go back/Cancel
- **Tab**: Move between buttons

### In Checklists
- **Space**: Toggle selection
- **Arrow Keys**: Navigate
- **Enter**: Confirm selections
- **A**: Select all (if supported)
- **N**: Select none (if supported)

## Troubleshooting

### TUI Won't Start

**Error**: `python-dialog not installed`

**Solution**:
```bash
sudo pacman -S python-dialog
```

### Display Issues

**Problem**: TUI looks corrupted or garbled

**Solution**:
```bash
export TERM=xterm-256color
./install-interactive.sh
```

### Hardware Detection Failed

**Problem**: TUI shows "generic" profile for known hardware

**Solution**:
```bash
# Run detection manually
./scripts/detect-hardware.sh

# Check results
cat /tmp/hardware-profile.env

# Re-run TUI
./install-interactive.sh
```

### Selections Not Saved

**Problem**: Bash installer doesn't see TUI selections

**Solution**:
```bash
# Check if files exist
ls -l /tmp/package-selection.txt
ls -l /tmp/container-selection.txt
ls -l /tmp/ai-dev-enabled.txt

# If missing, TUI may have failed - check exit code
python3 install-tui.py
echo $?
```

## Customization

### Adding New Packages

Edit `install-tui.py` to add packages to categories:

```python
self.core_packages = [
    "act-bin", "git-lfs", "go",
    "your-new-package"  # Add here
]
```

### Adding New Containers

Edit the `self.containers` dictionary:

```python
self.containers = {
    "your-container": {
        "name": "Your Container Name",
        "description": "What it does",
        "size": "~100MB",
        "gpu": "no",  # or "yes", "required", "optional"
        "port": "8080"  # or "none"
    }
}
```

### Changing Default Selections

In `select_packages()` or `select_containers()`, modify:

```python
# Pre-select by default
preselect = container_id in ["ollama", "open-webui", "your-container"]
```

## Integration with CI/CD

The TUI can be used in automated scenarios with pre-made selection files:

```bash
# Create selection files
echo "neovim" > /tmp/package-selection.txt
echo "zed" >> /tmp/package-selection.txt

echo "ollama" > /tmp/container-selection.txt

echo "yes" > /tmp/ai-dev-enabled.txt

# Run installer (skip TUI)
./install.sh
```

## Architecture

### TUI Flow

```
Welcome Screen
      ↓
Hardware Detection
      ↓
Installation Mode Selection
      ↓
  ┌─────────┬─────────┬─────────┐
  │  Full   │ Custom  │ Manual  │
  └─────────┴─────────┴─────────┘
      ↓         ↓         ↓
   Auto     Package  Step-by-Step
   Select   Select   Prompts
      ↓         ↓         ↓
   Container  Container Selections
   Auto       Select
      ↓         ↓         ↓
   AI Dev     AI Dev    AI Dev
   Prompt     Prompt    Prompt
      ↓         ↓         ↓
      └─────────┴─────────┘
              ↓
      Confirmation Summary
              ↓
      Save Selections
              ↓
      Completion Screen
```

### Bash Wrapper Flow

```
install-interactive.sh
      ↓
Check Dependencies
      ↓
Run install-tui.py
      ↓
Load Selections
      ↓
Symlink Dotfiles
      ↓
Hardware Pre-Setup
      ↓
Install Packages
      ↓
Deploy Containers
      ↓
Configure Services
      ↓
Final Update
      ↓
Completion + Reboot
```

## Development

### Testing the TUI

```bash
# Test TUI only (no installation)
python3 install-tui.py

# Check saved selections
cat /tmp/package-selection.txt
cat /tmp/container-selection.txt
cat /tmp/ai-dev-enabled.txt
```

### Debugging

Enable Python debugging:

```bash
python3 -u install-tui.py 2>&1 | tee tui-debug.log
```

Check bash variables:

```bash
bash -x install-interactive.sh 2>&1 | tee install-debug.log
```

### Dialog Library Documentation

- [Python Dialog Documentation](https://pythondialog.sourceforge.io/)
- [Dialog Man Page](https://linux.die.net/man/1/dialog)

## License

Same as the parent Omarchy dotfiles repository.

## Support

For issues, feature requests, or questions:
1. Check this README
2. Review the hardware detection output
3. Check `/tmp/` selection files
4. Review bash script logs

## Future Enhancements

Potential future improvements:

- [ ] Real-time progress bars during package installation
- [ ] Dependency visualization
- [ ] Rollback functionality
- [ ] Multi-language support
- [ ] Configuration profiles (minimal, full, developer, etc.)
- [ ] Network bandwidth monitoring during downloads
- [ ] Post-installation verification tests
- [ ] Integration with `awesome-omarchy-tui-bin` for system management

---

**Version**: 2.0
**Last Updated**: 2025-11-03
**Python Version**: 3.11+
**Compatible Systems**: Arch Linux, Omarchy Linux
