#!/bin/sh
# test/bench-inner.sh — interactive shell startup timing. Runs INSIDE the sandbox.
#
# No hyperfine dependency on purpose: the sandbox deliberately skips the tool
# downloads, and a benchmark that only runs on a fully provisioned box is a
# benchmark nobody runs. `date +%s%N` is available in coreutils and BusyBox.
#
# Budget: 60 ms for interactive zsh (report.md §8.1).

set -eu

BUDGET_MS=${BUDGET_MS:-60}
RUNS=${RUNS:-12}
WARMUP=3

bench() {
    shell=$1
    flag=$2
    command -v "$shell" > /dev/null 2>&1 || {
        printf '   skip  %s\n' "$shell"
        return 0
    }

    i=0
    while [ "$i" -lt "$WARMUP" ]; do
        ZELLIJ_SKIP=1 "$shell" "$flag" exit > /dev/null 2>&1 || true
        i=$((i + 1))
    done

    total=0
    min=999999
    max=0
    i=0
    while [ "$i" -lt "$RUNS" ]; do
        start=$(date +%s%N)
        ZELLIJ_SKIP=1 "$shell" "$flag" exit > /dev/null 2>&1 || true
        end=$(date +%s%N)
        ms=$(((end - start) / 1000000))
        total=$((total + ms))
        [ "$ms" -lt "$min" ] && min=$ms
        [ "$ms" -gt "$max" ] && max=$ms
        i=$((i + 1))
    done

    mean=$((total / RUNS))
    verdict='ok'
    [ "$mean" -gt "$BUDGET_MS" ] && verdict='OVER BUDGET'
    printf '   %-6s mean %3s ms   min %3s ms   max %3s ms   (budget %s ms) %s\n' \
        "$shell" "$mean" "$min" "$max" "$BUDGET_MS" "$verdict"

    [ "$mean" -le "$BUDGET_MS" ]
}

printf '\n── startup benchmark (%s runs)\n' "$RUNS"
rc=0
bench zsh -ic || rc=1
bench bash -ic || true # bash parity is a goal, not a budget
printf '\n'
exit "$rc"
