#!/bin/sh
# test/verify-tools.sh — prove every backend in tools.toml actually resolves.
#
# A wrong backend string in tools.toml is invisible to every other check: it
# renders fine, lints fine, and only fails during a real bootstrap on a real
# machine, halfway through. This asks mise to resolve each one for real.
#
# Network-bound, so it is NOT part of `make check`. Run it when tools.toml
# changes:  make verify-tools
#
# Version pins are checked too — a pinned version that no longer exists
# upstream is exactly as broken as a bad backend.
#
# KNOWN BLIND SPOT: this proves a backend RESOLVES, not that it INSTALLS.
# `aqua:golang/tools/gopls` resolved to v0.23.0 here and passed for months,
# while `mise install` rejected it outright — the aqua registry entry is package
# type `go_install`, which that backend cannot build. Only a real install finds
# this class, which is what the image workflow's assert step now does at `full`.

set -eu

MISE="${MISE:-mise}"

# ─── Worker mode ─────────────────────────────────────────────────────────────
# Dispatched first, before any output: xargs re-executes this script once per
# tool, so anything printed above here would be printed once per tool.
if [ "${1:-}" = "--one" ]; then
    name=$2 backend=$3 version=$4

    if [ "$version" = "latest" ]; then
        # stderr must NOT be merged in: mise reports "no aqua-registry found"
        # as a warning on stderr and still exits 0, so a merged capture makes a
        # missing package look like a successful resolution.
        out=$("$MISE" latest "$backend" 2> /dev/null || true)
        case "$out" in
            *[0-9]*)
                printf '   ok    %-34s %-42s %s\n' "$name" "$backend" "$out"
                ;;
            *)
                printf '   FAIL  %-34s %-42s unresolvable\n' "$name" "$backend"
                exit 1
                ;;
        esac
    else
        if "$MISE" ls-remote "$backend" 2> /dev/null | grep -qx "$version"; then
            printf '   ok    %-34s %-42s %s (pinned)\n' "$name" "$backend" "$version"
        else
            near=$("$MISE" ls-remote "$backend" 2> /dev/null | tail -3 | tr '\n' ' ')
            printf '   FAIL  %-34s pinned %s does not exist upstream\n         available near the top: %s\n' \
                "$name" "$version" "${near:-<nothing — backend itself is bad>}"
            exit 1
        fi
    fi
    exit 0
fi

# ─── Driver mode ─────────────────────────────────────────────────────────────
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
CHEZMOI="${CHEZMOI:-chezmoi}"
JOBS="${JOBS:-8}"
BUILD="$ROOT/.build"

command -v "$MISE" > /dev/null 2>&1 || {
    echo 'verify-tools: mise not found' >&2
    exit 127
}
mkdir -p "$BUILD"

# Extract "name<TAB>backend<TAB>version" straight from the data file — no
# second parser to keep in sync.
"$CHEZMOI" execute-template --source "$ROOT" \
    --config "$ROOT/test/fixtures/workstation-full.toml" \
    '{{ range .tools.list }}{{ .name }}	{{ .backend }}	{{ .version }}
{{ end }}' > "$BUILD/tools.tsv"

total=$(grep -c . < "$BUILD/tools.tsv" || true)
printf '── verifying %s backends (%s parallel)\n\n' "$total" "$JOBS"

# None of name/backend/version can contain whitespace, so xargs -n3 splits the
# triples correctly and -P gives concurrency without a job-control dance.
# Output goes to a file rather than through a pipe to sort: a pipeline's exit
# status is the LAST command's, which would swallow every failure.
rc=0
tr '\t' '\n' < "$BUILD/tools.tsv" | grep . |
    xargs -P "$JOBS" -n 3 sh "$0" --one > "$BUILD/verify.out" 2>&1 || rc=1
sort -k2 "$BUILD/verify.out"

printf '\n'
if [ "$rc" -eq 0 ]; then
    echo 'verify-tools: OK'
else
    echo 'verify-tools: FAILED' >&2
fi
exit "$rc"
