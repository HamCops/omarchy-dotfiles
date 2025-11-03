source ~/.local/share/omarchy/default/bash/rc

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/cam/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/cam/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/cam/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/cam/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# ===== Omarchy AI Development Environment =====
# Set OpenSSL workaround
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

# Core aliases
alias ai-env='conda activate ai-dev'
alias ai-deactivate='conda deactivate'

# Navigation
alias ai-workspace='cd ~/ai-workspace'
alias ai-projects='cd ~/ai-workspace/projects'
alias ai-notebooks='cd ~/ai-workspace/notebooks'
alias ai-models='cd ~/ai-workspace/models'

# Tools
alias jupyter-ai='cd ~/ai-workspace && jupyter lab'
alias mlflow-ui='cd ~/ai-workspace/experiments && mlflow ui'
alias tensorboard-ai='cd ~/ai-workspace/logs && tensorboard --logdir .'
alias gpu-monitor='watch -n 1 nvidia-smi'
alias ai-doctor='conda activate ai-dev && ~/ai-workspace/tools/ai-doctor.sh'

# CI/CD
alias ai-init='~/ai-workspace/tools/init-ai-project.sh'
alias ai-test='cd ~/ai-workspace && make test'
alias ai-lint='cd ~/ai-workspace && make lint'
alias ai-format='cd ~/ai-workspace && make format'
alias ai-security='cd ~/ai-workspace && make security'

# Created by `pipx` on 2025-10-25 20:37:42
export PATH="$PATH:/home/cam/.local/bin"

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
