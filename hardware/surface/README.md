# Surface-Specific Configuration

This directory contains Microsoft Surface-specific configurations and notes.

## Surface Laptop Studio

Your current setup is optimized for:
- **Model:** Surface Laptop Studio
- **CPU:** Intel Core i7-11370H (11th Gen)
- **GPU:** NVIDIA RTX 3050 Ti + Intel Iris Xe (hybrid graphics)
- **Display:** High-DPI touchscreen with pen support
- **Kernel:** linux-surface or surface-patched kernel

## Required Packages

```bash
# Surface kernel
linux-surface
linux-surface-headers

# Touch and pen support
iptsd

# NVIDIA drivers (modern GPU)
nvidia-open-dkms
nvidia-utils
lib32-nvidia-utils
libva-nvidia-driver
nvidia-container-toolkit

# CUDA (for ML/AI)
cuda
cuda-tools
cudnn

# Python GPU libraries
python-pycuda
python-cupy
```

## Configuration Features

### Hyprland
- Hybrid graphics support (NVIDIA + Intel)
- High-DPI scaling configured
- Touch and pen input enabled

### Waybar
- GPU temperature monitoring (NVIDIA)
- GPU VRAM usage display
- Custom weather widget

### Power Management
- Idle timeouts: 15/20/25 minutes
- Power profiles daemon
- Fingerprint authentication

## Services

Enable these systemd services:
```bash
sudo systemctl enable iptsd@dev-hidraw7.service  # Touch/pen
sudo systemctl enable power-profiles-daemon.service
```

## Notes

- The dotfiles in the main directory are already configured for Surface
- No pre-setup script needed (this is the reference configuration)
- If deploying to T420s, use the T420s pre-setup script instead
