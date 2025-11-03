# Hardware-Specific Configurations

This document outlines the key differences between hardware setups and what needs to be adjusted.

## Surface Laptop Studio vs Lenovo T420s

### Surface Laptop Studio (Current Setup)

**CPU:** Intel Core i7-11370H (11th Gen, Tiger Lake)
**GPU:**
- Intel Iris Xe (integrated)
- NVIDIA GeForce RTX 3050 Ti Mobile (discrete)
**RAM:** 32 GB
**Display:** High-DPI touchscreen with pen support
**Special Features:**
- Touch screen support
- Surface Pen support (iptsd daemon)
- Hybrid graphics (Intel + NVIDIA)

**Required Packages:**
```
nvidia-open-dkms
nvidia-utils
lib32-nvidia-utils
nvidia-container-toolkit
iptsd
linux-surface (or surface kernel)
```

**Required Services:**
```
iptsd@dev-hidraw7.service  # For pen/touch support
```

---

### Lenovo T420s

**CPU:** Intel Core i5/i7 (2nd Gen, Sandy Bridge)
**GPU:**
- Intel HD Graphics 3000 (integrated)
- Optional: NVIDIA NVS 4200M (discrete, older)
**RAM:** Typically 8-16 GB max
**Display:** Standard 1600x900 or 1366x768 (no touch)
**Special Features:**
- TrackPoint
- Classic ThinkPad keyboard
- Easier to service/upgrade

**Required Packages:**
```
mesa                    # Intel graphics
xf86-video-intel       # Intel driver
vulkan-intel           # Vulkan support
```

**If NVIDIA NVS 4200M present:**
```
nvidia-390xx-dkms      # Legacy NVIDIA driver (NVS 4200M is old)
nvidia-390xx-utils
```

**NOT NEEDED on T420s:**
- iptsd (no touch/pen)
- nvidia-open-dkms (newer drivers won't work)
- Surface-specific kernel patches

---

## Configuration Adjustments Needed

### 1. GPU Drivers

**Surface (NVIDIA RTX 3050 Ti):**
- Uses: nvidia-open-dkms 580.95.05
- Supports: CUDA 13.0, ray tracing, DLSS

**T420s (Intel HD 3000 or NVIDIA NVS 4200M):**
- Intel: Use mesa + vulkan-intel
- NVIDIA: Use nvidia-390xx-dkms (legacy driver)
- No CUDA support on NVS 4200M (too old)

### 2. Waybar Configuration

**GPU Monitoring Widgets:**

Current config has NVIDIA-specific widgets:
```json
"custom/gpu-temp": {
  "exec": "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits"
}
```

For T420s, either:
- Remove GPU widgets (if using Intel only)
- Modify for Intel GPU monitoring:
  ```bash
  cat /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input | awk '{print $1/1000}'
  ```

### 3. Hyprland Environment Variables

**Surface (Hybrid Graphics):**
```bash
env = WLR_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0  # NVIDIA + Intel
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```

**T420s (Intel Only):**
```bash
env = WLR_DRM_DEVICES,/dev/dri/card0  # Intel only
env = LIBVA_DRIVER_NAME,i965
# Remove NVIDIA env vars
```

### 4. Power Management

**Surface:**
- Has power-profiles-daemon
- 56Wh battery (good battery life)
- Aggressive idle timeouts (15/20/25 min)

**T420s:**
- Older battery (likely degraded)
- Consider shorter idle timeouts to save battery
- May need tlp or auto-cpufreq for better battery management

Suggested hypridle.conf for T420s:
```
timeout = 300   # 5min screensaver
timeout = 600   # 10min lock
timeout = 900   # 15min screen off
```

### 5. Display Scaling

**Surface:**
- High DPI (likely 2400x1600 or similar)
- May use scaling: `env = GDK_SCALE,2`

**T420s:**
- 1600x900 or 1366x768 (standard DPI)
- No scaling needed
- Remove or set `GDK_SCALE=1`

### 6. Docker & Containers

**Surface:**
- 12 running containers (including GPU-dependent ones)
- GPU passthrough enabled for containers

**T420s:**
- May struggle with 12 containers (less RAM, weaker CPU)
- Disable GPU-specific containers:
  - mcp-gpu-optimizer (needs NVIDIA)
  - mcp-pytorch-inspector (if using GPU features)
- Consider reducing Ollama model sizes or disabling

### 7. Monitor Configuration

**Surface:**
Current `monitors.conf` is configured for Surface's display.

**T420s:**
Will need different resolution:
```
monitor=,1600x900@60,0x0,1  # For 1600x900 panel
# or
monitor=,1366x768@60,0x0,1  # For 1366x768 panel
```

External monitor support should work the same.

---

## Quick Setup Guide

### For T420s:

1. **Before running setup.sh:**
   ```bash
   cd ~/Projects/omarchy-dotfiles/hardware/t420s
   ./pre-setup.sh  # Adjusts configs for T420s hardware
   ```

2. **Run main setup:**
   ```bash
   cd ~/Projects/omarchy-dotfiles
   ./scripts/setup.sh
   ```

3. **Install T420s-specific packages:**
   ```bash
   # Don't install NVIDIA packages unless you have NVS 4200M
   # Remove these from packages.txt:
   # - nvidia-open-dkms
   # - nvidia-utils
   # - lib32-nvidia-utils
   # - nvidia-container-toolkit
   # - cuda
   # - cudnn
   ```

4. **Adjust Waybar:**
   Remove GPU monitoring widgets or replace with Intel equivalents

5. **Test and adjust:**
   Log in to Hyprland and verify everything works

---

## Package Differences Summary

### Remove for T420s:
- nvidia-open-dkms
- nvidia-utils
- lib32-nvidia-utils
- nvidia-container-toolkit
- cuda
- cuda-tools
- cudnn
- iptsd
- python-pycuda
- python-cupy

### Add for T420s:
- mesa
- vulkan-intel
- xf86-video-intel
- tlp (for better battery management)
- thermald (for thermal management)

### Optional for T420s with NVIDIA NVS 4200M:
- nvidia-390xx-dkms
- nvidia-390xx-utils
