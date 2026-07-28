#!/bin/sh
# scripts/gen-docs.sh — regenerate the parts of README.md that are derived.
#
# The tool inventory is a table of ~70 entries across three tiers. Maintained by
# hand it would be wrong within a month; CI would not notice, and the README
# would quietly describe a machine this repository does not build.
#
# So it is generated from .chezmoidata/tools.toml, between markers:
#
#     <!-- BEGIN GENERATED: tools -->
#     ...
#     <!-- END GENERATED: tools -->
#
# CI runs this and fails on any diff (`make docs && git diff --exit-code`).

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
README="$ROOT/README.md"
CHEZMOI="${CHEZMOI:-chezmoi}"
FIXTURE="$ROOT/test/fixtures/workstation-full.toml"

command -v "$CHEZMOI" > /dev/null 2>&1 || {
    echo 'gen-docs: chezmoi not found' >&2
    exit 127
}
[ -f "$README" ] || {
    echo 'gen-docs: README.md does not exist' >&2
    exit 1
}

BUILD="$ROOT/.build"
mkdir -p "$BUILD"

# ─── Tool inventory ──────────────────────────────────────────────────────────
# Rendered against the widest profile so every tier appears; the tier column
# tells the reader which machines actually get each one.
"$CHEZMOI" execute-template --source "$ROOT" --config "$FIXTURE" > "$BUILD/tools.md" << 'TPL'
{{- $tiers := .tools.tiers -}}
{{- $groups := list "prompt" "core-cli" "system" "git" "editor" "multiplexer" "terminal" "runtime" "lsp" "container" "k8s" "infra" "secrets" "workflow" -}}
{{- range $g := $groups }}
{{- $any := false }}
{{- range $.tools.list }}{{ if eq .group $g }}{{ $any = true }}{{ end }}{{ end }}
{{- if $any }}

**{{ $g }}**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
{{- range $.tools.list }}
{{- if eq .group $g }}
| `{{ dig "bin" .name . }}` | {{ .role }} | {{ index $tiers .rank }} | `{{ .backend }}`{{ if hasKey . "pin" }} **PIN {{ .version }}**{{ end }} |
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{ $m := 0 }}{{ $s := 0 }}{{ $f := 0 }}
{{- range .tools.list }}
{{- if eq .rank 0 }}{{ $m = add1 $m }}{{ $s = add1 $s }}{{ $f = add1 $f }}
{{- else if eq .rank 1 }}{{ $s = add1 $s }}{{ $f = add1 $f }}
{{- else }}{{ $f = add1 $f }}{{ end }}
{{- end }}
Totals: **minimal** {{ $m }} · **standard** {{ $s }} · **full** {{ $f }}
TPL

# ─── Splice between the markers ──────────────────────────────────────────────
awk -v gen="$BUILD/tools.md" '
    /<!-- BEGIN GENERATED: tools -->/ {
        print
        while ((getline line < gen) > 0) print line
        close(gen)
        skip = 1
        next
    }
    /<!-- END GENERATED: tools -->/ { skip = 0 }
    !skip
' "$README" > "$README.tmp.$$"

if ! grep -q 'BEGIN GENERATED: tools' "$README"; then
    rm -f "$README.tmp.$$"
    echo 'gen-docs: README.md has no <!-- BEGIN GENERATED: tools --> marker' >&2
    exit 1
fi

mv -f "$README.tmp.$$" "$README"
printf 'README.md: tool inventory regenerated\n'
