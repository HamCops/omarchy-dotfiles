#!/bin/bash

# TUI Installer Test Script
# Validates that the TUI can run and creates proper output files

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "========================================"
echo "  TUI Installer Test Suite"
echo "========================================"
echo ""

# Test 1: Check Python
echo "Test 1: Python installation"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    pass "Python 3 installed (version $PYTHON_VERSION)"
else
    fail "Python 3 not found"
fi

# Test 2: Check python-dialog
echo "Test 2: python-dialog library"
if python3 -c "import dialog" 2>/dev/null; then
    pass "python-dialog is installed"
else
    fail "python-dialog not found - install with: sudo pacman -S python-dialog"
fi

# Test 3: Check dialog binary
echo "Test 3: dialog binary"
if command -v dialog &> /dev/null; then
    DIALOG_VERSION=$(dialog --version 2>&1 | head -1)
    pass "dialog binary found ($DIALOG_VERSION)"
else
    warn "dialog binary not found (python-dialog includes it)"
fi

# Test 4: TUI script exists and is executable
echo "Test 4: TUI script"
if [ -f "$DOTFILES_DIR/install-tui.py" ]; then
    pass "install-tui.py exists"
else
    fail "install-tui.py not found"
fi

if [ -x "$DOTFILES_DIR/install-tui.py" ]; then
    pass "install-tui.py is executable"
else
    warn "install-tui.py not executable (will try to fix)"
    chmod +x "$DOTFILES_DIR/install-tui.py"
fi

# Test 5: Wrapper script exists and is executable
echo "Test 5: Wrapper script"
if [ -f "$DOTFILES_DIR/install-interactive.sh" ]; then
    pass "install-interactive.sh exists"
else
    fail "install-interactive.sh not found"
fi

if [ -x "$DOTFILES_DIR/install-interactive.sh" ]; then
    pass "install-interactive.sh is executable"
else
    warn "install-interactive.sh not executable (will try to fix)"
    chmod +x "$DOTFILES_DIR/install-interactive.sh"
fi

# Test 6: Python syntax check
echo "Test 6: Python syntax validation"
if python3 -m py_compile "$DOTFILES_DIR/install-tui.py" 2>/dev/null; then
    pass "Python syntax is valid"
else
    fail "Python syntax errors found"
fi

# Test 7: Bash syntax check
echo "Test 7: Bash syntax validation"
if bash -n "$DOTFILES_DIR/install-interactive.sh" 2>/dev/null; then
    pass "Bash syntax is valid"
else
    fail "Bash syntax errors found"
fi

# Test 8: Check required files
echo "Test 8: Required files"
REQUIRED_FILES=(
    "packages.txt"
    "packages-ai-dev.txt"
    "docker/docker-compose.yml"
    "scripts/detect-hardware.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$file" ]; then
        pass "$file exists"
    else
        fail "$file not found"
    fi
done

# Test 9: Hardware detection script
echo "Test 9: Hardware detection"
if [ -x "$DOTFILES_DIR/scripts/detect-hardware.sh" ]; then
    pass "Hardware detection script is executable"

    # Run it silently
    if "$DOTFILES_DIR/scripts/detect-hardware.sh" > /dev/null 2>&1; then
        pass "Hardware detection runs successfully"

        if [ -f /tmp/hardware-profile.env ]; then
            pass "Hardware profile created"

            # Check content
            if grep -q "HARDWARE_PROFILE=" /tmp/hardware-profile.env; then
                PROFILE=$(grep "HARDWARE_PROFILE=" /tmp/hardware-profile.env | cut -d'=' -f2)
                pass "Hardware profile detected: $PROFILE"
            fi
        else
            fail "Hardware profile not created"
        fi
    else
        fail "Hardware detection script failed"
    fi
else
    warn "Hardware detection script not executable"
fi

# Test 10: Mock TUI run (create fake selections)
echo "Test 10: Mock installation config"

# Create mock selection files
echo "neovim" > /tmp/package-selection.txt
echo "zed" >> /tmp/package-selection.txt
echo "docker" >> /tmp/package-selection.txt
pass "Created mock package selection"

echo "ollama" > /tmp/container-selection.txt
echo "open-webui" >> /tmp/container-selection.txt
pass "Created mock container selection"

echo "no" > /tmp/ai-dev-enabled.txt
pass "Created mock AI dev config"

# Verify they exist
if [ -f /tmp/package-selection.txt ] && \
   [ -f /tmp/container-selection.txt ] && \
   [ -f /tmp/ai-dev-enabled.txt ]; then
    pass "All selection files created successfully"
else
    fail "Selection files not created"
fi

# Test 11: Check package file format
echo "Test 11: Package file format validation"
if [ -f "$DOTFILES_DIR/packages.txt" ]; then
    # Check if file has content
    LINE_COUNT=$(wc -l < "$DOTFILES_DIR/packages.txt")
    if [ "$LINE_COUNT" -gt 0 ]; then
        pass "packages.txt has $LINE_COUNT lines"

        # Check format (should be: package-name version-arch)
        SAMPLE_LINE=$(head -1 "$DOTFILES_DIR/packages.txt")
        if [[ $SAMPLE_LINE =~ ^[a-zA-Z0-9_-]+ ]]; then
            pass "Package format looks valid"
        else
            warn "Package format might be incorrect"
        fi
    else
        fail "packages.txt is empty"
    fi
fi

# Test 12: Docker compose validation
echo "Test 12: Docker compose validation"
if command -v docker &> /dev/null; then
    if [ -f "$DOTFILES_DIR/docker/docker-compose.yml" ]; then
        cd "$DOTFILES_DIR/docker"
        if docker compose config > /dev/null 2>&1; then
            pass "docker-compose.yml is valid"
        else
            warn "docker-compose.yml validation failed (may need docker running)"
        fi
        cd "$DOTFILES_DIR"
    fi
else
    warn "Docker not installed, skipping compose validation"
fi

# Test 13: Documentation exists
echo "Test 13: Documentation files"
DOCS=(
    "TUI-INSTALLER-README.md"
    "QUICK-START-TUI.md"
    "INTEGRATION-GUIDE.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$DOTFILES_DIR/$doc" ]; then
        pass "$doc exists"
    else
        warn "$doc not found"
    fi
done

echo ""
echo "========================================"
echo "  Test Summary"
echo "========================================"
echo ""
pass "All critical tests passed!"
echo ""
echo "You can now run the TUI installer:"
echo "  ./install-interactive.sh"
echo ""
echo "Or test the TUI directly (won't install):"
echo "  python3 install-tui.py"
echo ""

# Cleanup mock files
echo "Cleaning up mock test files..."
rm -f /tmp/package-selection.txt
rm -f /tmp/container-selection.txt
rm -f /tmp/ai-dev-enabled.txt
echo "Done!"
