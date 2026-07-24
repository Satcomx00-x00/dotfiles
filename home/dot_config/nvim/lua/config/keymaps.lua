-- lua/config/keymaps.lua — core keymaps.
--
-- Decision #43: Space leader, mnemonic namespaces. With which-key declined, the
-- STRUCTURE has to carry discoverability, so every binding lives under a letter
-- that names its domain:
--
--   <leader>f  files        <leader>s  search
--   <leader>g  git          <leader>b  buffers
--   <leader>c  code         <leader>x  diagnostics
--   <leader>u  toggles      <leader>d  debug
--
-- The payoff is that "git blame" is almost certainly <leader>gb without looking
-- it up. Plugin-specific bindings live with their plugin; this file holds the
-- ones that need no plugin at all.
--
-- Every mapping goes through util.map, which REQUIRES a description — see the
-- comment there for why.

local map = require("util.map")

-- ─── Movement ────────────────────────────────────────────────────────────────
-- Move by visual line when wrapped, unless a count was given (so 5j still
-- means five real lines, and the jumplist stays intact).
map({ "n", "x" }, "j", function()
  return vim.v.count > 0 and "j" or "gj"
end, "down (visual line)", { expr = true })
map({ "n", "x" }, "k", function()
  return vim.v.count > 0 and "k" or "gk"
end, "up (visual line)", { expr = true })

-- Keep the cursor centred when jumping half a page or through search results.
map("n", "<C-d>", "<C-d>zz", "half page down, centred")
map("n", "<C-u>", "<C-u>zz", "half page up, centred")
map("n", "n", "nzzzv", "next match, centred")
map("n", "N", "Nzzzv", "previous match, centred")

-- ─── Windows — Ctrl-hjkl, crossing into Zellij (decision #12) ────────────────
-- Defined in plugins/navigation.lua, which owns the Zellij handoff.

-- ─── Editing ─────────────────────────────────────────────────────────────────
map("v", "<", "<gv", "outdent and keep the selection")
map("v", ">", ">gv", "indent and keep the selection")
map("v", "J", ":m '>+1<cr>gv=gv", "move selection down")
map("v", "K", ":m '<-2<cr>gv=gv", "move selection up")
-- Paste over a selection without losing the register to the thing you replaced.
map("x", "p", [["_dP]], "paste without clobbering the register")
map({ "n", "v" }, "<leader>D", [["_d]], "delete without clobbering the register")

map("n", "<Esc>", "<cmd>nohlsearch<cr>", "clear search highlight")
map("i", "<C-c>", "<Esc>", "escape (and trigger InsertLeave)")

-- Undo breakpoints, so one careless u does not swallow a whole paragraph.
for _, ch in ipairs({ ",", ".", ";", "(", "[", "{" }) do
  map("i", ch, ch .. "<c-g>u", "undo breakpoint after " .. ch)
end

-- ─── Files ───────────────────────────────────────────────────────────────────
map("n", "<C-s>", "<cmd>w<cr><esc>", "save file")
map("n", "<leader>fn", "<cmd>enew<cr>", "new file")
map("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify(path, vim.log.levels.INFO, { title = "copied path" })
end, "yank the file path")

-- ─── Buffers ─────────────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<cr>", "previous buffer")
map("n", "<S-l>", "<cmd>bnext<cr>", "next buffer")
map("n", "<leader>bb", "<cmd>e #<cr>", "switch to the alternate buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "close buffer")
map("n", "<leader>bD", "<cmd>%bdelete|edit #|bdelete #<cr>", "close all other buffers")

-- ─── Diagnostics ─────────────────────────────────────────────────────────────
map("n", "<leader>xx", vim.diagnostic.setloclist, "diagnostics to the location list")
map("n", "<leader>xd", vim.diagnostic.open_float, "show diagnostic under the cursor")
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, "next diagnostic")
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, "previous diagnostic")
map("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, "next error")
map("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, "previous error")

-- ─── Toggles ─────────────────────────────────────────────────────────────────
map("n", "<leader>uw", function()
  vim.opt_local.wrap = not vim.opt_local.wrap:get()
end, "toggle wrap")
map("n", "<leader>un", function()
  vim.opt_local.number = not vim.opt_local.number:get()
  vim.opt_local.relativenumber = not vim.opt_local.relativenumber:get()
end, "toggle line numbers")
map("n", "<leader>us", function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
end, "toggle spell check")
map("n", "<leader>ud", function()
  local on = not vim.diagnostic.is_enabled()
  vim.diagnostic.enable(on)
  vim.notify("diagnostics " .. (on and "on" or "off"))
end, "toggle diagnostics")
map("n", "<leader>ul", function()
  vim.opt_local.list = not vim.opt_local.list:get()
end, "toggle invisible characters")

-- ─── Quit ────────────────────────────────────────────────────────────────────
map("n", "<leader>qq", "<cmd>qa<cr>", "quit all")
map("n", "<leader>qw", "<cmd>wqa<cr>", "write all and quit")
