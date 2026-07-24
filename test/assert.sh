#!/bin/sh
# test/assert.sh — post-apply assertions. Runs INSIDE the sandbox container.
#
# Assertions are derived from the data files wherever possible rather than
# hand-listed, so adding a tool to tools.toml extends the test automatically.
# A hand-maintained assertion list is just a fourth place for the truth to live.

set -u

PASS=0
FAIL=0

ok() {
    PASS=$((PASS + 1))
    printf '   ok    %s\n' "$*"
}
no() {
    FAIL=$((FAIL + 1))
    printf '   FAIL  %s\n' "$*"
}
check() { if eval "$1" > /dev/null 2>&1; then ok "$2"; else no "$2"; fi; }

# Assert a target file exists IF the source tree actually manages it.
#
# This is what lets the same assertion file be green at every stage of the
# build: a not-yet-written config is reported as pending rather than failing,
# but the moment it appears in the source it becomes a hard requirement. The
# assertion is still strong — it proves apply materialised what it was given.
expect_managed() {
    src=$1
    target=$2
    label=$3
    # shellcheck disable=SC2086  # $src is a glob on purpose
    if ! ls -d /src/home/$src > /dev/null 2>&1; then
        printf '   ....  %s (not yet in source)\n' "$label"
        return 0
    fi
    if [ -e "$HOME/$target" ]; then ok "$label"; else no "$label"; fi
}

export PATH="$HOME/.local/bin:$PATH"
printf '\n── assertions\n'

# ─── Files that must exist wherever the source provides them ─────────────────
expect_managed 'dot_config/shell/env.sh*' '.config/shell/env.sh' 'shared env.sh'
expect_managed 'dot_config/shell/aliases.sh*' '.config/shell/aliases.sh' 'shared aliases.sh'
expect_managed 'dot_config/shell/functions.sh*' '.config/shell/functions.sh' 'shared functions.sh'
expect_managed 'dot_config/shell/interactive.sh*' '.config/shell/interactive.sh' 'shared interactive.sh'
expect_managed 'dot_zshenv*' '.zshenv' '~/.zshenv'
expect_managed 'dot_zshrc*' '.zshrc' '~/.zshrc'
expect_managed 'dot_bashrc*' '.bashrc' '~/.bashrc'
expect_managed 'dot_profile*' '.profile' '~/.profile'
expect_managed 'dot_config/git/config*' '.config/git/config' 'git config'
expect_managed 'dot_config/mise/config.toml*' '.config/mise/config.toml' 'mise config'
expect_managed 'dot_config/starship.toml*' '.config/starship.toml' 'starship config'
expect_managed 'dot_local/bin/executable_dotfiles*' '.local/bin/dotfiles' 'dotfiles command'

# ─── The load-silence contract (§5) ──────────────────────────────────────────
# A shell rc that prints anything breaks scp, rsync and git-over-ssh. This is
# the single most common way a dotfiles repo quietly breaks remote work.
if command -v zsh > /dev/null 2>&1; then
    noise=$(zsh -c 'exit' 2>&1)
    [ -z "$noise" ] && ok 'non-interactive zsh is silent' ||
        no "non-interactive zsh printed: $noise"

    out=$(ZELLIJ_SKIP=1 zsh -ic 'print -r -- __ZSH_OK__' 2> /dev/null)
    printf '%s' "$out" | grep -q __ZSH_OK__ &&
        ok 'interactive zsh sources cleanly' || no 'interactive zsh failed'
fi

if command -v bash > /dev/null 2>&1; then
    noise=$(bash -c 'exit' 2>&1)
    [ -z "$noise" ] && ok 'non-interactive bash is silent' ||
        no "non-interactive bash printed: $noise"

    out=$(ZELLIJ_SKIP=1 bash -ic 'echo __BASH_OK__' 2> /dev/null)
    printf '%s' "$out" | grep -q __BASH_OK__ &&
        ok 'interactive bash sources cleanly' || no 'interactive bash failed'
fi

# ─── Identity actually landed ────────────────────────────────────────────────
if [ -f "$HOME/.config/git/config" ]; then
    # The identity is repo data now, so this asserts the value in
    # .chezmoidata/identity.toml actually reached the target — read from the
    # data file rather than duplicated here.
    want=$(sed -n 's/^[[:space:]]*email[[:space:]]*=[[:space:]]*"\(.*\)".*/\1/p' \
        /src/home/.chezmoidata/identity.toml | head -1)
    check "git config --file \"\$HOME/.config/git/config\" --get user.email | grep -qF '$want'" \
        'git identity from identity.toml'
fi

# ─── Tools present, list computed from tools.toml ────────────────────────────
# Skipped when the sandbox ran with DOTFILES_SKIP_MISE_TOOLS.
if [ "${DOTFILES_SKIP_MISE_TOOLS:-0}" = "1" ]; then
    printf '   skip  tool presence (DOTFILES_SKIP_MISE_TOOLS=1)\n'
elif [ -f /src/home/.chezmoidata/tools.toml ]; then
    rank=0
    case "${DOTFILES_TEST_TIER:-standard}" in
        minimal) rank=0 ;; standard) rank=1 ;; full) rank=2 ;;
    esac
    bins=$(awk -v want="$rank" '
        function rankof(t) { return t == "minimal" ? 0 : (t == "standard" ? 1 : 2) }
        /^\[\[tool\]\]/ { name=""; bin=""; tier=""; next }
        /^[[:space:]]*name[[:space:]]*=/ { name=$0; sub(/.*"([^"]*)".*/, "\\1", name) }
        /^[[:space:]]*bin[[:space:]]*=/  { bin=$0;  sub(/.*"([^"]*)".*/, "\\1", bin) }
        /^[[:space:]]*tier[[:space:]]*=/ { tier=$0; sub(/.*"([^"]*)".*/, "\\1", tier) }
        /^$/ { if (name != "" && rankof(tier) <= want) print (bin != "" ? bin : name) }
    ' /src/home/.chezmoidata/tools.toml)
    missing=''
    for b in $bins; do
        command -v "$b" > /dev/null 2>&1 || missing="$missing $b"
    done
    [ -z "$missing" ] && ok 'every tool in tier is on PATH' ||
        no "missing from PATH:$missing"
fi

# ─── Profile-conditional expectations ────────────────────────────────────────
case "${DOTFILES_TEST_PROFILE:-server}" in
    container | server)
        check '[ ! -d "$HOME/.local/share/fonts" ]' 'no fonts on a headless host'
        ;;
    workstation)
        check '[ -d "$HOME/.local/share/fonts" ]' 'Nerd Font installed'
        ;;
esac

printf '\n── %s passed, %s failed\n\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
