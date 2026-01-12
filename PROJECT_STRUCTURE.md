# Project Structure

This document describes the complete structure of this dotfiles repository.

## Overview

```
dotfiles/
├── .github/                      # GitHub-specific files
│   ├── workflows/                # GitHub Actions CI/CD
│   │   └── test.yml             # Automated testing
│   ├── ISSUE_TEMPLATE/          # Issue templates
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── pull_request_template.md
│
├── .chezmoiscripts/             # Installation scripts
│   ├── run_once_before_install-packages.sh
│   ├── run_once_install-oh-my-zsh.sh
│   ├── run_once_install-zsh-plugins.sh
│   └── run_after_setup-shell.sh
│
├── docs/                        # Documentation
│   ├── CONFIGURATION.md         # Configuration guide
│   ├── TROUBLESHOOTING.md       # Common issues and solutions
│   └── MIGRATION.md             # Migration from old structure
│
├── examples/                    # Example configurations
│   ├── custom-zshrc.example.sh
│   └── template-usage.md
│
├── home/                        # Managed dotfiles (chezmoi source)
│   ├── dot_zshrc                # ~/.zshrc
│   ├── dot_p10k.zsh             # ~/.p10k.zsh
│   ├── dot_gitconfig.tmpl       # ~/.gitconfig (templated)
│   ├── dot_config/
│   │   └── zellij/
│   │       ├── config.kdl
│   │       └── themes/
│   │           └── custom-dark.kdl
│   └── dot_local/
│       └── bin/
│           └── executable_zellij
│
├── .chezmoi.toml.tmpl           # Chezmoi configuration template
├── .chezmoiignore               # Files to ignore
├── .chezmoiversion              # Required chezmoi version
├── .editorconfig                # Editor configuration
├── .gitignore                   # Git ignore rules
├── .pre-commit-config.yaml      # Pre-commit hooks
│
├── bootstrap.sh                 # Bootstrap installation script
├── Makefile                     # Common commands
│
├── CHANGELOG.md                 # Version history
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE                      # MIT License
├── PROJECT_STRUCTURE.md         # This file
└── README.md                    # Main documentation

## Legacy (for reference, not used by chezmoi)
├── dotfiles/                    # Old structure
└── scripts/                     # Old install scripts
```

## Directory Purposes

### `.github/`
GitHub-specific configuration including CI/CD workflows, issue templates, and PR templates.

**Key files:**
- `workflows/test.yml` - Automated testing on multiple platforms
- `ISSUE_TEMPLATE/` - Standardized issue reporting
- `pull_request_template.md` - PR checklist and guidelines

### `.chezmoiscripts/`
Automated installation scripts that run during `chezmoi apply`.

**Script types:**
- `run_once_*` - Execute only once (tracked by chezmoi)
- `run_onchange_*` - Execute when content changes
- `run_before_*` - Execute before applying dotfiles
- `run_after_*` - Execute after applying dotfiles

**Current scripts:**
- `run_once_before_install-packages.sh` - Install system packages
- `run_once_install-oh-my-zsh.sh` - Install Oh My Zsh framework
- `run_once_install-zsh-plugins.sh` - Install Zsh plugins
- `run_after_setup-shell.sh` - Final configuration steps

### `docs/`
Comprehensive documentation for users and contributors.

**Guides:**
- `CONFIGURATION.md` - How to configure and customize
- `TROUBLESHOOTING.md` - Common issues and solutions
- `MIGRATION.md` - Migrating from old setup or other managers

### `examples/`
Example configurations and usage patterns.

**Contents:**
- `custom-zshrc.example.sh` - Example custom Zsh configurations
- `template-usage.md` - Template syntax examples and patterns

### `home/`
The chezmoi source directory containing all managed dotfiles.

**Naming conventions:**
- `dot_` prefix → dotfiles (e.g., `dot_zshrc` → `~/.zshrc`)
- `executable_` prefix → executable files
- `private_` prefix → files with 0600 permissions
- `.tmpl` suffix → template files (processed by chezmoi)
- OS/hostname suffixes → conditional files (e.g., `.linux.tmpl`)

**Structure:**
```
home/
├── dot_zshrc                 # Main Zsh configuration
├── dot_p10k.zsh             # Powerlevel10k theme config
├── dot_gitconfig.tmpl       # Git config (templated for personalization)
├── dot_config/              # XDG config directory
│   └── zellij/             # Zellij configuration
└── dot_local/              # Local binaries and scripts
    └── bin/
```

## Configuration Files

### `.chezmoi.toml.tmpl`
Template for chezmoi's configuration file. On first run, prompts for:
- Name (for Git commits)
- Email
- Preferred editor
- GPG signing preference

### `.chezmoiignore`
Files and directories to ignore when applying dotfiles.

### `.chezmoiversion`
Minimum required chezmoi version (ensures compatibility).

### `.editorconfig`
Editor configuration for consistent coding styles across different editors.

### `.gitignore`
Files to ignore in version control:
- OS-specific files
- Editor configurations
- Temporary files
- Secrets

### `.pre-commit-config.yaml`
Pre-commit hooks configuration for code quality:
- Trailing whitespace removal
- YAML validation
- ShellCheck for shell scripts
- Shell script formatting

## Scripts

### `bootstrap.sh`
One-command installation script:
```bash
curl -fsSL https://raw.githubusercontent.com/Satcomx00-x00/dotfiles/main/bootstrap.sh | bash
```

Features:
- Auto-detects OS
- Installs prerequisites
- Installs chezmoi
- Initializes dotfiles

### `Makefile`
Common commands for convenience:
- `make install` - Install dotfiles
- `make update` - Update from repository
- `make test` - Test in Docker
- `make validate` - Validate templates
- `make doctor` - Run diagnostics

## Documentation Files

### `README.md`
Main project documentation:
- Quick start guide
- Features overview
- Installation instructions
- Usage examples
- Configuration guide

### `CHANGELOG.md`
Version history following [Keep a Changelog](https://keepachangelog.com/) format.

### `CONTRIBUTING.md`
Guidelines for contributors:
- Development setup
- Code style
- Testing requirements
- Pull request process

### `LICENSE`
MIT License - Open source and permissive.

### `PROJECT_STRUCTURE.md`
This file - complete repository structure documentation.

## Workflow

### Initial Installation

1. User runs `bootstrap.sh` or `chezmoi init`
2. Chezmoi clones repository to `~/.local/share/chezmoi`
3. `.chezmoi.toml.tmpl` prompts for configuration
4. Scripts in `.chezmoiscripts/` run in order
5. Files from `home/` are applied to `$HOME`

### Daily Usage

1. Edit files: `chezmoi edit ~/.zshrc`
2. Review changes: `chezmoi diff`
3. Apply changes: `chezmoi apply`
4. Commit to repository:
   ```bash
   chezmoi cd
   git add . && git commit -m "Update"
   git push
   ```

### Cross-Machine Sync

1. On Machine A: Make changes and push
2. On Machine B: `chezmoi update` (pulls and applies)

## File Transformation

Chezmoi transforms source files to target files:

```
Source (home/)              Target (~/)
─────────────────          ───────────────
dot_zshrc           →      .zshrc
dot_gitconfig.tmpl  →      .gitconfig (templated)
executable_script   →      script (chmod +x)
private_dot_file    →      .file (chmod 600)
```

## Template Processing

Templates (`.tmpl` files) are processed with data from `.chezmoi.toml`:

```toml
[data]
    name = "John Doe"
    email = "john@example.com"
```

```bash
# dot_gitconfig.tmpl
[user]
    name = {{ .name }}        # → John Doe
    email = {{ .email }}      # → john@example.com
```

## Best Practices

### Organization
- Keep related files together
- Use descriptive names
- Document complex configurations
- Maintain this structure document

### Security
- Never commit secrets in plain text
- Use chezmoi's encryption for sensitive files
- Add secrets to `.gitignore`

### Maintenance
- Update CHANGELOG.md for significant changes
- Keep documentation in sync with code
- Test changes before pushing
- Use semantic versioning for releases

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Dotfiles Best Practices](https://dotfiles.github.io/)
- [XDG Base Directory Spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)

## Questions?

For questions about this structure, see:
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [GitHub Discussions](https://github.com/Satcomx00-x00/dotfiles/discussions)
- [Issue Tracker](https://github.com/Satcomx00-x00/dotfiles/issues)
