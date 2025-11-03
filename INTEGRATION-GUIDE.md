# Integration Guide - Adding TUI to Existing Setup

## For Repository Maintainers

This guide explains how to integrate the new TUI installer into your existing dotfiles repository and documentation.

## Files Added

```
omarchy-dotfiles/
├── install-tui.py              # NEW - Python TUI application
├── install-interactive.sh      # NEW - Bash wrapper script
├── TUI-INSTALLER-README.md     # NEW - Comprehensive TUI docs
├── QUICK-START-TUI.md          # NEW - Quick start guide
└── INTEGRATION-GUIDE.md        # NEW - This file
```

## Quick Integration Steps

### 1. Update Main README.md

Add to the installation section:

```markdown
## Installation

### Interactive Installation (Recommended)

Use the new interactive TUI installer for a guided experience:

\`\`\`bash
git clone <your-repo> ~/omarchy-dotfiles
cd ~/omarchy-dotfiles
./install-interactive.sh
\`\`\`

This provides:
- Hardware detection and optimization
- Interactive package selection
- Container deployment choices
- AI development bundle option

See [Quick Start Guide](QUICK-START-TUI.md) for details.

### Automatic Installation

For fully automated installation (no prompts):

\`\`\`bash
git clone <your-repo> ~/omarchy-dotfiles
cd ~/omarchy-dotfiles
./install.sh
\`\`\`

### Manual Installation

See [Manual Installation](docs/manual-install.md) for step-by-step instructions.
```

### 2. Update Documentation Structure

Reorganize docs to include TUI:

```
docs/
├── README.md                    # Overview of documentation
├── QUICK-START-TUI.md           # Quick start for TUI
├── TUI-INSTALLER-README.md      # Complete TUI documentation
├── installation/
│   ├── automatic.md             # Original install.sh
│   ├── interactive.md           # New TUI installer
│   └── manual.md                # Manual steps
└── ...
```

### 3. Add to Table of Contents

Update your main README's table of contents:

```markdown
## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [Interactive (TUI)](#interactive-installation-recommended) ← NEW
  - [Automatic](#automatic-installation)
  - [Manual](#manual-installation)
- [Hardware Support](#hardware-support)
- [Documentation](#documentation)
  - [Quick Start Guide](QUICK-START-TUI.md) ← NEW
  - [TUI Installer Docs](TUI-INSTALLER-README.md) ← NEW
  - [Package List](packages.txt)
  - [Docker Containers](docker/README.md)
```

## Updating Existing Scripts

### Option A: Replace install.sh (Recommended)

Rename the old installer and make the TUI the default:

```bash
mv install.sh install-auto.sh
mv install-interactive.sh install.sh
```

Then update the wrapper to call the old script:

```bash
# In install.sh (formerly install-interactive.sh)
# After TUI completes, source old installer logic
# or extract the bash installation code to a library
```

### Option B: Keep Both (Current Setup)

Keep both installers side-by-side:
- `install.sh` - Original automatic installer
- `install-interactive.sh` - New TUI installer

Users choose based on preference.

### Option C: Use TUI as Frontend Only

Make `install.sh` detect if terminal is interactive:

```bash
#!/bin/bash

# At the start of install.sh, add:
if [ -t 0 ] && [ -t 1 ]; then
    # Interactive terminal detected
    if command -v python3 &> /dev/null; then
        # Try to run TUI
        if python3 -c "import dialog" 2>/dev/null; then
            echo "Starting interactive installer..."
            exec ./install-interactive.sh
        fi
    fi
fi

# Fall back to automatic installation
echo "Running automatic installation..."
# ... rest of original install.sh
```

## Git Integration

### Commit the Changes

```bash
git add install-tui.py install-interactive.sh
git add TUI-INSTALLER-README.md QUICK-START-TUI.md INTEGRATION-GUIDE.md
git commit -m "Add interactive TUI installer with hardware detection and package selection"
```

### Update .gitignore

Add to `.gitignore` if not already present:

```gitignore
# TUI temporary files (usually in /tmp, but just in case)
**/package-selection.txt
**/container-selection.txt
**/ai-dev-enabled.txt
**/installation-config.env
**/hardware-profile.env
```

### Create Release Notes

```markdown
## v2.0.0 - Interactive TUI Installer

### New Features
- **Interactive TUI Installer**: Professional dialog-based installation interface
- **Hardware Detection**: Automatic system detection and optimization
- **Package Selection**: Choose exactly what to install with categorized lists
- **Container Management**: Select which Docker/MCP containers to deploy
- **AI Development Bundle**: Optional ML/AI environment setup
- **Multiple Installation Modes**: Full auto, custom, or manual step-by-step

### Improvements
- Hardware-aware filtering (hides incompatible packages)
- Disk space and time estimates
- Comprehensive confirmation summaries
- Better error handling and user feedback

### Migration
- Existing `install.sh` still works for automated installations
- New `install-interactive.sh` provides guided experience
- All configs backed up automatically

See [Quick Start Guide](QUICK-START-TUI.md) and [TUI Documentation](TUI-INSTALLER-README.md).
```

## Testing Checklist

Before releasing, test on different systems:

### Test Scenarios

- [ ] Fresh Arch Linux install
- [ ] Fresh Omarchy Linux install
- [ ] Surface Laptop (if available)
- [ ] ThinkPad T420s (if available)
- [ ] Generic desktop/laptop
- [ ] With NVIDIA GPU
- [ ] Without NVIDIA GPU (Intel only)
- [ ] Low RAM system (4-8GB)
- [ ] High RAM system (16GB+)

### Test Cases

- [ ] Full automatic installation
- [ ] Custom installation with minimal packages
- [ ] Custom installation with all packages
- [ ] Manual step-by-step installation
- [ ] Cancel during package selection
- [ ] Cancel during container selection
- [ ] Enable AI development bundle
- [ ] Disable AI development bundle
- [ ] Installation with missing `python-dialog`
- [ ] Installation without sudo password cached
- [ ] Re-run installer over existing installation

### Validation

After each test:

- [ ] Check `/tmp/package-selection.txt` exists and is correct
- [ ] Check `/tmp/container-selection.txt` exists and is correct
- [ ] Check `/tmp/ai-dev-enabled.txt` is "yes" or "no"
- [ ] Verify hardware detection in `/tmp/hardware-profile.env`
- [ ] Ensure dotfiles are symlinked correctly
- [ ] Verify Docker containers are running
- [ ] Test MCP servers in Claude Desktop (if applicable)
- [ ] Check for backup directory creation
- [ ] Verify no errors in system logs

## Dependencies

Document the new dependency:

### In README.md

```markdown
## Prerequisites

- Arch Linux or Omarchy Linux
- Python 3.11+ (pre-installed)
- `python-dialog` (auto-installed if missing)
- `yay` AUR helper (for package installation)
- Docker or Podman (for containers)
```

### In PKGBUILD (if packaging)

```bash
depends=(
    'python>=3.11'
    'python-dialog'
    'dialog'
    'bash'
    # ... other deps
)
```

## User Migration

For existing users, provide migration instructions:

### In README or CHANGELOG

```markdown
## Migrating from Old Installer

If you previously used the automatic installer:

1. **Backup your config**: Automatic backups are created, but manual backup recommended
   \`\`\`bash
   cp -r ~/.config ~/.config-backup-$(date +%Y%m%d)
   \`\`\`

2. **Pull latest changes**:
   \`\`\`bash
   cd ~/omarchy-dotfiles
   git pull
   \`\`\`

3. **Run new installer**:
   \`\`\`bash
   ./install-interactive.sh
   \`\`\`

4. **Choose "Custom"** mode to see what's new and select packages

5. **Verify everything works** after reboot

Your old configs are preserved and symlinks are updated, not replaced.
```

## Documentation Updates

### Create docs/installation/ Structure

```bash
mkdir -p docs/installation
```

Create `docs/installation/README.md`:

```markdown
# Installation Options

Choose the installation method that works best for you.

## 🚀 Interactive TUI (Recommended)

Best for most users. Provides guided setup with hardware detection.

**See**: [Quick Start Guide](../../QUICK-START-TUI.md)

**Details**: [TUI Documentation](../../TUI-INSTALLER-README.md)

## ⚡ Automatic

Fastest option. Installs everything with default settings.

**See**: [Automatic Installation](automatic.md)

## 🔧 Manual

Complete control. Install components one by one.

**See**: [Manual Installation](manual.md)
```

## CI/CD Integration

If you have CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Test TUI Installer

on: [push, pull_request]

jobs:
  test-tui:
    runs-on: ubuntu-latest
    container:
      image: archlinux:latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install dependencies
        run: |
          pacman -Syu --noconfirm
          pacman -S --noconfirm python python-dialog dialog

      - name: Test TUI (dry-run)
        run: |
          # Create mock selections
          echo "neovim" > /tmp/package-selection.txt
          echo "ollama" > /tmp/container-selection.txt
          echo "no" > /tmp/ai-dev-enabled.txt

          # Test that TUI can parse these
          python3 install-tui.py --help || true

      - name: Validate scripts
        run: |
          bash -n install-interactive.sh
          python3 -m py_compile install-tui.py
```

## Support and Troubleshooting

Add to your support documentation:

```markdown
## Getting Help with TUI Installer

### Common Issues

**TUI Won't Start**
- Ensure `python-dialog` is installed: `sudo pacman -S python-dialog`
- Check Python version: `python3 --version` (needs 3.11+)

**Hardware Detection Wrong**
- Manually edit `/tmp/hardware-profile.env`
- Or run detection separately: `./scripts/detect-hardware.sh`

**Selections Not Applied**
- Check `/tmp/package-selection.txt` exists
- Verify permissions: `ls -l /tmp/*.txt`

**Want to Re-run Without TUI**
- Use the original installer: `./install.sh` (if separate)
- Or create selection files manually (see Advanced Usage)

### Reporting Bugs

When reporting TUI issues, include:
1. Hardware profile: `cat /tmp/hardware-profile.env`
2. System info: `uname -a`
3. Python version: `python3 --version`
4. Dialog version: `dialog --version`
5. Error messages (full output)
```

## Next Steps

After integration:

1. **Update repository description** to mention interactive installer
2. **Add screenshots** (use `dialog` screenshot tools or describe UI)
3. **Update demo videos** if you have them
4. **Announce in changelog** and release notes
5. **Update wiki/docs** if you maintain one
6. **Test thoroughly** on all supported hardware
7. **Get user feedback** and iterate

## Future Enhancements

Consider these for future versions:

- [ ] Add `--help` flag to TUI with usage info
- [ ] Create `.desktop` file for GUI launcher
- [ ] Add configuration profiles (minimal, developer, full)
- [ ] Implement dry-run mode
- [ ] Add package dependency resolution visualization
- [ ] Create web-based alternative for remote installation
- [ ] Add localization support
- [ ] Integrate with system update notifications

## Rollback Plan

If issues arise, rollback is simple:

```bash
# Revert to old installer
git revert <commit-hash>

# Or just remove TUI files
rm install-tui.py install-interactive.sh
rm TUI-INSTALLER-README.md QUICK-START-TUI.md

# Keep old install.sh as primary
git commit -m "Temporarily disable TUI installer"
```

Users can continue with `install.sh` as before.

---

**Need Help?** Open an issue or discussion in the repository.
