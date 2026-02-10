# 🏠 Modern Dotfiles with Chezmoi

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A state-of-the-art dotfiles repository managed by [chezmoi](https://www.chezmoi.io/), featuring:

- 🔐 **Secrets management** with encrypted files
- 🖥️ **Multi-machine support** with templating
- 🚀 **One-command installation** with automatic bootstrapping
- 🎨 **Modern shell**: Zsh + Oh My Zsh + Powerlevel10k
- 📦 **Terminal multiplexer**: Zellij with custom config
- 🔄 **Automatic updates** and conflict resolution
- 📝 **Template-driven configuration** for personalization
- 🪝 **Pre/post installation hooks** for custom setup

## ⚡ Quick Start

### One-Line Installation

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Satcomx00-x00/dotfiles
```

**Note**: On first run, if you see template errors, run `chezmoi init` first to configure your personal data, then apply:

```bash
chezmoi init Satcomx00-x00/dotfiles
# Answer the prompts for name, email, editor, etc.
chezmoi apply -v
```

Or if you already have chezmoi installed:

```bash
chezmoi init --apply Satcomx00-x00/dotfiles
```

### Manual Installation

```bash
# 1. Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b $HOME/.local/bin

# 2. Initialize with this repository
chezmoi init Satcomx00-x00/dotfiles

# 3. Review changes before applying
chezmoi diff

# 4. Apply the dotfiles
chezmoi apply -v

# 5. Update later
chezmoi update -v
```

## 📦 What's Included

### Shell Environment
- **Zsh** with intelligent completion and history
- **Oh My Zsh** framework with curated plugins
- **Powerlevel10k** theme with rich prompt customization
- **FZF** fuzzy finder integration
- **Zoxide** smart directory jumping
- **Eza** modern replacement for ls

### Terminal
- **Zellij** terminal multiplexer with custom theme
- Sensible keybindings and layouts
- Custom dark theme optimized for productivity

### Development Tools
- **Git** with powerful aliases and smart defaults
- **Docker** aliases and shortcuts
- **Python** development helpers
- Language-specific configurations

### Configurations
- `.zshrc` - Comprehensive shell configuration
- `.gitconfig.tmpl` - Templated Git configuration
- `.p10k.zsh` - Powerlevel10k theme settings
- `zellij/` - Terminal multiplexer configuration
- Custom scripts and utilities

## 🎯 Features

### Template-Based Configuration

Chezmoi uses Go templates to personalize your dotfiles:

```bash
# On first init, you'll be prompted for:
- Git name
- Git email
- Preferred editor
- Machine type (personal/work)
```

These values are stored in `~/.config/chezmoi/chezmoi.toml` and used across all template files.

### Secrets Management

Encrypted files using age or gpg:

```bash
# Edit encrypted files
chezmoi edit --watch ~/.ssh/config

# Add encrypted file
chezmoi add --encrypt ~/.ssh/private_key
```

### Multi-Machine Support

Different configurations for different machines:

```bash
# Machine-specific files
.chezmoi.os.linux.yaml    # Linux-only
.chezmoi.os.darwin.yaml   # macOS-only
.chezmoi.hostname.work.yaml  # Work machine

# Template conditions
{{- if eq .chezmoi.os "linux" }}
# Linux-specific content
{{- end }}
```

## 📖 Usage

### Daily Commands

```bash
# Check status
chezmoi status

# See changes
chezmoi diff

# Apply changes
chezmoi apply

# Edit a file
chezmoi edit ~/.zshrc

# Update from repository
chezmoi update

# Add new file
chezmoi add ~/.config/newfile

# Re-run scripts
chezmoi state reset && chezmoi apply
```

### Advanced Usage

```bash
# Archive your current dotfiles
chezmoi archive > dotfiles.tar.gz

# Import from existing dotfiles
chezmoi import --strip-components 1 https://github.com/user/dotfiles/archive/master.tar.gz

# Execute a template
chezmoi execute-template '{{ .chezmoi.os }}/{{ .chezmoi.arch }}'

# Manage on multiple machines
chezmoi init --apply  # On new machine
chezmoi update        # Pull latest changes
```

## 🛠️ Customization

### 1. Configure Your Data

Edit `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    name = "Your Name"
    email = "your.email@example.com"
    editor = "code"
    
[data.machine]
    type = "personal"  # or "work"
    
[diff]
    pager = "delta"
```

### 2. Add Your Own Dotfiles

```bash
# Add a file
chezmoi add ~/.vimrc

# Add a directory
chezmoi add --recursive ~/.config/nvim

# Add as template (for personalization)
chezmoi add --template ~/.gitconfig
```

### 3. Create Scripts

Scripts in `.chezmoiscripts` run automatically:

- `run_once_*.sh` - Run only once
- `run_onchange_*.sh` - Run when content changes
- `run_before_*.sh` - Run before applying
- `run_after_*.sh` - Run after applying

## 🔧 Maintenance

### Update Your Dotfiles

```bash
# Make changes
chezmoi edit ~/.zshrc

# Review changes
chezmoi diff

# Apply changes
chezmoi apply

# Commit to repository
chezmoi cd
git add .
git commit -m "Update zshrc"
git push
```

### Sync Across Machines

```bash
# On machine A (after making changes)
chezmoi cd
git add . && git commit -m "Update" && git push

# On machine B
chezmoi update  # Pulls and applies changes
```

## 🐳 Development Container

A Containerfile is provided for development and testing with **all tools pre-installed**. This container includes the complete shell environment with all packages, plugins, and configurations ready to use.

### Build the Container

```bash
make container-build
# Or manually:
docker build -f Containerfile -t dotfiles-dev:latest .
```

### Run the Container

```bash
make container-shell
# Or manually:
docker run --rm -it dotfiles-dev:latest /bin/zsh
```

### What's Included

The container has everything from the chezmoi scripts pre-installed:

**Shell & Tools:**
- Ubuntu 22.04 base image
- Zsh with Oh My Zsh framework
- Powerlevel10k theme
- All essential packages (git, curl, wget, build-essential, etc.)

**Modern CLI Tools:**
- k9s (Kubernetes CLI) v0.32.4
- fzf (fuzzy finder)
- ripgrep, fd-find
- bat (cat alternative)
- eza (ls alternative)
- zoxide (smart cd)
- htop, ncdu, jq, tree

**Zsh Plugins:**
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- fzf-tab

**Note:** Unlike local installation where chezmoi scripts run during `apply`, the container has all tools pre-installed at build time for faster startup and testing.
- All dotfiles from this repository

The container is perfect for:
- Testing dotfiles changes in a clean environment
- Kubernetes cluster management with k9s
- Development without polluting your local system

## 📚 Project Structure

```
.
├── .chezmoiignore              # Files to ignore
├── .chezmoiremove              # Files to remove
├── .chezmoiversion             # Required chezmoi version
├── .chezmoi.toml.tmpl          # Chezmoi configuration template
│
├── home/                       # Managed by chezmoi
│   ├── dot_zshrc.tmpl         # ~/.zshrc (templated)
│   ├── dot_gitconfig.tmpl     # ~/.gitconfig (templated)
│   ├── dot_p10k.zsh           # ~/.p10k.zsh
│   ├── dot_config/
│   │   └── zellij/
│   │       ├── config.kdl
│   │       └── themes/
│   └── dot_local/
│       └── bin/
│           └── executable_zellij
│
├── .chezmoiscripts/           # Installation scripts
│   ├── run_once_before_install-packages.sh
│   ├── run_once_install-oh-my-zsh.sh
│   ├── run_once_install-zsh-plugins.sh
│   └── run_after_setup-shell.sh
│
├── docs/                      # Documentation
│   ├── CONFIGURATION.md
│   ├── TROUBLESHOOTING.md
│   └── MIGRATION.md
│
└── README.md                  # This file
```

## 🐛 Troubleshooting

### Reset Everything

```bash
chezmoi state reset
chezmoi apply -v
```

### Dry Run

```bash
chezmoi apply --dry-run --verbose
```

### Debug Mode

```bash
chezmoi --verbose apply
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test on a clean environment
4. Submit a pull request

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 🔗 Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Chezmoi How-To Guide](https://www.chezmoi.io/user-guide/command-overview/)
- [Template Documentation](https://www.chezmoi.io/user-guide/templating/)
- [My Blog Post on Dotfiles](https://github.com/Satcomx00-x00/dotfiles/wiki)

## ⭐ Inspiration

This dotfiles setup is inspired by best practices from:
- [chezmoi.io](https://www.chezmoi.io/)
- [Dotfiles community](https://dotfiles.github.io/)
- Various GitHub dotfiles repositories
- **.gitconfig**: User-specific configurations for Git, such as user information and preferred settings. **Note**: Update the user name and email placeholders with your actual details.
- **.zshrc**: User-specific configurations for the Zsh shell, including Oh My Zsh initialization and aliases.
- **.p10k.zsh**: Configuration file for Powerlevel10k, a theme for Zsh.

## Oh My Zsh

During installation, the script installs the necessary packages (`zsh`, `git`, `curl`, and `ca-certificates`) using `apt-get` when available, then bootstraps [Oh My Zsh](https://ohmyz.sh/) and installs [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. Additionally, [Zellij](https://zellij.dev/), a terminal workspace manager, is copied from the included binary with custom configuration and themes. Customizations from the repository's `.zshrc`, `.p10k.zsh`, and Zellij config files are applied after the installer completes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.