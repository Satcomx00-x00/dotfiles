#!/bin/bash

# download-binaries.sh
# Downloads latest binaries for essential tools

set -euo pipefail

BIN_DIR="$(chezmoi source-path)/home/dot_local/bin"
mkdir -p "$BIN_DIR"

echo "📥 Downloading latest binaries..."

# Function to download and extract
download_binary() {
    local repo=$1
    local asset_pattern=$2
    local binary_name=$3
    local extract_cmd=${4:-"tar -xzf"}

    echo "Downloading $binary_name from $repo..."

    # Get latest release
    local api_url="https://api.github.com/repos/$repo/releases/latest"
    local download_url=$(curl -s "$api_url" | jq -r ".assets[] | select(.name | test(\"$asset_pattern\")) | .browser_download_url" | head -1)

    if [ -z "$download_url" ]; then
        echo "❌ Could not find download URL for $binary_name"
        return 1
    fi

    local temp_dir=$(mktemp -d)
    local archive="$temp_dir/archive"

    curl -L -o "$archive" "$download_url"

    cd "$temp_dir"
    $extract_cmd "$archive"

    # Find the binary (usually in a subdirectory)
    local binary_path=$(find . -name "$binary_name" -type f -executable | head -1)
    if [ -z "$binary_path" ]; then
        echo "❌ Could not find binary $binary_name in archive"
        rm -rf "$temp_dir"
        return 1
    fi

    cp "$binary_path" "$BIN_DIR/$binary_name"
    chmod +x "$BIN_DIR/$binary_name"

    rm -rf "$temp_dir"
    echo "✅ $binary_name installed"
}

# Download binaries for x86_64-unknown-linux-gnu
ARCH="x86_64-unknown-linux-gnu"

# bat
download_binary "sharkdp/bat" "bat-.*${ARCH}\.tar\.gz" "bat" "tar -xzf"

# ripgrep
download_binary "BurntSushi/ripgrep" "ripgrep-.*${ARCH}\.tar\.gz" "rg" "tar -xzf"

# fd
download_binary "sharkdp/fd" "fd-.*${ARCH}\.tar\.gz" "fd" "tar -xzf"

# fzf
download_binary "junegunn/fzf" "fzf-.*linux_amd64\.tar\.gz" "fzf" "tar -xzf"

# eza
download_binary "eza-community/eza" "eza_${ARCH}\.tar\.gz" "eza" "tar -xzf"

# zoxide
download_binary "ajeetdsouza/zoxide" "zoxide-${ARCH}\.tar\.gz" "zoxide" "tar -xzf"

# jq (from stedolan/jq)
download_binary "stedolan/jq" "jq-linux64" "jq"

# htop (binary release)
download_binary "htop-dev/htop" "htop-.*linux.*\.tar\.gz" "htop" "tar -xzf"

# ncdu
download_binary "rofl0r/ncdu" "ncdu-.*linux.*\.tar\.gz" "ncdu" "tar -xzf"

# tree (if available, otherwise skip)
# tree is not commonly distributed as binary, skip or use package

echo "✅ All binaries downloaded successfully!"