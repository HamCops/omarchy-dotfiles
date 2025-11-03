#!/bin/bash

# Example: Scripted Installation (Non-Interactive)
# This demonstrates how to bypass the TUI and create selections programmatically

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Creating Scripted Installation Profile${NC}"
echo ""

# ===========================================
# Define Your Installation Profile
# ===========================================

# Example 1: Minimal Developer Setup
PROFILE="minimal-dev"

if [ "$PROFILE" = "minimal-dev" ]; then
    echo "Profile: Minimal Developer Setup"

    # Core development packages only
    cat > /tmp/package-selection.txt << EOF
act-bin
git-lfs
go
neovim
zed
buildah
podman
podman-compose
claude-code
rust
nano
EOF

    # Essential containers only
    cat > /tmp/container-selection.txt << EOF
ollama
open-webui
mcp-docker-manager
mcp-filesystem
EOF

    # No AI dev bundle
    echo "no" > /tmp/ai-dev-enabled.txt

# Example 2: Full AI/ML Developer Setup
elif [ "$PROFILE" = "ai-developer" ]; then
    echo "Profile: AI/ML Developer Setup"

    # All development packages
    cat > /tmp/package-selection.txt << EOF
act-bin
git-lfs
go
neovim
zed
buildah
podman
podman-compose
claude-code
rust
nano
lmstudio
jupyter-notebook
EOF

    # AI-focused containers
    cat > /tmp/container-selection.txt << EOF
ollama
open-webui
mcp-docker-manager
mcp-filesystem
mcp-pytorch-inspector
mcp-gpu-optimizer
EOF

    # Enable AI dev bundle
    echo "yes" > /tmp/ai-dev-enabled.txt

# Example 3: Security/Pentesting Setup
elif [ "$PROFILE" = "security" ]; then
    echo "Profile: Security/Pentesting Setup"

    # Security tools
    cat > /tmp/package-selection.txt << EOF
neovim
nmap
buildah
podman
podman-compose
tailscale
swaks
EOF

    # Security containers
    cat > /tmp/container-selection.txt << EOF
mcp-kali-tools
phoneinfoga
mcp-docker-manager
EOF

    # No AI dev
    echo "no" > /tmp/ai-dev-enabled.txt

# Example 4: Content Creator Setup
elif [ "$PROFILE" = "content-creator" ]; then
    echo "Profile: Content Creator Setup"

    # Content tools
    cat > /tmp/package-selection.txt << EOF
neovim
nano
brave-bin
jellyfin-media-player
librecad
EOF

    # Content containers
    cat > /tmp/container-selection.txt << EOF
mcp-filesystem
mcp-markdown-converter
mcp-librecad
mcp-obsidian
EOF

    # No AI dev
    echo "no" > /tmp/ai-dev-enabled.txt
fi

# ===========================================
# Create Installation Config
# ===========================================

# Detect hardware first (optional - installer will do this)
if [ -f "$(dirname "$0")/../scripts/detect-hardware.sh" ]; then
    echo "Detecting hardware..."
    "$(dirname "$0")/../scripts/detect-hardware.sh" > /dev/null 2>&1 || true

    # Load hardware profile
    if [ -f /tmp/hardware-profile.env ]; then
        source /tmp/hardware-profile.env
    fi
fi

# Create installation config
PACKAGE_COUNT=$(wc -l < /tmp/package-selection.txt)
CONTAINER_COUNT=$(wc -l < /tmp/container-selection.txt)
AI_DEV=$(cat /tmp/ai-dev-enabled.txt)

cat > /tmp/installation-config.env << EOF
HARDWARE_PROFILE=${HARDWARE_PROFILE:-generic}
INSTALLATION_MODE=scripted
PACKAGE_COUNT=$PACKAGE_COUNT
CONTAINER_COUNT=$CONTAINER_COUNT
AI_DEV_ENABLED=$([[ "$AI_DEV" == "yes" ]] && echo "true" || echo "false")
EOF

# ===========================================
# Display Configuration
# ===========================================

echo ""
echo "======================================"
echo "  Installation Configuration"
echo "======================================"
echo ""
echo "Profile:         $PROFILE"
echo "Hardware:        ${HARDWARE_PROFILE:-generic}"
echo "Packages:        $PACKAGE_COUNT"
echo "Containers:      $CONTAINER_COUNT"
echo "AI Dev Bundle:   $AI_DEV"
echo ""

echo "Packages to install:"
cat /tmp/package-selection.txt | sed 's/^/  • /'
echo ""

echo "Containers to deploy:"
cat /tmp/container-selection.txt | sed 's/^/  • /'
echo ""

# ===========================================
# Run Installation
# ===========================================

echo -e "${GREEN}Configuration saved!${NC}"
echo ""
echo "To proceed with installation, run:"
echo "  cd $(dirname "$0")/.."
echo "  ./install.sh"
echo ""
echo "Or to use the interactive wrapper:"
echo "  ./install-interactive.sh"
echo ""

# Optional: Automatically proceed
# Uncomment to auto-install without confirmation
# cd "$(dirname "$0")/.."
# ./install.sh
