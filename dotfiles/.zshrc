
# zellij auto start on zsh shell openning
if [[ -z "$ZELLIJ" ]]; then
    if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
    else
        zellij
    fi

    if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
        exit
    fi
fi



# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Path and Environment ---
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
export PATH="/usr/bin:$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export BROWSER="firefox"
export NODE_OPTIONS="--max-old-space-size=16384 --max-semi-space-size=64 --optimize-for-size=false"


# --- Key Bindings ---
bindkey -e

# --- History ---
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY HIST_VERIFY 

# --- Zsh Options ---
setopt AUTO_CD AUTO_LIST AUTO_MENU AUTO_PARAM_SLASH EXTENDED_GLOB
setopt MENU_COMPLETE HASH_LIST_ALL COMPLETE_IN_WORD NO_BEEP

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' completer _complete _match _approximate _prefix
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath' 

# --- Utility Functions ---

# Set alias if command exists
set_alias_if_exists() {
    local cmd="$1"
    shift
    if command -v "$cmd" &> /dev/null; then
        alias "$@"
    fi
}

# Set multiple aliases for a tool if command exists
set_tool_aliases() {
    local tool="$1"
    local package="$2"
    shift 2
    if command -v "$tool" &> /dev/null; then
        for alias_def in "$@"; do
            alias "$alias_def"
        done
    fi
}

# --- Alias Setup Functions ---

# Python aliases
python_aliases() {
    alias py3='python3'
    alias pipi='pip install'
    alias pipu='pip uninstall'
    alias pipir='pip install -r requirements.txt'
    alias py='python'
    alias pipi3='pip3 install'
    alias pipu3='pip3 uninstall'
    alias pipir3='pip3 install -r requirements.txt'
}

# Docker aliases
docker_aliases() {
    set_tool_aliases docker docker \
        dk='docker' \
        dkc='docker-compose' \
        dki='docker images' \
        dkr='docker run' \
        dkl='docker logs' \
        dkp='docker ps' \
        dke='docker exec -it' \
        dkb='docker build'
}

# Distrobox aliases
distrobox_aliases() {
    set_tool_aliases distrobox distrobox \
        db='distrobox' \
        dbc='distrobox create' \
        dbe='distrobox enter' \
        dbl='distrobox list' \
        dbs='distrobox stop' \
        dbrm='distrobox rm' \
        dbu='distrobox upgrade'
}

# Git aliases
git_aliases() {
    set_tool_aliases git git \
        gs='git status' \
        ga='git add' \
        gc='git commit -m' \
        gp='git push' \
        gl='git log --oneline --graph --decorate --all' \
        gpl='git pull' \
        gco='git checkout' \
        gcm='git checkout master' \
        gcb='git checkout -b' \
        gup='git pull --rebase' \
        gcl='git clone' \
        gpf='git push --force-with-lease' \
        gbr='git branch' \
        gbrd='git branch -d' \
        gbrm='git branch -m' \
        gpr='git pull --rebase' \
        gkr='bash $HOME/.config/git-scripts/git-keep-local.sh' \
        gkrh='bash $HOME/.config/git-scripts/git-keep-local.sh -h' \
        gcr='bash $HOME/.config/git-scripts/git-conflicts-resolver.sh' \
        gcrh='bash $HOME/.config/git-scripts/git-conflicts-resolver.sh -h'
}

# Directory navigation aliases
navigation_aliases() {
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
}

# System aliases
system_aliases() {
    alias h='history'
    alias j='jobs -l'
    alias df='df -h'
    alias du='du -h'
    alias free='free -h'
    alias ps='ps aux'
    alias top='htop'
    alias mount='mount | column -t'
    alias ping='ping -c 5'
    alias wget='wget -c'
}

# Utility aliases
utility_aliases() {
    alias cleanfd='find . -type d -empty -delete'
    alias reload='exec $SHELL -l'
    alias update-zshrc='bash $HOME/.update-zshrc.sh'
}

# Enhanced tools aliases
enhanced_tools_aliases() {
    # Enhanced listing aliases
    if command -v eza &> /dev/null; then
        alias ls='eza --color=auto'
        alias ll='eza -alF --color=auto'
        alias la='eza -a --color=auto'
        alias l='eza -CF'
        alias lt='eza --tree --color=auto'
    else
        alias ll='ls -alF'
        alias la='ls -A'
        alias l='ls -CF'
    fi

    # Better cat if bat is available
    set_alias_if_exists bat cat='bat'
}

# --- Setup Aliases ---
python_aliases
docker_aliases
distrobox_aliases
git_aliases
navigation_aliases
system_aliases
utility_aliases
enhanced_tools_aliases

# Custom functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Smart tmux session management
tmux-smart() {
    if tmux list-sessions &>/dev/null; then
        echo -e "\e[36mExisting tmux sessions:\e[0m"
        tmux list-sessions
        echo
        read -p "Attach to session (or press Enter for new): " session
        if [[ -n "$session" ]]; then
            tmux attach -t "$session" 2>/dev/null || echo -e "\e[31mSession '$session' not found.\e[0m"
        else
            tmux new-session
        fi
    else
        echo -e "\e[33mNo existing sessions. Creating new session...\e[0m"
        tmux new-session
    fi
}

# Smart tmux starter function
tmux-start() {
    if [[ -n "$TMUX" ]]; then
        echo -e "\e[33mAlready inside tmux session.\e[0m"
        return 1
    fi
    
    if tmux has-session -t main 2>/dev/null; then
        echo -e "\e[36mAttaching to existing 'main' session...\e[0m"
        tmux attach -t main
    else
        echo -e "\e[36mCreating new 'main' session...\e[0m"
        tmux new-session -s main
    fi
}

extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.rar)     unrar e "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.tar)     tar xf "$1" ;;
            *.tbz2)    tar xjf "$1" ;;
            *.tgz)     tar xzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1" ;;
            *)         echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# --- Environment Variables ---
# Set default editor
export EDITOR="nano"
export VISUAL="nano"


# Development environment setup
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$HOME/.cargo/bin"
export PATH="$PATH:$HOME/.local/bin"

# Node.js version manager (nvm)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"

# Python virtual environment
export WORKON_HOME="$HOME/.virtualenvs"
export VIRTUALENVWRAPPER_PYTHON="/usr/bin/python3"
[[ -f "/usr/local/bin/virtualenvwrapper.sh" ]] && source "/usr/local/bin/virtualenvwrapper.sh"

# --- Plugin Configs ---
plugins=(
    # Essential Zsh plugins
    colored-man-pages
    command-not-found
    extract
    history
    history-substring-search

    # Docker
    docker
    docker-compose
    docker-machine

    # Kubernetes
    kubectl
    kubectx
    kube-ps1
    kops
    kind

    # Python
    python
    pip
    pipenv
    pyenv
    pylint

    # Node.js
    node
    npm
    nvm

    # Bun
    bun

    # Git
    git
    git-auto-fetch
    git-commit
    git-escape-magic
    git-extras
    git-flow
    git-flow-avh
    git-hubflow
    git-lfs
    git-prompt
    gitfast
    github
    gitignore

    # Navigation
    z
    jump
    wd
)

# --- Welcome Message ---
# echo -e "\e[35mWelcome to your purple Zsh terminal!\e[0m"

# --- Help Command ---
help-zsh() {
    # Find available zshrc to inspect
    local zshrc
    if [[ -f "$HOME/.oh-my-zsh/.zshrc" ]]; then
        zshrc="$HOME/.oh-my-zsh/.zshrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        zshrc="$HOME/.zshrc"
    else
        zshrc=""
    fi

    cat <<'EOF'
Available commands and functions:
  - reload: Reload the shell
  - update-zshrc: Update the .zshrc file
  - mkcd <dir>: Create directory and cd into it
  - tmux-smart: Interactive tmux session manager
  - tmux-start: Smart tmux starter
  - extract <file>: Extract archives
  - banner: Display system information banner
  - help: This help output
EOF

    echo
    echo "Active aliases in this shell:"
    if alias >/dev/null 2>&1; then
        # Format: alias NAME='VALUE' ->  - NAME -> VALUE
        alias | sed -E "s/^alias[[:space:]]+([^=]+)='(.*)'$/  - \1 -> \2/"
    else
        echo "  (no active aliases detected)"
    fi

    echo
    if [[ -n "$zshrc" ]]; then
        echo "Configured aliases (grouped) from: $zshrc"

        local groups=(python_aliases docker_aliases distrobox_aliases git_aliases navigation_aliases system_aliases utility_aliases enhanced_tools_aliases)
        for fn in "${groups[@]}"; do
            if grep -q -E "^${fn}\(\)" "$zshrc" 2>/dev/null; then
                # friendly heading
                local heading="${fn%_aliases}"
                heading="${heading//_/ }"
                echo
                printf "  %s aliases:\n" "$heading"

                # Extract block and show alias-like entries
                awk "/^${fn}\\(\\)/,/^}/" "$zshrc" | \
                    sed -e 's/^[[:space:]]*//' -e 's/\\\s*$//' -e '/^$/d' | \
                    grep -E "^(alias |[A-Za-z0-9_+\-]+=)" | sed 's/^/    - /' || true
            fi
        done

        echo
        echo "All alias definitions in $zshrc:"
        grep -E "^[[:space:]]*alias |^[[:space:]]*[A-Za-z0-9_+\-]+=\'" "$zshrc" 2>/dev/null | sed -e 's/^[[:space:]]*//' -e 's/^/  - /' || echo "  (none)"
    else
        echo "Configured aliases: (no zshrc file found)"
    fi

    echo
    echo "Tip: run 'alias' to list aliases active in this shell, or open the zshrc file to view all configured aliases."
}

# --- Awesome Terminal Banner ---
banner() {
    echo -e "\e[1;36m"
    echo "  _____       _                      ";
    echo " / ____|     | |                     ";
    echo "| (___   __ _| |_ ___ ___  _ __ ___  ";
    echo " \___ \ / _\` | __/ __/ _ \| '_ \` _ \ ";
    echo " ____) | (_| | || (_| (_) | | | | | |";
    echo "|_____/ \__,_|\__\___\___/|_| |_| |_|";
    echo -e "\e[0m"
    echo -e "\e[1;32mWelcome to CustomShell!\e[0m"
    echo ""
    echo -e "\e[1;33mUser:\e[0m $(whoami) | \e[1;33mHost:\e[0m $(hostname)"
    # Get distro-friendly name(s)
    local distro_info
    distro_info=$(get_distro_name)
    echo -e "\e[1;33mOS:\e[0m ${distro_info} | \e[1;33mKernel:\e[0m $(uname -s) $(uname -r) | \e[1;33mUptime:\e[0m $(uptime -p)"
    echo -e "\e[1;33mMemory:\e[0m $(free -h | awk 'NR==2{printf "%.1fG/%.1fG", $3/1024, $2/1024}')"
    echo ""
}

alias help='help-zsh'



# Helper: return friendly distro name (maps common /etc/os-release IDs)
get_distro_name() {
    # Default fallback values
    local id=""
    local version=""
    local pretty=""

    if [[ -r "/etc/os-release" ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        id=${ID:-}
        version=${VERSION_ID:-}
        pretty=${PRETTY_NAME:-}
    elif command -v lsb_release &> /dev/null; then
        id=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        version=$(lsb_release -sr)
        pretty=$(lsb_release -sd)
    fi

    # Normalize and map common IDs to friendly names
    local name=""
    case "${id}" in
        debian) name="Debian" ;;
        ubuntu) name="Ubuntu" ;;
        alpine) name="Alpine Linux" ;;
        arch) name="Arch Linux" ;;
        manjaro) name="Manjaro" ;;
        fedora) name="Fedora" ;;
        centos) name="CentOS" ;;
        rhel|redhat) name="Red Hat Enterprise Linux" ;;
        rocky) name="Rocky Linux" ;;
        ol) name="Oracle Linux" ;;
        suse|opensuse|sles) name="openSUSE/SUSE" ;;
        *) name="${pretty:-${id:-Unknown}}" ;;
    esac

    if [[ -n "${version}" ]]; then
        echo -n "${name} ${version}"
    else
        echo -n "${name}"
    fi
}

# Show banner on interactive shells only
if [[ -n "$PS1" || -n "$ZSH_NAME" || -n "$ZSH_VERSION" ]]; then
    # Avoid printing during non-interactive runs
    if [[ -t 1 ]]; then
        banner
    fi
fi

# --- Oh My Zsh Setup ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


