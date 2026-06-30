# Aliases & helper functions — shared partial, included from ~/.zshrc.
# Managed by chezmoi: home/.chezmoitemplates/aliases.zsh

# ---- directory navigation ----
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# ---- ls -> eza (graceful fallback to coreutils ls) ----
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -lah --git --group-directories-first --icons=auto'
    alias la='eza -a   --group-directories-first --icons=auto'
    alias l='eza -1    --group-directories-first --icons=auto'
    alias lt='eza --tree --level=2 --icons=auto'
else
    alias ls='ls --color=auto'
    alias ll='ls -lAh'
    alias la='ls -A'
    alias l='ls -CF'
fi

# ---- cat -> bat ----
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias catp='bat --paging=never --style=plain'
fi

# ---- system ----
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias ping='ping -c 5'
alias path='echo $PATH | tr ":" "\n"'
alias ports='ss -tulanp 2>/dev/null || netstat -tulanp'
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
elif command -v htop >/dev/null 2>&1; then
    alias top='htop'
fi

# ---- git (your muscle-memory set; loaded after the OMZ git plugin so these win) ----
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit -v'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gb='git branch'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull --rebase --autostash'
alias gf='git fetch --all --prune'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gst='git stash'
alias gcl='git clone'

# ---- docker ----
if command -v docker >/dev/null 2>&1; then
    alias dk='docker'
    alias dkc='docker compose'
    alias dkp='docker ps'
    alias dki='docker images'
    alias dkl='docker logs -f'
    alias dke='docker exec -it'
    alias dkb='docker build'
    alias dkprune='docker system prune -af'
fi

# ---- distrobox ----
if command -v distrobox >/dev/null 2>&1; then
    alias db='distrobox'
    alias dbe='distrobox enter'
    alias dbl='distrobox list'
    alias dbc='distrobox create'
fi

# ---- kubernetes ----
if command -v kubectl >/dev/null 2>&1; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get svc'
    alias kgn='kubectl get nodes'
    alias kaf='kubectl apply -f'
fi

# ---- python ----
alias py='python3'
alias py3='python3'
alias pipi='pip install'
alias venv='python3 -m venv .venv && source .venv/bin/activate'
alias act='source .venv/bin/activate'

# ---- lazygit ----
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

# ---- chezmoi / dotfiles ----
alias dot='chezmoi'
alias dotcd='chezmoi cd'
alias dotedit='chezmoi edit'
alias dotapply='chezmoi apply -v'
alias dotdiff='chezmoi diff'
alias dotupdate='chezmoi update -v'

# ---- misc ----
alias reload='exec ${SHELL} -l'
alias h='history'
alias j='jobs -l'

# ===================== helper functions =====================

# mkcd <dir> : create (with parents) and enter
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# killport <port> : kill whatever listens on a TCP port
killport() {
    [ -z "${1:-}" ] && { echo "usage: killport <port>"; return 1; }
    if command -v lsof >/dev/null 2>&1; then
        lsof -ti tcp:"$1" | xargs -r kill -9
    elif command -v fuser >/dev/null 2>&1; then
        fuser -k "$1"/tcp
    else
        echo "killport needs lsof or fuser"; return 1
    fi
}

# friendly distro name from /etc/os-release
get_distro_name() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        echo "${PRETTY_NAME:-${NAME:-$ID}}"
    else
        uname -s
    fi
}

# banner : one-shot system summary (auto-shown only if SHOW_BANNER is set)
banner() {
    local up mem host
    up="$(uptime -p 2>/dev/null || true)"
    mem="$(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2}')"
    host="$(hostname -s 2>/dev/null || hostname)"
    print -P "%F{045}╭─ %F{213}${USER}%f@%F{213}${host}%f"
    print -P "%F{045}├─%f OS:     $(get_distro_name)"
    print -P "%F{045}├─%f Kernel: $(uname -r)"
    [ -n "$up" ]  && print -P "%F{045}├─%f Uptime: ${up}"
    [ -n "$mem" ] && print -P "%F{045}├─%f Memory: ${mem}"
    print -P "%F{045}╰─%f Shell:  ${SHELL}"
}

# help : list custom aliases & helper functions
help() {
    print -P "%F{045}Custom aliases:%f"
    alias | sed -E 's/^([^=]+)=/  \1 -> /' | sort
    print -P "\n%F{045}Functions:%f mkcd, killport, get_distro_name, banner, extract(omz), help"
    print -P "%F{045}Dotfiles:%f dot, dotapply, dotdiff, dotupdate, dotedit, dotcd"
}
