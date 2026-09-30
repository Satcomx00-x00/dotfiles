-- lua/plugins/navigation.lua — the editor half of the Zellij boundary.
--
-- Decision #12. Ctrl-h/j/k/l moves between Neovim splits; when there is no
-- split in that direction it hands off to Zellij, which moves to the next PANE.
-- One muscle memory for both, and the seam is invisible.
--
-- The handoff is one-way: Zellij runs no navigator plugin, so from a non-editor
-- pane you move with the stock Alt-h/j/k/l. Ctrl-h is also Zellij's stock Move
-- mode, which takes the key before Neovim sees it.

return {
  {
    "swaits/zellij-nav.nvim",
    lazy = true,
    event = "VeryLazy",
    -- Only load inside Zellij. On a bare terminal or over plain SSH the plugin
    -- has nothing to talk to, and the fallback below is what you want.
    cond = function()
      return vim.env.ZELLIJ ~= nil
    end,
    keys = {
      { "<C-h>", "<cmd>ZellijNavigateLeftTab<cr>", desc = "focus left (split or Zellij pane)" },
      { "<C-j>", "<cmd>ZellijNavigateDown<cr>", desc = "focus down (split or Zellij pane)" },
      { "<C-k>", "<cmd>ZellijNavigateUp<cr>", desc = "focus up (split or Zellij pane)" },
      { "<C-l>", "<cmd>ZellijNavigateRightTab<cr>", desc = "focus right (split or Zellij pane)" },
    },
    opts = {},
  },

  -- Outside Zellij the same keys still move between splits, so the binding
  -- never simply does nothing.
  {
    "folke/snacks.nvim",
    optional = true,
    init = function()
      if vim.env.ZELLIJ ~= nil then
        return
      end
      local map = require("util.map")
      map("n", "<C-h>", "<C-w>h", "focus the split to the left")
      map("n", "<C-j>", "<C-w>j", "focus the split below")
      map("n", "<C-k>", "<C-w>k", "focus the split above")
      map("n", "<C-l>", "<C-w>l", "focus the split to the right")
    end,
  },
}
