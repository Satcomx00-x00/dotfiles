# vscode-codespaces-dotfiles

This repository contains an installer for setting up your development environment in a Codespace using custom dotfiles. It provisions the core shell configuration files, installs Oh My Zsh, and ensures the required packages are available inside the Codespace.

## Project Structure

```
vscode-codespaces-dotfiles
├── dotfiles
│   ├── .bashrc          # Bash shell configurations
│   ├── .gitconfig       # Git configurations
│   ├── .zshrc           # Zsh shell configurations and Oh My Zsh setup
│   └── .p10k.zsh        # Powerlevel10k prompt configuration
├── scripts
│   ├── install.sh       # Installation script for dotfiles
│   └── post-create.sh   # Post-creation setup script
└── README.md            # Project documentation
```

## Installation

To set up your environment with the provided dotfiles, follow these steps:

1. Clone this repository to your Codespace:
   ```
   git clone https://github.com/yourusername/vscode-codespaces-dotfiles.git
   cd vscode-codespaces-dotfiles
   ```

2. Run the installation script (installs required packages, Oh My Zsh, and copies the dotfiles):
   ```
   bash scripts/install.sh
   ```

3. (Optional) Re-run the install script from the post-create hook when your Codespace boots:
   ```
   bash scripts/post-create.sh
   ```

## Dotfiles Overview

- **.bashrc**: User-specific configurations for the Bash shell, including environment variables and aliases.
- **.gitconfig**: User-specific configurations for Git, such as user information and preferred settings.
- **.zshrc**: User-specific configurations for the Zsh shell, including Oh My Zsh initialization and aliases.
- **.p10k.zsh**: Configuration file for Powerlevel10k, a theme for Zsh.

## Oh My Zsh

During installation, the script installs the necessary packages (`zsh`, `git`, `curl`, and `ca-certificates`) using `apt-get` when available, then bootstraps [Oh My Zsh](https://ohmyz.sh/) and installs [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. Customizations from the repository's `.zshrc` and `.p10k.zsh` are applied after the installer completes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.