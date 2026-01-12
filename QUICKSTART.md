# 🎯 Quick Start Guide

Welcome to your state-of-the-art dotfiles repository! This guide will get you up and running in minutes.

## ⚡ Installation (Choose One)

### Option 1: One-Line Install (Recommended)

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Satcomx00-x00/dotfiles
```

### Option 2: Bootstrap Script

```bash
curl -fsSL https://raw.githubusercontent.com/Satcomx00-x00/dotfiles/main/bootstrap.sh | bash
```

### Option 3: Manual Installation

```bash
# Install chezmoi
curl -fsLS get.chezmoi.io | sh

# Initialize dotfiles
chezmoi init Satcomx00-x00/dotfiles

# Review what will change
chezmoi diff

# Apply dotfiles
chezmoi apply -v
```

### Option 4: Using Makefile

```bash
git clone https://github.com/Satcomx00-x00/dotfiles.git
cd dotfiles
make install
```

## 🔧 Configuration

On first run, you'll be prompted for:

```
What is your full name? John Doe
What is your email address? john@example.com
What is your preferred editor? code
Enable GPG commit signing? no
```

These values personalize your dotfiles across all configurations.

## 📚 Essential Commands

### Daily Usage

```bash
chezmoi status          # Check what's changed
chezmoi diff            # See differences
chezmoi edit ~/.zshrc   # Edit a dotfile
chezmoi apply           # Apply changes
```

### Updates

```bash
chezmoi update          # Pull latest from GitHub and apply
```

### Adding Files

```bash
chezmoi add ~/.vimrc                    # Add a file
chezmoi add --template ~/.gitconfig     # Add as template
chezmoi add --encrypt ~/.ssh/config     # Add encrypted
```

### Troubleshooting

```bash
chezmoi doctor          # Run diagnostics
chezmoi --verbose apply # Debug mode
make validate           # Validate templates
```

## 🚀 What Gets Installed

### Shell
- **Zsh** with Oh My Zsh framework
- **Powerlevel10k** beautiful prompt theme
- **Zsh plugins**: autosuggestions, syntax highlighting, completions
- Smart aliases and functions

### Tools
- **Zellij** terminal multiplexer with custom config
- **FZF** fuzzy finder
- **Eza** modern ls replacement  
- **Zoxide** smart cd
- **Bat** better cat
- **Ripgrep** fast grep
- **Delta** better git diffs (if available)

### Configurations
- Git with optimized settings
- Zsh with comprehensive aliases
- Zellij with custom theme
- Enhanced command completions

## 📁 Repository Structure

```
dotfiles/
├── .github/              # CI/CD and templates
├── .chezmoiscripts/      # Auto-run installation scripts
├── docs/                 # Comprehensive documentation
├── examples/             # Example configurations
├── home/                 # Your dotfiles (managed by chezmoi)
├── bootstrap.sh          # Bootstrap installer
├── Makefile              # Common commands
└── README.md             # Full documentation
```

## 🎨 Customization

### Edit Your Dotfiles

```bash
# Edit through chezmoi (recommended)
chezmoi edit ~/.zshrc

# Direct edit (not recommended)
vim ~/.zshrc
chezmoi add ~/.zshrc
```

### Add Custom Configurations

Create `~/.local_config` for machine-specific settings:

```bash
# Custom aliases
alias myproject="cd ~/projects/special"

# Custom environment variables
export MY_VAR="value"
```

### Change Configurations

```bash
# Edit chezmoi config
chezmoi edit-config

# Example: Change editor
[data]
    editor = "nvim"  # or "vim", "nano", etc.
```

## 🔄 Sync Across Machines

### Setup on New Machine

```bash
# One command installs everything
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply youruser/dotfiles
```

### Update from Repository

```bash
# On any machine, pull latest changes
chezmoi update
```

### Push Your Changes

```bash
# Make changes
chezmoi edit ~/.zshrc

# Commit and push
chezmoi cd
git add .
git commit -m "Add custom aliases"
git push
exit

# Changes now available on all machines
```

## 🛟 Getting Help

### Documentation

- [Full README](README.md) - Complete documentation
- [Configuration Guide](docs/CONFIGURATION.md) - Detailed customization
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues
- [Migration Guide](docs/MIGRATION.md) - From old dotfiles
- [Project Structure](PROJECT_STRUCTURE.md) - Repository layout
- [Contributing](CONTRIBUTING.md) - How to contribute

### Commands Reference

```bash
# Get help
chezmoi help
make help

# Check status
chezmoi status
chezmoi doctor

# View what would change
chezmoi diff
chezmoi apply --dry-run

# Edit files
chezmoi edit FILE
chezmoi edit-config

# Manage state
chezmoi state dump
chezmoi state reset

# Repository
chezmoi cd              # Enter source directory
chezmoi archive         # Create backup
```

### Examples

- [Custom Zsh Config](examples/custom-zshrc.example.sh)
- [Template Usage](examples/template-usage.md)

## 🎓 Next Steps

1. ✅ **Install dotfiles** (you just did this!)
2. 🎨 **Customize** your settings with `chezmoi edit`
3. 📖 **Read** the [full README](README.md)
4. 🔧 **Configure** additional tools
5. 💾 **Commit** your changes
6. 🚀 **Deploy** to other machines

## ⚙️ Advanced Usage

### Test in Docker

```bash
make test  # Test installation in containers
```

### Validate Templates

```bash
make validate  # Check all templates compile
```

### Use Makefile

```bash
make install    # Install dotfiles
make update     # Update from repository
make diff       # Show differences
make status     # Check status
make clean      # Reset state
```

## 💡 Tips

- Use `chezmoi edit` instead of direct file editing
- Run `chezmoi diff` before `chezmoi apply`
- Keep machine-specific configs in `~/.local_config`
- Use templates for values that change per machine
- Encrypt sensitive files with `--encrypt`
- Regular commits keep history clean
- Test changes on one machine before syncing

## 🌟 Features

✅ One-command installation  
✅ Auto-installs all dependencies  
✅ Template-based personalization  
✅ Multi-machine support  
✅ Encrypted secrets management  
✅ Automatic updates  
✅ Version controlled  
✅ Tested on multiple platforms  
✅ Comprehensive documentation  
✅ Active maintenance  

## 📞 Support

- 📖 [Documentation](README.md)
- 🐛 [Report Issues](https://github.com/Satcomx00-x00/dotfiles/issues)
- 💬 [Discussions](https://github.com/Satcomx00-x00/dotfiles/discussions)
- 🎯 [Chezmoi Docs](https://www.chezmoi.io/)

---

**Ready to start?** Run the installation command and enjoy your optimized development environment! 🚀
