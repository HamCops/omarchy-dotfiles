#!/usr/bin/env python3
"""
Filter Base Packages Script
Removes base Omarchy packages from packages.txt, keeping only additional packages
"""

import os
import sys

# Colors
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'

def info(msg):
    print(f"{GREEN}[INFO]{NC} {msg}")

# Base Omarchy packages
BASE_OMARCHY_PACKAGES = {
    # From omarchy-base.packages
    "1password-beta", "1password-cli", "aether", "alacritty", "asdcontrol",
    "avahi", "bash-completion", "bat", "blueberry", "brightnessctl", "btop",
    "cargo", "clang", "cups", "cups-browsed", "cups-filters", "cups-pdf",
    "docker", "docker-buildx", "docker-compose", "dust", "elephant",
    "elephant-bluetooth", "elephant-calc", "elephant-clipboard",
    "elephant-desktopapplications", "elephant-files", "elephant-menus",
    "elephant-providerlist", "elephant-runner", "elephant-symbols",
    "elephant-todo", "elephant-unicode", "elephant-websearch", "evince",
    "expac", "eza", "fastfetch", "fcitx5", "fcitx5-gtk", "fcitx5-qt", "fd",
    "ffmpegthumbnailer", "fontconfig", "fzf", "github-cli",
    "gnome-calculator", "gnome-keyring", "gnome-themes-extra", "grim",
    "gpu-screen-recorder", "gum", "gvfs-mtp", "gvfs-nfs", "gvfs-smb",
    "hypridle", "hyprland", "hyprland-qtutils", "hyprlock", "hyprpicker",
    "hyprsunset", "imagemagick", "impala", "imv", "inetutils", "inxi", "iwd",
    "jq", "kdenlive", "kvantum-qt5", "lazydocker", "lazygit", "less",
    "libsecret", "libyaml", "libqalculate", "libreoffice-fresh", "llvm",
    "localsend", "luarocks", "mako", "man-db", "mariadb-libs", "mise", "mpv",
    "nautilus", "gnome-disk-utility", "noto-fonts", "noto-fonts-cjk",
    "noto-fonts-emoji", "noto-fonts-extra", "nss-mdns", "nvim", "obs-studio",
    "obsidian", "omarchy-chromium", "omarchy-nvim", "pamixer", "pinta",
    "playerctl", "plocate", "plymouth", "polkit-gnome", "postgresql-libs",
    "power-profiles-daemon", "python-gobject", "python-poetry-core",
    "python-terminaltexteffects", "qt5-wayland", "ripgrep", "satty", "sddm",
    "signal-desktop", "slurp", "spotify", "starship", "sushi", "swaybg",
    "swayosd", "system-config-printer", "tldr", "tree-sitter-cli",
    "ttf-cascadia-mono-nerd", "ttf-ia-writer", "ttf-jetbrains-mono-nerd",
    "typora", "tzupdate", "ufw", "ufw-docker", "unzip", "uwsm", "walker",
    "waybar", "wayfreeze", "whois", "wireless-regdb", "wiremix", "wireplumber",
    "wl-clipboard", "woff2-font-awesome", "xdg-desktop-portal-gtk",
    "xdg-desktop-portal-hyprland", "xmlstarlet", "xournalpp",
    "yaru-icon-theme", "yay", "zoxide",

    # From omarchy-other.packages
    "autoconf-archive", "base", "base-devel", "broadcom-wl", "btrfs-progs",
    "dart", "dkms", "egl-wayland", "git", "gst-plugin-pipewire",
    "gtk4-layer-shell", "htop", "intltool", "jdk-openjdk", "libpulse",
    "libsass", "libva-intel-driver", "libva-nvidia-driver", "limine",
    "limine-mkinitcpio-hook", "limine-snapper-sync", "linux", "linux-firmware",
    "linux-headers", "macbook12-spi-driver-dkms", "nvidia-dkms",
    "nvidia-open-dkms", "nvidia-utils", "lib32-nvidia-utils", "pipewire",
    "pipewire-alsa", "pipewire-jack", "pipewire-pulse", "qt5-remoteobjects",
    "qt6-wayland", "sassc", "snapper", "webp-pixbuf-loader", "wget",
    "yay-debug", "zram-generator", "apple-bcm-firmware", "apple-t2-audio-config",
    "linux-t2", "linux-t2-headers", "t2fanrd", "tiny-dfr"
}

def main():
    # Get dotfiles directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    dotfiles_dir = os.path.dirname(script_dir)

    packages_file = os.path.join(dotfiles_dir, "packages.txt")
    output_file = os.path.join(dotfiles_dir, "packages-additional.txt")
    base_file = os.path.join(dotfiles_dir, "omarchy-base-packages.txt")

    print("=" * 40)
    print("  Package Filter")
    print("=" * 40)
    print()

    # Save base packages list
    info(f"Creating base packages reference...")
    with open(base_file, 'w') as f:
        for pkg in sorted(BASE_OMARCHY_PACKAGES):
            f.write(f"{pkg}\n")
    info(f"✓ {base_file}")
    print()

    # Filter packages
    info("Filtering packages...")
    print()

    total = 0
    base_count = 0
    keep_count = 0

    with open(packages_file, 'r') as infile, open(output_file, 'w') as outfile:
        for line in infile:
            line = line.strip()
            if not line:
                continue

            total += 1
            pkg_name = line.split()[0]

            if pkg_name in BASE_OMARCHY_PACKAGES:
                base_count += 1
                print(f"{BLUE}[BASE]{NC} {pkg_name}")
            else:
                keep_count += 1
                print(f"{GREEN}[KEEP]{NC} {pkg_name}")
                outfile.write(f"{line}\n")

    print()
    print("=" * 40)
    print("  Filtering Complete")
    print("=" * 40)
    info(f"Total packages: {total}")
    info(f"Base Omarchy packages (excluded): {base_count}")
    info(f"Additional packages (kept): {keep_count}")
    print()
    info(f"Output: {output_file}")
    print()

if __name__ == "__main__":
    main()
