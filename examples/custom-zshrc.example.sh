#!/bin/bash
# Example: Custom .zshrc additions
# Place this in your local chezmoi repo and reference it from dot_zshrc

# ========================================
# Custom Aliases
# ========================================

# Project shortcuts
alias proj="cd ~/projects"
alias work="cd ~/work"

# Docker shortcuts
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dclean="docker system prune -af --volumes"

# Git shortcuts
alias gst="git status -sb"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# ========================================
# Custom Functions
# ========================================

# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Find and kill process by name
fkill() {
    local pid
    pid=$(ps aux | grep -v grep | grep "$@" | awk '{print $2}')
    if [ -n "$pid" ]; then
        echo "Killing process $pid"
        kill -9 "$pid"
    else
        echo "No process found matching: $@"
    fi
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar e "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a file"
    fi
}

# Git clone and enter
gcl() {
    git clone "$1" && cd "$(basename "$1" .git)" || return
}

# Create backup of file
backup() {
    cp "$1"{,.bak-$(date +%Y%m%d-%H%M%S)}
}

# ========================================
# Custom Environment Variables
# ========================================

# Development paths
export DEV_HOME="$HOME/dev"
export PROJECTS="$HOME/projects"

# Language-specific settings
export PYTHONDONTWRITEBYTECODE=1
export NODE_ENV="development"

# Tool configurations
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# ========================================
# Conditional Configurations
# ========================================

# Work-specific settings
if [ -f "$HOME/.work_config" ]; then
    source "$HOME/.work_config"
fi

# Machine-specific settings
if [ -f "$HOME/.local_config" ]; then
    source "$HOME/.local_config"
fi

# ========================================
# Prompt Customization
# ========================================

# Add custom segments to p10k (if using)
# See .p10k.zsh for detailed customization

# ========================================
# Key Bindings
# ========================================

# Custom key bindings (zsh)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# ========================================
# Completions
# ========================================

# Add custom completion paths
fpath+=~/.zfunc

# Load custom completions
autoload -Uz compinit && compinit
