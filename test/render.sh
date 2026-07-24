#!/bin/sh
# test/render.sh — render every template against every fixture.
#
# The fast inner loop of this repository: no container, no network, no prompts.
# Three machine profiles x every template, in about a second.
#
# It checks two distinct things:
#   1. Every template renders without error for every profile.
#   2. The fixtures and home/.chezmoi.toml.tmpl agree on the data schema.
#
# (2) is the one that matters. Without it the fixtures slowly become a fiction
# that passes CI while a real `chezmoi init` fails on a missing key.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
BUILD="$ROOT/.build/render"
CHEZMOI="${CHEZMOI:-chezmoi}"
FAILED=0

command -v "$CHEZMOI" > /dev/null 2>&1 || {
    echo "render: chezmoi not found — run 'make dev-tools'" >&2
    exit 127
}

rm -rf "$BUILD"
mkdir -p "$BUILD"

# ─── Template inventory ──────────────────────────────────────────────────────
# Everything ending .tmpl, plus .chezmoiignore, which is evaluated as a template
# despite having no suffix. .chezmoi.toml.tmpl is excluded: it needs --init and
# is handled separately below.
templates() {
    find "$ROOT/home" -type f -name '*.tmpl' ! -name '.chezmoi.toml.tmpl' | sort
    [ -f "$ROOT/home/.chezmoiignore" ] && echo "$ROOT/home/.chezmoiignore"
    return 0
}

fixtures() {
    find "$ROOT/test/fixtures" -type f -name '*.toml' | sort
}

# ─── 1. Render matrix ────────────────────────────────────────────────────────
for fixture in $(fixtures); do
    fname=$(basename "$fixture" .toml)
    printf '── %s\n' "$fname"

    for tpl in $(templates); do
        rel=${tpl#"$ROOT"/home/}
        out="$BUILD/$fname/${rel%.tmpl}"
        mkdir -p "$(dirname "$out")"

        # stderr to the capture, stdout to the file — order matters here.
        if ! err=$("$CHEZMOI" execute-template \
            --source "$ROOT" --config "$fixture" \
            < "$tpl" 2>&1 > "$out"); then
            printf '   FAIL  %s\n' "$rel"
            printf '%s\n' "$err" | sed 's/^/         /'
            FAILED=1
        fi
    done
done

# ─── 2. Schema agreement: fixtures vs the real prompt file ───────────────────
# Renders the init template with every prompt supplied, then compares the [data]
# keys it emits against the keys each fixture provides.
data_keys() {
    awk '
        /^[[:space:]]*\[data\]/ { in_data = 1; next }
        /^[[:space:]]*\[/       { in_data = 0 }
        in_data && /=/ {
            sub(/^[[:space:]]+/, "")
            if ($0 ~ /^#/) next
            split($0, kv, "=")
            gsub(/[[:space:]]/, "", kv[1])
            if (kv[1] != "") print kv[1]
        }
    ' "$1" | sort -u
}

init_tpl="$ROOT/home/.chezmoi.toml.tmpl"
if [ -f "$init_tpl" ]; then
    printf '── schema\n'
    rendered="$BUILD/.chezmoi.toml"
    if (
        . "$ROOT/test/prompts.sh"
        "$CHEZMOI" execute-template --init --source "$ROOT" "$@" \
            < "$init_tpl" > "$rendered" 2> "$BUILD/.schema.err"
    ); then

        data_keys "$rendered" > "$BUILD/.keys.real"

        for fixture in $(fixtures); do
            fname=$(basename "$fixture" .toml)
            data_keys "$fixture" > "$BUILD/.keys.fixture"

            missing=$(comm -23 "$BUILD/.keys.real" "$BUILD/.keys.fixture")
            extra=$(comm -13 "$BUILD/.keys.real" "$BUILD/.keys.fixture")

            if [ -n "$missing" ] || [ -n "$extra" ]; then
                printf '   FAIL  %s\n' "$fname"
                [ -n "$missing" ] && printf '         missing (init emits, fixture lacks): %s\n' \
                    "$(echo "$missing" | tr '\n' ' ')"
                [ -n "$extra" ] && printf '         stale   (fixture has, init drops):    %s\n' \
                    "$(echo "$extra" | tr '\n' ' ')"
                FAILED=1
            fi
        done
    else
        printf '   FAIL  .chezmoi.toml.tmpl did not render\n'
        sed 's/^/         /' "$BUILD/.schema.err"
        # The overwhelmingly likely cause, and not obvious from chezmoi's error.
        if grep -qiE 'TTY|EOF' "$BUILD/.schema.err"; then
            printf '         HINT: a prompt went unanswered. chezmoi keys --promptString on the\n'
            printf '               PROMPT TEXT, not the data key — test/prompts.sh must quote the\n'
            printf '               exact wording used in .chezmoi.toml.tmpl.\n'
        fi
        FAILED=1
    fi
fi

if [ "$FAILED" -eq 0 ]; then
    printf 'render: OK (%s templates x %s fixtures)\n' \
        "$(templates | wc -l | tr -d ' ')" "$(fixtures | wc -l | tr -d ' ')"
else
    printf 'render: FAILED\n' >&2
fi
exit "$FAILED"
