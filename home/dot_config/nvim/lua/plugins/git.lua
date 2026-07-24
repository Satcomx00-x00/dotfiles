-- lua/plugins/git.lua — hunks and blame in the gutter.
--
-- lazygit itself comes from snacks.nvim (<leader>gg); this is the inline layer.
-- Namespace g (decision #43).

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      current_line_blame = false, -- toggled on demand; always-on is noise
      current_line_blame_opts = { delay = 400, virt_text_pos = "eol" },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local map = require("util.map")

        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "next hunk", { buffer = buffer })

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "previous hunk", { buffer = buffer })

        map({ "n", "v" }, "<leader>gh", gs.stage_hunk, "stage hunk", { buffer = buffer })
        map({ "n", "v" }, "<leader>gr", gs.reset_hunk, "reset hunk", { buffer = buffer })
        map("n", "<leader>gp", gs.preview_hunk_inline, "preview hunk", { buffer = buffer })
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "blame this line", { buffer = buffer })
        map("n", "<leader>gB", gs.blame, "blame this file", { buffer = buffer })
        map("n", "<leader>gd", gs.diffthis, "diff against the index", { buffer = buffer })
        map("n", "<leader>gu", gs.undo_stage_hunk, "unstage the last staged hunk", { buffer = buffer })
        map("n", "<leader>ub", gs.toggle_current_line_blame, "toggle inline blame", { buffer = buffer })
        map({ "o", "x" }, "ih", gs.select_hunk, "select hunk", { buffer = buffer })
      end,
    },
  },
}
