# Dotfiles — Design Report

**Repository:** `github.com/Satcomx00-x00/dotfiles` (public)
**Date:** 2026-07-24
**Status:** Plan — awaiting approval before implementation

---

## 1. Context

The goal is a single dotfiles repository producing an identical shell and
environment on every machine you touch: Linux servers, ephemeral dev containers
and Codespaces, and WSL2 on Windows. One command on a fresh box should yield a
fully configured, fully tooled shell.

A previous version existed and was wiped in commit `5796fbd` ("chore: reset").
It is recoverable at `7f01ba9` and was already a competent chezmoi setup. This
plan keeps its good bones — chezmoi, templated per-machine config, mise for
tooling, a multi-distro CI job — and fixes its four real weaknesses:

| Weakness in the old setup | Fix |
| --- | --- |
| Oh My Zsh cost ~400 ms on every shell start | No framework; plugins lazy-loaded with `zsh-defer` (~50 ms target) |
| Powerlevel10k is zsh-only, so bash and root shells shared nothing | Starship: one prompt across zsh and bash |
| Secrets support was written, then left commented out | Bitwarden backend wired end to end |
| Only shell and git were managed | Adds editor, multiplexer, SSH, terminals, AI tooling, cloud/k8s |

The current `.github/workflows/ci.yml` still references the deleted layout, so it
is broken today and gets rewritten as part of this work.

---

## 2. Decision record

Every decision below was explicitly confirmed. This table is the contract; the
rest of the document elaborates on it.

| # | Area | Decision |
| --- | --- | --- |
| 1 | Dotfiles manager | **chezmoi** |
| 2 | Shell framework | **None** — plugins lazy-loaded via `zsh-defer` |
| 3 | Prompt | **Starship**, shared by zsh and bash |
| 4 | Primary shell | **zsh**, with full-parity bash fallback |
| 5 | Tool installation | **mise** for tools and runtimes; OS packages for the base layer only |
| 6 | Platforms | Linux servers (deb/rpm/apk), dev containers and Codespaces, WSL2 |
| 7 | Shell history | **Plain zsh history + fzf** — no Atuin, no daemon, no sync server |
| 8 | Theme | **Tokyo Night**, enforced across every tool |
| 9 | Terminal emulators managed | **Alacritty** and **Ghostty** |
| 10 | Font | **JetBrainsMono Nerd Font** (workstations only) |
| 11 | Multiplexer | **Zellij only** — no tmux, no fallback |
| 12 | Zellij plugins | **zjstatus**, **vim-zellij-navigator + autolock**, **room** |
| 13 | Zellij sessions | **Auto-attach per host**, named after the hostname |
| 14 | Editor | **Hand-rolled Neovim on lazy.nvim** |
| 15 | Language support | **All four stacks**: shell/Docker/Make, Python/Go/Rust, TypeScript/web, Terraform/YAML/K8s/Ansible |
| 16 | Secrets backend | **Bitwarden CLI** (`bw`), Vaultwarden-compatible |
| 17 | SSH client | **Performance + hardening**; no jump-host templates, no Mosh |
| 18 | Ops toolkit | **Disk and files only** — ncdu, dust, duf, fclones |
| 19 | Security posture | **gitleaks + pre-commit** only |
| 20 | Version pinning | **Float everything**, except Zellij and Neovim which are pinned exactly |
| 21 | Shell behaviours | Transient prompt + timing, smart `cd`, command-not-found installer |
| 22 | Commit convention | **Conventional Commits** enforced by hook; no changelog or release automation |
| 23 | CI depth | **Minimal** — lint plus a single Ubuntu apply |
| 24 | Clipboard | **OSC52 everywhere** |
| 25 | Login output | **Nothing** — instant prompt; `sysinfo` on demand |
| 26 | Bash fallback | **Full parity** where bash permits |
| 27 | Root shells | **Environment preserved through sudo**; nothing installed into `/root` |
| 28 | AI tooling | **Claude Code config + MCP server list** managed |
| 29 | Ephemeral hosts | **Single-file portable rc**, generated from the same source |
| 30 | Repository visibility | **Public**, with identifying metadata split into private/local files |
| 31 | zsh keybindings | **Emacs mode** — vim keys stay inside Neovim |
| 32 | Neovim core stack | **snacks.nvim picker + blink.cmp + lualine** |
| 33 | Per-host overrides | **Deferred** — not in the first version |
| 34 | Update cadence | **Manual only**, with a staleness hint after 7 days |
| 35 | Git identity | **Single identity everywhere** — no work/personal split |
| 36 | Container image | **Full toolchain pre-baked** |
| 37 | Discoverability | **A `dotfiles help` command**, generated from the real config |
| 38 | Backup / uninstall | **Neither** — git is the rollback |
| 39 | Package managers | **bun** for Node, **uv** for Python |
| 40 | Shell pickers | **Core** (files, history, dirs) + **Infra** (containers, pods, contexts, SSH hosts) |
| 41 | WSL2 clipboard | **OSC52 + WSL bridge** — `win32yank` / `clip.exe` / `wslview`, inert outside WSL |
| 42 | Zellij keybindings | **Default modal scheme** — Ctrl-p/t/n/o, lock mode, unmodified |
| 43 | Neovim keymap | **Space leader, mnemonic namespaces** — f/g/c/s/b/x/u |
| 44 | Prompt layout | **Two-line with a right-side prompt** |
| 45 | Language tooling source | **mise for anything with a CLI**; mason.nvim only for DAP adapters |
| 46 | Tool consolidation | **Keep direnv and just** — mise's built-in equivalents not adopted |
| 47 | mise backend order | **aqua first, github fallback** — free cryptographic verification |

### Rejected alternatives

| Rejected | Reason |
| --- | --- |
| GNU Stow | Symlinks only; no templating, so per-machine differences need branches |
| Nix / home-manager | Best reproducibility available, disproportionate learning curve and footprint here |
| yadm | Comparable to chezmoi, smaller community, weaker cross-platform placement |
| Oh My Zsh | ~400 ms startup, low maintenance activity |
| Powerlevel10k | Faster and deeper than Starship, but zsh-only — conflicts with the universality goal |
| asdf | mise is a faster reimplementation reading the same version files |
| tmux | Zellij chosen outright; carrying two multiplexers means two keymaps |
| Atuin | Rejected in favour of a zero-dependency history file |
| telescope, nvim-cmp | Superseded by snacks.nvim and blink.cmp on speed and plugin count |
| vi-mode in the shell | Emacs bindings transfer to every machine on earth; modal editing stays in the editor |
| which-key, tldr, navi | Discoverability handled by one generated `dotfiles help` command instead |

---

## 3. Machine profiles

One prompt at first install selects a profile. It is auto-detected — Codespaces
and `/.dockerenv` imply container, absent `DISPLAY` implies server — and can be
overridden. The profile drives every conditional in the repo.

| Behaviour | `workstation` | `server` | `container` |
| --- | --- | --- | --- |
| Nerd Font installed | Yes | No | No |
| Terminal emulator configs applied | Yes | No | No |
| Zellij auto-attach on login | Yes | Yes | No |
| Change default shell to zsh | Yes | Yes | No — image sets it |
| Default tool tier | `full` | `standard` | `standard` |
| Node heap default | 8 GB | 2 GB | 2 GB |
| Bitwarden integration active | Yes | Optional | No |
| Staleness hint shown | Yes | Yes | No |

A second prompt selects the **tool tier** — `minimal`, `standard` or `full` —
independently of profile, so a constrained VPS can be a `server` on `minimal`.

Because of decision #35 there is **no work/personal identity prompt**: one name,
one email, one signing key, everywhere.

---

## 4. Public repository, private metadata

Decision #30. The repo is public and shareable; nothing in it identifies your
infrastructure. The split is enforced by design, not by discipline.

| Stays in the public repo | Lives outside it |
| --- | --- |
| All shell, editor, multiplexer and tool configuration | Server hostnames and SSH host entries |
| All bootstrap and installation logic | Bitwarden vault and item names |
| The theme palette, keymaps, aliases, functions | Any internal domain or IP |
| Documentation and CI | Machine-specific PATH or env additions |

Mechanism:

| File | Role |
| --- | --- |
| `~/.ssh/config` | Managed, generic: crypto, multiplexing, hardening. Ends with an include of `config.d/` |
| `~/.ssh/config.d/*` | **Not managed.** Your actual hosts. Never committed |
| `~/.config/shell/local.sh` | **Not managed.** Machine-local env, PATH, aliases. Sourced last by every shell |
| `~/.config/shell/secrets.sh` | Generated from Bitwarden at apply time; item names come from local config, not the repo |

The result is a repo you can link to publicly without it being a map of your
estate.

---

## 5. Repository layout

Files under `home/` are the chezmoi source. Everything else is repo
infrastructure and never lands on a machine.

| Path | Purpose |
| --- | --- |
| `.chezmoiroot` | Points chezmoi at `home/`, keeping repo tooling out of the source tree |
| `install.sh` | One-command bootstrap; the only thing a fresh machine curls |
| `portable.sh` | Generated single-file rc for throwaway hosts (see §12) |
| `Makefile` | Local entry points: install, update, lint, test, container, doctor, portable |
| `report.md` | This document |
| `README.md` | Quick start, tool inventory, day-2 operations |
| `docs/SECRETS.md` | Bitwarden and Vaultwarden setup |
| `docs/CUSTOMIZING.md` | Adding a tool, an alias, a profile, a language |
| `docs/TROUBLESHOOTING.md` | Known failures per distro |
| `Containerfile` | Image with the full standard-tier toolchain pre-baked |
| `.devcontainer/devcontainer.json` | Codespaces and VS Code entry point |
| `.github/workflows/ci.yml` | Lint plus a single end-to-end Ubuntu apply |
| `.pre-commit-config.yaml` | shellcheck, shfmt, gitleaks, commitlint, template render |

### chezmoi source tree

| Path | Purpose |
| --- | --- |
| `home/.chezmoi.toml.tmpl` | First-run prompts; answers persist and are never re-asked |
| `home/.chezmoidata/packages.toml` | Per-distro base package lists |
| `home/.chezmoidata/tools.toml` | Tool inventory per tier — single source of truth for mise config, `dotfiles help`, docs and CI |
| `home/.chezmoidata/theme.toml` | Tokyo Night palette — single source of truth for every themed config |
| `home/.chezmoiexternal.toml.tmpl` | zsh plugins, Zellij WASM plugins, font |
| `home/.chezmoiignore` | Per-machine exclusions, evaluated as a template |
| `home/.chezmoiscripts/` | Ordered, idempotent bootstrap scripts |

The two data files matter more than they look. `theme.toml` means Tokyo Night is
defined once as hex values and templated into eleven consumers — changing theme
later is a one-file edit. `tools.toml` means the tool list, the mise config, the
`dotfiles help` output and the docs can never disagree with each other.

---

## 6. Bootstrap flow

A single command on a fresh machine runs these phases in order. Each script is
idempotent, and either `run_once` or `run_onchange` (re-runs only when its
inputs change).

| Phase | Script | What happens |
| --- | --- | --- |
| 0 | `install.sh` | Detects OS and architecture, installs chezmoi to `~/.local/bin`, clones the repo, hands off to `chezmoi init --apply` |
| 1 | `run_once_before_00-install-packages` | Detects apt/apk/dnf/pacman/zypper and installs the base layer only |
| 2 | `run_once_before_10-install-mise` | Installs mise |
| 3 | — | chezmoi writes all config files and fetches externals |
| 4 | `run_onchange_after_20-mise-install` | Installs every tool in the selected tier; re-runs only when the tool list changes |
| 5 | `run_onchange_after_25-zellij-plugins` | Fetches the three WASM plugins |
| 6 | `run_onchange_after_30-fonts` | Rebuilds the font cache; skipped on headless machines |
| 7 | `run_onchange_after_35-nvim-sync` | Headless Neovim plugin and LSP sync so first real launch is instant |
| 8 | `run_once_after_40-default-shell` | Changes login shell to zsh where permitted; skipped in containers |

Constraints applied throughout: no `sudo` prompt unless a package genuinely
needs installing, every phase safe to re-run, and a failure in an optional phase
warns rather than aborting.

**Note on decision #38:** the installer does not back up pre-existing dotfiles.
On a machine that already has a `~/.zshrc`, that file is replaced. See §16.

---

## 7. Tools installed

Tier legend: **m** = minimal, **s** = standard, **f** = full. Everything floats
to `latest` except the two pinned entries, marked **PIN**.

### 7.1 Base OS layer — system package manager

Deliberately small: only what mise cannot bootstrap, plus build dependencies.
Defined per distro for apt, apk, dnf, pacman and zypper.

| Category | Packages |
| --- | --- |
| Shell | zsh; bash on Alpine (BusyBox `sh` is insufficient) |
| VCS and fetch | git, curl, wget, ca-certificates, gnupg |
| Archives | unzip, tar, gzip, xz |
| Build | build-essential / base-devel / gcc + make |
| System | procps, file, less, coreutils, shadow (`chsh` on Alpine), gcompat (glibc shim for musl) |
| Locale and fonts | locales / glibc-langpack-en, fontconfig |
| Remote | openssh-client |

### 7.2 Shell and prompt

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| starship | Prompt for zsh and bash | m | mise |
| zsh-defer | Defers plugin loading past the first prompt | m | external |
| zsh-autosuggestions | Inline suggestion from history | m | external |
| fast-syntax-highlighting | Command-line colouring, faster than the classic plugin | m | external |
| zsh-completions | Additional completion definitions | m | external |
| zsh-history-substring-search | Up-arrow searches what you have typed | m | external |
| fzf-tab | Replaces the completion menu with an fzf picker plus previews | m | external |
| JetBrainsMono Nerd Font | Prompt glyphs and file icons | workstation | external |

### 7.3 Core CLI replacements

| Tool | Replaces | Tier |
| --- | --- | --- |
| eza | `ls` — git status, icons, tree mode | m |
| bat | `cat` — syntax highlighting, paging, man pages | m |
| fd | `find` — sane defaults, respects gitignore | m |
| ripgrep | `grep -r` | m |
| fzf | Fuzzy finder; drives history, files, completion menu, all pickers | m |
| zoxide | `cd` — frecency-ranked jumps | m |
| jq / yq | JSON and YAML/XML/TOML processing | m |
| delta | git diff pager, side-by-side, syntax highlighted | m |
| sd | `sed` for simple substitution | s |
| hyperfine | Command benchmarking | s |

### 7.4 Disk, files and system

| Tool | Replaces | Tier |
| --- | --- | --- |
| btop | `top` / `htop` | s |
| ncdu | Interactive disk usage explorer | s |
| dust | `du` — visual size tree | s |
| duf | `df` — readable filesystem overview | s |
| fclones | Duplicate file detection and removal | s |

### 7.5 Git

| Tool | Role | Tier |
| --- | --- | --- |
| lazygit | Terminal git UI | s |
| gh | GitHub CLI | s |
| git-lfs | Large file support | s |
| gitleaks | Secret scanning, pre-commit hook and CI | s |

### 7.6 Runtimes and package managers

Decision #39. Per-project `.tool-versions` or `mise.toml` always wins over these
global defaults.

| Tool | Role | Tier |
| --- | --- | --- |
| bun | **Default Node package manager and runtime** — install, run, bundle and test in one binary | s |
| node | Runtime, for tooling that requires real Node rather than bun | s |
| uv | **Default Python toolchain** — replaces pip, pipx, venv, poetry and pyenv | s |
| python | Interpreter, managed by mise and consumed by uv | s |
| go, rust | Additional runtimes | f |

`npm`, `pnpm` and `pip` remain available for projects that demand them; only the
defaults and the aliases change.

### 7.7 Editor and language tooling

Decision #32.

| Component | Choice | Why |
| --- | --- | --- |
| Plugin manager | lazy.nvim | Hand-rolled, everything lazy-loaded |
| Picker | snacks.nvim | Faster than telescope, and bundles ~20 quality-of-life modules from one dependency |
| Completion | blink.cmp | Rust-backed, sub-millisecond, replaces nvim-cmp plus five source plugins |
| Statusline | lualine | Tokyo Night themed |
| Neovim itself | **PIN** | Lua API churn across 0.10/0.11/0.12 |

Roughly 30 plugins, ~25 ms startup target.

| Area | Plugins and configuration |
| --- | --- |
| Core | Options, keymaps, autocmds, lazy.nvim bootstrap |
| LSP | `nvim-lspconfig` + `mason.nvim`, automatic server installation for all four stacks |
| Syntax | `nvim-treesitter` with incremental selection and textobjects |
| Navigation | snacks.nvim picker for files, grep, symbols, diagnostics; file explorer; `flash.nvim` motions |
| Git | `gitsigns.nvim` hunks and blame; lazygit in a floating terminal |
| UI | `tokyonight.nvim`, lualine, snacks notifier and dashboard |
| Editing | Autopairs, surround, comment, multi-cursor, indent guides |
| Format and lint | `conform.nvim` and `nvim-lint`, wired to the same shellcheck/shfmt/ruff binaries the shell uses |
| Debug | `nvim-dap` with adapters for Python, Go and Rust |
| Integration | `vim-zellij-navigator` counterpart for Ctrl-hjkl across the editor/multiplexer boundary; OSC52 clipboard provider |

**Where language tooling comes from (decision #45).** The split is by whether a
tool has meaning outside the editor. Anything with a CLI comes from mise, so a
single binary serves Neovim, the shell, the pre-commit hook and CI — they can
never disagree about whether your code is clean. Only editor-only components
stay in mason.

| Source | Tools |
| --- | --- |
| **mise** — one binary, four consumers | shellcheck, shfmt, hadolint, ruff, basedpyright, gopls, golangci-lint, gofumpt, rust-analyzer, clippy, rustfmt, vtsls, eslint, biome, terraform-ls, tflint, yamllint, yaml-language-server, ansible-lint, ansible-language-server, helm-ls, bash-language-server, dockerfile-language-server, tailwindcss-language-server |
| **mason.nvim** — no CLI meaning | codelldb, debugpy, delve, and any adapter that only exists to serve `nvim-dap` |

Per stack, this yields:

| Stack | Coverage |
| --- | --- |
| Shell / Docker / Make | bash-language-server, shellcheck, shfmt, hadolint, dockerfile-language-server, docker-compose-language-service, systemd-language-server |
| Python | basedpyright, ruff (lint + format), debugpy |
| Go | gopls, golangci-lint, gofumpt, delve |
| Rust | rust-analyzer, clippy, rustfmt, codelldb |
| TypeScript / web | vtsls, eslint, biome, tailwindcss-language-server, html/cssls/jsonls, emmet |
| Terraform | terraform-ls, tflint |
| YAML / Kubernetes | yaml-language-server with SchemaStore and Kubernetes schema validation |
| Ansible | ansible-language-server, ansible-lint |
| Helm | helm-ls |

This corrects a genuine defect in the earlier revision of this plan, where
shellcheck, shfmt and ruff were installed twice — once by mise for the shell and
again by mason for the editor — at two independently floating versions.

**Keymap (decision #43): Space leader with mnemonic namespaces.** With which-key
declined, the *structure* has to carry discoverability — so every binding lives
under a letter that names its domain, consistently enough that you can guess
bindings you have never used.

| Namespace | Domain | Examples |
| --- | --- | --- |
| `<leader>f` | Files | find, grep, recent, browse |
| `<leader>g` | Git | status, blame, diff, hunks, lazygit |
| `<leader>c` | Code | action, rename, format, references |
| `<leader>s` | Search | symbols, diagnostics, help, keymaps |
| `<leader>b` | Buffers | switch, close, close others |
| `<leader>x` | Diagnostics | list, next, previous, quickfix |
| `<leader>u` | Toggles | wrap, numbers, diagnostics, spell |
| `<leader>d` | Debug | breakpoint, continue, step, UI |

The payoff is that "git blame" is almost certainly `<leader>gb` without looking
it up, and `dotfiles help` covers the rest from outside the editor.

`~/.vimrc` ships separately: deliberately minimal, no plugins, so a box with only
stock `vim` or `vi` is still comfortable. The Neovim config is skipped entirely
on `minimal` machines.

### 7.8 Multiplexer

| Tool | Role | Tier |
| --- | --- | --- |
| zellij | The multiplexer — **PIN** (KDL format has broken across minor releases) | s |
| zjstatus | Single-line configurable status bar, Tokyo Night themed | s |
| vim-zellij-navigator | Unified Ctrl-hjkl across Neovim splits and Zellij panes | s |
| zellij-autolock | Auto-locks Zellij when Neovim has focus so vim binds are never stolen | s |
| room | Fuzzy session and project switcher on one keybind | s |

### 7.9 Containers

| Tool | Role | Tier |
| --- | --- | --- |
| lazydocker | Terminal Docker UI | s |
| dive | Image layer and waste inspection | f |
| trivy | Container and filesystem vulnerability scanning | f |

The Docker engine itself is **not** installed — client tooling and aliases only.

### 7.10 Kubernetes

| Tool | Role | Tier |
| --- | --- | --- |
| kubectl | Cluster CLI | f |
| k9s | Terminal cluster UI, Tokyo Night skinned | f |
| helm | Chart management | f |
| kubectx / kubens | Context and namespace switching | f |
| kustomize | Manifest overlays | f |
| stern | Multi-pod log tailing | f |

### 7.11 Infrastructure and cloud

| Tool | Role | Tier |
| --- | --- | --- |
| terraform | Infrastructure as code | f |
| opentofu | Terraform fork, installed alongside | f |
| awscli | AWS CLI v2 | f |
| ansible | Configuration management — retained because you selected Ansible LSP support | f |

### 7.12 Secrets

| Tool | Role | Tier |
| --- | --- | --- |
| bw | Bitwarden CLI — resolves secrets at apply time | s |
| age | File encryption primitive | s |
| sops | Encrypted config files | f |

### 7.13 Workflow

| Tool | Role | Tier |
| --- | --- | --- |
| direnv | Per-directory environment loading | s |
| just | Project command runner | s |
| chezmoi | The dotfiles manager itself | m |
| win32yank, wslu | WSL2 clipboard bridge and `wslview` — installed only when WSL is detected | s (WSL only) |

Decision #46: mise could replace both direnv and `just` — its `[env]` covers most
per-directory environment loading, and it ships a task runner — but both are
kept. direnv handles arbitrary shell logic in `.envrc` that declarative env
cannot, and `just` is more widely recognised by anyone else reading a project.

### 7.14 Terminal emulators

**Config only** — these are GUI applications you install yourself. The repo
manages their configuration, themed to Tokyo Night and pointed at JetBrainsMono
Nerd Font. Applied on `workstation` profiles only.

| Tool | Notes |
| --- | --- |
| Ghostty | Primary. Native, GPU-accelerated, excellent defaults, OSC52 support |
| Alacritty | Secondary. Minimal and fast; you already had a config in an earlier commit |

**Approximate totals:** `minimal` ≈ 16 tools, `standard` ≈ 45, `full` ≈ 62.

---

## 8. Configurations managed

### 8.1 Shell — layered for bash/zsh parity

All portable configuration lives in POSIX files under `~/.config/shell/`,
sourced by both shells. Only genuinely shell-specific behaviour lives in
`.zshrc` or `.bashrc`. This layering delivers decision #26: landing in bash as
root feels like a plainer version of home, not a different machine.

| File | Loaded by | Contents |
| --- | --- | --- |
| `~/.config/shell/env.sh` | Every shell, including scripts | XDG directories, PATH with de-duplication, locale, editor and pager fallback chain, XDG relocation of tool state (npm, bun, python, gnupg, docker, aws, terraform, rustup), profile-dependent settings, WSL2 detection and interop PATH cleanup |
| `~/.config/shell/aliases.sh` | Interactive shells | Navigation, listing, safety rails, git, docker, kubernetes, terraform, chezmoi. Every alias depending on a modern tool is guarded so it degrades cleanly on a bare server |
| `~/.config/shell/functions.sh` | Interactive shells | Extract-any-archive, mkdir-and-cd, `up N`, directory bookmarks, `sysinfo`, backup-file, port lookup |
| `~/.config/shell/pickers.sh` | Interactive shells | The fzf pickers of decision #40 (see §8.4) |
| `~/.config/shell/interactive.sh` | Interactive shells | Starship, zoxide, fzf, direnv and mise init — each guarded and shell-detected so one file serves both shells |
| `~/.config/shell/secrets.sh` | Interactive shells, Bitwarden configured only | Tokens resolved from the vault at apply time |
| `~/.config/shell/local.sh` | Every shell | **Not managed.** Machine-local overrides, never committed |

| Entry point | Role |
| --- | --- |
| `~/.zshenv` | Sources `env.sh`; runs for every zsh invocation |
| `~/.zprofile` | Login shells; wires mise shims so cron and IDEs see managed tools |
| `~/.zshrc` | Interactive zsh: history, options, keybindings, completion styling, deferred plugins, shared layer, Zellij auto-attach |
| `~/.profile` | Sources `env.sh` for bash and any POSIX login shell |
| `~/.bash_profile` | Sources `~/.profile` then `~/.bashrc` |
| `~/.bashrc` | Interactive bash: history, shell options, shared layer, Starship, fzf keybindings, zoxide |

**Startup budget:** under 60 ms for interactive zsh.

**Keybindings (decision #31): emacs mode.** Ctrl-a/e/w/u/k/r behave identically
here, on a stock server, in bash, and in every REPL. No mode indicator, no ESC
timeout tuning, no mode confusion. Modal editing stays inside Neovim, where it
belongs.

zsh specifics: 100k-entry history with de-duplication and timestamps, shared
across sessions, lines beginning with a space never recorded; `AUTO_CD` and the
directory stack; case-insensitive and partial-word completion matching; a
completion cache rebuilt at most once daily; fzf-tab previews for directories,
git objects, environment variables and processes.

### 8.2 Shell behaviours

Decision #21 — the parts that make the config feel bespoke rather than
assembled.

| Behaviour | What it does |
| --- | --- |
| **Transient prompt** | Once a command is submitted, its prompt collapses to a single minimal marker. Scrollback stays clean; only the live prompt is full-width |
| **Command timing** | Commands exceeding a threshold print their duration. Zero cost below it |
| **Auto-`ls` on `cd`** | Entering a directory lists it — suppressed above a file-count limit so `/usr/bin` does not flood the screen |
| **Directory bookmarks** | Named jump targets, tab-completable, stored in a plain editable file |
| **`up N`** | Climb N directory levels in one word |
| **zoxide-backed `cd`** | Normal `cd` behaviour plus frecency jumps, so `cd dot` reaches this repo from anywhere |
| **Command-not-found installer** | A missing command prints the exact `mise use` or package-manager command to obtain it, and offers to run it |
| **Staleness hint** | Decision #34. After 7 days without an update, a subtle line appears once per day showing how many commits behind you are. A local file-timestamp check — no network call on shell start |

### 8.3 Discoverability — `dotfiles help`

Decision #37. One command, generated from the actual configuration, so it can
never drift from reality.

| Aspect | Behaviour |
| --- | --- |
| Source | Parsed from `aliases.sh`, `functions.sh`, `pickers.sh`, the Zellij keybindings and the Neovim keymaps at build time |
| Output | Grouped by domain — navigation, git, docker, kubernetes, pickers, multiplexer, editor — with the binding, the command and a one-line description |
| Search | Pipes into fzf, so you fuzzy-search your own config and see the matching entry |
| Coverage | Every alias, function, picker and keybinding this repo defines, across all three keymaps |

This replaces which-key, tldr and navi, all of which were considered and
declined. §16 notes the trade-off.

### 8.4 fzf pickers

Decision #40. Bound in both zsh and bash, themed to Tokyo Night.

| Group | Pickers |
| --- | --- |
| **Core** | Files with a bat preview; history search; directory jump with an eza preview |
| **Infra** | Docker container to exec into or tail; Kubernetes pod to log or shell into; kube context and namespace switch; SSH host picked from your config |

Git pickers and process/port killers were offered and declined.

### 8.5 Theming — Tokyo Night everywhere

The palette lives once in `home/.chezmoidata/theme.toml` and is templated into
every consumer. No tool keeps its own hardcoded colours.

| Consumer | How it is themed |
| --- | --- |
| Starship | Palette definition, per-module colours |
| Zellij + zjstatus | Theme block and status-bar format string |
| Neovim | `tokyonight.nvim` with matched lualine and picker highlights |
| bat, delta | Shared syntax theme, so `cat` and `git diff` agree |
| fzf | `--color` flags exported from the palette; every picker matches |
| eza | `EZA_COLORS` derived from the palette |
| btop, k9s | Generated theme files |
| Ghostty, Alacritty | Full 16-colour palette plus cursor and selection colours |

### 8.6 Prompt

`~/.config/starship.toml`, shared by zsh and bash. **Two-line with a right-side
prompt** (decision #44): context on line one, a clean input line below, and
volatile information pushed to the right so it never shifts your cursor. The
input column is therefore constant, which is what makes a long session scannable.

| Position | Segment | Behaviour |
| --- | --- | --- |
| Left, line 1 | Context marker | Distinct hostname colour under SSH, a marker inside a container, red under root |
| Left, line 1 | Directory | Truncated to the git root, with a repo-relative path |
| Left, line 1 | Git | Branch, ahead/behind, compact dirty-state indicator |
| Left, line 1 | Language versions | Shown only inside a project of that language |
| Left, line 1 | Kubernetes | Context and namespace, only when a kubeconfig is active — the segment that stops you running against the wrong cluster |
| Left, line 1 | AWS | Profile and region when set |
| **Right, line 1** | Command duration | Above a threshold only |
| **Right, line 1** | Exit status | Non-zero only, coloured |
| **Right, line 1** | Clock | Current time |
| Left, line 2 | Input | A single character, always at the same column |

Two further behaviours: **transient prompt** collapses a submitted prompt to the
line-2 character alone, keeping scrollback clean; and an **ASCII-only fallback**
is auto-selected on a bare TTY with no Nerd Font.

### 8.7 Git

Decision #35 removes the work/personal split entirely: no work-email prompt, no
conditional include, no second config file.

| File | Contents |
| --- | --- |
| `~/.config/git/config` | Single identity from install prompts. `main` default branch, rebase-on-pull with autostash, auto-setup remote on push, prune on fetch, `zdiff3` conflict style, histogram diff, rerere enabled, verbose commits, branch sort by recency. delta as pager, side-by-side, Tokyo Night. Short alias set for log graphs, sync, undo, amend |
| `~/.config/git/ignore` | Global ignore: OS artefacts, editor directories, build output, env files |
| `~/.config/git/allowed_signers` | SSH signature allow-list; installed only when signing is explicitly enabled |

Per decision #19, SSH commit signing is **available but off by default**.

### 8.8 SSH client

| Area | Contents |
| --- | --- |
| Performance | `ControlMaster` with a persistent socket, so the 2nd..Nth connection to a host skips the handshake. `ServerAliveInterval` tuned so flaky links fail fast instead of hanging. Compression disabled |
| Hardening | Restricted to ed25519 / chacha20-poly1305 / AES-GCM. Agent and X11 forwarding disabled by default, opt-in per host. `HashKnownHosts`, `StrictHostKeyChecking` set to ask, `AddKeysToAgent` |
| Metadata split | Ends with `Include config.d/*` — your real hosts live there, unmanaged and uncommitted (decision #30) |

Written with restrictive permissions. Jump-host templates and Mosh were
considered and declined.

### 8.9 Clipboard — OSC52

Decision #24, and the single change that makes remote work feel local: yanking
in Neovim or copying in Zellij **on a remote server** places the text in your
local clipboard, transported over the SSH connection itself.

| Layer | Configuration |
| --- | --- |
| Neovim | Clipboard provider set to OSC52 when `SSH_TTY` is present, native otherwise |
| Zellij | Copy command set to OSC52 so it passes through rather than intercepting |
| Ghostty, Alacritty | OSC52 read/write permitted |

No X11 forwarding, no clipboard daemon on the server, no extra ports, and it
survives nesting.

**WSL2 bridge (decision #41).** OSC52 solves the remote-SSH case but not the
WSL-local one — yanking inside WSL and pasting into a Windows application needs a
bridge. Detected at runtime and entirely inert outside WSL:

| Direction | Mechanism |
| --- | --- |
| WSL → Windows clipboard | `clip.exe`, with `win32yank` as the Neovim provider |
| Windows clipboard → WSL | `powershell.exe Get-Clipboard`, normalised for line endings |
| Opening URLs and files | `wslview`, so `open` reaches your Windows browser |

### 8.10 Zellij

**Keybindings (decision #42): Zellij's default modal scheme, unmodified.** Every
Zellij doc, issue and answer online then applies directly to your setup, and the
zjstatus bar shows the active mode at all times.

| Key | Mode |
| --- | --- |
| Ctrl-p | Pane — new, close, split, focus |
| Ctrl-t | Tab — new, close, jump by number |
| Ctrl-n | Resize |
| Ctrl-o | Session — includes the `room` switcher |
| Ctrl-s | Scroll and search |
| Ctrl-g | Lock — engaged automatically while Neovim has focus |
| Ctrl-h/j/k/l | Pane navigation, crossing into Neovim splits transparently |

| File | Contents |
| --- | --- |
| `~/.config/zellij/config.kdl` | Tokyo Night theme, zjstatus replacing the default two-line bar, the default modal keybindings plus the `room` session switcher and unified Ctrl-hjkl navigation, autolock for Neovim, OSC52 copy, scrollback and mouse settings |
| `~/.config/zellij/layouts/default.kdl` | Single-pane layout with the zjstatus bar |
| `~/.config/zellij/layouts/dev.kdl` | Editor pane plus a split terminal and a log pane |
| `~/.config/zellij/layouts/ops.kdl` | Multi-pane server layout: shell, logs, resource monitor |

**Session behaviour (decision #13):** on interactive login, attach to a session
named after the hostname, creating it if absent. A dropped SSH connection costs
nothing. Hard-disabled when already nested, in containers, and for
non-interactive invocations — so `scp`, `rsync` and remote scripts are never
affected. An environment variable gives you a bare shell on demand.

### 8.11 Root shells

Decision #27. Nothing is installed into `/root`.

| Mechanism | Behaviour |
| --- | --- |
| Sudo wrapper | Preserves `PATH`, `EDITOR` and key environment variables, so `sudo nvim` and `sudo kubectl` use your tools and your config |
| Visual distinction | Prompt turns red and the context marker changes under root |
| No footprint | `/root` is left exactly as the distro shipped it |

### 8.12 AI tooling

Decision #28.

| File | Contents |
| --- | --- |
| `~/.claude/CLAUDE.md` | Global conventions and preferences applied to every project |
| `~/.claude/settings.json` | Permissions, hooks, status line, model preferences |
| `~/.claude/commands/` | Custom slash commands synced across machines |
| MCP server list | Declarative server configuration, so filesystem/git/fetch servers are available on every box without re-adding them |

Shell-level AI integration (command explanation, commit-message generation) was
offered and declined.

### 8.13 Tool configuration

| File | Contents |
| --- | --- |
| `~/.config/mise/config.toml` | Tool and runtime inventory, backend order (§10.1), parallel installs, idiomatic version-file interop, auto-install on directory entry |
| `~/.config/bat/config` | Tokyo Night theme, style, man-page integration |
| `~/.config/ripgrep/config` | Smart case, hidden files, sensible excludes |
| `~/.config/btop/btop.conf` | Tokyo Night theme |
| `~/.config/k9s/` | Tokyo Night skin, default view (`full` tier only) |
| `~/.config/ghostty/config` | Theme, font, keybindings, OSC52 |
| `~/.config/alacritty/alacritty.toml` | Theme, font, OSC52 |
| `~/.editorconfig` | Cross-editor indentation and whitespace |
| `~/.local/bin/dotfiles` | Helper command: `update`, `edit`, `diff`, `doctor`, `bench`, `help`, `portable` |

---

## 9. Secrets — Bitwarden

Decision #16. Secrets are resolved from the vault at apply time and **never
enter the repository**, in any form.

| Aspect | Behaviour |
| --- | --- |
| Backend | Bitwarden CLI (`bw`), compatible with self-hosted Vaultwarden |
| In the public repo | Nothing — not even item names, which live in local config per decision #30 |
| On disk | Rendered secrets land in files with restrictive permissions, outside the repo |
| Prerequisite | `bw unlock` and an exported session variable before `chezmoi apply` |
| Machines without it | The `none` backend is fully supported; secret-bearing files are excluded entirely rather than failing |
| Guard rail | gitleaks runs as a pre-commit hook and in CI, so a staged credential fails locally before it can be pushed |

Practical caveat to document: the Bitwarden CLI session expires, so a long gap
between `bw unlock` and `chezmoi apply` fails with an unhelpful error.
`docs/SECRETS.md` covers unlock flow, Vaultwarden self-hosting, headless server
usage, and rotation.

---

## 10. mise strategy

### 10.1 Backend order

Decision #47. mise offers 20 backends; the order they are preferred in matters
more than it looks.

| Priority | Backend | Why |
| --- | --- | --- |
| 1 | `aqua` | Its registry carries cosign, SLSA, minisign and GitHub attestation verification, so every tool resolving through it is cryptographically verified at install time — at zero configuration cost |
| 2 | `github` | Direct GitHub release downloads for tools not in the aqua registry |
| 3 | `http` | Last resort, explicit URL, used only where nothing else works |

Note for implementation: the `ubi` backend is **deprecated** in favour of
`github`. The earlier repository at `7f01ba9` used bare registry names, which
silently resolve through whichever backend mise picks; this plan pins the backend
explicitly.

This recovers most of the supply-chain hardening declined in §16, for free.

### 10.2 What mise does and does not install

| Installed by mise | Why |
| --- | --- |
| All CLI tools and runtimes (§7.3–7.13) | Identical binary names and versions on every distro; no Debian `batcat` rename, no EPEL hunting |
| All LSP servers, formatters and linters with a CLI (#45) | One binary shared by editor, shell, pre-commit and CI |

| **Not** installed by mise | Why not |
| --- | --- |
| Base OS layer — zsh, git, curl, ca-certificates, build deps | Chicken-and-egg: git and curl bootstrap mise itself. And zsh must register in `/etc/shells` for `chsh` to accept it, which a mise-managed copy cannot do |
| zsh plugins, Zellij WASM plugins, Nerd Font | These are sourced files and asset paths, not `PATH` binaries. mise installs to versioned directories, so `.zshrc` would have to resolve a version-specific path at startup — six `mise where` calls would blow the 60 ms budget, and fontconfig needs stable real paths. chezmoi externals place them at fixed locations with a refresh period |
| DAP adapters (codelldb, debugpy, delve) | No meaning as CLI tools; mason.nvim handles them natively |

### 10.3 Version pinning

Decision #20 and its exception.

| Category | Strategy | Why |
| --- | --- | --- |
| Zellij | **Exact pin** | KDL config format has broken across minor releases; an unpinned upgrade can leave you without a working multiplexer on a remote box |
| Neovim | **Exact pin** | Lua API churn across 0.10/0.11/0.12 breaks plugin configs |
| Zellij WASM plugins | Float | Considered for pinning and declined; they build against Zellij's plugin API and may need attention when Zellij is bumped |
| Everything else | Float to `latest` | Zero dependency maintenance; a regression in eza or bat is cosmetic |

Bumping the two pinned tools is a deliberate two-line edit made when you have
time to handle fallout.

---

## 11. Installation and day-2 operations

| Scenario | Approach |
| --- | --- |
| Fresh machine | One curl-to-shell command: installs chezmoi, clones, prompts for identity and profile, applies everything |
| Fully unattended | Same command with every prompt supplied as a flag — used by CI and the container image |
| Pull changes | `dotfiles update` — fetch, show diff, apply. **Manual only** (decision #34) |
| Knowing you are behind | A staleness hint after 7 days, from a local timestamp check — never a network call on shell start |
| Edit a config | Edit source and apply in one step; live immediately, committable immediately |
| Add a tool | One line in `tools.toml`; next apply installs it everywhere and it appears in `dotfiles help` |
| Rediscover your setup | `dotfiles help`, fuzzy-searchable |
| Health check | `dotfiles doctor` — missing tools, stale externals, shell startup time, drift between source and target |
| Roll back | git revert, then apply. This is the **only** rollback mechanism (decision #38) |

---

## 12. Ephemeral hosts — portable rc

Decision #29. For boxes you touch once and never see again.

| Property | Detail |
| --- | --- |
| What it is | A single self-contained shell file, generated from the same `~/.config/shell/` sources, so it cannot drift from the real config |
| What you get | Aliases, functions, history settings, emacs keybindings, and a basic prompt |
| What it does not do | Install anything, write anything to disk, require root, or need chezmoi |
| How it is used | Curl it and source it into one shell; on exit the box is exactly as you found it |
| How it stays current | Regenerated by a `make` target and committed |

---

## 13. Container image

Decision #36. Full standard-tier toolchain pre-baked.

| Aspect | Detail |
| --- | --- |
| Base | Debian slim |
| Baked in | zsh + all plugins, starship, the full standard tier of mise tools, Zellij with its plugins, Neovim with plugins and LSP servers pre-synced |
| Approximate size | ~1.2 GB |
| Startup | Container ready in seconds, versus a ~4-minute bootstrap on every launch |
| Consumers | `Containerfile` for direct use, `.devcontainer/devcontainer.json` for Codespaces and VS Code |

---

## 14. Testing and CI

Decision #23 — minimal.

| Job | Coverage |
| --- | --- |
| Lint | Every template renders with representative data; rendered scripts pass shellcheck; shfmt formatting enforced |
| Apply | One end-to-end `chezmoi init --apply` on Ubuntu at the standard tier |
| Smoke | Interactive zsh and bash start and source cleanly |
| Secrets | gitleaks over the diff |
| Commits | commitlint validates Conventional Commit format |

**Explicitly accepted gap:** distro-specific breakage — Alpine's musl and
BusyBox, RHEL package naming, pacman differences — reaches a server rather than
being caught in CI. The base package lists and scripts are still written for all
five package managers; they are simply not proven on every push.

---

## 15. Work breakdown

| Phase | Deliverable |
| --- | --- |
| 1 | chezmoi core: root marker, prompts, package/tool/theme data, externals, ignore rules |
| 2 | Shared POSIX shell layer: env, aliases, functions, interactive |
| 3 | zsh and bash entry points, emacs keybindings, deferred plugins, full parity |
| 4 | Starship prompt, transient prompt, Tokyo Night palette wiring |
| 5 | Shell behaviours: smart `cd`, bookmarks, `up N`, command-not-found installer, staleness hint |
| 6 | fzf pickers: core and infra |
| 7 | Bootstrap scripts: packages, mise, tools, Zellij plugins, fonts, nvim sync, default shell |
| 8 | git, SSH (with `config.d` split) and mise configuration |
| 9 | Zellij config, zjstatus bar, layouts, session auto-attach, OSC52 |
| 10 | Neovim: lazy.nvim + snacks + blink + lualine, LSP for four stacks, format/lint, DAP |
| 11 | Terminal emulator configs (Ghostty, Alacritty) and font |
| 12 | Bitwarden secrets wiring and documentation |
| 13 | Root/sudo environment preservation |
| 14 | Claude Code and MCP configuration |
| 15 | `install.sh`, `Makefile`, `dotfiles` helper including `help` generation, `portable.sh` |
| 16 | CI workflow, Containerfile, devcontainer, pre-commit, commitlint |
| 17 | README and the three docs |
| 18 | End-to-end verification |

Phase 1 and part of phase 2 exist on disk from the earlier interrupted run.
Several of those files now need editing to match final decisions — the ignore
rules still contain tmux and work-email logic, and the externals file has no
Zellij plugins.

---

## 16. Risks and accepted trade-offs

| Risk | Status |
| --- | --- |
| **Existing dotfiles are overwritten with no backup** | **Accepted** (#38). Installing on a machine that already has a `~/.zshrc` destroys it. There is no undo beyond whatever that machine had in git. This is the sharpest edge in the plan |
| Minimal CI means Alpine/RHEL breakage reaches a server first | **Accepted** (#23). Mitigated by writing scripts defensively for all five package managers |
| Floating versions mean two machines provisioned weeks apart differ | **Accepted** (#20). Mitigated by pinning the two tools that actually break |
| Bootstrap pipes a remote script to a shell without checksum verification | **Partly mitigated** by #47: preferring the `aqua` backend means every mise-installed tool is cryptographically verified. The residual exposure is narrowed to `install.sh` fetching chezmoi and mise themselves, plus the chezmoi externals |
| No guardrails on destructive commands | **Accepted** — offered and declined. The Kubernetes prompt segment partially compensates by always showing the active context |
| No which-key in Neovim | **Accepted** (#37). Partly mitigated by the mnemonic leader namespaces of #43, which make bindings guessable, and by `dotfiles help` — but neither gives you an in-context popup while editing |
| Zellij uses 3–5× tmux's memory and has weaker scripting | **Accepted** (#11) |
| bun as the Node default has imperfect ecosystem compatibility | **Accepted** (#39). npm and pnpm remain installed for projects that need them |
| Bitwarden CLI sessions expire, producing confusing apply failures | Mitigated by documentation and a clear error in the bootstrap |
| mise sits between you and every CLI tool | Mitigated: the base layer stays on OS packages, so a broken mise still leaves a working shell |
| Alpine/musl breaks some prebuilt binaries | Mitigated by installing `gcompat`; not proven in CI |
| Deferred plugins mean the first ~100 ms of a shell lacks highlighting | Inherent to the approach and the reason it is fast |

---

## 17. Open items

1. **Zellij WASM plugin pinning.** Left floating. If a Zellij bump breaks
   zjstatus, pinning all four together is the fix.
2. **Ansible retained** in the `full` tier, inferred from your selecting Ansible
   LSP support.
3. **Per-host overrides deferred** (#33). The mechanism is cheap to add later;
   `~/.config/shell/local.sh` and `~/.ssh/config.d/` already cover most of the
   need in the meantime.
4. **No backup on install** (#38) is worth revisiting before the first install on
   a machine that already has configuration you care about. Every other machine
   type in scope — fresh servers, containers, Codespaces — is unaffected.

Resolved since the previous revision: the WSL2 clipboard gap is closed by
decision #41.

---

## Sources

- [chezmoi — Why use chezmoi?](https://www.chezmoi.io/why-use-chezmoi/)
- [chezmoi — Setup guide](https://www.chezmoi.io/user-guide/setup/)
- [Best Dotfile Managers for a Portable Dev Setup (2026)](https://briandetering.net/2026/06/25/best-dotfile-managers-2026/)
- [dotfiles.github.io — General-purpose dotfiles utilities](https://dotfiles.github.io/utilities/)
- [Dotfile Management Tools Battle: YADM vs Chezmoi vs Nix](https://biggo.com/news/202412191324_dotfile-management-tools-comparison)
- [Shell Setup in 2026: Starship, Plugins, Fish](https://sumguy.com/shell-setup-2026-starship-zsh/)
- [Modern Terminal Setup 2026: Beyond Oh My Zsh and Bash](https://islinux.com/articles/modern-terminal-setup-2026.html)
- [Mise vs asdf: Which Version Manager Should You Choose?](https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/)
- [Best Dev Environment Managers in 2026: devbox vs Nix vs asdf](https://briandetering.net/2026/05/28/best-dev-environment-managers-2026/)
- [Terminal Multiplexers: tmux vs Zellij](https://dasroot.net/posts/2026/02/terminal-multiplexers-tmux-vs-zellij-comparison/)
- [Zellij vs tmux: Which Terminal Multiplexer Wins in 2026?](https://petronellatech.com/blog/zellij-terminal-multiplexer-guide-2026)
- [tmux Alternatives — tmux vs Screen vs Zellij vs Byobu (2026)](https://tmux.app/alternatives/)
