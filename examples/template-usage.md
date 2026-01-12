# Template Usage Examples

This document shows practical examples of using chezmoi templates.

## Basic Template Syntax

### Variable Substitution

```bash
# Input (dot_gitconfig.tmpl)
[user]
    name = {{ .name }}
    email = {{ .email }}

# Output (~/.gitconfig)
[user]
    name = John Doe
    email = john@example.com
```

### Quoted Values

```bash
# Use quote filter for proper escaping
name = {{ .name | quote }}
# Output: name = "John Doe"
```

### Conditional Blocks

```bash
{{- if eq .chezmoi.os "linux" }}
# Linux-specific configuration
export BROWSER="firefox"
{{- else if eq .chezmoi.os "darwin" }}
# macOS-specific configuration
export BROWSER="open"
{{- end }}
```

### Check Command Existence

```bash
{{- if lookPath "delta" }}
[core]
    pager = delta
{{- else }}
[core]
    pager = less
{{- end }}
```

## Advanced Examples

### Multi-OS Configuration

```bash
# dot_zshrc.tmpl
{{- $osPackageManager := "" -}}
{{- if eq .chezmoi.os "linux" -}}
{{-   if stat "/etc/debian_version" -}}
{{-     $osPackageManager = "apt" -}}
{{-   else if stat "/etc/redhat-release" -}}
{{-     $osPackageManager = "dnf" -}}
{{-   else if stat "/etc/arch-release" -}}
{{-     $osPackageManager = "pacman" -}}
{{-   end -}}
{{- else if eq .chezmoi.os "darwin" -}}
{{-   $osPackageManager = "brew" -}}
{{- end }}

# Package manager: {{ $osPackageManager }}

alias update='{{ $osPackageManager }} update && {{ $osPackageManager }} upgrade'
```

### Machine Type Configuration

```bash
# .chezmoi.toml.tmpl
{{- $machineType := promptStringOnce . "machineType" "Machine type (personal/work)" -}}

[data]
    machineType = {{ $machineType | quote }}

# dot_gitconfig.tmpl
[user]
    name = {{ .name | quote }}
{{- if eq .machineType "work" }}
    email = {{ .name | lower | replace " " "." }}@company.com
{{- else }}
    email = {{ .email | quote }}
{{- end }}
```

### Dynamic PATH

```bash
# dot_zshrc.tmpl
export PATH="$HOME/.local/bin:$PATH"

{{- if lookPath "go" }}
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
{{- end }}

{{- if lookPath "cargo" }}
export PATH="$HOME/.cargo/bin:$PATH"
{{- end }}

{{- if eq .chezmoi.os "darwin" }}
export PATH="/opt/homebrew/bin:$PATH"
{{- end }}
```

### Hostname-Based Configuration

```bash
# dot_ssh_config.tmpl
{{- if eq .chezmoi.hostname "work-laptop" }}
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_work
{{- end }}

Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_personal
```

### Environment-Specific Secrets

```bash
# private_dot_env.tmpl
{{- if .secrets }}
API_KEY={{ .secrets.apiKey | quote }}
DATABASE_URL={{ .secrets.databaseUrl | quote }}
{{- else }}
# Secrets not configured
API_KEY=""
DATABASE_URL=""
{{- end }}
```

## Template Functions

### String Manipulation

```bash
# Upper/Lower case
{{ .name | upper }}  # JOHN DOE
{{ .email | lower }} # john@example.com

# Replace
{{ .name | replace " " "-" }}  # John-Doe

# Trim
{{ .value | trim }}
{{ .value | trimPrefix "Mr. " }}
{{ .value | trimSuffix ".txt" }}
```

### Lists and Iteration

```bash
{{- $packages := list "git" "curl" "vim" "zsh" }}
{{- range $packages }}
- {{ . }}
{{- end }}
```

### Default Values

```bash
# Use default if variable not set
export EDITOR="{{ .editor | default "nano" }}"
```

### Include Other Templates

```bash
# header.tmpl
# This file is managed by chezmoi
# DO NOT EDIT MANUALLY

# dot_zshrc.tmpl
{{ template "header.tmpl" . }}

# Rest of configuration...
```

## Practical Use Cases

### Multi-Stage PATH Setup

```bash
# dot_zshrc.tmpl
{{- $paths := list "$HOME/.local/bin" "$HOME/bin" }}

{{- if stat "/usr/local/go/bin" }}
{{-   $paths = append $paths "/usr/local/go/bin" }}
{{- end }}

{{- if stat "$HOME/.cargo/bin" }}
{{-   $paths = append $paths "$HOME/.cargo/bin" }}
{{- end }}

{{- if eq .chezmoi.os "darwin" }}
{{-   $paths = append $paths "/opt/homebrew/bin" }}
{{-   $paths = append $paths "/opt/homebrew/sbin" }}
{{- end }}

export PATH="{{ join ":" $paths }}:$PATH"
```

### Conditional Plugin Loading

```bash
# dot_zshrc.tmpl
plugins=(
    git
    {{- if lookPath "docker" }}
    docker
    docker-compose
    {{- end }}
    {{- if lookPath "kubectl" }}
    kubectl
    {{- end }}
    {{- if eq .machineType "work" }}
    aws
    terraform
    {{- end }}
)
```

### Dynamic Aliases

```bash
# dot_zshrc.tmpl
{{- if lookPath "eza" }}
alias ls='eza --color=auto'
alias ll='eza -alF'
alias la='eza -a'
{{- else if lookPath "exa" }}
alias ls='exa --color=auto'
alias ll='exa -alF'
alias la='exa -a'
{{- else }}
alias ll='ls -alF'
alias la='ls -A'
{{- end }}
```

## Debugging Templates

### View Variables

```bash
# Show all available data
chezmoi data

# Output:
{
  "chezmoi": {
    "arch": "amd64",
    "os": "linux",
    "hostname": "myhost",
    ...
  },
  "name": "John Doe",
  "email": "john@example.com"
}
```

### Test Template Rendering

```bash
# Test a template
cat > test.tmpl <<'EOF'
Name: {{ .name }}
OS: {{ .chezmoi.os }}
{{- if lookPath "docker" }}
Docker: installed
{{- end }}
EOF

chezmoi execute-template < test.tmpl
```

### Dry Run

```bash
# See what would be generated
chezmoi apply --dry-run --verbose
```

## Best Practices

1. **Keep templates simple** - Don't overcomplicate logic
2. **Use comments** - Explain complex template code
3. **Test on multiple platforms** - Ensure cross-platform compatibility
4. **Provide defaults** - Use `default` filter for optional values
5. **Use whitespace control** - `{{-` and `-}}` to control spacing
6. **Validate before committing** - Test template rendering

## Resources

- [Chezmoi Template Documentation](https://www.chezmoi.io/user-guide/templating/)
- [Go Template Documentation](https://pkg.go.dev/text/template)
- [Sprig Functions](http://masterminds.github.io/sprig/)
