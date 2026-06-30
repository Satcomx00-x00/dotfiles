# 🏠 dotfiles

[![CI](https://github.com/Satcomx00-x00/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/Satcomx00-x00/dotfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

State-of-the-art, cross-distro dotfiles managed by [**chezmoi**](https://www.chezmoi.io/),
with CLI tooling provided by [**mise**](https://mise.jdx.dev/) and a finely-tuned
**Zsh + Oh My Zsh + Powerlevel10k** shell.

Runs identically on **Debian/Ubuntu**, **Alpine** (musl), and **CentOS/RHEL/Rocky/Alma** —
verified end-to-end in CI on every push.

---

## ✨ Highlights

- **One command** to provision a fresh machine (packages → mise → tools → shell → fonts).
- **chezmoi** templating: prompts once for name/email/editor/machine type, persists answers.
- **mise** installs every CLI tool (eza, bat, fd, ripgrep, fzf, zoxide, delta, jq, gh,
  lazygit, kubectl, k9s, helm, terraform, …) and runtimes (node, python, uv, bun, neovim) —
  so binaries have their **canonical names on every distro** (no Debian `batcat`/`fdfind`,
  no CentOS EPEL hunting).
- **Powerlevel10k** with instant prompt; plugins loaded in the correct order
  (`fzf-tab` → `zsh-autosuggestions` → `zsh-syntax-highlighting` **last**).
- **Zellij** terminal multiplexer with safe, opt-in auto-start (never on servers, never nests).
- **Git** with delta diffs, sane modern defaults, and per-directory work identity.
- **MesloLGS NF** Nerd Font auto-installed on graphical machines; ASCII fallback on bare TTYs.

## ⚡ Install

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply -b ~/.local/bin Satcomx00-x00/dotfiles
```

On minimal Alpine/CentOS images without `curl`:

```bash
sh -c "$(wget -qO- get.chezmoi.io)" -- init --apply -b ~/.local/bin Satcomx00-x00/dotfiles
```

You'll be prompted **once** for name, email, editor, machine type, signing and headless
flags. Then chezmoi installs base packages, bootstraps mise, fetches Oh My Zsh + plugins +
fonts, writes your configs, installs the mise toolset, and sets Zsh as your default shell.

Open a new terminal (or `exec zsh`). On a **graphical** machine, set your terminal font to
**MesloLGS NF** so Powerlevel10k glyphs render.

## 🚀 Bootstrap flow

| Step | What runs | Where |
|------|-----------|-------|
| 1 | `chezmoi init` — prompts, writes `~/.config/chezmoi/chezmoi.toml` | — |
| 2 | `run_once_before_00-install-packages` — base distro packages | `.chezmoidata.toml` |
| 3 | `run_once_before_10-install-mise` — mise binary | `mise.run` |
| 4 | externals fetched — Oh My Zsh, P10k, zsh plugins, fonts | `.chezmoiexternal.toml.tmpl` |
| 5 | dotfiles applied — `.zshrc`, git, mise, zellij configs | `home/` |
| 6 | `run_onchange_after_20-mise-install` — `mise install` (reruns on config change) | `dot_config/mise` |
| 7 | `run_onchange_after_30-fonts-cache` — `fc-cache` (non-headless) | — |
| 8 | `run_once_after_40-default-shell` — `chsh` to zsh (idempotent, non-fatal) | — |

## 🗂️ Layout

```
.chezmoiroot                                  # → "home" (only home/ maps to $HOME)
home/
├── .chezmoiversion                           # min chezmoi version (2.47.0)
├── .chezmoi.toml.tmpl                         # first-run prompts → [data]
├── .chezmoidata.toml                          # per-distro base package lists
├── .chezmoiignore                             # per-machine exclusions (fonts on headless…)
├── .chezmoiexternal.toml.tmpl                 # OMZ + P10k + plugins + Nerd Font
├── .chezmoitemplates/aliases.zsh             # shared alias/function partial
├── .chezmoiscripts/                          # ordered install scripts (POSIX sh)
├── dot_zshrc.tmpl                             # → ~/.zshrc
├── dot_zprofile.tmpl                          # → ~/.zprofile (mise shims)
├── dot_p10k.zsh                               # → ~/.p10k.zsh (Powerlevel10k)
└── dot_config/
    ├── git/{config,config-work,ignore,allowed_signers}.tmpl
    ├── mise/config.toml.tmpl                  # tools + runtimes
    └── zellij/{config.kdl,layouts/default.kdl}
```

## 🛠️ Everyday use

```bash
chezmoi edit ~/.zshrc      # edit a managed file (aliased: dotedit)
chezmoi diff               # preview pending changes (dotdiff)
chezmoi apply -v           # apply changes (dotapply)
chezmoi update -v          # pull latest from git + apply (dotupdate)
chezmoi cd                 # jump into the source repo (dotcd)
```

Add `~/.zshrc.local` for machine-specific tweaks — it's sourced automatically and never
managed by chezmoi.

### Adjusting the toolset

Tools live in [`home/dot_config/mise/config.toml.tmpl`](home/dot_config/mise/config.toml.tmpl).
Add a line under `[tools]`, run `chezmoi apply`, and the mise hook installs it.

### Zellij auto-start

Auto-starts on `personal`/`work` machines, **off** on `server`. Override per-shell:

```bash
export ZELLIJ_AUTOSTART=false   # disable
export ZELLIJ_SKIP=1            # one-off skip (e.g. inside scripts)
export ZELLIJ_AUTO_ATTACH=true  # attach to existing session vs. new (default true)
```

## 🔐 Secrets (optional)

Encryption is disabled by default so the repo applies cleanly. To enable age secrets:

```bash
age-keygen -o ~/.config/chezmoi/key.txt          # keep the private key OFF git
# uncomment the [age] block in home/.chezmoi.toml.tmpl, set `recipient`
chezmoi add --encrypt ~/.ssh/id_ed25519
```

## 🧪 Testing locally

```bash
docker build -f Containerfile -t dotfiles:debian .
docker build -f Containerfile --build-arg BASE=alpine:3.20  -t dotfiles:alpine .
docker build -f Containerfile --build-arg BASE=rockylinux:9 -t dotfiles:rocky  .
docker run --rm -it dotfiles:debian
```

CI ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) renders + shellchecks every
script and runs the full `chezmoi init --apply` on Debian, Ubuntu, Alpine, and Rocky.

## 📄 License

MIT — see [LICENSE](LICENSE).
