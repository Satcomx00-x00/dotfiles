#!/bin/sh
# scripts/gen-portable.sh — build portable.sh from the real shell layer.
#
# Decision #29: for boxes you touch once and never see again. Curl it, source
# it into one shell, and on exit the machine is exactly as you found it —
# nothing installed, nothing written to disk, no root, no chezmoi.
#
# The claim that matters is "it cannot drift from the real config", and the only
# way to make that true is to GENERATE it from the same sources rather than
# maintain a second copy. Regions marked
#
#     # >>> portable:skip
#     ...
#     # <<<
#
# are removed: anything that assumes this repository is installed, or writes to
# disk. CI regenerates and fails on any diff (`make portable && git diff
# --exit-code`), so a change to aliases.sh that never reaches portable.sh is a
# build failure rather than a slow divergence nobody notices.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
OUT="$ROOT/portable.sh"
CHEZMOI="${CHEZMOI:-chezmoi}"
# The leanest profile: whatever survives here is safe on a throwaway host.
FIXTURE="$ROOT/test/fixtures/container-minimal.toml"

command -v "$CHEZMOI" > /dev/null 2>&1 || {
    echo 'gen-portable: chezmoi not found' >&2
    exit 127
}

render() {
    "$CHEZMOI" execute-template --source "$ROOT" --config "$FIXTURE" \
        < "$ROOT/home/dot_config/shell/$1.tmpl"
}

strip_skips() {
    awk '
        /^[[:space:]]*#[[:space:]]*>>>[[:space:]]*portable:skip/ { skip = 1; next }
        /^[[:space:]]*#[[:space:]]*<<</ { skip = 0; next }
        !skip
    '
}

TMP="$OUT.tmp.$$"

cat > "$TMP" << 'HEADER'
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

HEADER

for f in env aliases functions; do
    printf '# ─── %s.sh ───────────────────────────────────────────────────────\n' "$f" >> "$TMP"
    render "$f.sh" | strip_skips >> "$TMP"
    printf '\n' >> "$TMP"
done

cat >> "$TMP" << 'FOOTER'
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
FOOTER

mv -f "$TMP" "$OUT"
chmod 0644 "$OUT"
printf 'portable.sh: %s lines\n' "$(wc -l < "$OUT" | tr -d ' ')"
