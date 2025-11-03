#!/bin/bash

# Hardware Detection Script
# Detects system type and sets appropriate configuration flags

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

detect() {
    echo -e "${BLUE}[DETECT]${NC} $1"
}

# Export variables for other scripts to use
export HARDWARE_PROFILE=""
export HAS_NVIDIA=false
export HAS_INTEL_GPU=false
export HAS_TOUCH_SCREEN=false
export HAS_SURFACE_PEN=false
export IS_LAPTOP=false
export RAM_GB=0
export CPU_GENERATION=""

echo "======================================"
echo "  Hardware Detection"
echo "======================================"
echo ""

# Detect system manufacturer
MANUFACTURER=$(cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || echo "Unknown")
PRODUCT_NAME=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "Unknown")
PRODUCT_VERSION=$(cat /sys/devices/virtual/dmi/id/product_version 2>/dev/null || echo "Unknown")

detect "Manufacturer: $MANUFACTURER"
detect "Product: $PRODUCT_NAME"
detect "Version: $PRODUCT_VERSION"

# Detect if it's a laptop
CHASSIS_TYPE=$(cat /sys/devices/virtual/dmi/id/chassis_type 2>/dev/null || echo "0")
if [ "$CHASSIS_TYPE" -eq 9 ] || [ "$CHASSIS_TYPE" -eq 10 ] || [ "$CHASSIS_TYPE" -eq 14 ]; then
    IS_LAPTOP=true
    detect "System type: Laptop"
else
    detect "System type: Desktop/Other"
fi

# Detect CPU
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
detect "CPU: $CPU_MODEL"

# Extract CPU generation (Intel)
if echo "$CPU_MODEL" | grep -qi "11th Gen"; then
    CPU_GENERATION="11"
elif echo "$CPU_MODEL" | grep -qi "10th Gen"; then
    CPU_GENERATION="10"
elif echo "$CPU_MODEL" | grep -qi "2nd Gen\|i[357]-2"; then
    CPU_GENERATION="2"
elif echo "$CPU_MODEL" | grep -qi "i[357]-3"; then
    CPU_GENERATION="3"
fi

if [ -n "$CPU_GENERATION" ]; then
    detect "CPU Generation: ${CPU_GENERATION}th Gen Intel"
fi

# Detect RAM
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$((RAM_KB / 1024 / 1024))
detect "RAM: ${RAM_GB} GB"

# Detect GPUs
detect "Scanning for GPUs..."

# Check for Intel GPU
if lspci | grep -i "VGA\|3D" | grep -qi "Intel"; then
    HAS_INTEL_GPU=true
    INTEL_GPU=$(lspci | grep -i "VGA\|3D" | grep -i "Intel" | cut -d':' -f3 | xargs)
    detect "✓ Intel GPU: $INTEL_GPU"
fi

# Check for NVIDIA GPU
if lspci | grep -i "VGA\|3D" | grep -qi "NVIDIA"; then
    HAS_NVIDIA=true
    NVIDIA_GPU=$(lspci | grep -i "VGA\|3D" | grep -i "NVIDIA" | cut -d':' -f3 | xargs)
    detect "✓ NVIDIA GPU: $NVIDIA_GPU"

    # Check if it's a modern GPU (supports recent drivers)
    if echo "$NVIDIA_GPU" | grep -Eqi "RTX|GTX 16|GTX 20|GTX 30|GTX 40"; then
        detect "  → Modern NVIDIA GPU (supports nvidia-open-dkms)"
        export NVIDIA_DRIVER="nvidia-open-dkms"
    else
        detect "  → Legacy NVIDIA GPU (needs nvidia-390xx-dkms or older)"
        export NVIDIA_DRIVER="nvidia-390xx-dkms"
    fi
fi

# Check for touch screen
if [ -d "/sys/devices/pci0000:00" ]; then
    if grep -q "ELAN\|Touchscreen\|Wacom" /proc/bus/input/devices 2>/dev/null; then
        HAS_TOUCH_SCREEN=true
        detect "✓ Touch screen detected"
    fi
fi

# Check for Surface Pen (iptsd)
if ls /dev/hidraw* 2>/dev/null | xargs -I {} udevadm info {} 2>/dev/null | grep -qi "IPTS\|Intel Precise Touch"; then
    HAS_SURFACE_PEN=true
    detect "✓ Surface Pen support detected"
fi

# Determine hardware profile
if [[ "$MANUFACTURER" == *"Microsoft"* ]] && [[ "$PRODUCT_NAME" == *"Surface"* ]]; then
    HARDWARE_PROFILE="surface"
    detect "Hardware Profile: Microsoft Surface"
elif [[ "$MANUFACTURER" == *"LENOVO"* ]] && [[ "$PRODUCT_NAME" == *"4173"* ]] || [[ "$PRODUCT_VERSION" == *"ThinkPad T420s"* ]]; then
    HARDWARE_PROFILE="t420s"
    detect "Hardware Profile: Lenovo T420s"
else
    HARDWARE_PROFILE="generic"
    detect "Hardware Profile: Generic (no specific optimizations)"
fi

echo ""
info "Hardware Detection Complete"
echo ""

# Print summary
echo "======================================"
echo "  Detection Summary"
echo "======================================"
echo "Profile: $HARDWARE_PROFILE"
echo "Laptop: $IS_LAPTOP"
echo "RAM: ${RAM_GB} GB"
echo "Intel GPU: $HAS_INTEL_GPU"
echo "NVIDIA GPU: $HAS_NVIDIA"
[ "$HAS_NVIDIA" = true ] && echo "NVIDIA Driver: $NVIDIA_DRIVER"
echo "Touch Screen: $HAS_TOUCH_SCREEN"
echo "Surface Pen: $HAS_SURFACE_PEN"
echo "======================================"
echo ""

# Export to file for other scripts
cat > /tmp/hardware-profile.env << EOF
HARDWARE_PROFILE=$HARDWARE_PROFILE
HAS_NVIDIA=$HAS_NVIDIA
HAS_INTEL_GPU=$HAS_INTEL_GPU
HAS_TOUCH_SCREEN=$HAS_TOUCH_SCREEN
HAS_SURFACE_PEN=$HAS_SURFACE_PEN
IS_LAPTOP=$IS_LAPTOP
RAM_GB=$RAM_GB
CPU_GENERATION=$CPU_GENERATION
NVIDIA_DRIVER=${NVIDIA_DRIVER:-none}
EOF

info "Hardware profile saved to /tmp/hardware-profile.env"
