# MCP Gateway Setup

This document explains the MCP (Model Context Protocol) bridge/gateway configuration and how to preserve it across deployments.

## Overview

The **ollama-mcp-bridge** acts as a gateway that connects Ollama to Docker-based MCP servers, allowing LLMs to interact with various tools and services.

### Architecture

```
┌─────────────────┐
│   Ollama/LLM    │
│  (Port 11434)   │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ ollama-mcp      │
│   bridge        │  ← Gateway/Proxy
│  (Port 8000)    │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│           Docker MCP Servers            │
├─────────────────────────────────────────┤
│  • mcp-docker-manager                   │
│  • mcp-obsidian                         │
│  • mcp-filesystem                       │
│  • mcp-pytorch-inspector                │
│  • mcp-kali-tools                       │
│  • mcp-librecad                         │
│  • mcp-gpu-optimizer                    │
│  • mcp-rss-aggregator                   │
│  • mcp-markdown-converter               │
└─────────────────────────────────────────┘
```

## Current Configuration

### MCP Bridge Binary

**Location:** `~/.local/bin/ollama-mcp-bridge`
**Installed via:** pipx
**Version:** Managed by pipx

```bash
# Check installation
which ollama-mcp-bridge
# Output: /home/cam/.local/bin/ollama-mcp-bridge
```

### MCP Config File

**Location:** `~/Development/mcp-servers/mcp-config.json`

```json
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
    "kali-tools": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-kali-tools", "node", "index.js"]
    },
    "librecad": {
      "command": "docker",
      "args": ["exec", "-i", "mcp-librecad", "node", "index.js"]
    }
  }
}
```

### Bash Functions and Aliases

All MCP management functions are defined in `.bashrc`:

```bash
# Start MCP bridge
start_mcp_bridge() {
    if ! pgrep -f "ollama-mcp-bridge" >/dev/null 2>&1 && ! ss -ltn | grep -q ":8000 " 2>/dev/null; then
        if docker info >/dev/null 2>&1; then
            echo "Starting ollama-mcp-bridge..."
            cd ~/Development/mcp-servers
            nohup ~/.local/bin/ollama-mcp-bridge --config mcp-config.json --port 8000 > ~/.mcp-bridge.log 2>&1 &
            sleep 1
            echo "MCP bridge started! (log: ~/.mcp-bridge.log)"
        else
            echo "⚠️  Docker is not running. Start Docker first."
        fi
    else
        echo "✓ MCP bridge is already running"
    fi
}

# Aliases
alias mcp-start='start_mcp_bridge'
alias mcp-stop='pkill -f ollama-mcp-bridge && echo "MCP bridge stopped"'
alias mcp-restart='mcp-stop && sleep 2 && mcp-start'
alias mcp-log='tail -f ~/.mcp-bridge.log'

# Status check
mcp-status() {
    if pgrep -f ollama-mcp-bridge >/dev/null; then
        echo "✓ MCP bridge is running (PID: $(pgrep -f ollama-mcp-bridge))"
        ss -ltn | grep :8000 || true
    else
        echo "✗ MCP bridge not running"
    fi
}
```

## Deployment on New System

### Prerequisites

1. ✅ Docker installed and running
2. ✅ pipx installed (`sudo pacman -S python-pipx`)
3. ✅ Ollama installed
4. ✅ MCP Docker containers deployed (via `scripts/deploy-mcp.sh`)

### Installation Steps

#### 1. Install ollama-mcp-bridge

```bash
# Install via pipx
pipx install ollama-mcp-bridge

# Verify installation
which ollama-mcp-bridge
# Should output: /home/YOUR_USER/.local/bin/ollama-mcp-bridge
```

#### 2. Create MCP Workspace

```bash
# Create directory structure
mkdir -p ~/Development/mcp-servers

# The deploy-mcp.sh script will create:
# - docker-compose.yml (MCP containers)
# - mcp-config.json (bridge configuration)
```

#### 3. Link .bashrc

The setup script will automatically link `.bashrc`:

```bash
cd ~/Projects/omarchy-dotfiles
./scripts/setup.sh
# This creates: ~/.bashrc -> ~/Projects/omarchy-dotfiles/.bashrc
```

Or manually:

```bash
ln -sf ~/Projects/omarchy-dotfiles/.bashrc ~/.bashrc
source ~/.bashrc
```

#### 4. Deploy MCP Containers

```bash
cd ~/Projects/omarchy-dotfiles
./scripts/deploy-mcp.sh
```

This will:
- Start Docker containers for all selected MCP servers
- Generate `mcp-config.json` automatically
- Configure Claude Desktop integration

#### 5. Start MCP Bridge

```bash
# Start the bridge
mcp-start

# Check status
mcp-status

# View logs
mcp-log
```

## Usage

### Managing the MCP Bridge

```bash
# Start bridge (safe - won't restart if already running)
mcp-start

# Stop bridge
mcp-stop

# Restart bridge (useful after config changes)
mcp-restart

# Check if running
mcp-status

# View real-time logs
mcp-log
```

### Accessing MCP Gateway

The bridge listens on **port 8000**:

```bash
# Test connectivity
curl http://localhost:8000

# Or check with netstat
ss -ltn | grep :8000
```

### MCP Server Management

All MCP servers run in Docker containers:

```bash
# View running containers
docker ps

# View container logs
docker logs mcp-docker-manager
docker logs mcp-obsidian

# Restart a specific server
docker restart mcp-filesystem

# Stop all MCP containers
cd ~/Development/mcp-servers
docker compose down

# Start all MCP containers
docker compose up -d
```

## Directory Structure

```
~/Development/mcp-servers/
├── docker-compose.yml          # Container definitions
├── mcp-config.json             # Bridge configuration
├── launch-dashboard.sh         # Dashboard launcher
├── logs/                       # Container logs
├── dashboard/                  # MCP dashboard
└── servers/                    # Individual server configs
```

## Configuration Files Preserved in Dotfiles

The following files are preserved in this repository:

1. **`.bashrc`** - Contains all MCP functions and aliases
2. **`scripts/local-bin/monitor-switch`** - Monitor configuration switcher
3. **`docker/docker-compose.yml`** - MCP container definitions
4. **`scripts/deploy-mcp.sh`** - Automated deployment script

## Troubleshooting

### Bridge Won't Start

```bash
# Check if port 8000 is already in use
ss -ltn | grep :8000

# Kill existing process
pkill -f ollama-mcp-bridge

# Check Docker is running
docker info

# Restart bridge
mcp-restart
```

### MCP Servers Not Responding

```bash
# Check container status
docker ps -a | grep mcp-

# Restart containers
cd ~/Development/mcp-servers
docker compose restart

# View container logs
docker logs mcp-docker-manager --tail 50
```

### Config Not Found

```bash
# Verify config location
ls -la ~/Development/mcp-servers/mcp-config.json

# Regenerate config (will be created by deploy script)
cd ~/Projects/omarchy-dotfiles
./scripts/deploy-mcp.sh
```

### Bridge Crashes on Startup

```bash
# View bridge logs
cat ~/.mcp-bridge.log

# Common issues:
# - Docker not running: sudo systemctl start docker
# - Port conflict: Change port in start_mcp_bridge function
# - Missing config: Run deploy-mcp.sh
```

## Auto-Start on Boot (Optional)

To automatically start the MCP bridge on login:

### Method 1: Hyprland Autostart

Add to `.config/hypr/autostart.conf`:

```conf
exec-once = sleep 5 && mcp-start
```

### Method 2: Systemd User Service

Create `~/.config/systemd/user/mcp-bridge.service`:

```ini
[Unit]
Description=Ollama MCP Bridge
After=docker.service

[Service]
Type=forking
ExecStart=/home/cam/.local/bin/ollama-mcp-bridge --config /home/cam/Development/mcp-servers/mcp-config.json --port 8000
WorkingDirectory=/home/cam/Development/mcp-servers
StandardOutput=append:/home/cam/.mcp-bridge.log
StandardError=append:/home/cam/.mcp-bridge.log
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable:

```bash
systemctl --user enable --now mcp-bridge.service
```

## Integration with Claude Desktop

The `deploy-mcp.sh` script automatically configures Claude Desktop.

**Config location:** `~/.config/Claude/claude_desktop_config.json`

The bridge gateway allows Claude to access all MCP servers through a single endpoint.

## Updating MCP Bridge

```bash
# Update via pipx
pipx upgrade ollama-mcp-bridge

# Restart bridge
mcp-restart

# Verify version
ollama-mcp-bridge --version
```

## Security Notes

⚠️ **Important Security Considerations:**

1. The MCP bridge runs on **localhost only** (port 8000)
2. No external access without explicit port forwarding
3. MCP servers run in isolated Docker containers
4. Kali tools container should only be used for authorized testing
5. Never expose port 8000 to the internet

## Backup and Migration

To migrate your MCP setup to a new machine:

1. ✅ Clone this dotfiles repo (includes `.bashrc`)
2. ✅ Run `scripts/deploy-mcp.sh` (deploys containers + generates config)
3. ✅ Install `ollama-mcp-bridge` via pipx
4. ✅ Run `mcp-start`

All configurations and functions will be preserved.

## Related Documentation

- **Container Setup:** [docker/README.md](docker/README.md)
- **MCP Selection:** Use `scripts/select-mcp.sh` for interactive container selection
- **Package Management:** [README.md](README.md#package-management)

## Support

If you encounter issues:

1. Check logs: `mcp-log`
2. Verify Docker: `docker info`
3. Check bridge status: `mcp-status`
4. Review container logs: `docker logs mcp-<server-name>`
5. Restart everything: `mcp-restart && docker compose restart`
