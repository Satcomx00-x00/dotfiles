#!/bin/sh
# test/lint.sh — static checks over rendered output and repo sources.
#
# Deliberate split:
#   * shellcheck / syntax checks run over RENDERED output, because that is what
#     actually ships. A template that renders to broken shell for the container
#     profile is a real bug that source-level linting cannot see.
#   * shfmt runs over plain (non-template) shell only. Formatting a file full of
#     {{ }} is not meaningful, and demanding it would make templates unwritable.
#
# Requires test/render.sh to have run first (make lint depends on make render).

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
BUILD="$ROOT/.build/render"
FAILED=0

have() { command -v "$1" > /dev/null 2>&1; }
fail() {
    printf '   FAIL  %s\n' "$*"
    FAILED=1
}
skip() { printf '   skip  %s\n' "$*"; }

[ -d "$BUILD" ] || {
    echo "lint: no rendered output — run 'make render' first" >&2
    exit 1
}

# ─── 1. shellcheck over rendered POSIX shell ─────────────────────────────────
printf '── shellcheck (rendered)\n'
if have shellcheck; then
    for f in $(find "$BUILD" -type f \
        \( -path '*/.chezmoiscripts/*' -o -path '*/.config/shell/*' -o -path '*/.local/bin/*' \) \
        ! -name '*.toml' | sort); do
        [ -s "$f" ] || continue # conditional template rendered empty — legitimate
        shellcheck --severity=warning --shell=sh --exclude=SC1090,SC1091 "$f" ||
            fail "shellcheck ${f#"$BUILD"/}"
    done
else
    skip 'shellcheck not installed'
fi

# ─── 2. Parser checks in the real interpreters ───────────────────────────────
# shellcheck cannot parse zsh at all, so zsh files get zsh's own parser. This is
# the only thing standing between a typo in .zshrc and an unusable remote box.
printf '── syntax\n'
for f in $(find "$BUILD" -type f \
    \( -name '.zshrc' -o -name '.zshenv' -o -name '.zprofile' \) | sort); do
    [ -s "$f" ] || continue
    if have zsh; then zsh -n "$f" || fail "zsh -n ${f#"$BUILD"/}"; else skip 'zsh'; fi
done

for f in $(find "$BUILD" -type f \
    \( -name '.bashrc' -o -name '.bash_profile' \) | sort); do
    [ -s "$f" ] || continue
    if have bash; then bash -n "$f" || fail "bash -n ${f#"$BUILD"/}"; else skip 'bash'; fi
done

# The shared layer must parse under a *strict* POSIX shell, not just bash's
# permissive POSIX mode — dash is what /bin/sh actually is on Debian.
POSIX_SH=sh
have dash && POSIX_SH=dash
for f in $(find "$BUILD" -type f -path '*/.config/shell/*' ! -name '*.toml' | sort); do
    [ -s "$f" ] || continue
    "$POSIX_SH" -n "$f" || fail "$POSIX_SH -n ${f#"$BUILD"/}"
done

# ─── 3. shfmt over plain shell sources ───────────────────────────────────────
printf '── shfmt (sources)\n'
if have shfmt; then
    # -i 4 -ci -sr matches .editorconfig's 4-space shell indent.
    plain=$(find "$ROOT/test" "$ROOT/scripts" -type f -name '*.sh' 2> /dev/null | sort)
    [ -f "$ROOT/install.sh" ] && plain="$plain $ROOT/install.sh"
    for f in $plain; do
        shfmt -i 4 -ci -sr -d "$f" || fail "shfmt ${f#"$ROOT"/}"
    done
else
    skip 'shfmt not installed'
fi

# ─── 4. TOML ─────────────────────────────────────────────────────────────────
printf '── toml\n'
if have taplo; then
    for f in $(find "$ROOT/home/.chezmoidata" "$ROOT/test/fixtures" -name '*.toml' 2> /dev/null | sort); do
        taplo check "$f" > /dev/null 2>&1 || fail "taplo ${f#"$ROOT"/}"
    done
    for f in $(find "$BUILD" -name '*.toml' | sort); do
        [ -s "$f" ] || continue
        taplo check "$f" > /dev/null 2>&1 || fail "taplo ${f#"$BUILD"/}"
    done
else
    skip 'taplo not installed'
fi

# ─── 5. Lua ──────────────────────────────────────────────────────────────────
printf '── lua\n'
if [ -d "$ROOT/home/dot_config/nvim" ]; then
    if have stylua; then
        stylua --check "$ROOT/home/dot_config/nvim" || fail 'stylua'
    else
        skip 'stylua not installed'
    fi
else
    skip 'no nvim config yet'
fi

# ─── 6. Glyph integrity ──────────────────────────────────────────────────────
# A whole class of bug found the hard way: Nerd Font glyphs written as raw
# bytes silently became EMPTY strings somewhere between authoring and disk, and
# `fillchars` with a zero-length foldclose is a hard error that stops Neovim
# from starting at all. The rest were invisible — just missing icons.
#
# So: an assignment to something clearly meant to be an icon must not be empty.
# Nerd Font codepoints belong in escape form (\u{...} in Lua, \UXXXXXXXX in
# TOML), which is pure ASCII and cannot be mangled in transit.
printf '── glyph integrity\n'
glyph_hits=$(grep -rnE '(icon|symbol|_symbol|text|fillchars|listchars)[a-z_]*[[:space:]]*=[[:space:]]*"[[:space:]]*"' \
    "$ROOT/home/dot_config/nvim" "$ROOT/home/.chezmoitemplates" 2> /dev/null |
    grep -vE 'unnamed|separator|ssh_symbol = ""' || true)
if [ -n "$glyph_hits" ]; then
    printf '%s\n' "$glyph_hits" | sed "s|$ROOT/||" | sed 's/^/   FAIL  /'
    fail 'empty glyph assignment (a Nerd Font character was probably lost)'
fi

# ─── 7. tools.toml pin rule ──────────────────────────────────────────────────
# Decision #20 says everything floats except two tools. A pinned version with no
# stated reason is how a repo silently accumulates frozen dependencies.
printf '── tools.toml pin rule\n'
TOOLS="$ROOT/home/.chezmoidata/tools.toml"
if [ -f "$TOOLS" ]; then
    awk '
        /^\[\[tool\]\]/          { name=""; version=""; pin=""; next }
        /^[[:space:]]*name[[:space:]]*=/    { name=$0 }
        /^[[:space:]]*version[[:space:]]*=/ { version=$0 }
        /^[[:space:]]*pin[[:space:]]*=/     { pin=$0 }
        /^$/ {
            if (version != "" && version !~ /"latest"/ && pin == "") {
                gsub(/^[[:space:]]*name[[:space:]]*=[[:space:]]*"|"$/, "", name)
                print "pinned without a reason: " name
                bad = 1
            }
        }
        END { exit bad }
    ' "$TOOLS" || fail 'tools.toml: pinned version missing a `pin = "why"` field'
else
    skip 'tools.toml does not exist yet'
fi

if [ "$FAILED" -eq 0 ]; then
    echo 'lint: OK'
else
    echo 'lint: FAILED' >&2
fi
exit "$FAILED"
