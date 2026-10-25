# Windows

The `windows` branch applies the same repository to a Windows 11 workstation:
Alacritty as the terminal, Zellij inside it, pwsh 7 inside Zellij — with the
palette, font and keybindings of the Linux setup.

## Install

Prerequisites (once): `winget install jdx.mise Alacritty.Alacritty Microsoft.PowerShell` — starship and the rest come from mise

```powershell
mise use -g chezmoi
chezmoi init --apply --branch windows Satcomx00-x00
```

`chezmoi init` detects the `workstation` profile on Windows (there is no
`DISPLAY` to test). `.ps1` scripts run under pwsh 7, not Windows PowerShell 5.1.

## What lands where

| Source                                         | Target on Windows                                   |
| ---------------------------------------------- | --------------------------------------------------- |
| `AppData/Roaming/alacritty/alacritty.toml.tmpl` | `%APPDATA%\alacritty\alacritty.toml` (includes the XDG template) |
| `AppData/Roaming/Zellij/config/config.kdl.tmpl` | `%APPDATA%\Zellij\config\config.kdl` (includes the XDG template) |
| `dot_config/zellij/layouts/`                   | `~\.config\zellij\layouts`, via `layout_dir`         |
| `Documents/PowerShell/…profile.ps1`            | pwsh 7 profile                                      |
| `Documents/WindowsPowerShell/…profile.ps1`     | Windows PowerShell 5.1 profile                      |
| `dot_config/mise/config.toml.tmpl`             | `tools.toml` entries named in `.chezmoidata/windows.toml` (`fromTools`), plus its Windows-only `extra` |
| `dot_config/yasb/`                             | yasb status bar                                     |
| `dot_wslconfig`                                | `~\.wslconfig`                                      |
| git, starship, bat, ripgrep, k9s               | the usual `~\.config` paths (the profile sets `BAT_CONFIG_PATH`, `RIPGREP_CONFIG_PATH`, `K9S_CONFIG_DIR`) |

Each Windows difference in a shared template sits behind
`{{ if eq .chezmoi.os "windows" }}`, so Linux renders the same output as `main`.

## Not managed on Windows

- The POSIX shell stack (bash, zsh, `~/.config/shell`, zsh externals, `.sh` scripts).
- `~/.ssh` — Windows OpenSSH has no `ControlMaster`, and the host list is private.
- `~/.claude` — per-machine.
- `~/.gitconfig` — stays local (credential helpers, `safe.directory`); it is read
  after `~/.config/git/config` and wins where both set a key.
- `~/.config/powershell/local.ps1` — machine-specific functions, sourced last by the profile.

## Secrets

The yasb weather widget reads its key from `YASB_WEATHER_API_KEY` at apply time:

```powershell
[Environment]::SetEnvironmentVariable('YASB_WEATHER_API_KEY', '<key>', 'User')
```

## Default terminal

Windows' *Default terminal application* setting only accepts Windows Terminal
and conhost. `run_onchange_after_60-alacritty-default.ps1` instead adds an
*Ouvrir dans Alacritty* Explorer entry and a Ctrl+Alt+T Start-menu shortcut.
