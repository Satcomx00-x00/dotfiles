---
description: Work on the chezmoi dotfiles repository
---

You are working in the chezmoi dotfiles repository.

Read `IMPLEMENTATION.md` before changing anything structural — in particular
§3 (the three invariants) and §5 (code conventions).

Key rules, which the harness enforces:

- **One fact, one file.** Colours live only in `.chezmoidata/theme.toml`, tools
  only in `tools.toml`, keybindings only in `keys.toml`. Everything else is
  generated. `make theme-check` fails if a config hardcodes a colour.
- **Compile-time beats runtime.** Anything knowable at `chezmoi apply` is a
  template conditional, not a shell `if`. The 60 ms startup budget depends on it.
- **Every alias and function needs a `# @group`.** `make lint-help` fails
  otherwise, because `dotfiles help` is generated from those markers.
- **Nothing under `~/.config/shell/` may print at load time.** A single stray
  echo breaks scp, rsync and git-over-ssh.

Before claiming anything works:

    make check          # render, lint, help, theme — no container needed
    make sandbox        # full bootstrap in a throwaway container

$ARGUMENTS
