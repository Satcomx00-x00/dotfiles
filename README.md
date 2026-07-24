# dotfiles

One shell, identical on every machine you touch: Linux servers, dev containers
and Codespaces, and WSL2. One command on a fresh box gives you a fully
configured, fully tooled environment.

Managed with [chezmoi](https://chezmoi.io). No framework, no plugin manager —
plugins are deferred past the first prompt, so an interactive zsh starts in
under 60 ms.

- **Design and decisions** — [report.md](report.md), 47 decisions with rationale
- **How it is built** — [IMPLEMENTATION.md](IMPLEMENTATION.md), the build plan and invariants

---

## Quick start

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Satcomx00-x00/dotfiles/main/install.sh)"
```

It asks for your name, email, editor, machine profile and tool tier, then does
everything else. Unattended:

```sh
DOTFILES_NAME="Your Name" DOTFILES_EMAIL=you@example.com \
DOTFILES_PROFILE=server DOTFILES_TIER=standard \
sh -c "$(curl -fsSL .../install.sh)" -- --yes
```

> **There is no backup.** On a machine that already has a `~/.zshrc`, that file
> is replaced. Git is the only rollback. The installer warns before writing.

### A machine you will never see again

```sh
curl -fsSL .../portable.sh > /tmp/p.sh && . /tmp/p.sh
```

Aliases, functions, history and keybindings in one shell. Installs nothing,
writes nothing, needs no root. Generated from the same sources as everything
else, so it cannot drift.

---

## Day two

| Command | What it does |
| --- | --- |
| `dotfiles help` | Fuzzy-search every alias, function, picker and keybinding this machine has |
| `dotfiles doctor` | Missing tools, stale externals, drift, startup cost |
| `dotfiles update` | Fetch, show the diff, apply — manual only, by design |
| `dotfiles diff` | What would change if you applied right now |
| `chezmoi edit --apply <file>` | Edit a managed file and apply it in one step |
| `dotfiles bench` | Measure shell startup against the 60 ms budget |

`dotfiles help` is **generated at apply time** from the configuration that is
actually installed, so it cannot describe an alias you do not have.

---

## Profiles and tiers

One prompt picks the profile (auto-detected), another picks the tier. They are
independent, so a small VPS can be a `server` on `minimal`.

| | `workstation` | `server` | `container` |
| --- | --- | --- | --- |
| Nerd Font | yes | no | no |
| Terminal emulator config | yes | no | no |
| Zellij auto-attach | yes | yes | no |
| Change login shell | yes | yes | no (image sets it) |
| Default tier | `full` | `standard` | `standard` |
| Node heap | 8 GB | 2 GB | 2 GB |

---

## What you get

| Area | Choice |
| --- | --- |
| Shell | zsh, emacs keybindings, full bash parity |
| Prompt | Starship — two lines, right-side prompt, transient |
| Theme | Tokyo Night, defined once and templated into 12 configs |
| Editor | Neovim on lazy.nvim — snacks.nvim, blink.cmp, lualine |
| Multiplexer | Zellij with zjstatus, unified `Ctrl-hjkl` across editor and panes |
| Tools | mise, `aqua` backend first for free signature verification |
| Clipboard | OSC52 — yanking on a remote server reaches your local clipboard |
| Secrets | Bitwarden at apply time; nothing sensitive in the repo |

### Tool inventory

<!-- BEGIN GENERATED: tools -->


**prompt**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `starship` | prompt, shared by zsh and bash | minimal | `aqua:starship/starship` |

**core-cli**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `eza` | ls — git status, icons, tree mode | minimal | `aqua:eza-community/eza` |
| `bat` | cat — syntax highlighting, paging, man pages | minimal | `aqua:sharkdp/bat` |
| `fd` | find — sane defaults, respects gitignore | minimal | `aqua:sharkdp/fd` |
| `rg` | grep -r, fast | minimal | `aqua:BurntSushi/ripgrep` |
| `fzf` | fuzzy finder — drives history, files, completion, every picker | minimal | `aqua:junegunn/fzf` |
| `zoxide` | cd — frecency-ranked jumps | minimal | `aqua:ajeetdsouza/zoxide` |
| `jq` | JSON processor | minimal | `aqua:jqlang/jq` |
| `yq` | YAML/XML/TOML processor | minimal | `aqua:mikefarah/yq` |
| `delta` | git diff pager — side-by-side, syntax highlighted | minimal | `aqua:dandavison/delta` |
| `sd` | sed, for the simple substitution case | standard | `aqua:chmln/sd` |
| `hyperfine` | command benchmarking | standard | `aqua:sharkdp/hyperfine` |

**system**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `btop` | top / htop | standard | `aqua:aristocratos/btop` |
| `dust` | du — visual size tree | standard | `aqua:bootandy/dust` |
| `duf` | df — readable filesystem overview | standard | `aqua:muesli/duf` |
| `fclones` | duplicate file detection and removal | standard | `aqua:pkolaczk/fclones` |

**git**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `lazygit` | terminal git UI | standard | `aqua:jesseduffield/lazygit` |
| `gh` | GitHub CLI | standard | `aqua:cli/cli` |
| `git-lfs` | large file support | standard | `aqua:git-lfs/git-lfs` |
| `gitleaks` | secret scanning — pre-commit hook and CI | standard | `aqua:gitleaks/gitleaks` |

**editor**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `nvim` | the editor | standard | `aqua:neovim/neovim` **PIN 0.11.4** |

**multiplexer**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `zellij` | terminal multiplexer | standard | `aqua:zellij-org/zellij` **PIN 0.43.1** |

**runtime**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `bun` | default Node package manager and runtime | standard | `aqua:oven-sh/bun` |
| `node` | runtime, for tooling that needs real Node rather than bun | standard | `core:node` |
| `uv` | default Python toolchain — replaces pip, pipx, venv, poetry, pyenv | standard | `aqua:astral-sh/uv` |
| `python3` | interpreter, consumed by uv | standard | `core:python` |
| `go` | Go toolchain | full | `core:go` |
| `cargo` | Rust toolchain | full | `core:rust` |

**lsp**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `shellcheck` | shell linter | standard | `aqua:koalaman/shellcheck` |
| `shfmt` | shell formatter | standard | `aqua:mvdan/sh` |
| `hadolint` | Dockerfile linter | standard | `aqua:hadolint/hadolint` |
| `ruff` | Python linter and formatter | standard | `aqua:astral-sh/ruff` |
| `bash-language-server` | shell LSP | standard | `npm:bash-language-server` |
| `basedpyright` | Python LSP | standard | `npm:basedpyright` |
| `docker-langserver` | Dockerfile LSP | standard | `npm:dockerfile-language-server-nodejs` |
| `gopls` | Go LSP | full | `aqua:golang/tools/gopls` |
| `golangci-lint` | Go linter aggregate | full | `aqua:golangci/golangci-lint` |
| `gofumpt` | stricter gofmt | full | `aqua:mvdan/gofumpt` |
| `rust-analyzer` | Rust LSP | full | `aqua:rust-lang/rust-analyzer` |
| `vtsls` | TypeScript LSP | full | `npm:@vtsls/language-server` |
| `eslint` | JavaScript/TypeScript linter | full | `npm:eslint` |
| `biome` | fast JS/TS formatter and linter | full | `aqua:biomejs/biome` |
| `vscode-html-language-server` | html, cssls, jsonls, eslint LSPs | full | `npm:vscode-langservers-extracted` |
| `tailwindcss-language-server` | Tailwind LSP | full | `npm:@tailwindcss/language-server` |
| `terraform-ls` | Terraform LSP | full | `aqua:hashicorp/terraform-ls` |
| `tflint` | Terraform linter | full | `aqua:terraform-linters/tflint` |
| `yaml-language-server` | YAML LSP with SchemaStore and Kubernetes schemas | full | `npm:yaml-language-server` |
| `yamllint` | YAML linter | full | `pipx:yamllint` |
| `ansible-lint` | Ansible linter | full | `pipx:ansible-lint` |
| `ansible-language-server` | Ansible LSP | full | `npm:@ansible/ansible-language-server` |
| `helm-ls` | Helm chart LSP | full | `aqua:mrjosh/helm-ls` |

**container**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `lazydocker` | terminal Docker UI | standard | `aqua:jesseduffield/lazydocker` |
| `dive` | image layer and waste inspection | full | `aqua:wagoodman/dive` |
| `trivy` | container and filesystem vulnerability scanning | full | `aqua:aquasecurity/trivy` |

**k8s**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `kubectl` | cluster CLI | full | `aqua:kubernetes/kubectl` |
| `k9s` | terminal cluster UI | full | `aqua:derailed/k9s` |
| `helm` | chart management | full | `aqua:helm/helm` |
| `kubectx` | context and namespace switching | full | `aqua:ahmetb/kubectx` |
| `kustomize` | manifest overlays | full | `aqua:kubernetes-sigs/kustomize` |
| `stern` | multi-pod log tailing | full | `aqua:stern/stern` |

**infra**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `terraform` | infrastructure as code | full | `aqua:hashicorp/terraform` |
| `tofu` | Terraform fork, installed alongside | full | `aqua:opentofu/opentofu` |
| `aws` | AWS CLI v2 | full | `aqua:aws/aws-cli` |
| `ansible` | configuration management | full | `pipx:ansible` |

**secrets**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `bw` | Bitwarden / Vaultwarden CLI — resolves secrets at apply time | standard | `npm:@bitwarden/cli` |
| `age` | file encryption primitive | standard | `aqua:FiloSottile/age` |
| `sops` | encrypted config files | full | `aqua:getsops/sops` |

**workflow**

| Tool | Role | Tier | Source |
| --- | --- | --- | --- |
| `direnv` | per-directory environment loading | standard | `aqua:direnv/direnv` |
| `just` | project command runner | standard | `aqua:casey/just` |
| `chezmoi` | the dotfiles manager itself | minimal | `aqua:twpayne/chezmoi` |
| `win32yank` | WSL2 clipboard bridge for Neovim | standard | `github:equalsraf/win32yank` |


Totals: **minimal** 11 · **standard** 40 · **full** 71
<!-- END GENERATED: tools -->

---

## Public repo, private machine

This repository is public and contains nothing that identifies any
infrastructure. The split is enforced by design:

| In the repo | Not in the repo |
| --- | --- |
| All configuration, bootstrap logic, theme, keymaps | Server hostnames and SSH entries |
| Documentation and CI | Bitwarden item names |
| The mechanism for secrets | Any internal domain or IP |

| File | Role |
| --- | --- |
| `~/.ssh/config` | Managed: crypto, multiplexing, hardening. Ends with `Include config.d/*` |
| `~/.ssh/config.d/*` | **Yours.** Never managed, never committed |
| `~/.config/shell/local.sh` | **Yours.** Machine-local env and PATH, sourced last |

---

## Working on this repo

Everything CI does is a `make` target, so nothing fails in a way you cannot
reproduce locally.

```sh
make dev-tools     # chezmoi + the pinned linters
make check         # render, lint, help, theme — no container, ~5 seconds
make sandbox       # full bootstrap in a throwaway container
make sandbox-all   # the distro and profile matrix
```

| Target | Checks |
| --- | --- |
| `render` | Every template renders on every profile, and the test fixtures still match the real prompt schema |
| `lint` | shellcheck on rendered output, `zsh -n`/`bash -n`/`dash -n`, shfmt, stylua, taplo, glyph integrity, version-pin rule |
| `lint-help` | Every alias and function is reachable from `dotfiles help` |
| `theme-check` | Mutates the whole palette and proves exactly the declared consumers change |
| `verify-tools` | Every backend in `tools.toml` resolves upstream (network) |
| `verify-externals` | Every external URL is reachable (network) |
| `verify-zellij` | The generated KDL parses in a real zellij |
| `verify-portable` | `portable.sh` sources on a bare container and defines what it claims |

Four artefacts are generated and committed — `portable.sh`, the table above,
the help index, and the theme fan-out. Each has a CI gate that regenerates it
and fails on any diff, because a generation convention without a gate decays.

---

## Docs

- [docs/SECRETS.md](docs/SECRETS.md) — Bitwarden and Vaultwarden setup
- [docs/CUSTOMIZING.md](docs/CUSTOMIZING.md) — adding a tool, alias, language or profile
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — known failures per distro

## Licence

[MIT](LICENSE).
