-- lua/config/lazy.lua — plugin manager bootstrap.
--
-- lazy.nvim installs itself on first launch. In practice that first launch is
-- headless, driven by 35-nvim-sync during `chezmoi apply`, so the first
-- interactive start is instant rather than a two-minute download.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    error("lazy.nvim clone failed:\n" .. out)
  end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },

  defaults = {
    -- Everything is lazy unless a plugin explicitly opts out. The colourscheme
    -- and snacks.nvim are the only two that load at startup, because a theme
    -- that arrives late produces a visible flash.
    lazy = true,
    version = false, -- track the default branch; decision #20 floats versions
  },

  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = false }, -- decision #34: updates are manual, always
  change_detection = { enabled = false, notify = false },

  ui = { border = "rounded", backdrop = 100 },

  performance = {
    rtp = {
      -- Built-in plugins that cost runtimepath scanning and do nothing this
      -- config wants. Disabling them is most of the difference between a
      -- 40 ms and a 25 ms startup.
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "rplugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
