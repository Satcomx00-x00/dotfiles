# Secrets

Decision #16: Bitwarden CLI (`bw`), compatible with self-hosted Vaultwarden.
Secrets are resolved **at apply time** and never enter the repository in any
form — not even the item names.

## The split that lets this repo be public

| Lives in the public repo | Lives only on your machine |
| --- | --- |
| The mechanism: `home/dot_config/shell/private_secrets.sh.tmpl` | Which vault items to read |
| The documentation you are reading | The rendered values |

The template iterates `.secrets.items`, which comes from your **local** chezmoi
config — `~/.config/chezmoi/chezmoi.toml`, which is never committed:

```toml
[data.secrets]
    items = [
        { env = "GITHUB_TOKEN",      item = "GitHub",    field = "pat" },
        { env = "ANTHROPIC_API_KEY", item = "Anthropic", field = "key" },
    ]
```

So the repository knows *how* to fetch a secret and nothing about *which*.

## Setup

```sh
mise use -g npm:@bitwarden/cli        # or: it is already in the standard tier
bw config server https://vault.example.com   # self-hosted Vaultwarden only
bw login
```

Then, before every `chezmoi apply` that needs secrets:

```sh
export BW_SESSION="$(bw unlock --raw)"
chezmoi apply
```

Add the items to your local config as above, and re-apply.

## The failure you will actually hit

**The `bw` session expires.** A long gap between `bw unlock` and `chezmoi apply`
produces an unhelpful error — usually a JSON parse failure or "You are not
logged in" surfacing as a template error on a file that looks unrelated.

The fix is always the same:

```sh
export BW_SESSION="$(bw unlock --raw)"
chezmoi apply
```

If you script an apply, unlock inside the same shell invocation rather than
relying on an exported session from earlier.

## Machines without a vault

The `none` backend is fully supported and is the default. `.chezmoiignore`
excludes `~/.config/shell/secrets.sh` entirely, so nothing calls `bw`, nothing
fails to render, and the machine is complete without it.

To move a machine off secrets:

```sh
chezmoi init --promptChoice "Secrets backend=none"
chezmoi apply
```

## Rotation

Rotate in the vault, then `chezmoi apply` on each machine. There is no cached
copy to invalidate: the rendered file is regenerated from the vault every time.

Rendered secrets land in `~/.config/shell/secrets.sh` with restrictive
permissions (the source is `private_`), outside the repository.

## Guard rail

`gitleaks` runs as a pre-commit hook and in CI. A staged credential fails
locally, before it can be pushed. It is the last line, not the first — the
first is that secrets are never written into the source tree at all.
