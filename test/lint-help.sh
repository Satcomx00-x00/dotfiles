#!/bin/sh
# test/lint-help.sh — every alias and function must be reachable from `dotfiles help`.
#
# Decision #37 says the help output is generated from the real configuration so
# it cannot drift. That is only true if an undocumented definition is a BUILD
# ERROR rather than an omission someone means to fix later. This is that error.
#
# Convention (IMPLEMENTATION.md §4.3):
#
#     # @group git — version control
#     alias gs='git status -sb'          <- inherits the group, body is the description
#
#     # @help climb N directory levels
#     up() { ... }                        <- explicit description where the body is opaque
#
# Requiring a group (once per section) rather than a description (once per
# definition) is deliberate: `alias gs='git status -sb'` documents itself, and a
# convention that demands 120 hand-written descriptions is one that rots.
# Underscore-prefixed names are private and exempt.
#
# Runs over rendered output, so a tier-gated alias is only checked on the
# profiles where it actually exists.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
BUILD="$ROOT/.build/render"
FAILED=0

[ -d "$BUILD" ] || {
    echo "lint-help: run 'make render' first" >&2
    exit 1
}

files=$(find "$BUILD" -type f \
    \( -name 'aliases.sh' -o -name 'functions.sh' -o -name 'pickers.sh' \) | sort)

[ -n "$files" ] || {
    echo 'lint-help: skip (no annotated files yet)'
    exit 0
}

for f in $files; do
    [ -s "$f" ] || continue
    out=$(awk '
        /^[[:space:]]*#[[:space:]]*@group[[:space:]]/ { group = $0; next }
        /^[[:space:]]*#[[:space:]]*@help[[:space:]]/  { next }

        /^[[:space:]]*alias[[:space:]]+[A-Za-z0-9_.:-]+=/ ||
        /^[[:space:]]*[A-Za-z0-9_.:-]+[[:space:]]*\(\)[[:space:]]*\{/ ||
        /^[[:space:]]*function[[:space:]]+[A-Za-z0-9_.:-]+/ {
            line = $0
            sub(/^[[:space:]]*/, "", line)
            sub(/^alias[[:space:]]+/, "", line)
            sub(/^function[[:space:]]+/, "", line)
            split(line, parts, /[=( \t]/)
            nm = parts[1]
            # `alias -- -=...` and private helpers are exempt.
            if (nm == "--" || nm == "-" || substr(nm, 1, 1) == "_") next
            if (group == "") printf "  line %d: %s\n", NR, nm
        }
    ' "$f")

    if [ -n "$out" ]; then
        printf '── definitions with no @group in %s\n' "${f#"$BUILD"/}"
        printf '%s\n' "$out"
        FAILED=1
    fi
done

if [ "$FAILED" -eq 0 ]; then
    echo 'lint-help: OK'
else
    echo 'lint-help: FAILED — add a `# @group <name> — <description>` header above the section' >&2
fi
exit "$FAILED"
