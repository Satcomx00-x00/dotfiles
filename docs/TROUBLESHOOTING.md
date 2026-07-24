# Troubleshooting

## Shell startup is slow

```sh
dotfiles doctor      # includes a timed measurement
dotfiles bench       # zsh and bash, against the 60 ms budget
```

The usual cause is the init cache being rebuilt on every start. It caches the
generated init snippets for starship, zoxide, fzf, direnv and mise, keyed on the
set of installed tools:

```sh
cat "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/init.zsh" | head -1   # the signature line
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles/init."*             # force a rebuild
```

Second suspect: `compinit` rebuilding its dump. It is meant to do that at most
once a day. If `~/.cache/zsh/zcompdump` is missing or unwritable, it happens
every time.

**Note on measuring.** A system-wide `/etc/zsh/zshrc` can cost far more than
this configuration does — over a second on some Codespaces images. Compare
against `zsh -d -ic exit`, which skips global rc files, before blaming anything
here.

## Nothing is themed / the prompt is boxes

You are missing the Nerd Font, or the terminal is not using it. On a bare TTY
the ASCII prompt is selected automatically; force it either way:

```sh
DOTFILES_ASCII=1 exec zsh    # ASCII
DOTFILES_ASCII=0 exec zsh    # glyphs
```

The font is only installed on the `workstation` profile — that is deliberate, a
server has nothing to render it with.

## `chsh` did not change my login shell

Common and expected on directory-backed accounts (LDAP, SSSD), locked accounts,
and images without `chsh`. The script warns rather than failing. Do it by hand:

```sh
chsh -s "$(command -v zsh)"
```

If zsh is missing from `/etc/shells`, add it first. This is exactly why zsh
comes from the OS package manager and not from mise — a mise-managed copy can
never register there.

## Alpine / musl

- Prebuilt binaries from `github:` backends may need `gcompat`, which the base
  package list installs.
- `/bin/sh` is BusyBox ash. The shared layer is POSIX and tested under `dash`,
  but a BusyBox-specific difference is possible.
- `shadow` provides `chsh`; without it the login shell cannot change.

Alpine is in CI at the `minimal` tier, so the bootstrap path is proven. Higher
tiers on musl are not.

## RHEL / Rocky / Alma

Package names differ (`openssh-clients`, `procps-ng`, `util-linux-user` for
`chsh`, `glibc-langpack-en` for locales). All are in `packages.toml`, but this
path is **not** proven in CI — report.md §14 accepts that.

## Zellij starts when I do not want it

```sh
ZELLIJ_SKIP=1 ssh host
```

Auto-attach is already disabled when nested, in containers, without a TTY, under
VS Code, and for non-interactive invocations — so `scp`, `rsync` and
`ssh host command` are unaffected. If it fires when it should not, that is a bug
in the guard list in `~/.zshrc`.

## Zellij will not start after an upgrade

This is the reason it is pinned (decision #20). If you bumped it and the KDL is
now rejected:

```sh
zellij setup --check          # says exactly which line
git revert <the bump>         # and apply
```

The four WASM plugins float, so they may need bumping with it.

## A tool is missing

```sh
dotfiles doctor       # says which, and that the fix is `mise install`
mise install
```

If a tool fails to resolve at all, its backend may have moved:

```sh
make verify-tools     # resolves every backend against upstream
```

## `chezmoi apply` asks about a file and then fails

```
.config/foo has changed since chezmoi last wrote it?
chezmoi: could not open a new TTY
```

Something modified a managed file outside chezmoi. Interactively it prompts;
non-interactively it cannot. Inspect, then choose:

```sh
chezmoi diff .config/foo      # what changed
chezmoi apply --force         # discard the local change
chezmoi add .config/foo       # keep it, into the source
```

## Secrets

See [SECRETS.md](SECRETS.md) — the session-expiry failure is the one you will
actually hit.
