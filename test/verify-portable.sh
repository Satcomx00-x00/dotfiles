#!/bin/sh
# test/verify-portable.sh — portable.sh must actually work, not merely be current.
#
# The freshness gate (`make portable && git diff --exit-code`) catches
# UNREGENERATED output. It cannot catch WRONG output — and wrong output is the
# realistic failure here, because portable.sh is a concatenation of files that
# were written to be sourced separately.
#
# That is not hypothetical: a `return 0` at the end of env.sh once ended the
# whole concatenated file, and portable.sh shipped defining zero aliases while
# passing every check in the repository.
#
# So this sources it in a container with none of the tools installed — the exact
# situation it exists for — and asserts a named set of things exists.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
PORTABLE="$ROOT/portable.sh"
IMAGE="${IMAGE:-debian:12}"

[ -f "$PORTABLE" ] || {
    echo 'verify-portable: portable.sh does not exist — run `make portable`' >&2
    exit 1
}
command -v docker > /dev/null 2>&1 || {
    echo 'verify-portable: skip (docker not available)'
    exit 0
}

# Must survive on a machine with none of these installed.
REQUIRED_FUNCS='up extract sysinfo mark jump marks unmark port bak mkcd sudo'
REQUIRED_ALIASES='ll la gs gd g h c e path now'
MIN_ALIASES=40

printf '── portable.sh on a bare %s\n' "$IMAGE"

docker run --rm -v "$PORTABLE:/p.sh:ro" \
    -e "REQUIRED_FUNCS=$REQUIRED_FUNCS" \
    -e "REQUIRED_ALIASES=$REQUIRED_ALIASES" \
    -e "MIN_ALIASES=$MIN_ALIASES" \
    "$IMAGE" bash -c '
        rc=0

        # It must not write anything to disk. Snapshot $HOME before and after.
        before=$(find "$HOME" -mindepth 1 2>/dev/null | sort)

        . /p.sh > /dev/null 2>&1 || { echo "   FAIL  sourcing failed"; exit 1; }
        echo "   ok    sources cleanly"

        after=$(find "$HOME" -mindepth 1 2>/dev/null | sort)
        if [ "$before" = "$after" ]; then
            echo "   ok    wrote nothing to \$HOME"
        else
            echo "   FAIL  created files in \$HOME:"
            diff <(printf "%s\n" "$before") <(printf "%s\n" "$after") | sed "s/^/         /"
            rc=1
        fi

        n=$(alias | wc -l)
        if [ "$n" -ge "$MIN_ALIASES" ]; then
            echo "   ok    $n aliases (minimum $MIN_ALIASES)"
        else
            echo "   FAIL  only $n aliases — the concatenation probably ended early"
            rc=1
        fi

        for f in $REQUIRED_FUNCS; do
            type "$f" > /dev/null 2>&1 || { echo "   FAIL  missing function: $f"; rc=1; }
        done
        for a in $REQUIRED_ALIASES; do
            alias "$a" > /dev/null 2>&1 || { echo "   FAIL  missing alias: $a"; rc=1; }
        done
        [ "$rc" -eq 0 ] && echo "   ok    every required alias and function present"

        # And it has to actually run, not just parse.
        cd /tmp && up 1 && [ "$PWD" = "/" ] \
            && echo "   ok    up 1 works" \
            || { echo "   FAIL  up 1 did not reach /"; rc=1; }

        exit $rc
    ' || {
    echo 'verify-portable: FAILED' >&2
    exit 1
}

echo 'verify-portable: OK'
