# Nerd Fonts for Powerlevel10k

## MesloLGS NF (Included)

This directory contains the MesloLGS NF font family, specifically patched for Powerlevel10k.

**Files:**
- `MesloLGS_NF_Regular.ttf` - Regular weight
- `MesloLGS_NF_Bold.ttf` - Bold weight
- `MesloLGS_NF_Italic.ttf` - Italic style
- `MesloLGS_NF_Bold_Italic.ttf` - Bold Italic style

## Installation

### For Local Use (Install on YOUR computer, not Codespace)

**Important**: These fonts must be installed on your **local machine** where VS Code is running, not in the Codespace.

#### Windows
1. Download these `.ttf` files to your computer
2. Select all 4 `.ttf` files
3. Right-click and choose "Install" or "Install for all users"
4. Restart VS Code

#### macOS
1. Download these `.ttf` files to your computer
2. Select all 4 `.ttf` files
3. Double-click to open in Font Book
4. Click "Install Font"
5. Restart VS Code

#### Linux
```bash
# Copy fonts to local fonts directory
mkdir -p ~/.local/share/fonts
cp MesloLGS_NF_*.ttf ~/.local/share/fonts/

# Refresh font cache
fc-cache -fv
```

## Download from Codespace

If you're viewing this in a Codespace, you can download these fonts to your local machine:

1. In VS Code, navigate to `/home/codespace/dotfiles/fonts/`
2. Right-click each `.ttf` file
3. Select "Download..."
4. Install on your local machine following the instructions above

Alternatively, commit and push these fonts to your dotfiles repo, then clone on your local machine.

## Verify Installation

After installing, restart VS Code and open a terminal. Run:
```bash
echo "\ue0b0 \u00b1 \ue0a0 \u27a6 \u2718 \u26a1 \u2699"
```

You should see icons like:  ±  ➦ ✘ ⚡ ⚙

If you still see squares, the font isn't active. Check VS Code settings:
```json
{
  "terminal.integrated.fontFamily": "MesloLGS NF"
}
```
