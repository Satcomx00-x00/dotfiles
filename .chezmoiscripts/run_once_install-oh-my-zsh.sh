#!/bin/bash

# run_once_install-oh-my-zsh.sh
# Installs Oh My Zsh framework and Powerlevel10k theme

set -euo pipefail

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Install Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🎨 Installing Oh My Zsh..."
    export RUNZSH=no
    export CHSH=no
    export KEEP_ZSHRC=yes
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "✅ Oh My Zsh installed successfully!"
else
    echo "✅ Oh My Zsh already installed"
fi

# Install Powerlevel10k theme
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "🎨 Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    echo "✅ Powerlevel10k installed successfully!"
else
    echo "✅ Powerlevel10k already installed"
fi
