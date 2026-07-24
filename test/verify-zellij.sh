#!/bin/sh
# test/verify-zellij.sh — prove the generated KDL actually parses.
#
# KDL is the reason Zellij is version-pinned (decision #20): the format has
# broken across minor releases, and a config Zellij rejects leaves you with no
# multiplexer on a remote box. Rendering the template proves the TEMPLATE is
# valid; only Zellij itself can say whether the KDL is.
#
# Layouts need more than `zellij setup --check`, which only looks at the config
# file. The only way Zellij validates a layout is by starting a session with it,
# and starting a session needs a pty — hence `script`.
#
# Requires zellij on PATH; skips cleanly when it is absent.  make verify-zellij

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
BUILD="$ROOT/.build/zellij"
CHEZMOI="${CHEZMOI:-chezmoi}"
FIXTURE="$ROOT/test/fixtures/workstation-full.toml"
rc=0

command -v zellij > /dev/null 2>&1 || {
    echo 'verify-zellij: skip (zellij not installed)'
    exit 0
}
command -v script > /dev/null 2>&1 || {
    echo 'verify-zellij: skip (util-linux `script` not available for a pty)'
    exit 0
}

rm -rf "$BUILD"
mkdir -p "$BUILD/layouts"

render() { "$CHEZMOI" execute-template --source "$ROOT" --config "$FIXTURE" < "$1" > "$2"; }

render "$ROOT/home/dot_config/zellij/config.kdl.tmpl" "$BUILD/config.kdl"
for l in default dev ops; do
    render "$ROOT/home/dot_config/zellij/layouts/$l.kdl.tmpl" "$BUILD/layouts/$l.kdl"
done

printf '── zellij %s\n' "$(zellij --version | awk '{ print $2 }')"

# ─── config.kdl ──────────────────────────────────────────────────────────────
if ZELLIJ_CONFIG_DIR="$BUILD" zellij setup --check 2>&1 | grep -q 'CONFIG FILE\]: Well defined'; then
    printf '   ok    config.kdl\n'
else
    printf '   FAIL  config.kdl rejected by zellij:\n'
    ZELLIJ_CONFIG_DIR="$BUILD" zellij setup --check 2>&1 | sed 's/^/         /' | head -20
    rc=1
fi

# ─── layouts ─────────────────────────────────────────────────────────────────
for l in default dev ops; do
    out=$(script -qec "ZELLIJ_CONFIG_DIR=$BUILD timeout 10 zellij -s verify-$l -l $l" /dev/null 2>&1 |
        tr -d '\r' | grep -iE 'error|invalid|expected|failed|panic|caused by' | head -4 || true)
    ZELLIJ_CONFIG_DIR="$BUILD" zellij delete-session "verify-$l" --force > /dev/null 2>&1 || true

    if [ -n "$out" ]; then
        printf '   FAIL  layout %s\n' "$l"
        printf '%s\n' "$out" | sed 's/^/         /'
        rc=1
    else
        printf '   ok    layout %s\n' "$l"
    fi
done

[ "$rc" -eq 0 ] && echo 'verify-zellij: OK' || echo 'verify-zellij: FAILED' >&2
exit "$rc"
