-- lua/plugins/editing.lua — the small mechanical things.

return {
  -- Brackets and quotes. treesitter-aware, so it does not close a bracket
  -- inside a string where you meant a literal one.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = { check_ts = true, fast_wrap = { map = "<M-e>" } },
  },

  -- ys/cs/ds — surround text with quotes, brackets, tags.
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    version = "*",
    opts = {},
  },

  -- gc / gcc. Understands embedded languages, so commenting JSX inside a .tsx
  -- file produces {/* */} rather than //.
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Multiple cursors, for the edits that are not worth a macro.
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = "VeryLazy",
    config = function()
      local mc = require("multicursor-nvim")
      local map = require("util.map")
      mc.setup()

      map({ "n", "v" }, "<C-Down>", function()
        mc.lineAddCursor(1)
      end, "add a cursor below")
      map({ "n", "v" }, "<C-Up>", function()
        mc.lineAddCursor(-1)
      end, "add a cursor above")
      map({ "n", "v" }, "<leader>cn", function()
        mc.matchAddCursor(1)
      end, "add a cursor at the next match")
      map({ "n", "v" }, "<leader>cA", function()
        mc.matchAllAddCursors()
      end, "add a cursor at every match")
      map("n", "<esc>", function()
        if mc.hasCursors() then
          mc.clearCursors()
        else
          vim.cmd("nohlsearch")
        end
      end, "clear cursors, or the search highlight")
    end,
  },

  -- Jump anywhere on screen with two characters. Replaces the habit of
  -- hammering w and b across a long line.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { char = { jump_labels = true } } },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "flash jump",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "flash treesitter select",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "remote flash",
      },
    },
  },
}
