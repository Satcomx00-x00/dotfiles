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

echo "Copying dotfiles into place..."

cp -f "$DOTFILES_DIR/.bashrc" "$HOME_DIR/.bashrc"
cp -f "$DOTFILES_DIR/.gitconfig" "$HOME_DIR/.gitconfig"
cp -f "$DOTFILES_DIR/.zshrc" "$HOME_DIR/.zshrc"
cp -f "$DOTFILES_DIR/.p10k.zsh" "$HOME_DIR/.p10k.zsh"

echo "Dotfiles installed successfully."