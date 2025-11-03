# AI Development Bundle (Optional)

The **AI Development Bundle** is an optional add-on for this dotfiles repository that provides a complete environment for AI/ML development with CUDA acceleration.

## Overview

The AI-dev bundle is **completely optional** and separate from the core dotfiles. It adds:

- 📦 **18 packages** (~5GB disk space)
- 🐍 **Conda environment management** (miniconda3)
- 🚀 **CUDA GPU acceleration** (CUDA, cuDNN, NCCL)
- 📊 **ML/Data Science libraries** (numpy, pandas, scipy, scikit-learn, matplotlib, etc.)
- 📓 **Jupyter Notebook** for interactive development
- ⚡ **Convenient aliases** for AI workflows

## When to Enable

✅ **Enable AI-dev if you:**
- Do machine learning or data science work
- Train or fine-tune ML models
- Use Jupyter notebooks
- Need CUDA for GPU acceleration
- Work with scientific Python libraries

❌ **Skip AI-dev if you:**
- Only do general development
- Don't work with ML/AI
- Want to save disk space (~5GB)
- Don't have an NVIDIA GPU (CUDA won't work)

## What's Included

### Packages (18 total)

**CUDA/GPU Acceleration:**
```
cuda 13.0.2-1
cuda-tools 13.0.2-1
cudnn 9.14.0.64-1
nccl 2.28.7-1
python-cupy 13.6.0-5
python-pycuda 2025.1.2-4
```

**Python Environment:**
```
miniconda3 25.5.1.1-2
python-virtualenv 20.35.3-1
python-toml 0.10.2-12
```

**Data Science Libraries:**
```
jupyter-notebook 7.4.7-1
openblas 0.3.30-1
python-numpy 2.3.4-1
python-pandas 2.3.1-1
python-scipy 1.16.3-1
python-scikit-learn 1.7.2-1
```

**Visualization:**
```
python-matplotlib 3.10.6-1
python-plotly 6.3.1-1
python-seaborn 0.13.2-2
```

### Bash Configuration

**File:** `.bashrc-ai-dev`

When enabled, provides these aliases and functions:

#### Environment Management
```bash
ai-env              # Activate conda ai-dev environment
ai-deactivate       # Deactivate conda environment
```

#### Navigation
```bash
ai-workspace        # cd ~/ai-workspace
ai-projects         # cd ~/ai-workspace/projects
ai-notebooks        # cd ~/ai-workspace/notebooks
ai-models           # cd ~/ai-workspace/models
```

#### Tools
```bash
jupyter-ai          # Launch Jupyter Lab from ~/ai-workspace
mlflow-ui           # Start MLflow tracking UI
tensorboard-ai      # Start TensorBoard for logs
gpu-monitor         # Watch nvidia-smi in real-time
ai-doctor           # Run environment diagnostics
```

#### CI/CD
```bash
ai-init             # Initialize new AI project
ai-test             # Run test suite
ai-lint             # Run linter
ai-format           # Format code
ai-security         # Security scan
```

## Installation

### During Initial Setup

When running `./scripts/setup.sh`, you'll be prompted:

```
======================================
  Optional: AI Development Bundle
======================================

The AI Development bundle includes:
  • Conda (miniconda3) for environment management
  • CUDA, cuDNN for GPU acceleration
  • Jupyter Notebook for interactive development
  • Python ML libraries (numpy, pandas, matplotlib, scipy, scikit-learn, etc.)
  • AI development aliases (ai-env, ai-workspace, jupyter-ai, etc.)

This bundle adds ~18 packages and requires ~5GB disk space.

Enable AI Development bundle? (y/N)
```

- **Press `y`** to enable AI-dev
- **Press `n`** (or just Enter) to skip

### Manual Installation (After Setup)

If you initially skipped AI-dev but want to enable it later:

```bash
# 1. Enable AI-dev configuration
echo "AI_DEV_ENABLED=true" > ~/.config/omarchy-dotfiles.conf

# 2. Link AI-dev bashrc
ln -sf ~/Projects/omarchy-dotfiles/.bashrc-ai-dev ~/.bashrc-ai-dev

# 3. Reload bash configuration
source ~/.bashrc

# 4. Install AI-dev packages
cd ~/Projects/omarchy-dotfiles
./scripts/install-packages.sh
```

The install script will detect `AI_DEV_ENABLED=true` and automatically include AI-dev packages.

## Usage

Once enabled, start a new shell session or reload your bash config:

```bash
source ~/.bashrc
```

You'll see:
```
✓ AI Development environment loaded
  • Use 'ai-env' to activate conda ai-dev environment
  • Use 'ai-workspace' to navigate to AI workspace
  • Use 'jupyter-ai' to launch Jupyter Lab
```

### Common Workflows

#### Start AI Development Session

```bash
ai-workspace        # Navigate to workspace
ai-env              # Activate conda environment
jupyter-ai          # Launch Jupyter Lab
```

#### Monitor GPU During Training

```bash
gpu-monitor         # Watch nvidia-smi every second
```

#### Track Experiments

```bash
cd ~/ai-workspace/experiments
mlflow-ui           # View experiment tracking
```

#### View Training Logs

```bash
cd ~/ai-workspace/logs
tensorboard-ai      # Visualize with TensorBoard
```

## Directory Structure

The AI-dev bundle expects this workspace structure:

```
~/ai-workspace/
├── projects/           # Your AI projects
├── notebooks/          # Jupyter notebooks
├── models/             # Trained models
├── experiments/        # MLflow experiments
├── logs/               # TensorBoard logs
└── tools/              # Custom scripts
    ├── ai-doctor.sh
    └── init-ai-project.sh
```

**Note:** The workspace directory is NOT included in dotfiles - you create this yourself.

## Disabling AI-dev

To disable the AI Development bundle:

### Option 1: Remove Configuration

```bash
# Disable AI-dev
rm ~/.config/omarchy-dotfiles.conf

# Reload shell
source ~/.bashrc
```

AI-dev packages remain installed but aliases won't load.

### Option 2: Edit Configuration

```bash
# Set to false
echo "AI_DEV_ENABLED=false" > ~/.config/omarchy-dotfiles.conf

# Reload shell
source ~/.bashrc
```

### Option 3: Uninstall Packages

To completely remove AI-dev packages:

```bash
# Read package list and remove
while read pkg; do
    pkg_name=$(echo "$pkg" | awk '{print $1}')
    sudo pacman -Rns "$pkg_name"
done < ~/Projects/omarchy-dotfiles/packages-ai-dev.txt
```

## Hardware Compatibility

### NVIDIA GPU Required

⚠️ **CUDA packages require an NVIDIA GPU**

On systems without NVIDIA GPU (Intel-only T420s, etc.):
- CUDA, cuDNN, NCCL won't be functional
- python-cupy, python-pycuda won't work
- You can still use CPU-based ML (numpy, scikit-learn, etc.)

### T420s Considerations

On Lenovo T420s:

**Intel-only (no discrete GPU):**
- ❌ Skip CUDA packages (won't work)
- ✅ Can use: miniconda3, jupyter, numpy, pandas, scikit-learn (CPU mode)
- Recommendation: Either skip AI-dev entirely OR manually remove CUDA packages

**With NVIDIA NVS 4200M:**
- ❌ Skip CUDA packages (legacy GPU, CUDA 13 unsupported)
- ✅ Can use CPU-based ML libraries
- Note: Legacy NVIDIA GPU doesn't support modern CUDA

### Surface Laptop Studio

✅ Full support with NVIDIA RTX 3050 Ti
- All CUDA packages work
- GPU acceleration available
- Recommended for ML workloads

## Troubleshooting

### AI-dev aliases not available

```bash
# Check if enabled
cat ~/.config/omarchy-dotfiles.conf
# Should show: AI_DEV_ENABLED=true

# Check if bashrc-ai-dev is linked
ls -la ~/.bashrc-ai-dev

# Reload configuration
source ~/.bashrc
```

### Conda not found

```bash
# Check if miniconda3 is installed
pacman -Qi miniconda3

# Install if missing
sudo pacman -S miniconda3

# Initialize conda
conda init bash
source ~/.bashrc
```

### CUDA not working

```bash
# Check NVIDIA drivers
nvidia-smi

# Check CUDA installation
nvcc --version

# Verify GPU is detected
python -c "import torch; print(torch.cuda.is_available())"
```

### Jupyter won't start

```bash
# Activate conda environment first
ai-env

# Then try jupyter
jupyter lab

# Or install in conda env
conda install -c conda-forge jupyterlab
```

## Customization

### Adding Custom AI Aliases

Edit `.bashrc-ai-dev` in the dotfiles repo:

```bash
nano ~/Projects/omarchy-dotfiles/.bashrc-ai-dev
```

Add your aliases:

```bash
# Custom AI aliases
alias my-gpu-script='python ~/ai-workspace/scripts/my_script.py'
alias quick-train='cd ~/ai-workspace/projects/current && python train.py'
```

Commit changes:

```bash
cd ~/Projects/omarchy-dotfiles
git add .bashrc-ai-dev
git commit -m "Add custom AI aliases"
```

### Adding More AI Packages

Edit `packages-ai-dev.txt`:

```bash
nano ~/Projects/omarchy-dotfiles/packages-ai-dev.txt
```

Add packages:

```
python-keras 2.13.1-1
python-pytorch 2.0.1-1
python-transformers 4.30.2-1
```

Then reinstall:

```bash
./scripts/install-packages.sh
```

## Migration and Backup

### Backing Up AI Workspace

The dotfiles repo does NOT include your AI workspace. Back it up separately:

```bash
# Backup workspace
tar -czf ai-workspace-backup.tar.gz ~/ai-workspace/

# Or use git
cd ~/ai-workspace
git init
git add .
git commit -m "Initial backup"
git remote add origin YOUR_REPO_URL
git push -u origin main
```

### Moving to New Machine

On new machine:

```bash
# 1. Clone and setup dotfiles with AI-dev enabled
cd ~/Projects
git clone YOUR_DOTFILES_REPO
cd omarchy-dotfiles
./scripts/setup.sh
# Answer 'y' to AI-dev bundle

# 2. Restore AI workspace
tar -xzf ai-workspace-backup.tar.gz -C ~/

# 3. Recreate conda environments
cd ~/ai-workspace
conda env create -f environment.yml  # if you have one
```

## Related Documentation

- **Main README:** [README.md](README.md)
- **Package Management:** [README.md#package-management](README.md#package-management)
- **MCP Gateway:** [MCP_GATEWAY_SETUP.md](MCP_GATEWAY_SETUP.md)

## Summary

| Feature | AI-dev Enabled | AI-dev Disabled |
|---------|---------------|-----------------|
| **Packages** | Base (40) + AI (18) = 58 | Base only (40) |
| **Disk Space** | ~7GB total | ~2GB |
| **CUDA Support** | Yes (with NVIDIA GPU) | No |
| **ML Libraries** | Full stack | None |
| **Jupyter** | Yes | No |
| **Conda** | Yes | No |
| **AI Aliases** | 15+ aliases | None |

The AI Development bundle is **completely optional** and can be enabled/disabled at any time without affecting the core dotfiles functionality.
