#!/bin/bash
# Bootstrap script for dotfiles installation
# Usage: curl -fsSL https://raw.githubusercontent.com/Satcomx00-x00/dotfiles/main/bootstrap.sh | bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/Satcomx00-x00/dotfiles.git"
CHEZMOI_BIN="${HOME}/.local/bin/chezmoi"

# Helper functions
info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Install chezmoi
install_chezmoi() {
    if command_exists chezmoi; then
        success "chezmoi already installed at $(command -v chezmoi)"
        return 0
    fi

    info "Installing chezmoi..."
    
    if command_exists curl; then
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${HOME}/.local/bin"
    elif command_exists wget; then
        sh -c "$(wget -qO- get.chezmoi.io)" -- -b "${HOME}/.local/bin"
    else
        error "Neither curl nor wget found. Please install one of them."
        return 1
    fi

    success "chezmoi installed successfully"
}

# Install prerequisites
install_prerequisites() {
    local os
    os=$(detect_os)
    
    info "Detected OS: $os"

    case "$os" in
        ubuntu|debian)
            info "Installing prerequisites with apt..."
            sudo apt-get update -qq
            sudo apt-get install -y curl git
            ;;
        fedora|rhel|centos)
            info "Installing prerequisites with dnf..."
            sudo dnf install -y curl git
            ;;
        arch|manjaro)
            info "Installing prerequisites with pacman..."
            sudo pacman -Sy --noconfirm curl git
            ;;
        macos)
            if ! command_exists brew; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            info "Installing prerequisites with brew..."
            brew install curl git
            ;;
        *)
            warning "Unknown OS. Skipping prerequisite installation."
            warning "Please ensure curl and git are installed."
            ;;
    esac
}

# Main installation
main() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║   Dotfiles Bootstrap Installation     ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""

    # Check for required tools
    if ! command_exists curl && ! command_exists wget; then
        error "Neither curl nor wget found."
        info "Installing prerequisites..."
        install_prerequisites
    fi

    if ! command_exists git; then
        error "git not found."
        info "Installing prerequisites..."
        install_prerequisites
    fi

    # Install chezmoi
    install_chezmoi

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":${HOME}/.local/bin:"* ]]; then
        export PATH="${HOME}/.local/bin:$PATH"
        info "Added ~/.local/bin to PATH for this session"
        info "Add this to your shell config to make it permanent:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    # Initialize dotfiles
    info "Initializing dotfiles from $REPO_URL..."
    echo ""
    
    if [ -d "${HOME}/.local/share/chezmoi" ]; then
        warning "Dotfiles already initialized. Updating instead..."
        "${CHEZMOI_BIN}" update -v
    else
        "${CHEZMOI_BIN}" init --apply "$REPO_URL"
    fi

    echo ""
    success "✨ Dotfiles installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Review the applied changes"
    echo "  2. Setting zsh as default shell..."
    
    # Try to set zsh as default shell
    if command_exists zsh; then
        local zsh_path
        zsh_path=$(command -v zsh)
        
        # Check if zsh is in /etc/shells
        if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
            if [ -w /etc/shells ]; then
                echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
                success "Added zsh to /etc/shells"
            else
                warning "Cannot add zsh to /etc/shells (no sudo access)"
            fi
        fi
        
        # Try to change default shell
        if command_exists chsh; then
            if chsh -s "$zsh_path" 2>/dev/null; then
                success "Set zsh as default shell"
                info "You may need to log out and back in for this to take effect"
            else
                warning "Could not set zsh as default shell (may require sudo)"
                info "Your .bashrc will auto-switch to zsh instead"
            fi
        else
            warning "chsh command not available"
            info "Your .bashrc will auto-switch to zsh instead"
        fi
    else
        warning "zsh not found. Please install it first:"
        echo "  Ubuntu/Debian: sudo apt-get install zsh"
        echo "  Fedora/RHEL:   sudo dnf install zsh"
        echo "  macOS:         brew install zsh"
    fi
    
    echo ""
    echo "  3. Start a new shell or run: exec zsh"
    echo ""
    echo "Useful commands:"
    echo "  chezmoi status    - Check status"
    echo "  chezmoi diff      - See differences"
    echo "  chezmoi update    - Update from repository"
    echo "  chezmoi edit FILE - Edit a dotfile"
    echo ""
    echo "For more information, visit: https://www.chezmoi.io/"
    echo ""
}

# Run main function
main "$@"
