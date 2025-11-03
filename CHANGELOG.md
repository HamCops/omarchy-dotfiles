# Changelog

## [2.0.0] - 2025-11-03

### 🎉 Major Release - Interactive TUI Installer

#### Added
- **Interactive TUI Installer** (`install-interactive.sh` + `install-tui.py`)
  - Professional dialog-based interface (like Arch installer)
  - Three installation modes:
    - Full Automatic: One-click install everything
    - Custom: Select packages and containers with checkboxes
    - Manual Step-by-Step: Guided installation with explanations
  - Multi-select package chooser organized by categories
  - Docker/MCP container selection with resource requirements
  - Hardware-aware filtering (hides incompatible options for T420s)
  - Disk space and time estimates
  - Progress indicators and status updates
  - Automatic backup creation
  - Comprehensive error handling

- **Unified Non-Interactive Installer** (`install.sh`)
  - Fully automated installation without prompts
  - Complete hardware detection and configuration
  - Automatic package installation
  - Docker/MCP deployment
  - System service configuration

- **Comprehensive Documentation**
  - `QUICK-START-TUI.md` - Quick reference with examples
  - `TUI-INSTALLER-README.md` - Complete technical documentation
  - `TUI-SUMMARY.md` - Executive summary
  - `INTEGRATION-GUIDE.md` - For developers integrating the TUI
  - Updated main `README.md` with TUI features
  - Updated `QUICKSTART.md` for both install methods

- **Testing & Validation**
  - `test-tui.sh` - Comprehensive validation script
  - `examples/scripted-installation.sh` - Pre-configured installation profiles

#### Fixed
- **T420s Monitor Setup** - Automatically creates proper monitor config for 1600x900/1366x768
- **Theme Loading** - Reverie theme now loads correctly after installation
- **Package Installation** - All packages install without manual intervention
- **Docker Setup** - Containers deploy automatically with hardware-aware filtering
- **Script Integration** - All scripts now run in proper sequence

#### Changed
- Package selection moved from broken menu scripts to professional TUI
- Container selection now uses interactive checkboxes instead of manual editing
- Hardware detection runs automatically at install start
- T420s pre-setup runs automatically when T420s is detected
- Installation is now a single command instead of multiple disconnected scripts

#### Technical Details
- Python 3.11+ with `python-dialog` library
- 557 lines of polished Python code
- 356 lines of bash integration
- 2000+ lines of documentation
- Exit codes: 0 (success), 1 (cancelled), 2 (error)
- Creates selection files in `/tmp/` for bash integration

### Backward Compatibility
- Old manual workflow still available for advanced users:
  - `./scripts/detect-hardware.sh`
  - `./hardware/t420s/pre-setup.sh`
  - `./scripts/setup.sh`
  - `./scripts/install-packages.sh`
  - `./scripts/deploy-mcp.sh`

## [1.0.0] - 2025-11-02

### Initial Release
- Hyprland, Waybar, Omarchy configurations
- Support for Surface Laptop Studio and T420s
- Manual installation scripts
- Docker/MCP container configs
- Basic documentation
