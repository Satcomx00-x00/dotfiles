# Claude Code on OpenRouter

`claude-or` runs Claude Code through [OpenRouter](https://openrouter.ai) — the
DeepSeek models by default — without touching your Anthropic login. The global
switch, the per-session launchers and the key manager are plain POSIX shell and
are installed by chezmoi into `~/.local/bin`.

This is the Linux counterpart of the PowerShell setup in
`~/.local/bin/claude-or.ps1`; the switch commands, launch options and model
defaults are the same.

## Prerequisites

Claude Code itself is not installed by this repository. Install it once with
the native installer:

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

`~/.local/bin` is already first on `PATH` (see `~/.config/shell/env.sh`), and
`jq` is part of the minimal tier, so `claude-or-key --status` works out of the
box.

## First run

```sh
claude-or-key --set-key     # prompts once, stores the key with mode 0600
claude-or enable            # every new shell routes claude through OpenRouter
claude-or status
```

`enable` writes `~/.config/claude-or/env.sh`. Open a new shell, or apply it to
the current one with:

```sh
. ~/.config/claude-or/env.sh
```

## Commands

| Command | Effect |
| --- | --- |
| `claude-or enable` (`on`) | global switch on: every `claude` uses OpenRouter |
| `claude-or disable` (`off`) | back to your Anthropic account |
| `claude-or toggle` | flip the switch |
| `claude-or status` | what is active, model, key, and whether this shell is stale |
| `claude-or` | one-shot OpenRouter session; the switch is untouched |
| `claude-an` | one-shot Anthropic session; the switch is untouched |
| `claude-or-key --set-key` | store or replace the key |
| `claude-or-key --status` | remaining OpenRouter credit |
| `claude-or-status` | same as `--status` |
| `claude-or-key --clear` | delete the key (and turn the switch off) |

Everything the wrapper does not claim is forwarded to `claude` verbatim:
`claude-or -p "explain this repo"`, `claude-or --resume`, and so on.

## Model overrides

The wrapper options mirror the Windows setup. Every CamelCase option also has a
GNU-style alias (`--or-model`, `--or-sonnet`, …).

| Option | Variable |
| --- | --- |
| `-Model <slug>` | pins Sonnet, Opus and sub-agents to one model |
| `-Sonnet <slug>` | `ANTHROPIC_DEFAULT_SONNET_MODEL` |
| `-Opus <slug>` | `ANTHROPIC_DEFAULT_OPUS_MODEL` |
| `-Fable <slug>` | `ANTHROPIC_DEFAULT_FABLE_MODEL` |
| `-Haiku <slug>` | `ANTHROPIC_DEFAULT_HAIKU_MODEL` |
| `-Subagent <slug>` | `CLAUDE_CODE_SUBAGENT_MODEL` |
| `-Discover` | `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` (the `/model` picker) |
| `-Print` | print the resolved configuration and exit |

Default models (also used by `enable`):

| Class | Model |
| --- | --- |
| Fable | `deepseek/deepseek-v4-pro[1m]` |
| Opus | `deepseek/deepseek-v4.1-flash-1017[1m]` |
| Sonnet | `deepseek/deepseek-v4.1-flash-1017[1m]` |
| Haiku | `deepseek/deepseek-v4-flash-0731[1m]` |
| Subagent | `deepseek/deepseek-v4.1-flash-1017[1m]` |

The `[1m]` marker tells Claude Code the window is 1M tokens instead of
compacting at 200k. OpenRouter strips it before routing.

The defaults live in `home/dot_local/bin/executable_claude-or` and are kept in
sync with the Windows wrapper by hand.

## Files and isolation

| Path | Purpose |
| --- | --- |
| `~/.claude-profiles/openrouter/` | the isolated `CLAUDE_CONFIG_DIR`; your `~/.claude` login is never touched |
| `~/.claude-profiles/openrouter/openrouter.key` | the API key, mode 0600 |
| `~/.config/claude-or/env.sh` | the global switch, mode 0600; absent when disabled |

The token is not copied into `env.sh`: the file reads the 0600 key file with
the shell's `read` builtin (no fork), so there is exactly one copy of the
secret and `claude-or-key --set-key` rotates it without re-enabling.

Linux has no DPAPI. The key is a private file, the same trust model as
`~/.ssh` and the AWS CLI. A desktop keyring was deliberately not used: it makes
the command unusable over SSH and in containers, which is where a one-shot
launcher is most useful.

## How the global switch reaches every shell

`~/.config/shell/env.sh` is sourced by every zsh and POSIX login shell, and it
sources `~/.config/claude-or/env.sh` after `local.sh`. The switch therefore
wins over a machine-local `ANTHROPIC_*` setting.

`~/.zshrc` and `~/.bashrc` source it a second time, after `secrets.sh`: that
drop-in can re-export `ANTHROPIC_API_KEY`, and Claude Code prefers an API key
over the gateway token when both are present. The switch unsets the API key.

`claude-an` clears the OpenRouter variables for its own process tree, then
re-sources `secrets.sh` if it exists, so an Anthropic API key hidden by the
switch is restored for that session.

## Remove

```sh
claude-or disable                    # the switch off first
rm -rf ~/.claude-profiles/openrouter ~/.config/claude-or
```

The four commands themselves are chezmoi-managed: remove them from
`home/dot_local/bin/` and apply, or `chezmoi forget` their target paths.

## Troubleshooting

- **`claude-or status` says `STALE`** — the switch changed after this shell
  started. Open a new shell, or `. ~/.config/claude-or/env.sh`.
- **`claude-or` says no key** — `claude-or-key --set-key`.
- **Requests fail with an auth error** — check `claude-or-key --status`, and
  make sure `ANTHROPIC_API_KEY` is not exported by a machine-local file. The
  switch is applied after `local.sh`, and the interactive rc files apply it
  again after `secrets.sh`.
- **`claude` is a shell function** — the dotfiles define one for Remote Control
  session naming. `claude-or` deliberately calls the binary, because an external
  script cannot call a shell function; use plain `claude` (with the switch on)
  if you need the named session.
