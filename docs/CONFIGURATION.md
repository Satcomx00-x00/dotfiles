# Configuration Guide

This document explains how to configure your dotfiles managed by chezmoi.

## Initial Configuration

On first run, chezmoi will prompt you for:

- **Name**: Your full name (for Git commits)
- **Email**: Your email address (for Git commits)
- **Editor**: Your preferred editor (code, vim, nano, etc.)
- **GPG Signing**: Whether to enable GPG commit signing

These values are stored in `~/.config/chezmoi/chezmoi.toml`.

## Editing Configuration

### Edit the configuration file

```bash
chezmoi edit-config
```

This opens `~/.config/chezmoi/chezmoi.toml` where you can modify:

```toml
[data]
    name = "Your Name"
    email = "your@email.com"
    editor = "code"
    gpgSign = false

[data.machine]
    type = "personal"  # or "work"

[diff]
    pager = "delta"
```

### Re-apply after changes

```bash
chezmoi apply -v
```

## Template Variables

Template files (`.tmpl` extension) use Go template syntax to personalize content.

### Available Variables

- `.name` - Your full name
- `.email` - Your email
- `.editor` - Your editor
- `.gpgSign` - GPG signing enabled
- `.chezmoi.os` - OS name (linux, darwin, windows)
- `.chezmoi.arch` - Architecture (amd64, arm64)
- `.chezmoi.hostname` - Machine hostname
- `.chezmoi.username` - Current username
- `.chezmoi.homeDir` - Home directory path

### Template Syntax Examples

#### Conditional content

```bash
{{- if eq .chezmoi.os "linux" }}
# Linux-specific config
export BROWSER="firefox"
{{- else if eq .chezmoi.os "darwin" }}
# macOS-specific config
export BROWSER="open"
{{- end }}
```

#### Check if command exists

```bash
{{- if lookPath "delta" }}
[core]
    pager = delta
{{- end }}
```

#### Machine-specific config

```bash
{{- if eq .machine.type "work" }}
# Work machine settings
{{- else }}
# Personal machine settings
{{- end }}
```

## Machine-Specific Configuration

### Create machine-specific files

Files can be suffixed with machine attributes:

```
dot_zshrc.tmpl              # All machines
dot_zshrc.linux.tmpl        # Linux only
dot_zshrc.darwin.tmpl       # macOS only
dot_gitconfig.work.tmpl     # Work machine only
```

### Set machine type

Edit `~/.config/chezmoi/chezmoi.toml`:

```toml
[data.machine]
    type = "work"  # or "personal"
```

## Secrets Management

### Encrypting files

```bash
# Add encrypted file
chezmoi add --encrypt ~/.ssh/config

# Edit encrypted file
chezmoi edit --watch ~/.ssh/private_key
```

### Using age encryption

1. Install age:
   ```bash
   # Ubuntu/Debian
   sudo apt install age
   
   # macOS
   brew install age
   ```

2. Generate a key:
   ```bash
   age-keygen -o ~/.config/chezmoi/key.txt
   ```

3. Configure chezmoi:
   ```bash
   chezmoi edit-config
   ```
   
   Add:
   ```toml
   encryption = "age"
   [age]
       identity = "~/.config/chezmoi/key.txt"
       recipient = "age1..." # from key.txt
   ```

### Using GPG encryption

```toml
encryption = "gpg"
[gpg]
    recipient = "your@email.com"
```

## Custom Scripts

Scripts in `.chezmoiscripts/` run automatically at different stages.

### Script naming conventions

- `run_once_*.sh` - Run only once (tracked by chezmoi)
- `run_onchange_*.sh` - Run when script content changes
- `run_before_*.sh` - Run before applying dotfiles
- `run_after_*.sh` - Run after applying dotfiles

### Script order

1. `run_once_before_*.sh`
2. `run_before_*.sh`
3. Dotfiles are applied
4. `run_after_*.sh`
5. `run_once_after_*.sh`

### Re-run scripts

```bash
# Reset state and re-run all scripts
chezmoi state reset
chezmoi apply -v

# Re-run only changed scripts
chezmoi apply -v
```

## Environment Variables

Set environment variables in templates:

```toml
[data]
    github_token = "ghp_..."
    api_key = "secret"
```

Access in templates:

```bash
export GITHUB_TOKEN="{{ .github_token }}"
```

## Custom Functions

Create helper functions in `.chezmoi.toml.tmpl`:

```toml
[data]
    [data.functions]
        hello = "echo Hello"
```

## Advanced Configuration

### Ignore files

Edit `.chezmoiignore`:

```
README.md
*.bak
.vscode/
```

### Remove files

List files to remove in `.chezmoiremove`:

```
~/.old-config
~/.deprecated-file
```

### Modify attributes

Use special prefixes:

- `executable_` - Make file executable
- `private_` - Set permissions to 0600
- `readonly_` - Make file read-only
- `symlink_` - Create symlink
- `encrypted_` - Encrypt file

Example:
```
home/
  executable_script.sh       # chmod +x
  private_dot_ssh_config     # chmod 600
```

## Troubleshooting Configuration

### View resolved templates

```bash
chezmoi execute-template < template.tmpl
```

### Dump all data

```bash
chezmoi data
```

### Dry run

```bash
chezmoi apply --dry-run --verbose
```

### Debug mode

```bash
chezmoi --verbose apply
```

## Examples

### Conditional package installation

`.chezmoiscripts/run_once_install-packages.sh.tmpl`:

```bash
#!/bin/bash
{{- if eq .chezmoi.os "linux" }}
sudo apt-get install package-name
{{- else if eq .chezmoi.os "darwin" }}
brew install package-name
{{- end }}
```

### Dynamic gitconfig

`dot_gitconfig.tmpl`:

```toml
[user]
    name = {{ .name | quote }}
    email = {{ .email | quote }}

{{- if eq .machine.type "work" }}
[user]
    signingkey = {{ .work.signingkey }}
{{- end }}
```

## Further Reading

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Template Documentation](https://www.chezmoi.io/user-guide/templating/)
- [How-To Guide](https://www.chezmoi.io/user-guide/command-overview/)
