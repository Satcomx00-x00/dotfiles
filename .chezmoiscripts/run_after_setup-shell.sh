#!/bin/bash

# run_after_setup-shell.sh
# Final setup steps after dotfiles are applied

set -euo pipefail

echo "🐚 Finalizing shell setup..."

# Make Zsh the default shell if not already
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting Zsh as default shell..."
    if command -v chsh >/dev/null 2>&1; then
        chsh -s "$(which zsh)"
        echo "✅ Zsh set as default shell"
        echo "ℹ️  Please log out and log back in for the change to take effect"
    else
        echo "⚠️  chsh not available. Please set Zsh as default manually:"
        echo "    sudo chsh -s \$(which zsh) \$USER"
    fi
else
    echo "✅ Zsh is already the default shell"
fi

# Verify installations
echo ""
echo "🔍 Verifying installations..."

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "  ✅ $1 is installed"
    else
        echo "  ⚠️  $1 is not installed"
    fi
}

check_command zsh
check_command git
check_command fzf
check_command eza
check_command zoxide
check_command bat
check_command zellij

echo ""
echo "✨ Setup complete! Start a new shell or run 'exec zsh' to begin."
