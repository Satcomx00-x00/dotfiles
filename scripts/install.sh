#!/bin/bash

# Install base packages, bootstrap Oh My Zsh, and copy repo dotfiles into $HOME.

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
REPO_ROOT="${SCRIPT_DIR}/.."
DOTFILES_DIR="${REPO_ROOT}/dotfiles"
HOME_DIR="$HOME"

echo "Installing required packages..."

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y zsh git curl ca-certificates
else
    echo "apt-get not found; please ensure zsh, git, and curl are installed." >&2
fi

echo "Bootstrapping Oh My Zsh..."

if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
    export RUNZSH=no
    export CHSH=no
    export KEEP_ZSHRC=yes
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh already installed; skipping."
fi

echo "Installing Powerlevel10k theme..."

if [ ! -d "$HOME_DIR/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME_DIR/.oh-my-zsh/custom/themes/powerlevel10k"
else
    echo "Powerlevel10k already installed; skipping."
fi

echo "Installing Zellij..."

if ! command -v zellij >/dev/null 2>&1; then
    # Copy Zellij binary from dotfiles
    mkdir -p "$HOME_DIR/.local/bin"
    cp "$DOTFILES_DIR/bin/zellij" "$HOME_DIR/.local/bin/zellij"
    chmod +x "$HOME_DIR/.local/bin/zellij"
    echo "Zellij installed successfully."
else
    echo "Zellij already installed; skipping."
fi

echo "Copying dotfiles into place..."

cp -f "$DOTFILES_DIR/.gitconfig" "$HOME_DIR/.gitconfig"
cp -f "$DOTFILES_DIR/.zshrc" "$HOME_DIR/.zshrc"
cp -f "$DOTFILES_DIR/.p10k.zsh" "$HOME_DIR/.p10k.zsh"
cp -r "$DOTFILES_DIR/.config" "$HOME_DIR/"

# Disable GPG signing to prevent authentication issues
git config --global commit.gpgsign false
git config --local commit.gpgsign false

echo "Setting Zsh as default shell..."
if command -v chsh >/dev/null 2>&1; then
    # Try with sudo first
    if sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null; then
        echo "Shell changed to zsh successfully."
    # Try without sudo (for environments where it's not needed)
    elif chsh -s "$(which zsh)" 2>/dev/null; then
        echo "Shell changed to zsh successfully."
    # Fallback: modify /etc/passwd directly if possible
    elif [ -w /etc/passwd ] && grep -q "^$USER:" /etc/passwd; then
        sed -i "s|^\($USER:.*\):[^:]*$|\1:$(which zsh)|" /etc/passwd
        echo "Shell changed to zsh successfully."
    else
        echo "Could not change shell to zsh automatically. Please run: chsh -s $(which zsh)"
    fi
else
    echo "chsh command not available. Please set zsh as your default shell manually."
fi

echo "Dotfiles installed successfully."