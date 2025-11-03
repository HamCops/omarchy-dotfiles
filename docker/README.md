# MCP Container Deployment

This directory contains Docker Compose configurations for all MCP (Model Context Protocol) servers and AI infrastructure.

## Quick Start

### Interactive Selection (Recommended for T420s)

```bash
cd ~/Projects/omarchy-dotfiles
./scripts/deploy-mcp.sh
# Choose option 2 for interactive selection
```

Or directly:

```bash
./scripts/select-mcp.sh
```

### Deploy All Containers

```bash
./scripts/deploy-mcp.sh
# Choose option 1 or just press Enter
```

---

## Container Presets

### Minimal (3 containers, ~4GB disk, 2-3GB RAM)
Perfect for low-resource systems like T420s
- **ollama** - Local LLM inference
- **mcp-docker-manager** - Docker management
- **mcp-filesystem** - File operations

### Standard (6 containers, ~10GB disk, 3-4GB RAM)
Good balance for most systems
- Everything in Minimal, plus:
- **open-webui** - Web UI for Ollama
- **mcp-obsidian** - Obsidian vault management
- **mcp-rss-aggregator** - RSS feeds

### Full (9-10 containers, ~20GB disk, 6-8GB RAM)
For powerful systems like Surface Laptop Studio
- Everything in Standard, plus:
- **mcp-markdown-converter** - Document conversion
- **mcp-pytorch-inspector** - PyTorch model inspection
- **mcp-librecad** - CAD file viewing
- **mcp-gpu-optimizer** - GPU monitoring (NVIDIA only)
- **phoneinfoga** - OSINT tool

### NOT included by default:
- **mcp-kali-tools** (8.94GB!) - Too large, opt-in only

---

## Interactive Selection Features

The MCP selector (`select-mcp.sh`) provides:

✅ **Visual interface** - See all containers with checkboxes
✅ **Resource info** - RAM/disk requirements shown
✅ **GPU warnings** - Alerts for NVIDIA-only containers
✅ **Quick presets** - Minimal/Standard/Full options
✅ **Hardware detection** - Auto-recommends based on your system
✅ **Live preview** - See what's selected before deploying

### Commands in Selector:

```
1-12  - Toggle individual containers
p     - Apply preset (minimal/standard/full)
a     - Select all
n     - Deselect all (start over)
s     - Save and deploy
q     - Quit without changes
```

---

## Container Details

### AI Services

**ollama** (3.5GB)
- Local LLM inference server
- Supports Llama, Mistral, CodeLlama, etc.
- CPU and GPU modes
- Access: http://localhost:11434

**open-webui** (4.5GB)
- Web UI for Ollama
- Chat interface
- Model management
- Access: http://localhost:8080

### Essential MCP Servers

**mcp-docker-manager** (174MB)
- Manage Docker containers via MCP
- List, start, stop, inspect containers
- View logs and stats

**mcp-filesystem** (141MB)
- File operations via MCP
- Read, write, search files
- Directory management

### Productivity MCP Servers

**mcp-obsidian** (141MB)
- Obsidian vault management
- Note creation and search
- Tag management
- Requires: ~/Documents/Obsidian vault

**mcp-rss-aggregator** (276MB)
- RSS feed reader
- Popular tech/security feeds pre-configured
- Article extraction

**mcp-markdown-converter** (1.95GB)
- Markdown to PDF/DOCX/HTML
- Batch conversion
- Requires: Pandoc, LaTeX

### Development MCP Servers

**mcp-pytorch-inspector** (2GB)
- PyTorch model inspection
- Model analysis and stats
- Requires: ~/ai-workspace/models

**mcp-gpu-optimizer** (141MB)
- GPU monitoring and optimization
- VRAM suggestions
- **NVIDIA GPU required**

### Specialized MCP Servers

**mcp-librecad** (827MB)
- CAD file viewing and conversion
- DXF/DWG support
- VNC access on port 5900

**mcp-kali-tools** (8.94GB!)
- Security testing tools
- Pentesting utilities
- **Very large, opt-in only**

### Other Services

**phoneinfoga** (43MB)
- Phone number OSINT tool
- Carrier lookup
- Access: http://localhost:8081

---

## Hardware-Specific Behavior

### On Surface Laptop Studio:
- All containers available
- GPU optimizer enabled
- Full resources allocated

### On T420s:
- GPU optimizer disabled (no NVIDIA)
- Reduced resource limits
- Recommended: Use Minimal or Standard preset
- Skip: pytorch-inspector, kali-tools (too heavy)

---

## Managing Containers

### View Status
```bash
cd ~/Projects/omarchy-dotfiles/docker
docker compose ps
```

### View Logs
```bash
docker compose logs -f
docker compose logs -f ollama  # Specific container
```

### Stop All
```bash
docker compose down
```

### Restart Containers
```bash
docker compose restart
```

### Update Images
```bash
docker compose pull
docker compose up -d
```

### Remove Everything (including volumes)
```bash
docker compose down -v
```

---

## Saved Selections

Your MCP selections are saved in:
```
docker/mcp-selection.env
```

To change your selection:
```bash
./scripts/select-mcp.sh
```

To deploy with saved selection:
```bash
./scripts/deploy-mcp.sh --use-selection
```

---

## Troubleshooting

### Container won't start
```bash
# Check logs
docker compose logs container-name

# Rebuild
docker compose up -d --force-recreate container-name
```

### Out of disk space
```bash
# Clean up unused images
docker system prune -a

# Use minimal preset instead
./scripts/select-mcp.sh  # Choose preset 1
```

### GPU optimizer fails on T420s
This is normal - T420s has Intel GPU, not NVIDIA. Just don't select it in the menu.

### Ollama uses too much RAM
```bash
# Edit docker-compose.yml and add memory limits
# Or use T420s override which already has limits
```

---

## Files

```
docker/
├── docker-compose.yml           # Main compose file (all containers)
├── docker-compose.t420s.yml     # T420s overrides (auto-used)
├── docker-compose.custom.yml    # Generated from your selection
├── mcp-selection.env            # Your saved selections
└── README.md                    # This file
```

---

## Tips

💡 **For T420s**: Always use the selector and choose Minimal or Standard
💡 **First time**: Try Minimal preset, add more later if needed
💡 **Low disk space**: Skip markdown-converter, pytorch-inspector, kali-tools
💡 **Just want Ollama**: Use Minimal preset (includes essentials)
💡 **Want everything**: Surface can handle Full preset + kali-tools
💡 **Save disk**: Don't run all containers at once, start/stop as needed

---

Ready to deploy? Run:
```bash
./scripts/deploy-mcp.sh
```
