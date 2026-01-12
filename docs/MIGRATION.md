# Migration Guide

How to migrate from the old dotfiles structure to chezmoi-managed dotfiles.

## Overview

This repository has been migrated from a simple script-based approach to **chezmoi**, a modern dotfile manager with:

- Template-based configuration
- Multi-machine support
- Secrets management
- Automated installation scripts
- Version control integration

## Migrating Your Existing Setup

### If you were using the old structure

The old structure used `scripts/install.sh` to copy files from `dotfiles/` to `$HOME`.

**Old way**:
```bash
git clone https://github.com/youruser/dotfiles
cd dotfiles
bash scripts/install.sh
```

**New way**:
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply youruser/dotfiles
```

### Step-by-Step Migration

#### 1. Backup Current Dotfiles

```bash
# Create backup
tar -czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz \
    ~/.zshrc \
    ~/.gitconfig \
    ~/.p10k.zsh \
    ~/.config/zellij/

# Or use chezmoi's archive
cd /path/to/old/dotfiles
tar -czf ~/old-dotfiles-backup.tar.gz .
```

#### 2. Save Your Customizations

```bash
# Extract your custom config
diff ~/.zshrc /path/to/dotfiles/dotfiles/.zshrc > ~/my-zshrc-customizations.diff
diff ~/.gitconfig /path/to/dotfiles/dotfiles/.gitconfig > ~/my-gitconfig-customizations.diff
```

#### 3. Clean Installation

Remove old installations:

```bash
# Optional: remove old structure
rm -rf ~/old-dotfiles-repo

# Keep .oh-my-zsh and plugins (chezmoi will manage them)
# Keep ~/.config/zellij (chezmoi will manage it)
```

#### 4. Install with Chezmoi

```bash
# One-command installation
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Satcomx00-x00/dotfiles

# During initialization, you'll be prompted for:
# - Your name (for Git commits)
# - Your email
# - Your preferred editor
# - GPG signing preference
```

#### 5. Restore Customizations

```bash
# Edit files via chezmoi
chezmoi edit ~/.zshrc

# Add your customizations from the diff
# Save and apply
chezmoi apply -v
```

#### 6. Commit Your Changes

```bash
# Enter chezmoi source directory
chezmoi cd

# Review changes
git status
git diff

# Commit
git add .
git commit -m "Add personal customizations"
git push

# Exit
exit
```

## Migrating From Other Dotfile Managers

### From GNU Stow

**Old**:
```bash
cd ~/dotfiles
stow zsh
stow git
```

**New with chezmoi**:
```bash
# Import existing dotfiles
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig

# Apply
chezmoi apply
```

### From yadm

**Old**:
```bash
yadm clone https://github.com/user/dotfiles
yadm pull
```

**New**:
```bash
# Initialize chezmoi with repo
chezmoi init --apply user/dotfiles

# Update later
chezmoi update
```

### From bare git repository

**Old**:
```bash
git clone --bare https://github.com/user/dotfiles $HOME/.dotfiles
git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME checkout
```

**New**:
```bash
# Chezmoi handles git internally
chezmoi init --apply user/dotfiles
```

## Importing Existing Files

### Add individual files

```bash
# Add a file to chezmoi
chezmoi add ~/.vimrc

# Add with template support
chezmoi add --template ~/.gitconfig

# Add as executable
chezmoi add --template ~/.local/bin/myscript
# chezmoi automatically detects executable bit

# Add as encrypted
chezmoi add --encrypt ~/.ssh/config
```

### Bulk import

```bash
# Add multiple files
chezmoi add ~/.zshrc ~/.bashrc ~/.vimrc

# Add entire directory
chezmoi add --recursive ~/.config/nvim/
```

### Import from archive

```bash
# Import from tarball
chezmoi import --strip-components 1 \
    https://github.com/user/old-dotfiles/archive/master.tar.gz
```

## Converting to Templates

### Why use templates?

Templates allow personalization across machines without maintaining separate files.

### Convert static to template

**Before** (static `~/.gitconfig`):
```ini
[user]
    name = John Doe
    email = john@example.com
```

**After** (`dot_gitconfig.tmpl`):
```ini
[user]
    name = {{ .name | quote }}
    email = {{ .email | quote }}
```

### Add template to chezmoi

```bash
# Add as template
chezmoi add --template ~/.gitconfig

# Edit template
chezmoi edit ~/.gitconfig

# Apply
chezmoi apply
```

## Machine-Specific Configurations

### Separate work and personal

**Create machine-specific variables**:

Edit `~/.config/chezmoi/chezmoi.toml`:

```toml
[data]
    name = "Your Name"
    email = "personal@email.com"

[data.machine]
    type = "personal"  # or "work"
```

**Use in templates**:

```bash
{{- if eq .machine.type "work" }}
export WORK_PROXY="proxy.company.com"
{{- end }}
```

### OS-specific files

Create OS-specific versions:

```
home/
  dot_zshrc.tmpl           # All systems
  dot_zshrc.linux.tmpl     # Linux only
  dot_zshrc.darwin.tmpl    # macOS only
```

## Migrating Scripts

### Old script approach

```bash
# scripts/install.sh
#!/bin/bash
cp dotfiles/.zshrc ~/.zshrc
cp dotfiles/.gitconfig ~/.gitconfig
```

### New chezmoi approach

Scripts in `.chezmoiscripts/` run automatically:

```bash
.chezmoiscripts/
  run_once_before_install-packages.sh
  run_once_install-oh-my-zsh.sh
  run_after_setup-shell.sh
```

**Converting a script**:

Old `scripts/install-zsh.sh`:
```bash
#!/bin/bash
apt-get install zsh
```

New `.chezmoiscripts/run_once_install-zsh.sh`:
```bash
#!/bin/bash
if ! command -v zsh &>/dev/null; then
    sudo apt-get install -y zsh
fi
```

## Secrets Migration

### Plain text secrets (insecure)

**Old**:
```bash
# .zshrc
export API_KEY="secret123"
```

**New (encrypted)**:
```bash
# Install age
sudo apt install age

# Generate key
age-keygen -o ~/.config/chezmoi/key.txt

# Configure chezmoi
chezmoi edit-config

# Add:
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."

# Add encrypted file
chezmoi add --encrypt ~/.config/secrets.env

# Edit encrypted
chezmoi edit ~/.config/secrets.env
```

## Sync Across Machines

### Old approach

```bash
# Machine 1
cd ~/dotfiles
git add .
git commit -m "Update"
git push

# Machine 2
cd ~/dotfiles
git pull
./install.sh
```

### New with chezmoi

```bash
# Machine 1
chezmoi edit ~/.zshrc
# Make changes, save
chezmoi cd
git add . && git commit -m "Update" && git push
exit

# Machine 2
chezmoi update  # Pulls and applies automatically
```

## Testing Migration

### Dry run

```bash
# See what would change without applying
chezmoi init --dry-run --verbose youruser/dotfiles

# Or after init
chezmoi diff
chezmoi apply --dry-run --verbose
```

### Test in container

```bash
# Docker test
docker run -it ubuntu:latest bash

# Inside container
apt-get update && apt-get install -y curl git
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply youruser/dotfiles

# Verify
zsh --version
git --version
```

## Common Migration Issues

### Issue: Existing files conflict

**Error**: Target file already exists

**Solution**:
```bash
# Merge interactively
chezmoi merge ~/.zshrc

# Or force overwrite
chezmoi apply --force
```

### Issue: Lost customizations

**Problem**: Applied default config, lost changes

**Solution**:
```bash
# Restore from backup
cp ~/dotfiles-backup/zshrc ~/.zshrc

# Add to chezmoi
chezmoi add ~/.zshrc

# Commit
chezmoi cd
git add . && git commit -m "Restore customizations"
```

### Issue: Scripts don't run

**Problem**: Installation incomplete

**Solution**:
```bash
# Force re-run
chezmoi state reset
chezmoi apply -v
```

## Rollback Plan

If migration fails:

```bash
# Remove chezmoi
rm -rf ~/.local/share/chezmoi
rm -rf ~/.config/chezmoi

# Restore backup
cd ~
tar -xzf dotfiles-backup-YYYYMMDD.tar.gz

# Or use old install script
cd ~/old-dotfiles
bash scripts/install.sh
```

## Post-Migration Checklist

- [ ] Verify all dotfiles applied correctly
- [ ] Test shell functionality (aliases, functions)
- [ ] Verify Oh My Zsh and plugins loaded
- [ ] Test Zellij configuration
- [ ] Confirm Git config (name, email)
- [ ] Check editor preferences
- [ ] Test custom scripts
- [ ] Verify secrets (if encrypted)
- [ ] Commit any customizations
- [ ] Update documentation
- [ ] Remove old dotfiles repo (after confirmation)

## Benefits After Migration

✅ One-command installation on new machines  
✅ Automatic dependency installation  
✅ Template-based personalization  
✅ Secrets management with encryption  
✅ Multi-machine support  
✅ Version control integration  
✅ Easy updates across machines  
✅ Dry-run and diff support  
✅ Extensible with scripts  
✅ Active community and documentation  

## Resources

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Migration Guide](https://www.chezmoi.io/user-guide/setup/#using-chezmoi-across-multiple-machines)
- [Template Guide](https://www.chezmoi.io/user-guide/templating/)
- [Configuration Guide](CONFIGURATION.md)
- [Troubleshooting](TROUBLESHOOTING.md)

## Need Help?

If you encounter issues during migration:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Review [chezmoi FAQ](https://www.chezmoi.io/user-guide/frequently-asked-questions/)
3. Open an issue on this repository
4. Ask in [chezmoi discussions](https://github.com/twpayne/chezmoi/discussions)
