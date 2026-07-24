-- lua/config/options.lua — editor options. No plugins involved.
--
-- Runs before lazy.nvim so the leader is set before any plugin can register a
-- mapping against it.

local opt = vim.opt
local g = vim.g

-- ─── Leader ──────────────────────────────────────────────────────────────────
g.mapleader = " "
g.maplocalleader = "\\"

-- ─── Providers we do not use ─────────────────────────────────────────────────
-- Each of these otherwise costs a `has()` probe and, for python3, an executable
-- search on startup. Disabling them is a measurable part of the 25 ms budget.
g.loaded_python3_provider = 0
g.loaded_ruby_provider = 0
g.loaded_perl_provider = 0
g.loaded_node_provider = 0

-- ─── UI ──────────────────────────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes" -- never let the gutter appear and shift the text
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false -- lualine already shows it
opt.laststatus = 3 -- one global statusline, not one per split
opt.cmdheight = 1
opt.pumheight = 12
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.linebreak = true
-- Plain Unicode, not Nerd Font private-use codepoints: these render on a bare
-- TTY and over a serial console too, where a missing glyph becomes a box.
opt.fillchars = { eob = " ", fold = " ", foldopen = "▾", foldsep = "│", foldclose = "▸" }
opt.list = true
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- ─── Editing ─────────────────────────────────────────────────────────────────
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftround = true
opt.smartindent = true
opt.autoindent = true
opt.textwidth = 0
opt.formatoptions = "jcroqlnt"
opt.virtualedit = "block"
opt.inccommand = "nosplit" -- live preview of :s
opt.confirm = true -- ask rather than refuse on an unsaved buffer

-- ─── Search ──────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.grepprg = "rg --vimgrep --smart-case" -- same ripgrep as the shell
opt.grepformat = "%f:%l:%c:%m"

-- ─── Files and state ─────────────────────────────────────────────────────────
-- XDG paths, matching the rest of this repository. Neovim already defaults to
-- XDG for most of these; being explicit means one less thing that differs on a
-- machine with an unusual /etc/profile.
opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false -- undofile covers the real use, swap only creates conflicts
opt.backup = false
opt.writebackup = false
opt.updatetime = 200 -- CursorHold, and how fast gitsigns reacts
opt.timeoutlen = 400
opt.autoread = true
opt.hidden = true

-- ─── Completion and diagnostics ──────────────────────────────────────────────
opt.completeopt = { "menu", "menuone", "noselect" }
opt.shortmess:append({ W = true, I = true, c = true, C = true })

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✗ ",
      [vim.diagnostic.severity.WARN] = "▲ ",
      [vim.diagnostic.severity.INFO] = "● ",
      [vim.diagnostic.severity.HINT] = "◆ ",
    },
  },
})

-- ─── Clipboard — OSC52 (decision #24) ────────────────────────────────────────
-- The single change that makes remote work feel local: yanking on a REMOTE
-- server puts the text in the LOCAL clipboard, carried over the SSH connection
-- itself. No X11 forwarding, no clipboard daemon, no extra ports, and it
-- survives nesting inside Zellij.
--
-- Three cases, decided at startup because none of them can change mid-session:
--   over SSH        -> OSC52, always
--   WSL             -> win32yank, which bridges to the Windows clipboard (#41)
--   local Linux/mac -> whatever Neovim would have picked
opt.clipboard = "unnamedplus"

if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    -- Paste is deliberately a no-op that returns the register: OSC52 reads are
    -- refused by most terminals for good security reasons, and a provider that
    -- hangs waiting for a reply is worse than one that does not read.
    paste = {
      ["+"] = function()
        return vim.split(vim.fn.getreg('"'), "\n")
      end,
      ["*"] = function()
        return vim.split(vim.fn.getreg('"'), "\n")
      end,
    },
  }
elseif vim.env.WSL_DISTRO_NAME and vim.fn.executable("win32yank.exe") == 1 then
  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
    paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
    cache_enabled = false,
  }
end
