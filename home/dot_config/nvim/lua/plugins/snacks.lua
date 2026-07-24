-- lua/plugins/snacks.lua — the picker, and about twenty other things.
--
-- Decision #32. snacks.nvim replaces telescope and roughly six single-purpose
-- plugins: it is faster than telescope on large trees, and one dependency is
-- one thing to keep working rather than seven.
--
-- Namespaces follow decision #43: f files, g git, s search, b buffers.

local map = require("util.map")

return {
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false, -- provides the notifier and the dashboard, both needed at start
    opts = {
      bigfile = { enabled = true }, -- disable the expensive things on huge files
      quickfile = { enabled = true }, -- render before plugins load
      notifier = { enabled = true, timeout = 3000, style = "compact" },
      indent = { enabled = true, animate = { enabled = false } },
      input = { enabled = true },
      scope = { enabled = true },
      words = { enabled = true }, -- highlight other references to the symbol
      statuscolumn = { enabled = true },

      -- Decision #25 applies inside the editor too: a dashboard, not a splash.
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = "⌕ ", key = "f", desc = "Find file", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "✚ ", key = "n", desc = "New file", action = ":ene | startinsert" },
            { icon = "⌕ ", key = "g", desc = "Grep", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "◷ ", key = "r", desc = "Recent", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = "⚙ ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = "⏻ ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },

      picker = {
        ui_select = true, -- vim.ui.select goes through the picker too
        win = { input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } } },
      },

      -- lazygit inherits the theme automatically; snacks passes the colours in.
      lazygit = { configure = true },
      gitbrowse = { enabled = true },
      terminal = { win = { style = "terminal" } },
      scratch = { enabled = true },
    },

    keys = {
      -- ── f: files ──────────────────────────────────────────────────────────
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "find files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "recent files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "git-tracked files",
      },
      {
        "<leader>fe",
        function()
          Snacks.explorer()
        end,
        desc = "file explorer",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "nvim config files",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "projects",
      },

      -- ── s: search ─────────────────────────────────────────────────────────
      {
        "<leader>sg",
        function()
          Snacks.picker.grep()
        end,
        desc = "grep the tree",
      },
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "grep the word under the cursor",
        mode = { "n", "x" },
      },
      {
        "<leader>sb",
        function()
          Snacks.picker.lines()
        end,
        desc = "search in this buffer",
      },
      {
        "<leader>ss",
        function()
          Snacks.picker.lsp_symbols()
        end,
        desc = "document symbols",
      },
      {
        "<leader>sS",
        function()
          Snacks.picker.lsp_workspace_symbols()
        end,
        desc = "workspace symbols",
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "diagnostics",
      },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "help tags",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "keymaps",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "marks",
      },
      {
        "<leader>sr",
        function()
          Snacks.picker.registers()
        end,
        desc = "registers",
      },
      {
        "<leader>sq",
        function()
          Snacks.picker.qflist()
        end,
        desc = "quickfix list",
      },
      {
        "<leader>su",
        function()
          Snacks.picker.undo()
        end,
        desc = "undo history",
      },
      {
        "<leader>sn",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "notification history",
      },

      -- ── b: buffers ────────────────────────────────────────────────────────
      {
        "<leader>bl",
        function()
          Snacks.picker.buffers()
        end,
        desc = "list buffers",
      },

      -- ── g: git ────────────────────────────────────────────────────────────
      {
        "<leader>gg",
        function()
          Snacks.lazygit()
        end,
        desc = "lazygit",
      },
      {
        "<leader>gl",
        function()
          Snacks.picker.git_log()
        end,
        desc = "git log",
      },
      {
        "<leader>gL",
        function()
          Snacks.picker.git_log_line()
        end,
        desc = "git log for this line",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "git status",
      },
      {
        "<leader>gB",
        function()
          Snacks.gitbrowse()
        end,
        desc = "open in the browser",
        mode = { "n", "v" },
      },

      -- ── misc ──────────────────────────────────────────────────────────────
      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "scratch buffer",
      },
      {
        "<leader>tt",
        function()
          Snacks.terminal()
        end,
        desc = "terminal",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "dismiss notifications",
      },
      {
        "]]",
        function()
          Snacks.words.jump(1, true)
        end,
        desc = "next reference",
        mode = { "n", "t" },
      },
      {
        "[[",
        function()
          Snacks.words.jump(-1, true)
        end,
        desc = "previous reference",
        mode = { "n", "t" },
      },
    },

    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- Route vim.notify and the debug helpers through snacks once it is up.
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          vim.print = _G.dd

          map("n", "<leader>ur", function()
            Snacks.rename.rename_file()
          end, "rename this file")
        end,
      })
    end,
  },
}
