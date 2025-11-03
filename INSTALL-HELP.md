# Installation Help

## Quick Fix for "externally-managed-environment" Error

If you got the error:
```
error: externally-managed-environment
failed to install pythondialog
```

**Solution:** Install the dependency manually, then run the installer:

```bash
# Install the required packages
sudo pacman -S dialog
yay -S python-pythondialog

# Now run the interactive installer
./install-interactive.sh
```

---

## What Each Package Does

| Package | Purpose | Source |
|---------|---------|--------|
| `dialog` | Terminal UI backend (ncurses-based) | Arch core repos |
| `python-pythondialog` | Python wrapper for dialog | AUR |

---

## Installation Methods

### Method 1: Let the Script Auto-Install (Easiest)

The script will automatically install dependencies if you have `yay`:

```bash
./install-interactive.sh
```

### Method 2: Manual Install First (Safest)

Install dependencies manually before running the installer:

```bash
# Step 1: Install dialog
sudo pacman -S dialog

# Step 2: Install python-pythondialog from AUR
yay -S python-pythondialog

# Step 3: Run installer
./install-interactive.sh
```

### Method 3: Without yay (Uses pipx)

If you don't have `yay` installed:

```bash
# Install dialog and pipx
sudo pacman -S dialog python-pipx

# Install pythondialog via pipx
pipx install pythondialog

# Add pipx bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Run installer
./install-interactive.sh
```

---

## Don't Have yay?

Install `yay` (AUR helper) first:

```bash
# Install base-devel if not already installed
sudo pacman -S --needed base-devel git

# Clone yay repository
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay

# Build and install yay
makepkg -si

# Now you can install python-pythondialog
yay -S python-pythondialog
```

---

## Verification

Check if dependencies are installed correctly:

```bash
# Check dialog
dialog --version

# Check python-pythondialog
python3 -c "import dialog; print('✓ pythondialog is installed')"
```

If both commands succeed, you're ready to run the installer!

---

## Still Having Issues?

### Error: "dialog: command not found"
```bash
sudo pacman -S dialog
```

### Error: "ModuleNotFoundError: No module named 'dialog'"
```bash
yay -S python-pythondialog
# OR
pipx install pythondialog && export PATH="$HOME/.local/bin:$PATH"
```

### Error: "yay: command not found"

You need to install yay first (see "Don't Have yay?" section above), or use the pipx method.

---

## Alternative: Use the Non-Interactive Installer

If the TUI is giving you trouble, use the fully automated installer instead:

```bash
./install.sh
```

This doesn't require `dialog` or `pythondialog`, but you won't get the interactive menus.

---

## Quick Command Reference

```bash
# Check what you have installed
pacman -Q dialog python-pythondialog 2>/dev/null

# Install everything at once
sudo pacman -S dialog && yay -S python-pythondialog

# Verify installation
python3 -c "import dialog" && echo "✓ Ready to install!"

# Run installer
./install-interactive.sh
```
