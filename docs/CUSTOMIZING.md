# Customizing

The rule that makes this repository maintainable: **one fact lives in one file,
and everything else is generated from it.** Before adding anything, check
whether a data file already owns it.

| To change... | Edit only |
| --- | --- |
| A colour, anywhere | `home/.chezmoidata/theme.toml` |
| The tool list | `home/.chezmoidata/tools.toml` |
| Base OS packages | `home/.chezmoidata/packages.toml` |
| Zellij or shell keybindings shown in help | `home/.chezmoidata/keys.toml` |

## Add a tool

One entry in `home/.chezmoidata/tools.toml`:

```toml
[[tools.list]]
name    = "difftastic"
backend = "aqua:Wilfred/difftastic"   # aqua first — free signature verification
version = "latest"
rank    = 1                            # 0 minimal, 1 standard, 2 full
group   = "git"
role    = "structural diff"
bin     = "difft"                      # only when it differs from `name`
```

That one entry reaches six consumers: `~/.config/mise/config.toml`, the install
script's re-run hash, `dotfiles doctor`, `dotfiles help`, the README table, and
the post-apply assertions. Nothing else is edited.

```sh
make verify-tools     # does the backend actually resolve?
make docs             # regenerate the README table
chezmoi apply
```

A pinned version (anything other than `latest`) **requires** a `pin = "why"`
field. `make lint` fails without it, so nobody freezes a version by accident and
leaves no note saying why.

## Add an alias or function

Edit `home/dot_config/shell/aliases.sh.tmpl` or `functions.sh.tmpl`. It must sit
under a `# @group` header:

```sh
# @group git — version control
alias gwt='git worktree'

# @help what the body does not make obvious
gclean() { ... }
```

`make lint-help` fails on a definition with no group, because `dotfiles help` is
built from those markers — an undocumented alias is a build error, not an
omission. `@help` is optional: without it the definition itself is the
description, which is enough for `alias gs='git status -sb'`.

Both files are POSIX `sh`, sourced by bash and zsh. No arrays, no `[[`, no
bashisms, and **nothing may print at load time** — a stray echo breaks `scp`,
`rsync` and git-over-ssh.

## Change the theme

Edit the palette in `home/.chezmoidata/theme.toml`. Twelve consumers follow.

```sh
make theme-check      # proves exactly the declared consumers changed
```

Adding a new themed config means adding it to `test/theme-consumers.txt` as
well. The check runs in both directions: a declared consumer that does not
change has hardcoded its colours, and an undeclared one that does change is a
consumer nobody wrote down.

## Add a language

1. The CLI tools — LSP, linter, formatter — go in `tools.toml` with `group = "lsp"`.
   They come from mise so one binary serves the editor, the shell, the
   pre-commit hook and CI (decision #45).
2. Map the server name to its executable in
   `home/dot_config/nvim/lua/plugins/lsp.lua`. A server whose executable is
   absent is simply not enabled, so a lower tier needs no extra handling.
3. Add formatters to `formatters_by_ft` in `plugins/format.lua`, linters to
   `linters_by_ft`.
4. Add the treesitter parser to `ensure_installed` in `plugins/treesitter.lua`.

**Only DAP adapters go in mason.nvim** — they have no meaning as CLI tools, so
there is nothing to share. Everything else comes from mise.

## Machine-local settings

Never commit these. Two unmanaged files exist for them:

```sh
~/.config/shell/local.sh    # env, PATH, machine-specific aliases; sourced last
~/.ssh/config.d/work.conf   # your real hosts; included by the managed ssh config
```

This is decision #30, and it is what lets the repository be public.

## Add a machine profile

Profiles are `workstation`, `server`, `container`. Adding a fourth means:

1. Add it to the `promptChoiceOnce` list in `home/.chezmoi.toml.tmpl`, and give
   every derived flag a value for it.
2. Add a fixture in `test/fixtures/` — `test/render.sh` compares fixture keys
   against the real schema, so a missing key fails immediately.
3. Run `make render`.

## Known limitations

**Neovim buffer-local keymaps are not in `dotfiles help`.** The help index is
built by asking a headless Neovim for `nvim_get_keymap`, which returns global
maps only. gitsigns' `<leader>g` hunk bindings and every LSP binding (`gd`,
`gr`, `<leader>c*`) are registered by an `on_attach` callback that does not fire
headlessly — this was tried, and gitsigns attaches without ever calling it.

Those bindings work normally when you are editing; they simply are not indexed.
They follow the same mnemonic namespaces (decision #43), which is what makes
them guessable, and they are listed in the plugin files:
`lua/plugins/git.lua` and `lua/plugins/lsp.lua`.
