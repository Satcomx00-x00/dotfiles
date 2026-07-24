-- lua/config/autocmds.lua

local function augroup(name)
  return vim.api.nvim_create_augroup("dotfiles_" .. name, { clear = true })
end

-- Briefly highlight whatever was just yanked. With OSC52 this is also the only
-- feedback that a remote yank reached the local clipboard.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank({ timeout = 150 })
  end,
})

-- Return to the last cursor position, except in commit messages, where the top
-- of the file is always what you want.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_location"),
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[event.buf].filetype) then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(event.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- q closes throwaway windows. Every one of these is a window you got into by
-- accident at some point and could not get out of.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "man",
    "qf",
    "checkhealth",
    "lspinfo",
    "notify",
    "startuptime",
    "gitsigns-blame",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Create missing parent directories on save, rather than failing with E212.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Strip trailing whitespace on save, except where it is significant.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("trim_whitespace"),
  callback = function(event)
    if vim.tbl_contains({ "markdown", "diff", "gitsendemail" }, vim.bo[event.buf].filetype) then
      return
    end
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Indentation that matches .editorconfig for the two-space languages, without
-- pulling in an editorconfig plugin to say something this short.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_by_filetype"),
  pattern = {
    "yaml",
    "yaml.ansible",
    "json",
    "jsonc",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "html",
    "css",
    "scss",
    "lua",
    "terraform",
    "hcl",
    "markdown",
  },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
    vim.bo.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("indent_tabs"),
  pattern = { "go", "gomod", "make" },
  callback = function()
    vim.bo.expandtab = false
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
  end,
})

-- Wrap and spell-check prose, and only prose.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("prose"),
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})
