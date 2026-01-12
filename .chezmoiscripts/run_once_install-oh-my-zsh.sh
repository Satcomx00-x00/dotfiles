#!/bin/bash

# run_once_install-oh-my-zsh.sh
# Installs Oh My Zsh framework

set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✅ Oh My Zsh already installed"
    exit 0
fi

echo "🎨 Installing Oh My Zsh..."

export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "✅ Oh My Zsh installed successfully!"
