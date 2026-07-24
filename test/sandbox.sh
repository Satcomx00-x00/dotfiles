#!/bin/sh
# test/sandbox.sh — full bootstrap into a throwaway container.
#
#   test/sandbox.sh [IMAGE] [PROFILE] [TIER]
#   make sandbox IMAGE=alpine:3.20 PROFILE=server TIER=minimal
#
# The source tree is mounted READ-ONLY, so a script that tries to write back
# into the repo fails here rather than on your machine.
#
# Two applies always run. The second must report no changes and execute no
# scripts — the idempotence contract (§5). A bootstrap that only works once is
# a bootstrap that breaks on `dotfiles update`.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
IMAGE=${1:-${IMAGE:-debian:12}}
PROFILE=${2:-${PROFILE:-server}}
TIER=${3:-${TIER:-standard}}

command -v docker > /dev/null 2>&1 || {
    echo 'sandbox: docker not available' >&2
    exit 127
}

printf '\n═══ sandbox: %s (profile=%s tier=%s)\n\n' "$IMAGE" "$PROFILE" "$TIER"

# DOTFILES_SKIP_MISE_TOOLS keeps the loop fast: the tool downloads are hundreds
# of megabytes and prove nothing about the templates. `make sandbox-full` drops
# it for the real end-to-end run.
docker run --rm \
    -v "$ROOT:/src:ro" \
    -e "DOTFILES_TEST_PROFILE=$PROFILE" \
    -e "DOTFILES_TEST_TIER=$TIER" \
    -e "DOTFILES_SKIP_MISE_TOOLS=${DOTFILES_SKIP_MISE_TOOLS:-1}" \
    -e "ZELLIJ_SKIP=1" \
    -e "HOME=/root" \
    -e "SANDBOX_POST=${SANDBOX_POST:-/src/test/assert.sh}" \
    "$IMAGE" sh -eu -c '
        # ── Bootstrap prerequisites, per package manager ────────────────────
        if command -v apt-get >/dev/null 2>&1; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq >/dev/null
            apt-get install -y -qq --no-install-recommends \
                git curl ca-certificates sudo >/dev/null
        elif command -v apk >/dev/null 2>&1; then
            apk add --no-cache --quiet git curl ca-certificates bash sudo shadow >/dev/null
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y -q git curl sudo >/dev/null
        elif command -v pacman >/dev/null 2>&1; then
            pacman -Sy --noconfirm --quiet git curl sudo >/dev/null
        fi

        export PATH="$HOME/.local/bin:$PATH"
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null

        # ── Apply #1: from nothing to a configured machine ──────────────────
        echo "── apply (1/2)"
        ( . /src/test/prompts.sh
          chezmoi init --apply --source=/src --no-tty "$@" )

        # ── Apply #2: must be a no-op ───────────────────────────────────────
        echo "── apply (2/2) — idempotence"
        out=$(chezmoi apply --source=/src --no-tty --verbose 2>&1 || true)
        if printf "%s" "$out" | grep -qE "^(install|chmod|create|update)"; then
            echo "IDEMPOTENCE FAILED — second apply changed things:" >&2
            printf "%s\n" "$out" >&2
            exit 1
        fi
        echo "   no changes"

        # ── Post-apply step: assertions by default, benchmark for `make bench` ──
        exec sh "$SANDBOX_POST"
    '
