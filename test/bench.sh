#!/bin/sh
# test/bench.sh — run the startup benchmark in a clean container.
#
# Reuses test/sandbox.sh so the machine under test is bootstrapped exactly the
# way a real one is; only the post-apply step differs.

set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SANDBOX_POST=/src/test/bench-inner.sh \
    exec sh "$ROOT/test/sandbox.sh" "${1:-debian:12}" "${2:-server}" "${3:-standard}"
