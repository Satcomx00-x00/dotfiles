#!/bin/sh
# Phase 8b — create the socket directory ControlMaster needs.
#
# ~/.ssh/config sets `ControlPath ~/.ssh/sockets/%r@%h-%p`. If that directory
# does not exist, every single ssh invocation prints a "No such file or
# directory" error before connecting anyway — noise on every git push, forever.
#
# It cannot be shipped as a managed file because it must be EMPTY, and git does
# not track empty directories.
#
# OPTIONAL phase.

set -eu

mkdir -p "$HOME/.ssh/sockets" 2> /dev/null || exit 0
chmod 700 "$HOME/.ssh" "$HOME/.ssh/sockets" 2> /dev/null || true
printf '  ssh: socket directory ready\n'
