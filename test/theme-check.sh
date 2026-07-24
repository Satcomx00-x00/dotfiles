#!/bin/sh
# test/theme-check.sh — prove the theme really is defined in exactly one place.
#
# Method: replace every colour in home/.chezmoidata/theme.toml with a sentinel,
# re-render everything, and diff. The set of files that changed IS the set of
# real consumers. Compare it against test/theme-consumers.txt, the declared
# contract.
#
# This catches the failure that makes "themed everywhere" a lie: a config with
# the palette hardcoded renders identically, so it never shows up in the diff.
# Adding a consumer without adding it here fails too — the declaration and the
# reality are checked against each other in both directions.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
THEME="$ROOT/home/.chezmoidata/theme.toml"
EXPECT="$ROOT/test/theme-consumers.txt"
BUILD="$ROOT/.build/theme"
CHEZMOI="${CHEZMOI:-chezmoi}"
FIXTURE="$ROOT/test/fixtures/workstation-full.toml" # widest profile: every consumer exists

[ -f "$THEME" ] || {
    echo 'theme-check: skip (theme.toml does not exist yet)'
    exit 0
}
[ -f "$EXPECT" ] || {
    echo 'theme-check: skip (no declared consumer list yet)'
    exit 0
}

rm -rf "$BUILD"
mkdir -p "$BUILD/before" "$BUILD/after" "$BUILD/src"

# A repo-shaped copy so .chezmoiroot still resolves.
cp "$ROOT/.chezmoiroot" "$BUILD/src/"
cp -r "$ROOT/home" "$BUILD/src/home"

render_into() {
    dest=$1
    src=$2
    for tpl in $(find "$src/home" -type f -name '*.tmpl' ! -name '.chezmoi.toml.tmpl' | sort); do
        rel=${tpl#"$src"/home/}
        out="$dest/${rel%.tmpl}"
        mkdir -p "$(dirname "$out")"
        "$CHEZMOI" execute-template --source "$src" --config "$FIXTURE" < "$tpl" > "$out" 2> /dev/null || true
    done
}

render_into "$BUILD/before" "$BUILD/src"

# Mutate EVERY colour and theme name to a value that cannot occur naturally.
#
# Mutating a single key was the obvious first design and it is too weak: a
# config that only ever references `red` would sail through a test that only
# perturbs `blue`. Changing the whole palette means any file that embeds any
# part of it has to move.
sed -e 's|"#[0-9a-fA-F]\{6\}"|"#fa11ed"|g' \
    -e 's|"tokyonight[a-z_-]*"|"sentinel-theme"|g' \
    "$THEME" > "$BUILD/src/home/.chezmoidata/theme.toml"

if cmp -s "$THEME" "$BUILD/src/home/.chezmoidata/theme.toml"; then
    echo 'theme-check: mutation changed nothing — theme.toml has no colours?' >&2
    exit 1
fi

render_into "$BUILD/after" "$BUILD/src"

# ─── Compare ─────────────────────────────────────────────────────────────────
(cd "$BUILD/before" && find . -type f | sort) > "$BUILD/list"
: > "$BUILD/actual"
while read -r f; do
    cmp -s "$BUILD/before/$f" "$BUILD/after/$f" || printf '%s\n' "${f#./}" >> "$BUILD/actual"
done < "$BUILD/list"

# Translate chezmoi SOURCE names to TARGET paths, so theme-consumers.txt can be
# written the way a human thinks about it (~/.config/bat/config) rather than the
# way the source tree spells it (dot_config/bat/config).
to_target() {
    awk -F/ '{
        out = ""
        for (i = 1; i <= NF; i++) {
            seg = $i
            # Attribute prefixes may stack: private_readonly_dot_foo
            while (seg ~ /^(private|readonly|executable|encrypted|symlink|create|modify|remove)_/)
                sub(/^[a-z]+_/, "", seg)
            sub(/^dot_/, ".", seg)
            out = (out == "" ? seg : out "/" seg)
        }
        print out
    }'
}

to_target < "$BUILD/actual" | sort -u > "$BUILD/actual.sorted"
# Every file that was rendered at all, in target form — needed below to tell a
# not-yet-built consumer apart from one that exists and ignored the palette.
sed 's|^\./||' "$BUILD/list" | to_target | sort -u > "$BUILD/all.sorted"
grep -v '^[[:space:]]*#' "$EXPECT" | grep -v '^[[:space:]]*$' | sort -u > "$BUILD/expect.sorted"

missing=$(comm -23 "$BUILD/expect.sorted" "$BUILD/actual.sorted")
extra=$(comm -13 "$BUILD/expect.sorted" "$BUILD/actual.sorted")

# A declared consumer whose file was never rendered is PENDING, not broken —
# it belongs to a stage that has not been built yet. One that was rendered and
# did not change is a genuine failure: its colours are hardcoded.
pending=''
hardcoded=''
for f in $missing; do
    if grep -qxF "$f" "$BUILD/all.sorted"; then
        hardcoded="$hardcoded $f"
    else
        pending="$pending $f"
    fi
done

rc=0
printf '── theme fan-out (whole palette mutated)\n'
if [ -n "$hardcoded" ]; then
    printf '   FAIL  declared consumers that did NOT change (hardcoded colour?):\n'
    for f in $hardcoded; do printf '         %s\n' "$f"; done
    rc=1
fi
if [ -n "$pending" ]; then
    for f in $pending; do printf '   ....  %s (not built yet)\n' "$f"; done
fi
if [ -n "$extra" ]; then
    printf '   FAIL  undeclared consumers that changed (add to theme-consumers.txt):\n'
    printf '%s\n' "$extra" | sed 's/^/         /'
    rc=1
fi
[ "$rc" -eq 0 ] && printf 'theme-check: OK (%s live consumers, %s pending)\n' \
    "$(wc -l < "$BUILD/actual.sorted" | tr -d ' ')" "$(printf '%s' "$pending" | wc -w | tr -d ' ')"
exit "$rc"
