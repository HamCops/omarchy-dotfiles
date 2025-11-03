#!/bin/bash

# MCP Container Selector
# Interactive menu to choose which MCP containers to deploy

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="$DOTFILES_DIR/docker"
SELECTION_FILE="$DOCKER_DIR/mcp-selection.env"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

header() {
    echo -e "${CYAN}$1${NC}"
}

# MCP Container definitions
declare -A MCP_CONTAINERS=(
    # Core AI Services
    ["ollama"]="Local LLM inference server (3.5GB, CPU/GPU)"
    ["open-webui"]="Web UI for Ollama models (4.5GB)"

    # Essential MCP Servers
    ["mcp-docker-manager"]="Manage Docker containers via MCP (174MB, essential)"
    ["mcp-filesystem"]="File operations via MCP (141MB, essential)"

    # Productivity MCP Servers
    ["mcp-obsidian"]="Obsidian vault management (141MB)"
    ["mcp-rss-aggregator"]="RSS feed reader and aggregator (276MB)"
    ["mcp-markdown-converter"]="Markdown to PDF/DOCX/HTML (1.95GB)"

    # Development MCP Servers
    ["mcp-pytorch-inspector"]="PyTorch model inspection (2GB)"
    ["mcp-gpu-optimizer"]="GPU monitoring and optimization (141MB, needs NVIDIA)"

    # Specialized MCP Servers
    ["mcp-librecad"]="CAD file viewer (827MB, has VNC)"
    ["mcp-kali-tools"]="Security/pentesting tools (8.94GB, LARGE!)"

    # Other Services
    ["phoneinfoga"]="Phone number OSINT tool (43MB)"
)

# Resource requirements
declare -A MCP_RESOURCES=(
    ["ollama"]="2-4GB RAM, benefits from GPU"
    ["open-webui"]="512MB RAM"
    ["mcp-docker-manager"]="50MB RAM"
    ["mcp-filesystem"]="50MB RAM"
    ["mcp-obsidian"]="50MB RAM"
    ["mcp-rss-aggregator"]="100MB RAM"
    ["mcp-markdown-converter"]="200MB RAM"
    ["mcp-pytorch-inspector"]="500MB RAM"
    ["mcp-gpu-optimizer"]="50MB RAM, NVIDIA GPU required"
    ["mcp-librecad"]="200MB RAM"
    ["mcp-kali-tools"]="1-2GB RAM"
    ["phoneinfoga"]="50MB RAM"
)

# Presets
declare -A PRESET_MINIMAL=(
    ["ollama"]=1
    ["mcp-docker-manager"]=1
    ["mcp-filesystem"]=1
)

declare -A PRESET_STANDARD=(
    ["ollama"]=1
    ["open-webui"]=1
    ["mcp-docker-manager"]=1
    ["mcp-filesystem"]=1
    ["mcp-obsidian"]=1
    ["mcp-rss-aggregator"]=1
)

declare -A PRESET_FULL=(
    ["ollama"]=1
    ["open-webui"]=1
    ["mcp-docker-manager"]=1
    ["mcp-filesystem"]=1
    ["mcp-obsidian"]=1
    ["mcp-rss-aggregator"]=1
    ["mcp-markdown-converter"]=1
    ["mcp-pytorch-inspector"]=1
    ["mcp-librecad"]=1
    ["phoneinfoga"]=1
)

# User selections
declare -A SELECTED

# Load hardware profile if available
if [ -f /tmp/hardware-profile.env ]; then
    source /tmp/hardware-profile.env
else
    HARDWARE_PROFILE="generic"
    HAS_NVIDIA=false
    RAM_GB=16
fi

# Display header
clear
echo "======================================"
header "    MCP Container Selector"
echo "======================================"
echo ""
info "Hardware: $HARDWARE_PROFILE"
info "RAM: ${RAM_GB}GB"
info "NVIDIA GPU: $HAS_NVIDIA"
echo ""

# Function to show menu
show_menu() {
    echo "======================================"
    header "Available MCP Containers"
    echo "======================================"
    echo ""

    local index=1
    local total_selected=0

    for container in ollama open-webui mcp-docker-manager mcp-filesystem mcp-obsidian \
                     mcp-rss-aggregator mcp-markdown-converter mcp-pytorch-inspector \
                     mcp-gpu-optimizer mcp-librecad mcp-kali-tools phoneinfoga; do

        local status="[ ]"
        if [ "${SELECTED[$container]}" = "1" ]; then
            status="${GREEN}[✓]${NC}"
            ((total_selected++))
        fi

        # Warning for GPU-only containers
        local gpu_warn=""
        if [ "$container" = "mcp-gpu-optimizer" ] && [ "$HAS_NVIDIA" = false ]; then
            gpu_warn=" ${RED}(needs NVIDIA GPU!)${NC}"
        fi

        echo -e "${BLUE}$index.${NC} $status $container"
        echo -e "   ${MCP_CONTAINERS[$container]}$gpu_warn"
        echo -e "   Resources: ${MCP_RESOURCES[$container]}"
        echo ""

        ((index++))
    done

    echo "======================================"
    info "Selected: $total_selected containers"
    echo "======================================"
    echo ""
}

# Function to apply preset
apply_preset() {
    local preset=$1
    SELECTED=()

    case $preset in
        "minimal")
            for container in "${!PRESET_MINIMAL[@]}"; do
                SELECTED[$container]=1
            done
            info "Applied MINIMAL preset (3 containers)"
            ;;
        "standard")
            for container in "${!PRESET_STANDARD[@]}"; do
                SELECTED[$container]=1
            done
            info "Applied STANDARD preset (6 containers)"
            ;;
        "full")
            for container in "${!PRESET_FULL[@]}"; do
                SELECTED[$container]=1
            done

            # Add GPU optimizer only if NVIDIA present
            if [ "$HAS_NVIDIA" = true ]; then
                SELECTED["mcp-gpu-optimizer"]=1
            fi

            # Don't include Kali Tools by default (too large)
            unset SELECTED["mcp-kali-tools"]

            info "Applied FULL preset (9-10 containers)"
            ;;
    esac

    sleep 1
}

# Interactive selection
while true; do
    show_menu

    echo "Commands:"
    echo "  1-12    - Toggle container on/off"
    echo "  p       - Choose preset (minimal/standard/full)"
    echo "  a       - Select all"
    echo "  n       - Deselect all"
    echo "  s       - Save and continue"
    echo "  q       - Quit without saving"
    echo ""

    read -p "Enter command: " choice

    case $choice in
        [1-9]|1[0-2])
            # Toggle selection
            local containers=(ollama open-webui mcp-docker-manager mcp-filesystem mcp-obsidian \
                            mcp-rss-aggregator mcp-markdown-converter mcp-pytorch-inspector \
                            mcp-gpu-optimizer mcp-librecad mcp-kali-tools phoneinfoga)
            local idx=$((choice - 1))
            local container="${containers[$idx]}"

            if [ "${SELECTED[$container]}" = "1" ]; then
                unset SELECTED[$container]
            else
                SELECTED[$container]=1
            fi
            clear
            ;;

        p|P)
            echo ""
            echo "Presets:"
            echo "  1. Minimal (Ollama + essential MCPs) - ~4GB disk, 2-3GB RAM"
            echo "  2. Standard (+ Web UI + productivity MCPs) - ~10GB disk, 3-4GB RAM"
            echo "  3. Full (everything except Kali) - ~20GB disk, 6-8GB RAM"
            echo ""
            read -p "Choose preset (1-3): " preset_choice

            case $preset_choice in
                1) apply_preset "minimal" ;;
                2) apply_preset "standard" ;;
                3) apply_preset "full" ;;
                *) warn "Invalid preset" ;;
            esac
            clear
            ;;

        a|A)
            # Select all
            for container in "${!MCP_CONTAINERS[@]}"; do
                SELECTED[$container]=1
            done
            clear
            info "Selected all containers"
            ;;

        n|N)
            # Deselect all
            SELECTED=()
            clear
            info "Deselected all containers"
            ;;

        s|S)
            # Save and exit
            if [ ${#SELECTED[@]} -eq 0 ]; then
                warn "No containers selected!"
                sleep 1
                clear
                continue
            fi

            clear
            info "Saving selection..."

            # Create selection file
            cat > "$SELECTION_FILE" << EOF
# MCP Container Selection
# Generated: $(date)
# Hardware: $HARDWARE_PROFILE

SELECTED_CONTAINERS=(
EOF

            for container in "${!SELECTED[@]}"; do
                echo "    \"$container\"" >> "$SELECTION_FILE"
            done

            echo ")" >> "$SELECTION_FILE"

            info "Selection saved to: $SELECTION_FILE"
            echo ""

            # Show summary
            echo "======================================"
            header "Selected Containers"
            echo "======================================"
            for container in "${!SELECTED[@]}"; do
                echo -e "${GREEN}✓${NC} $container"
            done
            echo "======================================"
            echo ""

            info "Total: ${#SELECTED[@]} containers"
            echo ""

            read -p "Deploy these containers now? (y/N) " deploy
            if [[ $deploy =~ ^[Yy]$ ]]; then
                info "Launching deployment..."
                exec "$DOTFILES_DIR/scripts/deploy-mcp.sh" --use-selection
            fi

            exit 0
            ;;

        q|Q)
            warn "Exiting without saving"
            exit 0
            ;;

        *)
            warn "Invalid command"
            sleep 1
            clear
            ;;
    esac
done
