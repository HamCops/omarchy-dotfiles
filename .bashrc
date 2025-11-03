source ~/.local/share/omarchy/default/bash/rc

# Created by `pipx` on 2025-10-25 20:37:42
export PATH="$PATH:/home/cam/.local/bin"

# ===== AI Development Environment (Optional) =====
# To enable AI development tools, uncomment the line below or run:
# echo "AI_DEV_ENABLED=true" > ~/.config/omarchy-dotfiles.conf
if [ -f ~/.config/omarchy-dotfiles.conf ]; then
    source ~/.config/omarchy-dotfiles.conf
fi

if [ "$AI_DEV_ENABLED" = "true" ] && [ -f ~/.bashrc-ai-dev ]; then
    source ~/.bashrc-ai-dev
fi

# ===== MCP Bridge Management =====
# Manual start function for ollama-mcp-bridge
start_mcp_bridge() {
    # Check if bridge is already running (by process or port)
    if ! pgrep -f "ollama-mcp-bridge" >/dev/null 2>&1 && ! ss -ltn | grep -q ":8000 " 2>/dev/null; then
        # Check if Docker is running
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

# Helpful aliases for managing MCP bridge
alias mcp-start='start_mcp_bridge'
alias mcp-stop='pkill -f ollama-mcp-bridge && echo "MCP bridge stopped"'
alias mcp-restart='mcp-stop && sleep 2 && mcp-start'
mcp-status() { if pgrep -f ollama-mcp-bridge >/dev/null; then echo "✓ MCP bridge is running (PID: $(pgrep -f ollama-mcp-bridge))"; ss -ltn | grep :8000 || true; else echo "✗ MCP bridge not running"; fi; }
alias mcp-log='tail -f ~/.mcp-bridge.log'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/cam/.lmstudio/bin"
# End of LM Studio CLI section
