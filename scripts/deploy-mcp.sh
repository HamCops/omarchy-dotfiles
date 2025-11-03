#!/bin/bash

# MCP Server Deployment Script
# Deploys MCP containers with optional interactive selection

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="$DOTFILES_DIR/docker"
SELECTION_FILE="$DOCKER_DIR/mcp-selection.env"

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

# Parse arguments
USE_SELECTION=false
INTERACTIVE=false

for arg in "$@"; do
    case $arg in
        --use-selection)
            USE_SELECTION=true
            ;;
        --interactive|-i)
            INTERACTIVE=true
            ;;
    esac
done

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
    source "$DOTFILES_DIR/scripts/detect-hardware.sh" > /dev/null 2>&1 || true
    if [ -f /tmp/hardware-profile.env ]; then
        source /tmp/hardware-profile.env
    fi
else
    warn "Hardware detection script not found. Assuming generic setup."
    HARDWARE_PROFILE="generic"
fi

info "Hardware Profile: $HARDWARE_PROFILE"

# Interactive selection if requested
if [ "$INTERACTIVE" = true ] && [ "$USE_SELECTION" = false ]; then
    if [ -f "$DOTFILES_DIR/scripts/select-mcp.sh" ]; then
        "$DOTFILES_DIR/scripts/select-mcp.sh"
        exit $?
    else
        warn "MCP selector not found. Proceeding with default deployment."
    fi
fi

# Ask about selection if not already using it
if [ "$USE_SELECTION" = false ] && [ "$INTERACTIVE" = false ]; then
    echo ""
    echo "Deployment options:"
    echo "  1. Deploy all containers (default)"
    echo "  2. Interactive selection (choose which containers)"
    echo ""
    read -p "Choose option (1/2) [1]: " deploy_option

    if [ "$deploy_option" = "2" ]; then
        if [ -f "$DOTFILES_DIR/scripts/select-mcp.sh" ]; then
            "$DOTFILES_DIR/scripts/select-mcp.sh"
            exit $?
        else
            warn "MCP selector not found. Deploying all containers."
        fi
    fi
fi

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

# Generate custom compose file if using selection
if [ "$USE_SELECTION" = true ] && [ -f "$SELECTION_FILE" ]; then
    info "Using custom container selection..."
    source "$SELECTION_FILE"

    # Create custom override
    cat > docker-compose.custom.yml << 'EOF'
version: '3.8'

# Custom selection override
services:
EOF

    # List all containers
    ALL_CONTAINERS=(ollama open-webui mcp-docker-manager mcp-filesystem mcp-obsidian \
                    mcp-rss-aggregator mcp-markdown-converter mcp-pytorch-inspector \
                    mcp-gpu-optimizer mcp-librecad mcp-kali-tools phoneinfoga)

    # Disable unselected containers
    for container in "${ALL_CONTAINERS[@]}"; do
        local is_selected=false
        for selected in "${SELECTED_CONTAINERS[@]}"; do
            if [ "$container" = "$selected" ]; then
                is_selected=true
                break
            fi
        done

        if [ "$is_selected" = false ]; then
            cat >> docker-compose.custom.yml << EOF
  $container:
    profiles:
      - disabled
EOF
        fi
    done

    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.custom.yml"
    info "Generated custom compose override"
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
    warn "These containers will fail to start. You'll need to build or pull them."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Deployment cancelled"
        exit 1
    fi
fi

# Deploy containers
info "Deploying MCP containers..."

# Pull public images
info "Pulling public images..."
docker compose $COMPOSE_FILES pull ollama open-webui phoneinfoga 2>/dev/null || warn "Some images couldn't be pulled"

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

# Check which services are actually running
if docker ps --format '{{.Names}}' | grep -q "^ollama$"; then
    echo "Ollama API:    http://localhost:11434"
fi

if docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
    echo "Open WebUI:    http://localhost:8080"
fi

if docker ps --format '{{.Names}}' | grep -q "^phoneinfoga$"; then
    echo "PhoneInfoga:   http://localhost:8081"
fi

echo "======================================"
echo ""

# Create/update Claude Desktop config
CLAUDE_CONFIG="$HOME/.config/claude/claude_desktop_config.json"

if [ ! -f "$CLAUDE_CONFIG" ]; then
    info "Creating Claude Desktop MCP configuration..."
    mkdir -p "$(dirname "$CLAUDE_CONFIG")"

    cat > "$CLAUDE_CONFIG" << 'CONFIGEOF'
{
  "mcpServers": {
CONFIGEOF

    # Add only running MCP containers
    first=true
    for container in mcp-docker-manager mcp-filesystem mcp-obsidian mcp-pytorch-inspector \
                     mcp-rss-aggregator mcp-librecad mcp-gpu-optimizer mcp-kali-tools mcp-markdown-converter; do
        if docker ps --format '{{.Names}}' | grep -q "^$container$"; then
            if [ "$first" = false ]; then
                echo "," >> "$CLAUDE_CONFIG"
            fi
            first=false

            # Get container name without mcp- prefix for config key
            config_key="${container#mcp-}"

            cat >> "$CLAUDE_CONFIG" << CONFIGEOF
    "$config_key": {
      "command": "docker",
      "args": ["exec", "-i", "$container", "node", "index.js"]
    }CONFIGEOF
        fi
    done

    cat >> "$CLAUDE_CONFIG" << 'CONFIGEOF'

  }
}
CONFIGEOF

    info "✓ Claude Desktop config created"
else
    info "Claude Desktop config already exists at $CLAUDE_CONFIG"
    warn "You may need to manually update it with new MCP servers"
fi

echo ""
info "Next steps:"
echo "  - Restart Claude Desktop to use MCP servers"
if docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
    echo "  - Access Open WebUI at http://localhost:8080"
fi
echo "  - View logs: cd $DOCKER_DIR && docker compose logs -f"
echo "  - Stop all: cd $DOCKER_DIR && docker compose down"
echo ""

# Show selection summary if custom
if [ "$USE_SELECTION" = true ]; then
    info "Deployed with custom selection ($(docker ps --filter "name=mcp-" --filter "name=ollama" --filter "name=open-webui" --filter "name=phoneinfoga" | wc -l | xargs) containers)"
fi
