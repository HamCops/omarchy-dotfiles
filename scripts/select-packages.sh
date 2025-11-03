#!/bin/bash

# Package Selector for Omarchy Dotfiles
# Interactive menu to choose which packages to install

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_FILE="$DOTFILES_DIR/packages.txt"
SELECTION_FILE="$DOTFILES_DIR/package-selection.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
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

header() {
    echo -e "${CYAN}$1${NC}"
}

# Load hardware profile
if [ -f /tmp/hardware-profile.env ]; then
    source /tmp/hardware-profile.env
else
    # Run detection if not already done
    if [ -f "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
        "$DOTFILES_DIR/scripts/detect-hardware.sh" > /dev/null 2>&1
        source /tmp/hardware-profile.env
    else
        HARDWARE_PROFILE="generic"
        HAS_NVIDIA=false
        HAS_SURFACE_PEN=false
        RAM_GB=16
    fi
fi

# Package categories
declare -A PACKAGE_CATEGORIES

# System Core
CATEGORY_SYSTEM_CORE="base base-devel linux-surface linux-surface-headers btrfs-progs systemd"

# Display & Desktop (Hyprland ecosystem)
CATEGORY_DESKTOP="hyprland hyprland-qtutils waybar sddm alacritty hypridle hyprlock hyprpicker hyprsunset swaybg swayosd-server polkit-gnome xdg-desktop-portal-hyprland"

# Audio
CATEGORY_AUDIO="pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire"

# Network
CATEGORY_NETWORK="iwd networkmanager avahi tailscale"

# Development Tools
CATEGORY_DEV_TOOLS="git git-lfs github-cli lazygit neovim omarchy-nvim zed claude-code"

# Containers & Virtualization
CATEGORY_CONTAINERS="docker docker-buildx docker-compose containerd buildah crun nvidia-container-toolkit"

# NVIDIA/CUDA (Surface only)
CATEGORY_NVIDIA="nvidia-open-dkms nvidia-utils lib32-nvidia-utils libva-nvidia-driver cuda cuda-tools cudnn"

# Python Development
CATEGORY_PYTHON="python-pip python-pipx python-virtualenv python-poetry-core python-numpy python-pandas python-scipy python-matplotlib python-seaborn python-plotly python-scikit-learn python-pycuda python-cupy"

# Surface-Specific
CATEGORY_SURFACE="iptsd linux-surface linux-surface-headers"

# System Utilities
CATEGORY_UTILS="bat dust btop brightnessctl bash-completion blueberry brave-bin"

# Printing
CATEGORY_PRINTING="cups cups-browsed cups-filters cups-pdf"

# Themes & Appearance
CATEGORY_THEMES="yaru-icon-theme papirus-icon-theme"

# Build Tools
CATEGORY_BUILD="clang cmake make ninja gcc"

# Incompatible packages per hardware
declare -A INCOMPATIBLE_PACKAGES

# T420s incompatible
INCOMPATIBLE_T420S="nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-container-toolkit cuda cuda-tools cudnn python-pycuda python-cupy iptsd linux-surface linux-surface-headers libva-nvidia-driver"

# Generic/Desktop incompatible
INCOMPATIBLE_GENERIC="iptsd linux-surface linux-surface-headers"

# User selections
declare -A SELECTED
declare -A PACKAGE_STATUS

# Load all packages
readarray -t ALL_PACKAGES < <(awk '{print $1}' "$PACKAGES_FILE" | sort)

# Initialize all as selected
for pkg in "${ALL_PACKAGES[@]}"; do
    SELECTED[$pkg]=1
done

# Mark incompatible packages
mark_incompatible() {
    local incomp_list=""

    case $HARDWARE_PROFILE in
        "t420s")
            incomp_list="$INCOMPATIBLE_T420S"
            ;;
        "generic")
            incomp_list="$INCOMPATIBLE_GENERIC"
            ;;
        "surface")
            # Everything compatible on Surface
            incomp_list=""
            ;;
    esac

    for pkg in $incomp_list; do
        PACKAGE_STATUS[$pkg]="INCOMPATIBLE"
        unset SELECTED[$pkg]  # Auto-deselect
    done

    # Additional checks
    if [ "$HAS_NVIDIA" = false ]; then
        for pkg in nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-container-toolkit cuda cuda-tools cudnn python-pycuda python-cupy libva-nvidia-driver; do
            PACKAGE_STATUS[$pkg]="NO_NVIDIA"
            unset SELECTED[$pkg]
        done
    fi

    if [ "$HAS_SURFACE_PEN" = false ]; then
        for pkg in iptsd; do
            PACKAGE_STATUS[$pkg]="NO_SURFACE"
            unset SELECTED[$pkg]
        done
    fi
}

# Get package category
get_category() {
    local pkg=$1

    for cat_var in CATEGORY_SYSTEM_CORE CATEGORY_DESKTOP CATEGORY_AUDIO CATEGORY_NETWORK \
                   CATEGORY_DEV_TOOLS CATEGORY_CONTAINERS CATEGORY_NVIDIA CATEGORY_PYTHON \
                   CATEGORY_SURFACE CATEGORY_UTILS CATEGORY_PRINTING CATEGORY_THEMES CATEGORY_BUILD; do
        eval "cat_pkgs=\$$cat_var"
        if [[ " $cat_pkgs " =~ " $pkg " ]]; then
            echo "${cat_var#CATEGORY_}"
            return
        fi
    done
    echo "OTHER"
}

# Get category display name
get_category_name() {
    case $1 in
        SYSTEM_CORE) echo "System Core" ;;
        DESKTOP) echo "Desktop/Hyprland" ;;
        AUDIO) echo "Audio (PipeWire)" ;;
        NETWORK) echo "Networking" ;;
        DEV_TOOLS) echo "Development Tools" ;;
        CONTAINERS) echo "Containers/Docker" ;;
        NVIDIA) echo "NVIDIA/CUDA" ;;
        PYTHON) echo "Python Development" ;;
        SURFACE) echo "Surface Hardware" ;;
        UTILS) echo "System Utilities" ;;
        PRINTING) echo "Printing (CUPS)" ;;
        THEMES) echo "Themes & Icons" ;;
        BUILD) echo "Build Tools" ;;
        OTHER) echo "Other Packages" ;;
    esac
}

# Presets
apply_preset() {
    local preset=$1

    # First, deselect all
    SELECTED=()

    case $preset in
        "minimal")
            # Only essentials
            local minimal_pkgs="base base-devel bash-completion git docker hyprland waybar alacritty sddm pipewire pipewire-pulse networkmanager"
            for pkg in $minimal_pkgs; do
                if [[ "${PACKAGE_STATUS[$pkg]}" != "INCOMPATIBLE" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_NVIDIA" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_SURFACE" ]]; then
                    SELECTED[$pkg]=1
                fi
            done
            ;;

        "desktop")
            # Minimal + full desktop experience
            for pkg in $CATEGORY_SYSTEM_CORE $CATEGORY_DESKTOP $CATEGORY_AUDIO $CATEGORY_NETWORK $CATEGORY_UTILS; do
                if [[ "${PACKAGE_STATUS[$pkg]}" != "INCOMPATIBLE" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_NVIDIA" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_SURFACE" ]]; then
                    SELECTED[$pkg]=1
                fi
            done
            ;;

        "development")
            # Desktop + dev tools
            for pkg in $CATEGORY_SYSTEM_CORE $CATEGORY_DESKTOP $CATEGORY_AUDIO $CATEGORY_NETWORK \
                       $CATEGORY_DEV_TOOLS $CATEGORY_CONTAINERS $CATEGORY_UTILS $CATEGORY_BUILD; do
                if [[ "${PACKAGE_STATUS[$pkg]}" != "INCOMPATIBLE" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_NVIDIA" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_SURFACE" ]]; then
                    SELECTED[$pkg]=1
                fi
            done
            # Add Python if not incompatible
            if [ "$HARDWARE_PROFILE" != "t420s" ]; then
                for pkg in $CATEGORY_PYTHON; do
                    if [[ "${PACKAGE_STATUS[$pkg]}" != "INCOMPATIBLE" ]] && \
                       [[ "${PACKAGE_STATUS[$pkg]}" != "NO_NVIDIA" ]]; then
                        SELECTED[$pkg]=1
                    fi
                done
            fi
            ;;

        "full")
            # Everything compatible
            for pkg in "${ALL_PACKAGES[@]}"; do
                if [[ "${PACKAGE_STATUS[$pkg]}" != "INCOMPATIBLE" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_NVIDIA" ]] && \
                   [[ "${PACKAGE_STATUS[$pkg]}" != "NO_SURFACE" ]]; then
                    SELECTED[$pkg]=1
                fi
            done
            ;;
    esac
}

# Show packages by category
show_by_category() {
    local current_category=""
    local pkg_num=1
    local total_selected=0
    local total_incompatible=0

    clear
    echo "======================================"
    header "    Package Selector"
    echo "======================================"
    echo ""
    info "Hardware: $HARDWARE_PROFILE | RAM: ${RAM_GB}GB | NVIDIA: $HAS_NVIDIA"
    echo ""

    for pkg in "${ALL_PACKAGES[@]}"; do
        local cat=$(get_category "$pkg")

        # Print category header if changed
        if [ "$cat" != "$current_category" ]; then
            current_category="$cat"
            echo ""
            echo -e "${MAGENTA}$(get_category_name $cat)${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi

        # Status indicator
        local status="[ ]"
        local color="$NC"
        local note=""

        if [[ "${PACKAGE_STATUS[$pkg]}" == "INCOMPATIBLE" ]]; then
            status="${RED}[✗]${NC}"
            note=" ${RED}(incompatible with $HARDWARE_PROFILE)${NC}"
            ((total_incompatible++))
        elif [[ "${PACKAGE_STATUS[$pkg]}" == "NO_NVIDIA" ]]; then
            status="${RED}[✗]${NC}"
            note=" ${RED}(needs NVIDIA GPU)${NC}"
            ((total_incompatible++))
        elif [[ "${PACKAGE_STATUS[$pkg]}" == "NO_SURFACE" ]]; then
            status="${RED}[✗]${NC}"
            note=" ${RED}(needs Surface hardware)${NC}"
            ((total_incompatible++))
        elif [[ "${SELECTED[$pkg]}" == "1" ]]; then
            status="${GREEN}[✓]${NC}"
            ((total_selected++))
        fi

        echo -e "${BLUE}$pkg_num.${NC} $status $pkg$note"
        ((pkg_num++))
    done

    echo ""
    echo "======================================"
    info "Selected: $total_selected | Incompatible: $total_incompatible | Total: ${#ALL_PACKAGES[@]}"
    echo "======================================"
    echo ""
}

# Filter packages by search term
search_packages() {
    read -p "Search packages: " search_term

    if [ -z "$search_term" ]; then
        return
    fi

    clear
    echo "======================================"
    header "Search Results: $search_term"
    echo "======================================"
    echo ""

    local found=0
    local pkg_num=1

    for pkg in "${ALL_PACKAGES[@]}"; do
        if [[ "$pkg" =~ $search_term ]]; then
            local status="[ ]"
            if [[ "${SELECTED[$pkg]}" == "1" ]]; then
                status="${GREEN}[✓]${NC}"
            fi

            local note=""
            if [[ "${PACKAGE_STATUS[$pkg]}" =~ INCOMPATIBLE|NO_NVIDIA|NO_SURFACE ]]; then
                note=" ${RED}(incompatible)${NC}"
            fi

            echo -e "${BLUE}$pkg_num.${NC} $status $pkg$note"
            ((found++))
            ((pkg_num++))
        fi
    done

    echo ""
    if [ $found -eq 0 ]; then
        warn "No packages found matching '$search_term'"
    else
        info "Found $found packages"
    fi
    echo ""
    read -p "Press Enter to continue..."
}

# Main menu
main_menu() {
    mark_incompatible

    while true; do
        show_by_category

        echo "Commands:"
        echo "  c <category>  - Toggle entire category (c desktop, c nvidia, etc.)"
        echo "  <number>      - Toggle individual package"
        echo "  p             - Apply preset (minimal/desktop/development/full)"
        echo "  a             - Select all compatible"
        echo "  n             - Deselect all"
        echo "  /             - Search packages"
        echo "  s             - Save selection and install"
        echo "  q             - Quit without saving"
        echo ""

        read -p "Enter command: " cmd

        if [[ "$cmd" =~ ^[0-9]+$ ]]; then
            # Toggle package by number
            local idx=$((cmd - 1))
            if [ $idx -ge 0 ] && [ $idx -lt ${#ALL_PACKAGES[@]} ]; then
                local pkg="${ALL_PACKAGES[$idx]}"

                # Check if compatible
                if [[ "${PACKAGE_STATUS[$pkg]}" =~ INCOMPATIBLE|NO_NVIDIA|NO_SURFACE ]]; then
                    warn "Package $pkg is incompatible with your hardware"
                    sleep 1
                else
                    if [[ "${SELECTED[$pkg]}" == "1" ]]; then
                        unset SELECTED[$pkg]
                    else
                        SELECTED[$pkg]=1
                    fi
                fi
            fi

        elif [[ "$cmd" =~ ^c\ .+ ]]; then
            # Toggle category
            local cat_input="${cmd#c }"
            local cat_var="CATEGORY_${cat_input^^}"
            cat_var="${cat_var//-/_}"

            eval "cat_pkgs=\$$cat_var" 2>/dev/null || cat_pkgs=""

            if [ -n "$cat_pkgs" ]; then
                local any_selected=false
                for pkg in $cat_pkgs; do
                    if [[ "${SELECTED[$pkg]}" == "1" ]]; then
                        any_selected=true
                        break
                    fi
                done

                # Toggle entire category
                for pkg in $cat_pkgs; do
                    if [[ ! "${PACKAGE_STATUS[$pkg]}" =~ INCOMPATIBLE|NO_NVIDIA|NO_SURFACE ]]; then
                        if [ "$any_selected" = true ]; then
                            unset SELECTED[$pkg]
                        else
                            SELECTED[$pkg]=1
                        fi
                    fi
                done
            else
                warn "Category not found: $cat_input"
                sleep 1
            fi

        elif [[ "$cmd" == "p" ]]; then
            # Presets
            clear
            echo "Presets:"
            echo "  1. Minimal    - Core system only (~50 packages)"
            echo "  2. Desktop    - Full desktop experience (~80 packages)"
            echo "  3. Development - Desktop + dev tools (~120 packages)"
            echo "  4. Full       - Everything compatible (~200+ packages)"
            echo ""
            read -p "Choose preset (1-4): " preset_choice

            case $preset_choice in
                1) apply_preset "minimal" ; info "Applied Minimal preset" ; sleep 1 ;;
                2) apply_preset "desktop" ; info "Applied Desktop preset" ; sleep 1 ;;
                3) apply_preset "development" ; info "Applied Development preset" ; sleep 1 ;;
                4) apply_preset "full" ; info "Applied Full preset" ; sleep 1 ;;
                *) warn "Invalid preset" ; sleep 1 ;;
            esac

        elif [[ "$cmd" == "a" ]]; then
            # Select all compatible
            for pkg in "${ALL_PACKAGES[@]}"; do
                if [[ ! "${PACKAGE_STATUS[$pkg]}" =~ INCOMPATIBLE|NO_NVIDIA|NO_SURFACE ]]; then
                    SELECTED[$pkg]=1
                fi
            done

        elif [[ "$cmd" == "n" ]]; then
            # Deselect all
            SELECTED=()

        elif [[ "$cmd" == "/" ]]; then
            # Search
            search_packages

        elif [[ "$cmd" == "s" ]]; then
            # Save and install
            if [ ${#SELECTED[@]} -eq 0 ]; then
                warn "No packages selected!"
                sleep 1
                continue
            fi

            clear
            info "Saving selection..."

            # Create selection file
            > "$SELECTION_FILE"
            for pkg in "${!SELECTED[@]}"; do
                # Get version from original file
                grep "^$pkg " "$PACKAGES_FILE" >> "$SELECTION_FILE" || echo "$pkg" >> "$SELECTION_FILE"
            done

            # Sort the file
            sort -o "$SELECTION_FILE" "$SELECTION_FILE"

            info "Selection saved to: $SELECTION_FILE"
            echo ""
            info "Selected ${#SELECTED[@]} packages"
            echo ""

            read -p "Install these packages now? (y/N) " install
            if [[ $install =~ ^[Yy]$ ]]; then
                exec "$DOTFILES_DIR/scripts/install-packages.sh" --use-selection
            fi

            exit 0

        elif [[ "$cmd" == "q" ]]; then
            warn "Exiting without saving"
            exit 0
        fi
    done
}

# Run main menu
main_menu
