#!/bin/bash

# MCP Server Deployment Script
# Deploys all MCP containers with hardware detection

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="$DOTFILES_DIR/docker"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "======================================"
echo "  MCP Server Deployment"
echo "======================================"
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Detect hardware
if [ -f "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
    info "Running hardware detection..."
    source "$DOTFILES_DIR/scripts/detect-hardware.sh" > /dev/null
    source /tmp/hardware-profile.env
else
    warn "Hardware detection script not found. Assuming generic setup."
    HARDWARE_PROFILE="generic"
fi

info "Hardware Profile: $HARDWARE_PROFILE"

# Change to docker directory
cd "$DOCKER_DIR"

# Determine which compose files to use
COMPOSE_FILES="-f docker-compose.yml"

if [ "$HARDWARE_PROFILE" = "t420s" ]; then
    if [ -f "docker-compose.t420s.yml" ]; then
        info "Using T420s-specific Docker Compose overrides"
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.t420s.yml"
    fi
fi

# Check if MCP images exist
info "Checking for MCP container images..."
MISSING_IMAGES=()

for image in mcp-docker-manager mcp-filesystem mcp-obsidian mcp-pytorch-inspector \
             mcp-rss-aggregator mcp-librecad mcp-markdown-converter mcp-gpu-optimizer mcp-kali-tools; do
    if ! docker images | grep -q "^$image"; then
        warn "Image $image not found locally"
        MISSING_IMAGES+=("$image")
    fi
done

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    warn "The following MCP images are missing:"
    for img in "${MISSING_IMAGES[@]}"; do
        echo "  - $img"
    done
    echo ""
    warn "You'll need to build or pull these images first."
    warn "Continue anyway? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        error "Deployment cancelled"
        exit 1
    fi
fi

# Deploy containers
info "Deploying MCP containers..."

# Pull public images
info "Pulling public images..."
docker compose $COMPOSE_FILES pull ollama open-webui phoneinfoga

# Start services
info "Starting services..."

if [ "$HARDWARE_PROFILE" = "surface" ] && [ "$HAS_NVIDIA" = true ]; then
    info "Starting with NVIDIA GPU support..."
    docker compose $COMPOSE_FILES --profile nvidia-gpu up -d
else
    info "Starting without GPU-specific containers..."
    docker compose $COMPOSE_FILES up -d
fi

# Wait for services to be healthy
info "Waiting for services to start..."
sleep 5

# Check status
echo ""
info "Container Status:"
docker compose $COMPOSE_FILES ps

echo ""
info "MCP Deployment Complete!"
echo ""

# Print access information
echo "======================================"
echo "  Service Access"
echo "======================================"
echo "Ollama API:    http://localhost:11434"
echo "Open WebUI:    http://localhost:8080"
echo "PhoneInfoga:   http://localhost:8081"
echo "======================================"
echo ""

# Create Claude Desktop config if it doesn't exist
CLAUDE_CONFIG="$HOME/.config/claude/claude_desktop_config.json"

if [ ! -f "$CLAUDE_CONFIG" ]; then
    info "Creating Claude Desktop MCP configuration..."
    mkdir -p "$(dirname "$CLAUDE_CONFIG")"

    cat > "$CLAUDE_CONFIG" << 'EOF'
{
  "mcpServers": {
    "docker-manager": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-docker-manager", "node", "index.js"]
    },
    "obsidian": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-obsidian", "node", "index.js"]
    },
    "filesystem": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-filesystem", "node", "index.js"]
    },
    "pytorch-inspector": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-pytorch-inspector", "node", "index.js"]
    },
    "rss-aggregator": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-rss-aggregator", "node", "index.js"]
    },
    "librecad": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-librecad", "node", "index.js"]
    },
    "gpu-optimizer": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-gpu-optimizer", "node", "index.js"]
    },
    "kali-tools": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-kali-tools", "node", "index.js"]
    },
    "markdown-converter": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-markdown-converter", "node", "index.js"]
    }
  }
}
EOF
    info "✓ Claude Desktop config created"
else
    info "Claude Desktop config already exists at $CLAUDE_CONFIG"
fi

echo ""
info "Next steps:"
echo "  - Restart Claude Desktop to use MCP servers"
echo "  - Access Open WebUI at http://localhost:8080"
echo "  - Run 'docker compose $COMPOSE_FILES logs -f' to view logs"
echo ""
