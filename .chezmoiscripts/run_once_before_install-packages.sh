#!/bin/bash
# chezmoi:template:left-delimiter="# {{" right-delimiter="}}"

# run_once_before_install-packages.sh
# Installs essential packages before applying dotfiles

set -euo pipefail

echo "📦 Installing essential packages..."

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y \
        zsh \
        git \
        curl \
        wget \
        ca-certificates \
        build-essential \
        unzip \
        fzf \
        ripgrep \
        fd-find \
        bat \
        htop \
        ncdu \
        jq \
        tree
    
    # Install eza (modern ls replacement)
    if ! command -v eza >/dev/null 2>&1; then
        echo "Installing eza..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        sudo apt-get install -y eza
    fi
    
    # Install zoxide (smart cd)
    if ! command -v zoxide >/dev/null 2>&1; then
        echo "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi

    # Debian/Ubuntu ships `bat` as `batcat` in some distros. Create a user-local wrapper so `bat` works.
    if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        echo "Creating user-local wrapper for bat (batcat -> bat)"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        chmod +x "$HOME/.local/bin/bat"
    fi

elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh git curl wget ca-certificates gcc make unzip fzf ripgrep fd-find bat htop ncdu jq tree eza zoxide

elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Syu --noconfirm zsh git curl wget ca-certificates base-devel unzip fzf ripgrep fd bat htop ncdu jq tree eza zoxide

elif command -v brew >/dev/null 2>&1; then
    brew install zsh git curl wget fzf ripgrep fd bat htop ncdu jq tree eza zoxide

else
    echo "⚠️  Package manager not recognized. Please install packages manually."
    exit 1
fi

echo "✅ Essential packages installed successfully!"
