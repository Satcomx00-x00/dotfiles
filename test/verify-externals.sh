#!/bin/sh
# test/verify-externals.sh — every external URL must still be reachable.
#
# Same reasoning as verify-tools.sh: a dead URL renders and lints perfectly and
# only fails during a real bootstrap. The failure mode here is worse, because a
# missing zsh plugin produces a shell that starts but silently lacks features.
#
# Network-bound, so not part of `make check`.  make verify-externals

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
BUILD="$ROOT/.build/render"
rc=0
seen=''

[ -d "$BUILD" ] || {
    echo 'verify-externals: run make render first' >&2
    exit 1
}

printf '── external URLs\n'

# The rendered externals differ per fixture (tier and font gates), so check the
# union across all of them — every URL any machine could ever fetch.
urls=$(find "$BUILD" -name '.chezmoiexternal.toml' -exec cat {} + |
    sed -n 's/^[[:space:]]*url[[:space:]]*=[[:space:]]*"\(.*\)"/\1/p' |
    sort -u)

for url in $urls; do
    case " $seen " in *" $url "*) continue ;; esac
    seen="$seen $url"

    # -L: every one of these is a redirect to a CDN.
    code=$(curl -fsSL -o /dev/null -w '%{http_code}' --max-time 30 --retry 1 \
        -r 0-0 "$url" 2> /dev/null || echo 000)

    case "$code" in
        200 | 206)
            printf '   ok    %s\n' "$url"
            ;;
        *)
            printf '   FAIL  %s  (HTTP %s)\n' "$url" "$code"
            rc=1
            ;;
    esac
done

printf '\n'
if [ "$rc" -eq 0 ]; then
    echo "verify-externals: OK ($(printf '%s\n' $urls | grep -c .) URLs)"
else
    echo 'verify-externals: FAILED' >&2
fi
exit "$rc"
