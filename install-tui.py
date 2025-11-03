#!/usr/bin/env python3
"""
Omarchy Dotfiles - Interactive TUI Installer
Professional installation interface for Hyprland configs, packages, and Docker containers
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from typing import List, Tuple, Dict, Optional

# Try to import dialog, fallback to basic interface if not available
try:
    from dialog import Dialog
    DIALOG_AVAILABLE = True
except ImportError:
    DIALOG_AVAILABLE = False
    print("WARNING: python-dialog not installed. Install with: sudo pacman -S python-dialog")
    sys.exit(2)


class OmarchyInstaller:
    """Main installer class with TUI interface"""

    def __init__(self):
        self.d = Dialog(dialog="dialog", autowidgetsize=True)
        self.d.set_background_title("Omarchy Dotfiles Installer v2.0")

        # Paths
        self.dotfiles_dir = Path(__file__).parent.resolve()
        self.packages_file = self.dotfiles_dir / "packages.txt"
        self.ai_packages_file = self.dotfiles_dir / "packages-ai-dev.txt"
        self.docker_compose = self.dotfiles_dir / "docker" / "docker-compose.yml"

        # Hardware detection results
        self.hardware_profile = "generic"
        self.has_nvidia = False
        self.has_intel_gpu = False
        self.ram_gb = 0
        self.cpu_generation = ""

        # User selections
        self.selected_packages = []
        self.selected_containers = []
        self.ai_dev_enabled = False
        self.installation_mode = "full"

        # Package categories
        self.core_packages = [
            "act-bin", "git-lfs", "go", "nano", "neovim", "rust",
            "buildah", "podman", "podman-compose", "crun", "fuse-overlayfs",
            "slirp4netns", "skopeo", "nvidia-container-toolkit"
        ]

        self.dev_tools = [
            "zed", "claude-code", "lmstudio", "jenkins", "drone",
            "awesome-omarchy-tui-bin", "mkcert", "nginx"
        ]

        self.system_packages = [
            "linux-surface", "linux-surface-headers", "intel-ucode",
            "efibootmgr", "fwupd", "iptsd", "sof-firmware"
        ]

        self.optional_tools = [
            "brave-bin", "jellyfin-media-player", "protonmail-bridge",
            "tailscale", "nmap", "swaks", "librecad", "wttrbar"
        ]

        # Container definitions
        self.containers = {
            "ollama": {
                "name": "Ollama LLM Server",
                "description": "Local LLM inference",
                "size": "~4GB",
                "gpu": "optional",
                "port": "11434"
            },
            "open-webui": {
                "name": "Open WebUI",
                "description": "Web interface for Ollama",
                "size": "~500MB",
                "gpu": "no",
                "port": "8080"
            },
            "mcp-docker-manager": {
                "name": "MCP Docker Manager",
                "description": "Docker container management MCP",
                "size": "~100MB",
                "gpu": "no",
                "port": "none"
            },
            "mcp-filesystem": {
                "name": "MCP Filesystem",
                "description": "File system access MCP",
                "size": "~80MB",
                "gpu": "no",
                "port": "none"
            },
            "mcp-obsidian": {
                "name": "MCP Obsidian",
                "description": "Obsidian vault integration",
                "size": "~90MB",
                "gpu": "no",
                "port": "none"
            },
            "mcp-rss-aggregator": {
                "name": "MCP RSS Aggregator",
                "description": "RSS feed aggregation",
                "size": "~70MB",
                "gpu": "no",
                "port": "none"
            },
            "mcp-markdown-converter": {
                "name": "MCP Markdown Converter",
                "description": "Markdown to PDF/HTML conversion",
                "size": "~120MB",
                "gpu": "no",
                "port": "none"
            },
            "mcp-pytorch-inspector": {
                "name": "MCP PyTorch Inspector",
                "description": "PyTorch model inspection",
                "size": "~200MB",
                "gpu": "yes",
                "port": "none"
            },
            "mcp-gpu-optimizer": {
                "name": "MCP GPU Optimizer",
                "description": "GPU optimization tools",
                "size": "~150MB",
                "gpu": "required",
                "port": "none"
            },
            "mcp-librecad": {
                "name": "MCP LibreCAD",
                "description": "CAD file management",
                "size": "~300MB",
                "gpu": "no",
                "port": "5900"
            },
            "mcp-kali-tools": {
                "name": "MCP Kali Tools",
                "description": "Security testing tools",
                "size": "~2GB",
                "gpu": "no",
                "port": "none"
            },
            "phoneinfoga": {
                "name": "PhoneInfoga",
                "description": "OSINT phone number tool",
                "size": "~100MB",
                "gpu": "no",
                "port": "8081"
            }
        }

    def run(self):
        """Main execution flow"""
        try:
            # Welcome screen
            if not self.show_welcome():
                return 1

            # Hardware detection
            self.detect_hardware()
            self.show_hardware_info()

            # Installation mode selection
            mode = self.select_installation_mode()
            if mode is None:
                return 1

            self.installation_mode = mode

            if mode == "full":
                # Full auto - select all packages and containers
                self.selected_packages = self.load_all_packages()
                self.selected_containers = self.get_compatible_containers()
                self.ai_dev_enabled = self.prompt_ai_dev_bundle()

            elif mode == "custom":
                # Custom selection
                self.selected_packages = self.select_packages()
                if self.selected_packages is None:
                    return 1

                self.selected_containers = self.select_containers()
                if self.selected_containers is None:
                    return 1

                self.ai_dev_enabled = self.prompt_ai_dev_bundle()

            elif mode == "manual":
                # Step-by-step with explanations
                if not self.manual_mode():
                    return 1

            # Confirmation
            if not self.show_confirmation():
                return 1

            # Save selections
            self.save_selections()

            # Show completion
            self.show_completion()

            return 0

        except KeyboardInterrupt:
            self.d.msgbox("Installation cancelled by user", height=6, width=50)
            return 1
        except Exception as e:
            self.d.msgbox(f"Error: {str(e)}", height=10, width=60, title="Error")
            return 2

    def show_welcome(self) -> bool:
        """Display welcome screen with ASCII art"""
        banner = r"""
╔══════════════════════════════════════════════╗
║   Omarchy Dotfiles - Interactive Installer  ║
║   Professional Hyprland Configuration       ║
╚══════════════════════════════════════════════╝

This installer will guide you through:

  • Hardware detection and optimization
  • Dotfiles and configuration setup
  • Package selection and installation
  • Docker container deployment
  • AI development environment (optional)

The installation is fully customizable and
hardware-aware, ensuring optimal performance
for your specific system.

Press OK to continue...
"""
        code = self.d.msgbox(banner, height=22, width=70, title="Welcome")
        return code == self.d.OK

    def detect_hardware(self):
        """Run hardware detection script"""
        detect_script = self.dotfiles_dir / "scripts" / "detect-hardware.sh"

        if not detect_script.exists():
            self.d.msgbox(
                "Warning: Hardware detection script not found.\n"
                "Using generic profile.",
                height=7, width=50
            )
            return

        # Show progress
        self.d.infobox("Detecting hardware...\nPlease wait...", height=5, width=40)

        try:
            subprocess.run([str(detect_script)], check=True,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

            # Load results
            env_file = Path("/tmp/hardware-profile.env")
            if env_file.exists():
                with open(env_file, 'r') as f:
                    for line in f:
                        if '=' in line:
                            key, value = line.strip().split('=', 1)
                            if key == "HARDWARE_PROFILE":
                                self.hardware_profile = value
                            elif key == "HAS_NVIDIA":
                                self.has_nvidia = value.lower() == "true"
                            elif key == "HAS_INTEL_GPU":
                                self.has_intel_gpu = value.lower() == "true"
                            elif key == "RAM_GB":
                                self.ram_gb = int(value) if value.isdigit() else 0
                            elif key == "CPU_GENERATION":
                                self.cpu_generation = value
        except Exception as e:
            self.d.msgbox(f"Hardware detection error: {str(e)}\nUsing generic profile.",
                         height=8, width=60)

    def show_hardware_info(self):
        """Display detected hardware information"""
        profile_name = {
            "surface": "Microsoft Surface Laptop",
            "t420s": "Lenovo ThinkPad T420s",
            "generic": "Generic System"
        }.get(self.hardware_profile, "Unknown")

        gpu_info = []
        if self.has_intel_gpu:
            gpu_info.append("Intel")
        if self.has_nvidia:
            gpu_info.append("NVIDIA")
        gpu_str = " + ".join(gpu_info) if gpu_info else "Unknown"

        info = f"""
Hardware Detection Complete

Profile:       {profile_name}
RAM:           {self.ram_gb} GB
GPU:           {gpu_str}
CPU Gen:       {self.cpu_generation if self.cpu_generation else 'Unknown'}

Hardware-specific optimizations will be applied
automatically during installation.
"""
        self.d.msgbox(info, height=15, width=60, title="Hardware Detection")

    def select_installation_mode(self) -> Optional[str]:
        """Select installation mode"""
        choices = [
            ("full", "Full Automatic Installation",
             "Install everything with default settings"),
            ("custom", "Custom Installation",
             "Choose specific packages and containers"),
            ("manual", "Manual Step-by-Step",
             "Guided installation with explanations")
        ]

        code, tag = self.d.menu(
            "Choose installation mode:",
            height=15,
            width=70,
            menu_height=3,
            choices=[(c[0], c[1]) for c in choices],
            title="Installation Mode"
        )

        if code == self.d.OK:
            return tag
        return None

    def load_all_packages(self) -> List[str]:
        """Load all packages from packages.txt"""
        packages = []

        if self.packages_file.exists():
            with open(self.packages_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        # Extract package name (first field)
                        pkg = line.split()[0]
                        packages.append(pkg)

        return packages

    def select_packages(self) -> Optional[List[str]]:
        """Interactive package selection with categories"""
        all_packages = self.load_all_packages()

        # Categorize packages
        categorized = {
            "Core Packages (Required)": [],
            "Development Tools": [],
            "System Packages": [],
            "Optional Tools": []
        }

        for pkg in all_packages:
            if pkg in self.core_packages:
                categorized["Core Packages (Required)"].append(pkg)
            elif pkg in self.dev_tools:
                categorized["Development Tools"].append(pkg)
            elif pkg in self.system_packages:
                categorized["System Packages"].append(pkg)
            else:
                categorized["Optional Tools"].append(pkg)

        # Build checklist items
        choices = []
        for category, pkgs in categorized.items():
            if pkgs:
                choices.append((f"--- {category} ---", "", False))
                for pkg in pkgs:
                    # Core packages pre-selected
                    selected = category.startswith("Core")
                    choices.append((pkg, "", selected))

        code, selections = self.d.checklist(
            "Select packages to install:\n"
            "(Core packages are pre-selected and recommended)\n\n"
            "Use SPACE to select/deselect, ENTER to confirm",
            height=25,
            width=70,
            list_height=18,
            choices=choices,
            title="Package Selection"
        )

        if code == self.d.OK:
            # Filter out category headers
            return [s for s in selections if not s.startswith("---")]
        return None

    def get_compatible_containers(self) -> List[str]:
        """Get list of containers compatible with current hardware"""
        containers = []

        for container_id, info in self.containers.items():
            # Skip GPU-required containers on T420s without NVIDIA
            if self.hardware_profile == "t420s" and info["gpu"] == "required":
                continue

            # Skip GPU-required if no GPU at all
            if info["gpu"] == "required" and not self.has_nvidia:
                continue

            containers.append(container_id)

        return containers

    def select_containers(self) -> Optional[List[str]]:
        """Interactive container selection"""
        compatible = self.get_compatible_containers()

        choices = []
        for container_id in compatible:
            info = self.containers[container_id]

            # Build description
            desc = f"{info['name']} - {info['description']} [{info['size']}]"
            if info['gpu'] == "required":
                desc += " [GPU Required]"
            elif info['gpu'] == "yes":
                desc += " [GPU Optional]"

            # Pre-select common containers
            preselect = container_id in ["ollama", "open-webui",
                                        "mcp-docker-manager", "mcp-filesystem"]

            choices.append((container_id, desc, preselect))

        # Show warning for incompatible containers
        warning = ""
        if self.hardware_profile == "t420s" or not self.has_nvidia:
            warning = "\nNote: GPU-dependent containers are hidden/disabled\ndue to hardware limitations.\n"

        code, selections = self.d.checklist(
            f"Select Docker containers to deploy:\n"
            f"{warning}\n"
            f"Use SPACE to select/deselect, ENTER to confirm",
            height=25,
            width=78,
            list_height=15,
            choices=choices,
            title="Container Selection"
        )

        if code == self.d.OK:
            return selections
        return None

    def prompt_ai_dev_bundle(self) -> bool:
        """Prompt for AI development bundle"""
        message = """
AI Development Bundle

This bundle includes:
  • Conda (miniconda3) for environment management
  • CUDA 13.0 + cuDNN for GPU acceleration
  • Jupyter Notebook for interactive development
  • Python ML libraries:
    - NumPy, Pandas, Matplotlib
    - Scikit-learn, SciPy, Seaborn
    - CuPy, PyCUDA for GPU computing
  • Custom AI development aliases

Requirements:
  • Disk Space: ~5 GB
  • Package Count: 18 additional packages
  • Recommended RAM: 8 GB+

Enable AI Development Bundle?
"""

        # Skip CUDA on T420s without NVIDIA
        if self.hardware_profile == "t420s" and not self.has_nvidia:
            message += "\nWarning: Your system has no NVIDIA GPU.\n"
            message += "CUDA packages will be skipped, but CPU ML tools will be installed.\n"

        code = self.d.yesno(message, height=23, width=70, title="AI Development Bundle")
        return code == self.d.OK

    def manual_mode(self) -> bool:
        """Step-by-step manual installation mode"""
        steps = [
            ("Dotfiles", "Symlink configuration files?"),
            ("Packages", "Install system packages?"),
            ("Containers", "Deploy Docker containers?"),
            ("AI-Dev", "Enable AI development environment?"),
        ]

        selections = {
            "Dotfiles": True,
            "Packages": False,
            "Containers": False,
            "AI-Dev": False
        }

        for step_name, question in steps:
            code = self.d.yesno(question, height=8, width=50,
                               title=f"Step: {step_name}")
            selections[step_name] = (code == self.d.OK)

        # Configure based on selections
        if selections["Packages"]:
            self.selected_packages = self.select_packages()
            if self.selected_packages is None:
                return False

        if selections["Containers"]:
            self.selected_containers = self.select_containers()
            if self.selected_containers is None:
                return False

        if selections["AI-Dev"]:
            self.ai_dev_enabled = self.prompt_ai_dev_bundle()

        return True

    def show_confirmation(self) -> bool:
        """Show confirmation summary before installation"""
        # Calculate estimates
        pkg_count = len(self.selected_packages)
        container_count = len(self.selected_containers)

        # Estimate disk space
        disk_space = pkg_count * 50  # ~50MB per package average
        for container_id in self.selected_containers:
            size_str = self.containers[container_id]["size"]
            if "GB" in size_str:
                disk_space += int(size_str.split("~")[1].split("GB")[0]) * 1024
            elif "MB" in size_str:
                disk_space += int(size_str.split("~")[1].split("MB")[0])

        if self.ai_dev_enabled:
            disk_space += 5 * 1024  # AI bundle ~5GB

        disk_gb = disk_space / 1024

        # Estimate time
        time_estimate = pkg_count * 2 + container_count * 3  # rough estimate in minutes

        summary = f"""
Installation Summary

Hardware Profile:    {self.hardware_profile.upper()}
Installation Mode:   {self.installation_mode.upper()}

Components:
  • Packages:        {pkg_count} packages
  • Containers:      {container_count} containers
  • AI Dev Bundle:   {"Enabled" if self.ai_dev_enabled else "Disabled"}

Estimates:
  • Disk Space:      ~{disk_gb:.1f} GB
  • Install Time:    ~{time_estimate} minutes
  • Network Usage:   High (downloading packages/images)

The following will be installed:
  ✓ Hyprland configuration and dotfiles
  ✓ Selected system packages
  ✓ Docker containers and MCP servers
  {"✓ AI development environment" if self.ai_dev_enabled else ""}

Your existing configs will be backed up to:
  ~/.dotfiles-backup-<timestamp>

Proceed with installation?
"""

        code = self.d.yesno(summary, height=25, width=70,
                           title="Confirm Installation",
                           defaultno=False)
        return code == self.d.OK

    def save_selections(self):
        """Save selections to temporary files for bash script"""
        # Save packages
        pkg_file = Path("/tmp/package-selection.txt")
        with open(pkg_file, 'w') as f:
            for pkg in self.selected_packages:
                f.write(f"{pkg}\n")

        # Save containers
        container_file = Path("/tmp/container-selection.txt")
        with open(container_file, 'w') as f:
            for container in self.selected_containers:
                f.write(f"{container}\n")

        # Save AI dev flag
        ai_dev_file = Path("/tmp/ai-dev-enabled.txt")
        with open(ai_dev_file, 'w') as f:
            f.write("yes" if self.ai_dev_enabled else "no")

        # Save hardware profile (for bash script)
        profile_file = Path("/tmp/installation-config.env")
        with open(profile_file, 'w') as f:
            f.write(f"HARDWARE_PROFILE={self.hardware_profile}\n")
            f.write(f"INSTALLATION_MODE={self.installation_mode}\n")
            f.write(f"PACKAGE_COUNT={len(self.selected_packages)}\n")
            f.write(f"CONTAINER_COUNT={len(self.selected_containers)}\n")
            f.write(f"AI_DEV_ENABLED={'true' if self.ai_dev_enabled else 'false'}\n")

    def show_completion(self):
        """Show completion message"""
        message = """
Configuration Complete!

Your selections have been saved and are ready
for installation.

The bash installer will now proceed with:
  1. Symlinking dotfiles
  2. Installing selected packages
  3. Deploying Docker containers
  4. Configuring system services
  5. Final system update

Selections saved to:
  /tmp/package-selection.txt
  /tmp/container-selection.txt
  /tmp/ai-dev-enabled.txt

Press OK to begin installation...
"""

        self.d.msgbox(message, height=20, width=65, title="Ready to Install")


def main():
    """Main entry point"""
    # Check if running as root
    if os.geteuid() == 0:
        print("ERROR: Do not run this installer as root")
        print("The installer will prompt for sudo when needed")
        sys.exit(2)

    # Check for dialog
    if not DIALOG_AVAILABLE:
        print("ERROR: python-dialog is not installed")
        print("Install with: sudo pacman -S python-dialog")
        sys.exit(2)

    # Create and run installer
    installer = OmarchyInstaller()
    exit_code = installer.run()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
