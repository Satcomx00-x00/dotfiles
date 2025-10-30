# Dotfiles

This repository contains dotfiles and an installer for setting up a development environment with Zsh, Oh My Zsh, Powerlevel10k, and Zellij. It provisions the core shell configuration files and ensures the required packages are available.

## Project Structure

```
dotfiles
├── dotfiles/
│   ├── .config/
│   │   └── zellij/
│   │       ├── config.kdl          # Zellij configuration
│   │       └── themes/
│   │           └── custom-dark.kdl # Custom Zellij theme
│   ├── bin/
│   │   └── zellij                 # Zellij binary executable
│   ├── .gitconfig       # Git configurations
│   ├── .zshrc           # Zsh shell configurations and Oh My Zsh setup
│   └── .p10k.zsh        # Powerlevel10k prompt configuration
├── scripts/
│   └── install.sh       # Installation script for dotfiles
└── README.md            # Project documentation
```

## Installation

To set up your environment with the provided dotfiles, follow these steps:

1. Clone this repository to your Codespace:
   ```
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

2. Run the installation script (installs required packages, Oh My Zsh, sets Zsh as default shell, and copies the dotfiles):
   ```
   bash scripts/install.sh
   ```

3. Configure Git (optional but recommended):
   ```
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

## Dotfiles Overview

- **bin/zellij**: Zellij terminal multiplexer binary (x86_64)
- **.config/zellij/config.kdl**: Zellij terminal multiplexer configuration with custom keybindings and layout
- **.config/zellij/themes/custom-dark.kdl**: Custom dark theme for Zellij
- **.gitconfig**: User-specific configurations for Git, such as user information and preferred settings. **Note**: Update the user name and email placeholders with your actual details.
- **.zshrc**: User-specific configurations for the Zsh shell, including Oh My Zsh initialization and aliases.
- **.p10k.zsh**: Configuration file for Powerlevel10k, a theme for Zsh.

## Oh My Zsh

During installation, the script installs the necessary packages (`zsh`, `git`, `curl`, and `ca-certificates`) using `apt-get` when available, then bootstraps [Oh My Zsh](https://ohmyz.sh/) and installs [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. Additionally, [Zellij](https://zellij.dev/), a terminal workspace manager, is copied from the included binary with custom configuration and themes. Customizations from the repository's `.zshrc`, `.p10k.zsh`, and Zellij config files are applied after the installer completes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.