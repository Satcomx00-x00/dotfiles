# shellcheck shell=sh
# portable.sh — a single-file shell profile for a machine you will never see again.
#
#   curl -fsSL <raw-url>/portable.sh > /tmp/p.sh && . /tmp/p.sh
#
# GENERATED — do not edit. Change ~/.config/shell/* in the dotfiles source and
# run `make portable`. CI fails if this file is out of date.
#
# What you get: the aliases, functions, history settings and emacs keybindings
# from the real configuration, plus a prompt that needs nothing installed.
# What it does NOT do: install anything, write anything to disk, require root,
# or need chezmoi. Sourcing it affects exactly one shell.

# ─── env.sh ───────────────────────────────────────────────────────
# shellcheck shell=sh
# ~/.config/shell/env.sh — environment for EVERY shell, everywhere.
#
# Strictly POSIX: sourced by dash, ash (BusyBox), bash and zsh, in login shells,
# non-login shells, and non-interactive script shells. It must never print
# output, never assume bash/zsh syntax, and never be slow.
#
# Sourced from: ~/.zshenv, ~/.profile (and therefore ~/.bash_profile).
#
# `# >>> portable:skip` … `# <<<` marks regions that scripts/gen-portable.sh
# strips when generating the single-file rc for throwaway hosts (decision #29):
# anything that assumes this repo is installed, or writes to disk.


# ─── XDG base directories ────────────────────────────────────────────────────
# Everything here is XDG-first; setting these explicitly means the same paths
# resolve on a distro whose /etc/profile forgot to define them.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

# ─── PATH ────────────────────────────────────────────────────────────────────
# POSIX-safe prepend that refuses duplicates, so re-sourcing never grows PATH.
_dotfiles_path_prepend() {
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1:${PATH}" ;;
    esac
}

export GOPATH="${GOPATH:-$HOME/go}"
export CARGO_HOME="${CARGO_HOME:-$XDG_DATA_HOME/cargo}"
export RUSTUP_HOME="${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}"
export BUN_INSTALL="${BUN_INSTALL:-$XDG_DATA_HOME/bun}"

# Lowest priority first — each prepend pushes the previous one down.
_dotfiles_path_prepend "$GOPATH/bin"
_dotfiles_path_prepend "$CARGO_HOME/bin"
_dotfiles_path_prepend "$BUN_INSTALL/bin"
_dotfiles_path_prepend "$HOME/bin"
# mise shims come from ~/.local/share/mise/shims and must outrank system copies
# so cron jobs, IDEs and non-interactive SSH see the managed tools too.
_dotfiles_path_prepend "$XDG_DATA_HOME/mise/shims"
_dotfiles_path_prepend "$XDG_BIN_HOME"
export PATH

# ─── Locale ──────────────────────────────────────────────────────────────────
# C.UTF-8 exists on every modern libc (including musl/Alpine) and never triggers
# the "setlocale: cannot change locale" noise that en_US.UTF-8 causes on minimal
# images. Override in ~/.config/shell/local.sh if you need a real locale.
export LANG="${LANG:-C.UTF-8}"

# A default only helps when nothing else set one, and on a server something else
# already has: sshd ships `AcceptEnv LANG LC_*`, so the locale from the machine
# you typed `ssh` on follows you to the machine you land on — whether or not
# that machine has it generated. LC_ALL outranks LANG, so the line above cannot
# rescue you either, and every command then prints several lines of setlocale
# warnings before doing its job.
#
# `locale` exits 0 even for a locale it cannot load, so the probe is whether it
# writes anything to stderr. One fork (~1 ms), skipped entirely when the locale
# is already a C variant — which it is on any box that took the default above.
case "${LC_ALL:-$LANG}" in
    C | C.* | POSIX) ;;
    *)
        if [ -n "$(LC_ALL="${LC_ALL:-$LANG}" locale 2>&1 > /dev/null)" ]; then
            # LC_ALL, not just LANG: sshd forwards the whole LC_* family, so a
            # box missing the locale usually has several of them wrong at once.
            # LC_ALL is the only one that overrides all of them in one go.
            # local.sh is sourced at the bottom of this file, so a machine that
            # really does have the locale can still put it back.
            export LC_ALL=C.UTF-8
            export LANG=C.UTF-8
        fi
        ;;
esac

# ─── Editor and pager ────────────────────────────────────────────────────────
# Fall down the chain so a box without the preferred editor still works.
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
elif command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
else
    export EDITOR="vi"
fi
export VISUAL="$EDITOR"
export SUDO_EDITOR="$EDITOR"

export PAGER="less"
# -R  keep colour   -F  quit if one screen   -i  smart case
# -M  verbose prompt  -w  highlight new page  -z-4 leave 4 lines of context
export LESS="-R -F -i -M -w -z-4"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# ─── XDG cleanup: keep $HOME free of tool droppings ──────────────────────────
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export KUBECACHEDIR="$XDG_CACHE_HOME/kube"
# Same argument as KUBECONFIG below, and a nastier failure: gpg does not fall
# back when GNUPGHOME names a directory that is not there, it refuses to run at
# all ("no writable keyring found"). That takes down everything that shells out
# to it — mise verifying a Node tarball signature, git verifying a signed
# commit — on any box where the XDG migration was never done. Relocate only if
# the XDG keyring genuinely exists; otherwise leave gpg on ~/.gnupg, where the
# keys of anyone who has not migrated actually are.
if [ -d "$XDG_DATA_HOME/gnupg" ]; then
    export GNUPGHOME="$XDG_DATA_HOME/gnupg"
elif [ -n "${GNUPGHOME:-}" ] && [ ! -d "$GNUPGHOME" ]; then
    # Actively unset, not merely "don't set". An earlier shell exported the
    # broken value into the environment, so every child — including the one you
    # get from `exec zsh` after fixing this file — inherits it and stays broken.
    # Declining to re-set it fixes nothing. A GNUPGHOME naming a directory that
    # does not exist is wrong no matter who set it, so drop it and let gpg find
    # ~/.gnupg on its own.
    unset GNUPGHOME
fi
# Only relocate kubeconfig if the XDG copy actually exists — pointing KUBECONFIG
# at a missing file breaks kubectl on every box using the classic path.
if [ -z "${KUBECONFIG:-}" ] && [ -f "$XDG_CONFIG_HOME/kube/config" ]; then
    export KUBECONFIG="$XDG_CONFIG_HOME/kube/config"
fi
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NODE_REPL_HISTORY="$XDG_STATE_HOME/node_repl_history"
export PYTHONPYCACHEPREFIX="$XDG_CACHE_HOME/python"
export PYTHON_HISTORY="$XDG_STATE_HOME/python_history"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export TERRAFORM_CLI_CONFIG_FILE="$XDG_CONFIG_HOME/terraform/terraformrc"
# uv and bun are the defaults per decision #39, so their state is relocated too.
export UV_CACHE_DIR="$XDG_CACHE_HOME/uv"
export UV_PYTHON_INSTALL_DIR="$XDG_DATA_HOME/uv/python"
export BUN_RUNTIME_TRANSPILER_CACHE_PATH="$XDG_CACHE_HOME/bun"

# ─── Tooling defaults ────────────────────────────────────────────────────────
# GPG_TTY is NOT set here. It requires $(tty), a fork, and this file runs for
# every scp, rsync and `ssh host command` on the machine. interactive.sh sets it
# where a tty actually exists.
export CLICOLOR=1
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# mise: offer to install a missing tool rather than failing outright.
export MISE_NOT_FOUND_AUTO_INSTALL="${MISE_NOT_FOUND_AUTO_INSTALL:-1}"

# Node heap, sized by machine profile (report.md §3).
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=2048}"

# ─── Machine profile, for anything that needs to branch at runtime ───────────
export DOTFILES_PROFILE="container"
export DOTFILES_TIER="minimal"

# ─── WSL2 interop (decision #41) ─────────────────────────────────────────────
# Windows PATH entries leak into WSL and make every command lookup slow (and
# `ls` on /mnt/c crawl). Detected at runtime, entirely inert elsewhere.
#
# File tests, not `grep /proc/version`: that grep is a fork on EVERY shell —
# including every non-interactive one — on every non-WSL machine in existence,
# to answer a question whose answer is always no. Both paths below exist only
# under WSL, and testing them costs nothing.
if [ -n "${WSL_DISTRO_NAME:-}" ] ||
    [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] ||
    [ -e /run/WSL ]; then
    export DOTFILES_WSL=1
    export BROWSER="${BROWSER:-wslview}"
    # WSLg gives real X11; without it, leave DISPLAY unset so nothing tries to
    # open a window that cannot appear.
    [ -d /mnt/wslg ] && export DISPLAY="${DISPLAY:-:0}"
fi

# ─── SSH detection, used by the prompt and the OSC52 clipboard decision ──────
if [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]; then
    export DOTFILES_SSH=1
fi


# ─── aliases.sh ───────────────────────────────────────────────────────
# shellcheck shell=sh
# ~/.config/shell/aliases.sh — aliases shared by bash and zsh.
#
# POSIX only. Every alias depending on a modern CLI is guarded, so this file
# degrades cleanly on a stock server where none of them are installed yet.
#
# `# @group` headers below are load-bearing: 50-build-help.sh parses them into
# ~/.local/share/dotfiles/help.tsv, which is what `dotfiles help` shows. A
# definition outside a group fails `make lint-help`.

# @group nav — moving around
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# @group ls — listing files
# eza when available, coreutils ls otherwise.
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -l --group-directories-first --icons=auto --git --time-style=long-iso'
    alias la='eza -la --group-directories-first --icons=auto --git --time-style=long-iso'
    alias lt='eza --tree --level=2 --group-directories-first --icons=auto'
    alias ltt='eza --tree --level=4 --group-directories-first --icons=auto'
    alias lsize='eza -l --sort=size --reverse --icons=auto'
    alias lmod='eza -l --sort=modified --reverse --icons=auto --time-style=long-iso'
else
    # GNU ls understands --color; BusyBox/BSD ls does not and would error out.
    # The probe runs at APPLY time (§3.2), not on every shell start: whether
    # this machine's ls is GNU cannot change between now and the next apply,
    # and a `ls --color=auto . >/dev/null` here would be a fork per shell.
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lAh'
    alias lt='ls -lhtr'
fi

# @group view — reading files
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    # @help bat without line numbers or decorations — safe to pipe
    alias catp='bat --paging=never --plain'
    alias less='bat --paging=always'
fi

# @group search — finding things
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'
# @help ripgrep including hidden and ignored files
command -v rg >/dev/null 2>&1 && alias rga='rg --hidden --no-ignore --glob "!.git"'
# @help fd including hidden and ignored files
command -v fd >/dev/null 2>&1 && alias fda='fd --hidden --no-ignore --exclude .git'

# @group safety — rails on destructive commands
# -i affects INTERACTIVE use only; scripts calling /bin/rm are unaffected,
# because aliases are not expanded in non-interactive shells.
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias ln='ln -i'
# --preserve-root is GNU-only; BusyBox coreutils rejects it outright. Probed at
# apply time for the same reason as ls above — this was two forks per shell.
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'

# @group system — disk, processes, network
alias df='df -h'
alias du='du -h'
alias free='free -h'
command -v duf >/dev/null 2>&1 && alias df='duf'
command -v dust >/dev/null 2>&1 && alias du='dust'
command -v btop >/dev/null 2>&1 && alias top='btop'
# @help PATH, one entry per line
alias path='printf "%s\n" $PATH | tr ":" "\n"'
alias now='date "+%Y-%m-%d %H:%M:%S"'
# @help current time as an ISO-8601 UTC timestamp
alias utc='date -u "+%Y-%m-%dT%H:%M:%SZ"'
# @help listening TCP/UDP sockets with owning processes
alias ports='ss -tulpn 2>/dev/null || netstat -tulpn'
# @help this machine's public IP address
alias myip='curl -fsSL https://ifconfig.me && echo'

# @group git — version control
# Deliberately short. Anything more elaborate lives as a git alias in
# ~/.config/git/config, so it works over plain `git` on machines without these.
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
# @help amend the last commit, keeping its message
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
# @help commit graph, one line each
alias gl='git log --graph --abbrev-commit --decorate --format=format:"%C(bold blue)%h%C(reset) %C(auto)%d%C(reset) %s %C(dim white)(%an, %ar)%C(reset)"'
alias gp='git push'
alias gpl='git pull --rebase --autostash'
alias gf='git fetch --all --prune'
alias gst='git stash'
alias gstp='git stash pop'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

# @group pkg — package managers (decision #39: bun and uv are the defaults)
if command -v bun >/dev/null 2>&1; then
    alias b='bun'
    alias bi='bun install'
    alias br='bun run'
    alias bx='bunx'
fi
if command -v uv >/dev/null 2>&1; then
    # @help run a Python tool without installing it
    alias ux='uvx'
    alias uvs='uv sync'
    alias uva='uv add'
    # @help run a command inside the project environment
    alias uvr='uv run'
fi
command -v mise >/dev/null 2>&1 && alias mi='mise'

# @group dot — these dotfiles
if command -v chezmoi >/dev/null 2>&1; then
    alias cm='chezmoi'
    # @help edit a managed file and apply it in one step
    alias cme='chezmoi edit --apply'
    alias cma='chezmoi apply'
    alias cmd='chezmoi diff'
    alias cmu='chezmoi update'
    # @help cd to the dotfiles source directory
    alias cmcd='cd "$(chezmoi source-path)"'
fi
if command -v dotfiles >/dev/null 2>&1; then
    # @help Zellij keybinding cheatsheet — keys.toml via the help index
    alias zk='dotfiles help zellij'
fi

# @group misc — quality of life
# @help replace this shell with a fresh login shell
alias reload='exec "$SHELL" -l'
alias please='sudo'
# @help sudo preserving the environment; trailing space expands the next alias
alias sudoe='sudo -E '
# @help trailing space, so `watch kgp` expands the alias too
alias watch='watch '
alias h='history'
alias c='clear'
alias e='$EDITOR'
# @help serve the current directory over HTTP on port 8000
alias serve='python3 -m http.server 8000'
alias jsonpp='jq .'

# ─── functions.sh ───────────────────────────────────────────────────────
# shellcheck shell=sh
# ~/.config/shell/functions.sh — shell functions shared by bash and zsh.
#
# POSIX only, and silent at load time. Anything that needs a shell hook
# (chpwd, command-not-found, precmd) lives in interactive.sh instead, because
# hooks are the one thing bash and zsh genuinely disagree about.

# @group files — archives, backups, navigation

# @help extract any archive by extension — one command for eight formats
extract() {
    if [ $# -eq 0 ]; then
        echo 'usage: extract <archive>...' >&2
        return 2
    fi
    for _archive in "$@"; do
        if [ ! -f "$_archive" ]; then
            echo "extract: not a file: $_archive" >&2
            continue
        fi
        case "$_archive" in
            *.tar.bz2 | *.tbz2) tar xjf "$_archive" ;;
            *.tar.gz | *.tgz) tar xzf "$_archive" ;;
            *.tar.xz | *.txz) tar xJf "$_archive" ;;
            *.tar.zst) tar --zstd -xf "$_archive" ;;
            *.tar) tar xf "$_archive" ;;
            *.bz2) bunzip2 "$_archive" ;;
            *.gz) gunzip "$_archive" ;;
            *.xz) unxz "$_archive" ;;
            *.zip) unzip -q "$_archive" ;;
            *.7z) 7z x "$_archive" ;;
            *.rar) unrar x "$_archive" ;;
            *.Z) uncompress "$_archive" ;;
            *)
                echo "extract: unknown format: $_archive" >&2
                return 1
                ;;
        esac
    done
    unset _archive
}

# @help create a directory and cd into it
mkcd() {
    [ $# -eq 1 ] || { echo 'usage: mkcd <dir>' >&2; return 2; }
    mkdir -p -- "$1" && cd -- "$1" || return 1
}

# @help climb N directory levels — `up 3` is ../../..
up() {
    _n=${1:-1}
    case "$_n" in
        '' | *[!0-9]*)
            echo 'usage: up [levels]' >&2
            unset _n
            return 2
            ;;
    esac
    _path=''
    while [ "$_n" -gt 0 ]; do
        _path="../$_path"
        _n=$((_n - 1))
    done
    unset _n
    # shellcheck disable=SC2164  # the cd failure is reported by cd itself
    cd "${_path:-.}" || return 1
    unset _path
}

# @help timestamped copy of a file, in place — `bak nginx.conf`
bak() {
    [ $# -ge 1 ] || { echo 'usage: bak <file>...' >&2; return 2; }
    for _f in "$@"; do
        cp -a -- "$_f" "$_f.$(date +%Y%m%d-%H%M%S).bak" || return 1
    done
    unset _f
}

# @group marks — named directory bookmarks
# Stored as a plain tab-separated file you can edit by hand. Completion for
# `jump` and `unmark` is registered per-shell in ~/.zshrc and ~/.bashrc.

_dotfiles_marks_file() {
    printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles/bookmarks"
}

# @help bookmark the current directory under a name
mark() {
    [ $# -eq 1 ] || { echo 'usage: mark <name>' >&2; return 2; }
    _file=$(_dotfiles_marks_file)
    mkdir -p -- "$(dirname -- "$_file")"
    [ -f "$_file" ] || : >"$_file"
    # Replace any existing entry with the same name.
    _tmp="$_file.tmp.$$"
    grep -v "^$1	" "$_file" >"$_tmp" 2>/dev/null || :
    printf '%s\t%s\n' "$1" "$PWD" >>"$_tmp"
    sort -o "$_file" "$_tmp" && rm -f "$_tmp"
    unset _file _tmp
}

# @help cd to a bookmark
jump() {
    [ $# -eq 1 ] || { echo 'usage: jump <name>' >&2; return 2; }
    _file=$(_dotfiles_marks_file)
    _dir=$(awk -F'\t' -v n="$1" '$1 == n { print $2; exit }' "$_file" 2>/dev/null)
    if [ -z "$_dir" ]; then
        echo "jump: no such mark: $1" >&2
        unset _file _dir
        return 1
    fi
    cd -- "$_dir" || { unset _file _dir; return 1; }
    unset _file _dir
}

# @help list bookmarks
marks() {
    _file=$(_dotfiles_marks_file)
    [ -s "$_file" ] || { echo 'no marks yet — use `mark <name>`'; unset _file; return 0; }
    while IFS='	' read -r _name _dir; do
        printf '%-16s %s\n' "$_name" "$_dir"
    done <"$_file"
    unset _file _name _dir
}

# @help remove a bookmark
unmark() {
    [ $# -eq 1 ] || { echo 'usage: unmark <name>' >&2; return 2; }
    _file=$(_dotfiles_marks_file)
    [ -f "$_file" ] || { unset _file; return 0; }
    _tmp="$_file.tmp.$$"
    grep -v "^$1	" "$_file" >"$_tmp" 2>/dev/null || :
    mv -- "$_tmp" "$_file"
    unset _file _tmp
}

# Emits mark names, one per line. Used by the per-shell completion wiring.
_dotfiles_mark_names() {
    cut -f1 "$(_dotfiles_marks_file)" 2>/dev/null || :
}

# @group root — sudo that keeps your environment (decision #27)
# Nothing is installed into /root: it is left exactly as the distro shipped it.
# Instead, the environment travels with you through sudo, so `sudo nvim` uses
# your editor and your config, and `sudo kubectl` uses the mise-managed binary
# rather than failing with "command not found" because root has a bare PATH.

# @help sudo, preserving PATH, EDITOR and the tools you actually use
sudo() {
    # Options-only invocations (`sudo -i`, `sudo -l`, `sudo -v`) must reach the
    # real sudo untouched — wrapping them in `env` would change what they mean.
    case "${1:-}" in
        '' | -*)
            command sudo "$@"
            return $?
            ;;
    esac

    # --preserve-env carries the variables through sudoers' env_reset; the
    # explicit `env PATH=` is needed as well, because secure_path in
    # /etc/sudoers overrides even a preserved PATH on most distributions.
    command sudo \
        --preserve-env=PATH,EDITOR,VISUAL,PAGER,LANG,LC_ALL,TERM,COLORTERM \
        --preserve-env=XDG_CONFIG_HOME,XDG_DATA_HOME,XDG_STATE_HOME,XDG_CACHE_HOME \
        --preserve-env=KUBECONFIG,AWS_PROFILE,AWS_REGION,STARSHIP_CONFIG \
        env "PATH=$PATH" "$@"
}

# @group net — ports and connectivity

# @help which process is listening on a port — `port 8080`
port() {
    [ $# -eq 1 ] || { echo 'usage: port <number>' >&2; return 2; }
    if command -v ss >/dev/null 2>&1; then
        ss -tulpn 2>/dev/null | grep -E "[:.]$1[[:space:]]" || echo "nothing listening on $1"
    elif command -v lsof >/dev/null 2>&1; then
        lsof -nP -iTCP:"$1" -sTCP:LISTEN || echo "nothing listening on $1"
    else
        netstat -tulpn 2>/dev/null | grep -E "[:.]$1[[:space:]]" || echo "nothing listening on $1"
    fi
}

# @group info — this machine

# @help host, OS, kernel, uptime, CPU, memory and disk at a glance
# Decision #25: login prints NOTHING. This is that information, on demand.
sysinfo() {
    printf '%-10s %s\n' 'host' "$(hostname 2>/dev/null || uname -n)"
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        printf '%-10s %s\n' 'os' "$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-$NAME}")"
    fi
    printf '%-10s %s\n' 'kernel' "$(uname -sr)"
    printf '%-10s %s\n' 'arch' "$(uname -m)"
    printf '%-10s %s\n' 'shell' "${SHELL##*/} ${ZSH_VERSION:-${BASH_VERSION:-}}"
    printf '%-10s %s\n' 'profile' "${DOTFILES_PROFILE:-unknown}/${DOTFILES_TIER:-unknown}"
    [ -r /proc/uptime ] && printf '%-10s %s\n' 'uptime' \
        "$(awk '{d=int($1/86400); h=int($1%86400/3600); m=int($1%3600/60);
                 if (d) printf "%dd %dh %dm", d, h, m; else if (h) printf "%dh %dm", h, m;
                 else printf "%dm", m}' /proc/uptime)"
    [ -r /proc/cpuinfo ] && printf '%-10s %s x %s\n' 'cpu' \
        "$(grep -c ^processor /proc/cpuinfo)" \
        "$(awk -F': ' '/model name/ { print $2; exit }' /proc/cpuinfo)"
    if [ -r /proc/meminfo ]; then
        printf '%-10s %s\n' 'memory' "$(awk '
            /^MemTotal:/     { t = $2 }
            /^MemAvailable:/ { a = $2 }
            END { printf "%.1f GiB used of %.1f GiB", (t - a) / 1048576, t / 1048576 }
        ' /proc/meminfo)"
    fi
    printf '%-10s %s\n' 'disk' "$(df -h / 2>/dev/null | awk 'NR == 2 { print $3 " used of " $2 " (" $5 ")" }')"
    [ -n "${DOTFILES_SSH:-}" ] && printf '%-10s %s\n' 'ssh' "${SSH_CONNECTION%% *}"
    [ -n "${DOTFILES_WSL:-}" ] && printf '%-10s %s\n' 'wsl' "${WSL_DISTRO_NAME:-yes}"
    return 0
}

# ─── Prompt and shell behaviour ──────────────────────────────────────────────
# Starship is not installed on a box like this, so the prompt is built from
# what every shell already has. Same information, no dependencies: user, host,
# path, and a red marker when the last command failed.
if [ -n "${ZSH_VERSION:-}" ]; then
    setopt PROMPT_SUBST 2> /dev/null || true
    setopt HIST_IGNORE_DUPS INC_APPEND_HISTORY HIST_IGNORE_SPACE 2> /dev/null || true
    bindkey -e 2> /dev/null || true
    PS1='%F{blue}%n@%m%f %F{cyan}%~%f %(?.%F{green}.%F{red})%#%f '
elif [ -n "${BASH_VERSION:-}" ]; then
    set -o emacs 2> /dev/null || true
    shopt -s histappend checkwinsize 2> /dev/null || true
    HISTCONTROL=ignoreboth
    PS1='\[\e[34m\]\u@\h\[\e[0m\] \[\e[36m\]\w\[\e[0m\] \$ '
else
    PS1='$(whoami)@$(hostname -s):$PWD $ '
fi

HISTSIZE=10000
export EDITOR="${EDITOR:-vi}"

printf 'portable dotfiles loaded — %s aliases, %s functions. Nothing was written to disk.\n' \
    "$(alias 2> /dev/null | wc -l | tr -d ' ')" \
    "$(set 2> /dev/null | grep -c '^[a-z_]* ()' || echo '?')"
