# Nerd Fonts Installation Guide

## Why Nerd Fonts?

Nerd Fonts are patched fonts that include icons and glyphs from popular icon sets like:
- Font Awesome
- Devicons
- Octicons
- Powerline symbols
- Material Design Icons
- And more...

These are required for Powerlevel10k and Zellij to display icons correctly.

## Recommended Fonts (in order of preference)

### 1. MesloLGS NF (Recommended for Powerlevel10k)
**Best for**: Powerlevel10k theme
**Download**: https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k

Direct links:
- [MesloLGS NF Regular.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf)
- [MesloLGS NF Bold.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf)
- [MesloLGS NF Italic.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf)
- [MesloLGS NF Bold Italic.ttf](https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf)

### 2. FiraCode Nerd Font
**Best for**: Coding with ligatures
**Download**: https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip

### 3. JetBrainsMono Nerd Font
**Best for**: Modern coding font with excellent readability
**Download**: https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip

### 4. Hack Nerd Font
**Best for**: Clean, professional look
**Download**: https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip

## Installation Instructions

### Windows
1. Download the font files (`.ttf`)
2. Extract the ZIP if needed
3. Right-click each `.ttf` file
4. Click "Install" or "Install for all users"

### macOS
1. Download the font files (`.ttf`)
2. Extract the ZIP if needed
3. Double-click each `.ttf` file
4. Click "Install Font" in Font Book

### Linux
```bash
# Create fonts directory if it doesn't exist
mkdir -p ~/.local/share/fonts

# Download and install (example with MesloLGS NF)
cd ~/.local/share/fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

# Refresh font cache
fc-cache -fv
```

## VS Code Configuration

After installing the font, the settings in this dotfiles repo are already configured:

```json
{
  "terminal.integrated.fontFamily": "'MesloLGS NF', 'FiraCode Nerd Font', 'JetBrainsMono Nerd Font', 'Hack Nerd Font', monospace",
  "editor.fontFamily": "'MesloLGS NF', 'FiraCode Nerd Font', 'JetBrainsMono Nerd Font', 'Hack Nerd Font', 'Droid Sans Mono', monospace",
  "terminal.integrated.fontSize": 13,
  "editor.fontSize": 13,
  "editor.fontLigatures": true
}
```

**Note**: These settings will work on your local VS Code when connecting to Codespaces. The font needs to be installed on your **local machine**, not in the Codespace.

## Verify Installation

After installing and configuring:

1. Restart VS Code
2. Open a terminal
3. Run: `echo "\ue0b0 \u00b1 \ue0a0 \u27a6 \u2718 \u26a1 \u2699"`

You should see: ` ±  ➦ ✘ ⚡ ⚙` (various icons)

If you see squares or question marks, the font isn't properly installed or configured.

## Troubleshooting

### Icons still show as squares
- **Solution**: Make sure the font is installed on your **local machine**, not in the Codespace
- Restart VS Code after installing fonts
- Check that VS Code settings are applied (Ctrl/Cmd+Shift+P → "Preferences: Open Settings (JSON)")

### Font looks weird or has spacing issues
- Try adjusting `terminal.integrated.letterSpacing` in VS Code settings
- Some fonts work better with specific letter spacing values (try 0, 0.5, or 1)

### Performance issues
- Set `terminal.integrated.gpuAcceleration` to `"off"` if you experience rendering issues

## Additional Resources

- [Nerd Fonts Official Site](https://www.nerdfonts.com/)
- [Nerd Fonts Cheat Sheet](https://www.nerdfonts.com/cheat-sheet)
- [Powerlevel10k Font Guide](https://github.com/romkatv/powerlevel10k#fonts)
