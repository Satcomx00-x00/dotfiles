# Troubleshooting Guide

Common issues and solutions when using chezmoi dotfiles.

## Installation Issues

### Chezmoi not found

**Problem**: `chezmoi: command not found`

**Solution**:
```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Add to PATH
export PATH="$PATH:$HOME/.local/bin"

# Or install via package manager
# Debian/Ubuntu
sudo apt install chezmoi

# macOS
brew install chezmoi

# Arch Linux
sudo pacman -S chezmoi
```

### Permission denied

**Problem**: Scripts fail with permission errors

**Solution**:
```bash
# Fix script permissions
chmod +x ~/.local/share/chezmoi/.chezmoiscripts/*.sh

# Re-apply
chezmoi apply -v
```

## Template Issues

### Template syntax error

**Problem**: `parse error` when applying templates

**Solution**:
```bash
# Validate template
chezmoi execute-template < ~/.local/share/chezmoi/home/dot_file.tmpl

# Check for common issues:
# - Missing closing braces: {{ .var
# - Wrong delimiters
# - Undefined variables
```

### Variable not defined

**Problem**: `undefined variable` in template

**Solution**:
```bash
# Check available variables
chezmoi data

# Add missing variable to config
chezmoi edit-config

# Example:
[data]
    missing_var = "value"
```

### Template not rendering

**Problem**: Template content appears literally

**Solution**:

Ensure file has `.tmpl` extension:
```bash
# Wrong
dot_gitconfig

# Correct
dot_gitconfig.tmpl
```

## Git Issues

### Merge conflicts

**Problem**: Conflicts when updating from remote

**Solution**:
```bash
# Enter chezmoi directory
chezmoi cd

# Resolve conflicts manually
git status
git diff
# Edit files to resolve

# Commit resolution
git add .
git commit -m "Resolve conflicts"

# Exit and apply
exit
chezmoi apply
```

### Uncommitted changes

**Problem**: "uncommitted changes" when updating

**Solution**:
```bash
chezmoi cd
git status
git add .
git commit -m "Local changes"
git push
exit
chezmoi apply
```

## Script Issues

### Scripts not running

**Problem**: Installation scripts don't execute

**Solution**:
```bash
# Check script permissions
ls -la ~/.local/share/chezmoi/.chezmoiscripts/

# Make executable
chmod +x ~/.local/share/chezmoi/.chezmoiscripts/*.sh

# Force re-run
chezmoi state reset
chezmoi apply -v
```

### Script runs repeatedly

**Problem**: `run_once` script executes every time

**Solution**:
```bash
# Check state
chezmoi state dump

# If corrupted, reset specific script
chezmoi state delete-bucket --bucket=scriptState

# Or reset all
chezmoi state reset
```

## Diff Issues

### Delta not working

**Problem**: Delta pager not showing colored diffs

**Solution**:
```bash
# Install delta
cargo install git-delta
# or
brew install git-delta

# Configure
chezmoi edit-config

# Add:
[diff]
    pager = "delta"
```

### Can't see differences

**Problem**: `chezmoi diff` shows nothing

**Solution**:
```bash
# Verbose diff
chezmoi diff --verbose

# Check status
chezmoi status

# Apply individual file
chezmoi apply --verbose ~/.zshrc
```

## Oh My Zsh Issues

### Theme not loading

**Problem**: Powerlevel10k doesn't appear

**Solution**:
```bash
# Verify installation
ls -la ~/.oh-my-zsh/custom/themes/powerlevel10k

# Re-install
rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ~/.oh-my-zsh/custom/themes/powerlevel10k

# Check .zshrc
grep "ZSH_THEME" ~/.zshrc
# Should be: ZSH_THEME="powerlevel10k/powerlevel10k"

# Reload
exec zsh
```

### Plugins not working

**Problem**: Zsh plugins don't load

**Solution**:
```bash
# Verify plugin installation
ls -la ~/.oh-my-zsh/custom/plugins/

# Re-install missing plugins
bash ~/.local/share/chezmoi/.chezmoiscripts/run_once_install-zsh-plugins.sh

# Check plugins array in .zshrc
grep "plugins=" ~/.zshrc

# Reload
exec zsh
```

## Zellij Issues

### Binary not found

**Problem**: `zellij: command not found`

**Solution**:
```bash
# Check if binary exists
ls -la ~/.local/bin/zellij

# Make executable
chmod +x ~/.local/bin/zellij

# Add to PATH
export PATH="$PATH:$HOME/.local/bin"
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc

# Or install system-wide
cargo install zellij
# or
brew install zellij
```

### Config not loading

**Problem**: Custom Zellij theme not applied

**Solution**:
```bash
# Verify config location
ls -la ~/.config/zellij/

# Check config syntax
zellij setup --check

# Apply dotfiles
chezmoi apply -v ~/.config/zellij/
```

## Encryption Issues

### Can't decrypt files

**Problem**: age decryption fails

**Solution**:
```bash
# Verify age identity
cat ~/.config/chezmoi/key.txt

# Check config
chezmoi edit-config

# Ensure:
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."  # public key from key.txt

# Test decryption
age -d -i ~/.config/chezmoi/key.txt encrypted_file
```

### Lost encryption key

**Problem**: Lost age/GPG key

**Solution**:

If you have backups:
```bash
# Restore key
cp backup/key.txt ~/.config/chezmoi/key.txt
```

If no backup (encrypted files are lost):
```bash
# Remove encrypted files from repo
chezmoi cd
git rm encrypted_*
git commit -m "Remove encrypted files"

# Generate new key
age-keygen -o ~/.config/chezmoi/key.txt

# Re-add files
chezmoi add --encrypt ~/.ssh/config
```

## Performance Issues

### Slow apply

**Problem**: `chezmoi apply` takes too long

**Solution**:
```bash
# Apply specific files only
chezmoi apply ~/.zshrc

# Skip scripts
chezmoi apply --exclude scripts

# Use --verbose to see what's slow
chezmoi apply --verbose
```

### Large repository

**Problem**: Dotfiles repo is huge

**Solution**:
```bash
chezmoi cd

# Check size
du -sh .

# Remove large files
git rm --cached large-file
git commit -m "Remove large file"

# Clean history
git filter-branch --tree-filter 'rm -f large-file' HEAD

# Add to .chezmoiignore
echo "large-files/" >> .chezmoiignore
```

## System-Specific Issues

### WSL/Windows

**Problem**: Line ending issues

**Solution**:
```bash
# Set Git config
git config --global core.autocrlf input

# Re-clone
chezmoi init --apply youruser/dotfiles
```

### macOS

**Problem**: Command not found after install

**Solution**:
```bash
# Homebrew not in PATH
eval "$(/opt/homebrew/bin/brew shellenv)"

# Add to .zshrc
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
```

### Minimal/Container environment

**Problem**: Missing dependencies

**Solution**:
```bash
# Install minimal essentials first
apt-get update && apt-get install -y curl git

# Then run chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply youruser/dotfiles
```

## Recovery Procedures

### Complete reset

```bash
# Backup first
chezmoi archive > ~/dotfiles-backup.tar.gz

# Remove everything
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi

# Re-initialize
chezmoi init --apply youruser/dotfiles
```

### Restore from backup

```bash
# Extract archive
cd ~
tar -xzf dotfiles-backup.tar.gz

# Re-apply
chezmoi apply -v
```

### Reset only state

```bash
# Reset script state
chezmoi state reset

# Reset and re-apply
chezmoi state reset && chezmoi apply -v
```

## Debug Mode

### Enable verbose logging

```bash
# Maximum verbosity
chezmoi --verbose --debug apply

# See what would change
chezmoi apply --dry-run --verbose

# Dump all data and templates
chezmoi data
chezmoi list
chezmoi dump
```

### Check chezmoi state

```bash
# View state database
chezmoi state dump

# View specific entry
chezmoi state get --bucket=scriptState --key=script-name
```

## Getting Help

### Check documentation

```bash
# Command help
chezmoi help
chezmoi help apply
chezmoi help add

# Online docs
open https://www.chezmoi.io/
```

### Report issues

1. Gather debug info:
   ```bash
   chezmoi doctor > debug-info.txt
   chezmoi --verbose apply 2>&1 | tee apply-log.txt
   ```

2. Create issue with:
   - Debug output
   - Expected behavior
   - Actual behavior
   - OS and chezmoi version

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `template: ...:X:Y: executing ...` | Template syntax error | Check line X column Y in template |
| `inappropriate ioctl for device` | Running in non-interactive shell | Use `--force` flag or fix prompt |
| `entry not found in state` | Corrupted state | Run `chezmoi state reset` |
| `target already exists` | File exists and differs | Use `--force` or `chezmoi merge` |
| `unknown format: ...` | Chezmoi version mismatch | Update chezmoi |

## Still Having Issues?

1. Check [official troubleshooting](https://www.chezmoi.io/user-guide/troubleshooting/)
2. Search [GitHub issues](https://github.com/twpayne/chezmoi/issues)
3. Ask in [Discussions](https://github.com/twpayne/chezmoi/discussions)
4. Join [Discord community](https://discord.gg/2pBnMJP)
