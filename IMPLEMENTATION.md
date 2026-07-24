# Dotfiles — Implementation Plan

**Companion to:** `report.md`
**Date:** 2026-07-24
**Status:** Build plan — ready to execute

---

## 1. What this document is

`report.md` is the contract: 47 decisions describing *what* the repository
contains and *why*. It is settled and this document does not reopen it.

This document is the *how* and the *in what order* — the procedure that turns
those decisions into ~85 files without the two failure modes that kill projects
of this shape: silent template drift, and a 60-file changeset that has never once
been executed end to end.

It re-orders `report.md` §15 on two grounds, both stated plainly rather than
smuggled in:

| Change from §15 | Reason |
| --- | --- |
| CI and the test harness move from phase 16 to **stage 0** | 85 templated files against a Go templating engine with no feedback loop is unverifiable by inspection. The harness is the cheapest file in the repo and every subsequent stage is gated on it |
| A new **stage 1** reconciles existing drift before extending | Four files on disk encode decisions that were later reversed. Building on them propagates a contradiction into every consumer |

---

## 2. Starting state

Audited against the final decision record.

| Path | State | Action in this plan |
| --- | --- | --- |
| `.chezmoiroot` | Correct — points at `home/` | Keep |
| `home/.chezmoiversion` | `2.47.0` | Keep; raise only if a used feature demands it |
| `home/.chezmoi.toml.tmpl` | **Contradicts #11, #16, #35** — prompts for tmux/zellij/none, offers a `1password` backend, asks for `workEmail` | Rewrite (stage 1) |
| `home/.chezmoiignore` | **Contradicts #11, #35** — tmux and work-email branches | Rewrite (stage 1) |
| `home/.chezmoiexternal.toml.tmpl` | Sound; zsh plugins and font correct. Missing the three Zellij WASM plugins (#12) | Extend (stage 1) |
| `home/.chezmoidata/packages.toml` | Correct and complete for five package managers | Keep as-is |
| `home/dot_config/shell/env.sh.tmpl` | Good quality, ~95% aligned. Missing `bun`/`uv` XDG relocation, staleness-hint state path | Extend (stage 2) |
| `home/dot_config/shell/aliases.sh.tmpl` | Good quality. Needs `@help` annotations (§4.3) and `mise`/`bun`/`uv` entries | Extend (stage 2) |
| `.github/workflows/ci.yml` | **Broken** — asserts `~/.oh-my-zsh`, uses the removed `machineType` prompt, renders files that no longer exist | Rewrite (stage 9) |
| `Containerfile` | Empty (0 bytes) | Write (stage 9) |
| `README.md` | One line | Write (stage 10) |
| `.editorconfig`, `.gitignore`, `.dockerignore`, `.github/ISSUE_TEMPLATE/` | Fine | Keep |

Nothing on disk is wasted work: `packages.toml` and the two shell files are the
two most tedious artefacts in the repo and both survive largely intact.

**Local toolchain check (this machine):** `docker` daemon reachable, `make` and
`git` present; `chezmoi`, `mise`, `shellcheck`, `shfmt` absent and installed by
stage 0.

---

## 3. Three invariants

Everything below is an application of these. They are what "smart" means in this
repository — not cleverness in any single file, but the property that a fact
appears exactly once and that nothing can silently disagree with it.

### 3.1 One fact, one file, many consumers

No value is written twice. A colour, a tool name, a package name, an alias
description exists in exactly one place, and every other file that needs it is
**generated** from that place at apply time. This is the difference between a
dotfiles repo and a pile of configs that were consistent on the day they were
written.

### 3.2 Compile-time beats runtime

Anything knowable when `chezmoi apply` runs is resolved by the template and never
appears as a shell conditional. Only genuinely per-invocation facts —
`$SSH_TTY`, WSL detection, `$EUID`, nested Zellij, whether a binary is on `PATH`
right now — are runtime checks.

This is not a style preference: it is the mechanism that buys the 60 ms startup
budget (#26, §8.1). A `{{ if eq .toolset "full" }}` block costs nothing at
runtime; the same test as `if [ "$TIER" = full ]` costs a fork on every shell.

### 3.3 Every artefact has a gate

No stage is "done" because the files exist. Each stage below ends with a command
that either exits 0 or does not. If a property cannot be checked by a command, it
is documented as an accepted gap rather than assumed.

---

## 4. The generation graph

### 4.1 Sources of truth

Three data files under `home/.chezmoidata/` are merged into the template context
by chezmoi and are the input to everything else.

| Source | Consumers |
| --- | --- |
| `theme.toml` — Tokyo Night, once, as hex | starship palette · zellij theme · zjstatus format · bat · delta · `FZF_DEFAULT_OPTS` · `EZA_COLORS` · btop · k9s skin · ghostty · alacritty · tokyonight.nvim overrides · lualine |
| `tools.toml` — every tool, with tier and role | `mise/config.toml` · the mise install script's re-run hash · `dotfiles doctor` probe manifest · `dotfiles help` tool section · README inventory table · CI apply assertions |
| `packages.toml` — base OS layer per distro | `run_once_before_00-install-packages` (already true today) |
| `keys.toml` — Zellij and shell keybindings | `zellij/config.kdl` additions · `dotfiles help` multiplexer section |

Changing the theme is one file edit that reaches eleven consumers. Adding a tool
is one table entry that reaches six. Neither can produce a repo that disagrees
with itself, because the disagreement is not representable.

### 4.2 `tools.toml` schema

The schema carries every field any consumer needs, so no consumer needs a lookup
table of its own.

```toml
# Tiers are cumulative: minimal ⊂ standard ⊂ full.
tiers = ["minimal", "standard", "full"]

[[tool]]
name    = "eza"
backend = "aqua:eza-community/eza"   # decision #47 — aqua first for verification
version = "latest"
tier    = "minimal"
group   = "core-cli"
role    = "ls — git status, icons, tree mode"

[[tool]]
name    = "zellij"
backend = "aqua:zellij-org/zellij"
version = "0.43.1"                   # PIN — #20
tier    = "standard"
group   = "multiplexer"
role    = "terminal multiplexer"
pin     = "KDL config format has broken across minor releases"

[[tool]]
name    = "shellcheck"
backend = "aqua:koalaman/shellcheck"
version = "latest"
tier    = "standard"
group   = "lsp"
role    = "shell linter — shared by nvim, pre-commit and CI"
bin     = "shellcheck"               # optional; defaults to `name`
```

`bin` exists because a handful of tools install under a different binary name
(`kubectl` from `aqua:kubernetes/kubectl`, `kubectx`/`kubens` from one package).
`doctor` probes `bin`, not `name`.

The `pin` field is documentation *and* a gate: `make lint` fails if `version` is
not `latest` and `pin` is absent, so nobody freezes a version by accident and
leaves no note saying why.

### 4.3 The `@help` annotation

Decision #37 says `dotfiles help` is generated from the real configuration so it
cannot drift. That is only true if drift is *impossible*, not merely discouraged.

Convention — one line directly above any alias or function definition:

```sh
# @help git: short status with branch and upstream tracking
alias gs='git status -sb'

# @help nav: climb N directory levels — `up 3`
up() { ... }
```

| Step | Mechanism |
| --- | --- |
| Extract | `run_onchange_after_50-build-help` runs a POSIX awk pass over `aliases.sh`, `functions.sh`, `pickers.sh`, pairing each `@help` line with the definition below it |
| Emit | A static TSV at `~/.local/share/dotfiles/help.tsv` — group, name, kind, description, definition |
| Serve | `dotfiles help` pipes the TSV into fzf. No parsing at call time, no cost at shell start |
| **Enforce** | `make lint-help` fails when any alias or function definition has no `@help` above it. An undocumented alias is a build error, not an omission |

Neovim keymaps are not parsed — the editor reports them. `run_onchange_after_35-nvim-sync`
ends with a headless dump of `vim.api.nvim_get_keymap`, filtered to leader-prefixed
maps, appended to the same TSV. The keymap helper used throughout the config
requires a `desc` argument and raises without one, so the dump is complete by
construction.

Zellij's stock modal scheme is unmodified (#42), so its bindings and this repo's
three additions live in `keys.toml` and template into both the KDL and the TSV.

### 4.4 Same binary, four consumers

Decision #45 made operational. `shellcheck`, `shfmt`, `ruff`, `hadolint`,
`stylua` and friends are installed once by mise, and every consumer is pointed at
that one installation:

| Consumer | Wiring |
| --- | --- |
| Shell | mise shims on `PATH` |
| Neovim | `conform.nvim` / `nvim-lint` given bare command names, resolved through the same `PATH` |
| pre-commit | Hooks declared `language: system` — never `language: python`, which would install a second copy at a second version |
| CI | `mise install` before running the same pre-commit hooks |

The failure this prevents is the one the previous revision actually had: ruff
installed by mise for the shell and again by mason for the editor, floating
independently, disagreeing about whether your code is clean.

---

## 5. Code conventions

Every file in the repository obeys these. They are listed once here rather than
restated per stage.

| Convention | Rule |
| --- | --- |
| **Guarded degradation** | Every reference to a non-base tool is `command -v X >/dev/null 2>&1 && …` or behind a tier template branch. A bare reference is a bug — it breaks the bare-server case that justifies the whole layout |
| **POSIX in shared files** | `~/.config/shell/*.sh` is sourced by dash, BusyBox ash, bash and zsh. No arrays, no `[[`, no `local` outside functions, no bashisms. `# shellcheck shell=sh` at the top of each |
| **No output at load** | Nothing under `~/.config/shell/` ever prints. A `.zshenv` that echoes breaks `scp`, `rsync` and `git push` over SSH — the classic dotfiles own-goal |
| **Idempotent scripts** | Every `.chezmoiscripts/` entry is safe to re-run. `run_onchange_` scripts carry an explicit hash header over their real input, e.g. `# tools: {{ include ".chezmoidata/tools.toml" \| sha256sum }}` |
| **Optional means optional** | A failure in fonts, nvim-sync or `chsh` warns and continues. A failure in packages or mise aborts. Each script declares which it is in its header |
| **No unrequested sudo** | Package scripts check whether the package is already present before escalating; nothing else in the repo escalates at all |
| **Template-only conditionals** | Per §3.2. Runtime `if` is reserved for `$SSH_TTY`, WSL, root, nesting and `command -v` |
| **Annotated definitions** | Per §4.3. Enforced by `make lint-help` |
| **Permissions in the name** | chezmoi attributes carry the mode: `private_` for `~/.ssh/config` and anything secret-bearing, `readonly_` where appropriate. Never a `chmod` in a script |
| **Formatting** | `shfmt -i 4 -ci -sr` for shell, `stylua` for Lua, both enforced in `make lint` |

---

## 6. Stages

Ten stages. Each lists what it produces, the integration points that make it
worth doing in that order, and the command that closes it.

### Stage 0 — Verification harness

**Produces:** `Makefile`, `test/fixtures/{workstation-full,server-standard,container-minimal}.toml`,
`test/assert.sh`, `test/sandbox.sh`, `mise.toml` (repo-local dev toolchain).

The fixtures are complete chezmoi config files, so any template can be rendered
against any machine profile without prompting and without docker:

```sh
chezmoi execute-template --source home --config test/fixtures/server-standard.toml < FILE
```

Three fixtures × every `.tmpl` is a full matrix render in under two seconds. That
is the loop every later stage runs on save.

| Target | What it does |
| --- | --- |
| `make render` | Renders every `.tmpl` against all three fixtures; fails on any template error |
| `make lint` | `shellcheck` on rendered scripts · `shfmt -d` · `stylua --check` · TOML/KDL parse · `lint-help` · `tools.toml` pin rule |
| `make sandbox` | `docker run` a bare image, mount the source read-only, `chezmoi init --apply` into a fresh `HOME`, run `test/assert.sh`. Parameterised by `IMAGE`, `PROFILE`, `TIER` |
| `make bench` | `hyperfine 'zsh -ic exit'` inside the sandbox; prints against the 60 ms budget |
| `make check` | `render` + `lint` + generated-artefact freshness (§8) |

**Gate:** `make render` and `make lint` both run to completion against the
current tree, and `make render` *reports the stage-1 drift* — a fixture with no
`multiplexer` key must fail `.chezmoiignore` today. A harness that passes on a
known-broken tree is not a harness.

---

### Stage 1 — Data plane and drift reconciliation

**Produces:** rewritten `home/.chezmoi.toml.tmpl`, rewritten `home/.chezmoiignore`,
extended `home/.chezmoiexternal.toml.tmpl`, new `home/.chezmoidata/theme.toml`,
`tools.toml`, `keys.toml`.

| Change | Decision |
| --- | --- |
| Drop the `multiplexer` prompt and every `tmux` branch | #11 — Zellij only |
| Drop `workEmail`, `config-work`, the conditional include | #35 — one identity |
| Reduce `secretsBackend` to `none` \| `bitwarden` | #16 |
| Rename `machineType` → `profile` consistently; keep auto-detection | #3, existing CI used the old name |
| Add `tier` prompt independent of profile | §3 of `report.md` |
| Add the three Zellij WASM plugins as externals | #12 |
| Populate `tools.toml` with all ~62 tools across three tiers | #7 |

The full tool inventory lands here, in one sitting, from `report.md` §7 — before
any consumer exists. Consumers written against a complete data file are loops;
consumers written against a growing one accumulate special cases.

**Gate:** `make render` green across all three fixtures. `chezmoi init` runs
fully non-interactively with every prompt supplied as a flag (the container image
and CI both depend on this).

---

### Stage 2 — Shared shell layer

**Produces:** `env.sh.tmpl` (extended), `aliases.sh.tmpl` (extended + annotated),
`functions.sh.tmpl`, `interactive.sh.tmpl`, `pickers.sh.tmpl`, `secrets.sh.tmpl`,
and the entry points `dot_zshenv`, `dot_zprofile.tmpl`, `dot_zshrc.tmpl`,
`dot_profile.tmpl`, `dot_bash_profile`, `dot_bashrc.tmpl`.

Integration points that matter here:

- **`interactive.sh` is the parity seam.** Starship, zoxide, fzf, direnv and mise
  init all differ by shell only in one argument. One file with a shell probe
  serves both, which is what makes bash-as-root feel like a plainer home rather
  than a different machine (#26).
- **Deferred loading is ordered explicitly.** `fzf-tab` before the completion
  system's consumers, `fast-syntax-highlighting` last. All six plugins wrapped in
  `zsh-defer`, which is itself the only thing sourced synchronously.
- **`compinit` is cached with a daily rebuild check** — the single largest zsh
  startup cost after plugins.
- **Every alias carries its `@help` line** as it is written. Retrofitting 120
  annotations later is the kind of task that does not get done.

**Gate:** `make sandbox IMAGE=debian:12` — both `zsh -ic exit` and `bash -ic exit`
exit clean with empty stderr. `make bench` under 60 ms. `sh -n` on the rendered
POSIX files under dash.

---

### Stage 3 — Prompt and theme fan-out

**Produces:** `starship.toml.tmpl`, `bat/config.tmpl`, `ripgrep/config`,
`btop/btop.conf.tmpl`, the `FZF_DEFAULT_OPTS` and `EZA_COLORS` blocks in
`env.sh.tmpl`, delta configuration inside the git config.

This stage exists separately from stage 7 for one reason: it is the first proof
that §4.1 works. Six consumers get built against `theme.toml` at once, and the
gate tests the property directly.

**Gate:** change one hex value in `theme.toml`, run `make render`, and confirm
that value propagates to every expected consumer and to no unexpected one —
`make theme-check` diffs rendered output before and after and asserts the
consumer set. Any consumer with a hardcoded colour fails to appear in the diff
and is caught here rather than in six months.

---

### Stage 4 — Bootstrap scripts

**Produces:** `home/.chezmoiscripts/` — `run_once_before_00-install-packages`,
`run_once_before_10-install-mise`, `run_onchange_after_20-mise-install`,
`run_onchange_after_25-zellij-plugins`, `run_onchange_after_30-fonts`,
`run_onchange_after_35-nvim-sync`, `run_once_after_40-default-shell`,
`run_onchange_after_50-build-help`.

The 20/25/35/50 scripts all carry input hashes (§5), so a re-apply that changes
nothing runs nothing. This is what keeps `chezmoi apply` a sub-second operation
in day-to-day use, which is what makes `chezmoi edit --apply` a habit rather than
a chore.

`00-install-packages` gets the accepted-risk treatment from `report.md` §14: it is
written for all five package managers, and proven on two.

**Gate:** `make sandbox` from bare `debian:12` and bare `alpine:3.20`, both from
nothing to a working shell. Then a second `chezmoi apply` in the same container
that reports no changes and executes no scripts.

---

### Stage 5 — Zellij

**Produces:** `zellij/config.kdl.tmpl`, three layouts, zjstatus format string,
session auto-attach in `.zshrc`.

Auto-attach (#13) is the one piece with real blast radius: it is hard-disabled
when `$ZELLIJ` is set, when not a TTY, in containers, and behind a
`ZELLIJ_SKIP` escape hatch. `scp` and `rsync` breaking against a remote host is
the failure mode, and it is only caught by testing non-interactive invocation
explicitly.

**Gate:** `ssh`-shaped non-interactive invocation in the sandbox
(`zsh -c 'echo ok'`) produces exactly `ok`; interactive invocation attaches; a
second interactive invocation reattaches rather than nesting.

---

### Stage 6 — Neovim

**Produces:** `~/.config/nvim/` — ~30 plugins on lazy.nvim, snacks + blink +
lualine, LSP for four stacks, conform/nvim-lint, DAP, the keymap helper with
mandatory `desc`, the OSC52 provider, and `dot_vimrc` as the no-plugin fallback.

Sequenced after stage 4 because `35-nvim-sync` must already exist — a config that
has only ever been loaded interactively usually fails headless, and headless is
how every container and CI run loads it.

**Gate:** `nvim --headless "+Lazy! sync" +qa` exits 0 with no errors; `:checkhealth`
reports no errors in the sandbox; startup under 25 ms via `--startuptime`; the
keymap dump lands in `help.tsv` with every entry carrying a description.

---

### Stage 7 — Configuration leaves

**Produces:** `git/config.tmpl`, `git/ignore`, `git/allowed_signers.tmpl`,
`private_dot_ssh/private_config.tmpl`, `mise/config.toml.tmpl`, the sudo wrapper,
`k9s/`, `ghostty/config.tmpl`, `alacritty/alacritty.toml.tmpl`, `~/.claude/`.

These are leaves — no other stage depends on them, so they can be built in any
order or in parallel. Two carry real constraints: the SSH config must end with
`Include config.d/*` and ship `private_` (0600), and `mise/config.toml.tmpl` is a
pure `range` over `tools.toml` with no hand-written entries whatsoever.

**Gate:** `ssh -G github.com` resolves without error and reports the intended
ciphers; `git config --list` shows one identity and delta as pager;
`mise ls --current` matches the tier's tool list exactly, computed from
`tools.toml` rather than typed into the assertion.

---

### Stage 8 — The `dotfiles` command and entry points

**Produces:** `~/.local/bin/dotfiles` (`update`, `edit`, `diff`, `doctor`,
`bench`, `help`, `portable`), `install.sh`, `portable.sh` + its generator,
staleness-hint state handling.

**`portable.sh` is generated, never written.** `make portable` renders `env.sh`,
`aliases.sh` and `functions.sh` against the `container-minimal` fixture, strips
regions marked `# >>> portable:skip` … `# <<<`, prepends a dependency-free
prompt, and writes the result. It is committed, and CI asserts regeneration
produces no diff (§8). That is what makes "cannot drift from the real config"
(#29) a fact rather than an intention.

`dotfiles doctor` reads the same manifest `tools.toml` produced, so a tool added
to the data file is checked by doctor without doctor being edited.

**Gate:** `curl`-to-shell of `install.sh` in a bare container reaches a working
shell. `dotfiles doctor` exits 0 on a healthy sandbox and non-zero with a precise
message when a tool is deliberately removed. `portable.sh` sourced into a bare
`sh` on an image with none of the tools installed produces no errors.

---

### Stage 9 — CI, container, hooks

**Produces:** rewritten `.github/workflows/ci.yml`, `Containerfile`,
`.devcontainer/devcontainer.json`, `.pre-commit-config.yaml`, `commitlint.config.js`.

CI is minimal per #23 but every job is a `make` target that already runs locally —
no logic exists only in YAML. The freshness gates of §8 are the one addition
beyond `report.md` §14.

**Gate:** the workflow passes on a branch; the built image starts a configured
shell in under two seconds; pre-commit blocks a deliberately staged fake
credential.

---

### Stage 10 — Documentation and end-to-end

**Produces:** `README.md`, `docs/SECRETS.md`, `docs/CUSTOMIZING.md`,
`docs/TROUBLESHOOTING.md`.

The README's tool inventory is generated by `make docs` from `tools.toml` between
marker comments, and CI asserts it is current — the docs cannot describe a tool
set the repo does not install.

**Gate:** a genuinely fresh machine (or fresh container, unprimed cache) from
`curl` to working shell, on the workstation-full and server-standard fixtures,
timed and recorded in the README.

---

## 7. Sequencing

| Stage | Depends on | Parallelisable with | Rough size |
| --- | --- | --- | --- |
| 0 Harness | — | — | 6 files |
| 1 Data plane | 0 | — | 6 files |
| 2 Shell layer | 1 | — | 12 files |
| 3 Theme fan-out | 1, 2 | — | 6 files |
| 4 Bootstrap | 1 | 3 | 8 files |
| 5 Zellij | 3, 4 | 6, 7 | 5 files |
| 6 Neovim | 4 | 5, 7 | ~20 files |
| 7 Leaves | 3 | 5, 6 | ~14 files |
| 8 `dotfiles` + install | 2, 4, 7 | — | 5 files |
| 9 CI + container | 8 | — | 5 files |
| 10 Docs | 9 | — | 4 files |

Critical path: **0 → 1 → 2 → 4 → 8 → 9 → 10.** Stages 3, 5, 6 and 7 hang off it
and can be reordered freely. Stage 6 is the largest single body of work and
depends only on stage 4, so it can start early and run alongside everything after
it.

---

## 8. Anti-drift gates

Four generated artefacts are committed to the repository. Each has a CI job that
regenerates it and fails on any diff — the standard `make X && git diff --exit-code`
pattern. Without these, generation is a convention that decays; with them, it is
enforced.

| Artefact | Generated from | Gate |
| --- | --- | --- |
| `portable.sh` | The shared shell layer | `make portable && git diff --exit-code` |
| README tool inventory | `tools.toml` | `make docs && git diff --exit-code` |
| `help.tsv` completeness | `@help` annotations + nvim keymap dump | `make lint-help` — undocumented definition fails |
| Theme consumer set | `theme.toml` | `make theme-check` — a hardcoded colour fails |

---

## 9. Risks specific to this build order

`report.md` §16 covers the design risks. These are the ones the *procedure*
introduces.

| Risk | Mitigation |
| --- | --- |
| Stage 1 rewrites files that stages 2–3 already assumed | Stage 1 is deliberately first and lands complete. No stage may add a prompt or data key after its stage |
| The three fixtures pass while a real fourth combination breaks | Fixtures cover the three shipped profiles at their default tiers. Off-diagonal combinations (server + full, workstation + minimal) are rendered but not sandboxed — accepted, consistent with #23 |
| Docker sandbox diverges from a real VM (systemd, non-root, real `chsh`) | `chsh` and the default-shell script are the known gap; the script warns rather than aborting, so a sandbox pass does not certify that path |
| Generated `portable.sh` silently loses a feature when a `portable:skip` marker is misplaced | The gate catches unregenerated output, not wrong output. Stage 8 adds a smoke test that sources it and asserts a named set of aliases exists |
| Neovim pin (#20) drifts from the mason/lazy plugin set over time | `35-nvim-sync` fails loudly on a `Lazy! sync` error rather than leaving a half-synced config |
| `mise` unavailable for the aqua backend on musl | Stage 4's Alpine gate catches it at build time, which is precisely why Alpine is in the gate and not only in CI |

---

## 10. Build outcome

Recorded after execution. Measured numbers, not targets.

### 10.1 Gates, as built

The plan called for four anti-drift gates (§8). Seven exist, because three
defect classes turned up during the build that static checks could not see.

| Gate | `make` target | Catches |
| --- | --- | --- |
| Render matrix + schema agreement | `render` | A template that breaks on one profile; fixtures drifting from the real prompt schema |
| Lint | `lint` | shellcheck on rendered output, `zsh -n`/`bash -n`/`dash -n`, shfmt, stylua, taplo |
| Help completeness | `lint-help` | An alias or function unreachable from `dotfiles help` |
| Theme fan-out | `theme-check` | A config with hardcoded colours, or an undeclared consumer |
| **Glyph integrity** | `lint` | *(new)* An icon assignment that is an empty string |
| **Backend resolution** | `verify-tools` | *(new)* A `tools.toml` entry no backend can resolve, or a pin that no longer exists |
| **External reachability** | `verify-externals` | *(new)* A dead download URL |
| **KDL parse** | `verify-zellij` | *(new)* Config or layout the real Zellij rejects |
| **Portable behaviour** | `verify-portable` | *(new)* `portable.sh` that is current but does not work |

The last one exists because the freshness gate the plan specified — regenerate
and diff — catches *stale* output and is blind to *wrong* output. That
distinction stopped being theoretical (§10.3).

### 10.2 Measured

| Property | Target | Measured |
| --- | --- | --- |
| Interactive zsh startup | < 60 ms | **~20 ms marginal** (70.9 ms total against a 51 ms bare-shell floor in this environment) |
| Neovim startup | ~25 ms | **30.6 ms total**, of which 11.5 ms is `nvim --clean` here — over target |
| Templates rendered | — | 37 templates × 4 fixtures |
| Tool backends verified | — | 71/71 resolve; both pins exist upstream |
| External URLs verified | — | 11/11 reachable |
| Theme consumers | 11 declared | **12 live, 0 pending** |
| Help index | — | 213 entries: 87 aliases, 55 keymaps, 40 tools, 18 functions, 13 keybindings |
| `portable.sh` | — | 545 lines, 53 aliases and 14 functions on a bare Debian |

Neovim's 30.6 ms is above the 25 ms target and is reported as measured rather
than adjusted. Most of the gap is `require('config.lazy')` at 18.5 ms, which is
lazy.nvim plus the three plugins that cannot be lazy-loaded (colourscheme,
snacks, lualine). Reducing it means loading fewer plugins at startup, not
configuring them differently.

### 10.3 Defects found by running things

Every one of these passed template rendering, shellcheck and review. They were
found only by executing the result, which is the argument for stage 0.

| Defect | Found by | Now guarded by |
| --- | --- | --- |
| `--promptString` keys on the **prompt text**, not the data key — so every unattended install silently prompted and hung | Running `chezmoi init` non-interactively | `render`'s schema step, plus a targeted hint on failure |
| Nerd Font glyphs written as raw bytes became **empty strings**; a zero-length `fillchars` stops Neovim starting at all | Headless Neovim run | `lint` glyph integrity; codepoints now written as `\u{...}` / `\UXXXXXXXX` escapes |
| Generated help script double-quoted a description containing `` `room` `` — **shell command substitution in generated data** | Sandbox run printing `room: not found` | Replaced `printf` lines with a quoted heredoc |
| `env.sh`'s trailing `return 0` ended the whole concatenated `portable.sh`, which shipped defining **zero aliases** | Sourcing it in a container | `verify-portable` |
| Neovim sync reported success while the editor was erroring — `nvim --headless` exits 0 on a config throw | Comparing sync output to a manual run | Output inspection, narrowly matched after stripping ANSI |
| `dotfiles doctor` reported `win32yank` missing on every non-WSL machine | Running `doctor` | `when` filtering, shared with the mise config template |
| `dotfiles help <term>` matched everything — an awk filter concatenated fields instead of testing them | Running `dotfiles help git` | — |
| `win32yank` has no aqua registry entry | `verify-tools` | The documented `github` fallback (#47) |

### 10.4 Accepted limitations

Beyond those already in `report.md` §16:

1. **Buffer-local Neovim keymaps are absent from `dotfiles help`.**
   `nvim_get_keymap` returns global maps only. gitsigns' `<leader>g` bindings
   and all LSP bindings are registered by an `on_attach` that does not fire in a
   headless Neovim — verified: gitsigns attaches (`b:gitsigns_head` is set) and
   `on_attach` is never called. Attempted and removed rather than left as
   machinery that returns nothing. Documented in `docs/CUSTOMIZING.md`.
2. **`report.md` §6 phase 5 (a Zellij plugin script) does not exist.** The four
   WASM plugins are chezmoi externals, which is declarative, cached and
   refresh-aware. An imperative download script would be strictly worse.
3. **Neovim startup is over target** — see §10.2.
4. **The `full` tier on musl is unproven.** Alpine runs at `minimal` in CI,
   consistent with decision #23.

---

## 11. Open items carried forward

Unchanged from `report.md` §17 and not resolved by this plan:

1. Zellij WASM plugin pinning — left floating.
2. Per-host overrides deferred (#33).
3. No backup on install (#38) — the sharpest edge, and worth a decision before
   the first apply on a machine with configuration you care about. Stage 8 is
   where a `--backup` flag would go if that decision changes.
