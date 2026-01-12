# Contributing to Dotfiles

Thank you for your interest in contributing! This document provides guidelines for contributing to this dotfiles repository.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/dotfiles.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Testing Your Changes

### Local Testing

```bash
# Test in a container
docker run -it --rm ubuntu:latest bash -c "
  apt-get update && apt-get install -y curl git &&
  curl -fsLS get.chezmoi.io | sh &&
  /root/.local/bin/chezmoi init --apply https://github.com/yourusername/dotfiles.git
"

# Or use dry-run
chezmoi init --dry-run --verbose youruser/dotfiles
```

### Validate Templates

```bash
# Check template syntax
chezmoi execute-template < home/dot_file.tmpl

# Verify all templates compile
find home -name "*.tmpl" -exec chezmoi execute-template < {} \;
```

### Test Scripts

```bash
# Make scripts executable
chmod +x .chezmoiscripts/*.sh

# Test individual scripts
bash -n .chezmoiscripts/script-name.sh  # Syntax check
bash -x .chezmoiscripts/script-name.sh  # Debug mode
```

## Guidelines

### Code Style

#### Shell Scripts

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use double brackets `[[ ]]` for tests
- Quote variables: `"$variable"`
- Use meaningful function names
- Add comments for complex logic

Example:
```bash
#!/bin/bash
set -euo pipefail

# Function to install packages
install_packages() {
    local packages=("$@")
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y "${packages[@]}"
    fi
}
```

#### Templates

- Use descriptive variable names
- Add comments explaining template logic
- Keep templates simple and readable
- Use helper functions when possible

Example:
```bash
# {{ template "header.tmpl" . }}
{{- /* Set editor based on OS */ -}}
{{- $editor := "nano" -}}
{{- if eq .chezmoi.os "darwin" -}}
{{-   $editor = "vim" -}}
{{- end }}

export EDITOR="{{ $editor }}"
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Formatting, missing semicolons, etc.
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance tasks

Examples:
```
feat: add support for fish shell
fix: correct Zellij config path
docs: update installation instructions
chore: update dependencies
```

### Pull Request Process

1. **Update Documentation**: Update README.md if you add new features
2. **Test Thoroughly**: Ensure changes work on clean installations
3. **Keep PRs Focused**: One feature/fix per PR
4. **Describe Changes**: Explain what and why in PR description
5. **Link Issues**: Reference related issues with `Fixes #123`

### What to Contribute

#### Welcome Contributions

- Bug fixes
- Documentation improvements
- New shell configurations (fish, nushell, etc.)
- Additional tool configurations
- Cross-platform compatibility
- Performance improvements
- Security enhancements

#### Examples of Good Contributions

- Add support for new OS/distro
- Improve installation scripts
- Add useful aliases or functions
- Better error handling
- Template enhancements
- Comprehensive examples

## Structure Guidelines

### Adding New Dotfiles

```bash
# Add a file
chezmoi add ~/.config/newapp/config.yml

# Add as template if it needs personalization
chezmoi add --template ~/.gitconfig

# Add as encrypted for secrets
chezmoi add --encrypt ~/.ssh/config

# Add entire directory
chezmoi add --recursive ~/.config/nvim/
```

### Creating Scripts

Place in `.chezmoiscripts/` with appropriate prefix:

- `run_once_` - Run only once
- `run_onchange_` - Run when content changes
- `run_before_` - Run before applying dotfiles
- `run_after_` - Run after applying dotfiles

### File Naming Conventions

- `dot_` prefix for dotfiles (e.g., `dot_zshrc` → `~/.zshrc`)
- `executable_` prefix for executables
- `private_` prefix for 0600 permissions
- `.tmpl` suffix for templates
- OS/hostname suffixes for conditional files

Examples:
```
home/
  dot_zshrc.tmpl                    # ~/.zshrc (templated)
  dot_gitconfig.linux.tmpl          # Linux only
  executable_myscript.sh            # Executable script
  private_dot_ssh_config.tmpl       # 600 permissions
```

## Reporting Issues

### Before Reporting

1. Check existing issues
2. Search documentation
3. Test on clean environment
4. Gather debug information

### Issue Template

```markdown
**Description**
Clear description of the issue

**Steps to Reproduce**
1. Step one
2. Step two
3. ...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: [e.g., Ubuntu 22.04]
- Chezmoi version: [e.g., 2.40.0]
- Shell: [e.g., zsh 5.8]

**Debug Information**
```bash
chezmoi doctor
```
Output here...
```
```

## Community

- Be respectful and inclusive
- Help others learn
- Share knowledge
- Give constructive feedback
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md)

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Dotfiles Best Practices](https://dotfiles.github.io/)

## Questions?

Open a [discussion](https://github.com/Satcomx00-x00/dotfiles/discussions) or issue if you have questions!

Thank you for contributing! 🎉
