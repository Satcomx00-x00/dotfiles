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
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ZELLIJ_ARCH="x86_64-unknown-linux-musl"
            ;;
        aarch64)
            ZELLIJ_ARCH="aarch64-unknown-linux-musl"
            ;;
        *)
            echo "Unsupported architecture: $ARCH" >&2
            exit 1
            ;;
    esac

    # Get latest release URL
    ZELLIJ_URL=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep "browser_download_url.*${ZELLIJ_ARCH}.tar.gz" | cut -d '"' -f 4)

    if [ -z "$ZELLIJ_URL" ]; then
        echo "Could not find Zellij binary for architecture $ZELLIJ_ARCH" >&2
        exit 1
    fi

    # Create local bin directory if it doesn't exist
    mkdir -p "$HOME_DIR/.local/bin"

    # Download and extract
    TEMP_DIR=$(mktemp -d)
    curl -L "$ZELLIJ_URL" -o "$TEMP_DIR/zellij.tar.gz"
    tar -xzf "$TEMP_DIR/zellij.tar.gz" -C "$TEMP_DIR"
    find "$TEMP_DIR" -name "zellij" -type f -executable -exec mv {} "$HOME_DIR/.local/bin/" \;
    rm -rf "$TEMP_DIR"

    echo "Zellij installed successfully."
else
    echo "Zellij already installed; skipping."
fi

echo "Copying dotfiles into place..."

cp -f "$DOTFILES_DIR/.gitconfig" "$HOME_DIR/.gitconfig"
cp -f "$DOTFILES_DIR/.zshrc" "$HOME_DIR/.zshrc"
cp -f "$DOTFILES_DIR/.p10k.zsh" "$HOME_DIR/.p10k.zsh"

echo "Setting Zsh as default shell..."
if command -v chsh >/dev/null 2>&1 && [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER" || echo "Could not change shell to zsh (may require password or manual setup)"
fi

echo "Dotfiles installed successfully."