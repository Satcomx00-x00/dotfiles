-- lua/plugins/ui.lua — statusline and visual chrome.
--
-- The indent guides, notifier and dashboard all come from snacks.nvim, so this
-- file is smaller than it would otherwise be.

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      -- The theme is tokyonight's own lualine palette, which is generated from
      -- the same colours plugins/colorscheme.lua overrides — so the statusline
      -- and the buffer cannot disagree.
      return {
        options = {
          theme = "tokyonight",
          globalstatus = true, -- one bar for the whole editor; matches laststatus=3
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
        },
        sections = {
          lualine_a = {
            {
              "mode",
              fmt = function(m)
                return m:sub(1, 1)
              end,
            },
          },
          lualine_b = { { "branch", icon = "⎇" } },
          lualine_c = {
            { "diagnostics", symbols = { error = "✗ ", warn = "▲ ", info = "● ", hint = "◆ " } },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", path = 1, symbols = { modified = " ●", readonly = " ⊘", unnamed = "[No Name]" } },
          },
          lualine_x = {
            -- Only the things that are not visible elsewhere on the screen.
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
          },
          lualine_y = {
            { "progress", separator = " ", padding = { left = 1, right = 0 } },
            { "location", padding = 0 },
          },
          lualine_z = {
            function()
              return os.date("%H:%M")
            end,
          },
        },
        extensions = { "lazy", "quickfix", "man" },
      }
    end,
  },
}
