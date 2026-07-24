-- lua/plugins/format.lua — formatting and linting.
--
-- Decision #45 in its most concrete form: every binary named below is the SAME
-- binary the shell, the pre-commit hook and CI use, installed once by mise from
-- .chezmoidata/tools.toml. Not a mason copy, not a bundled copy, not a pip
-- install into a virtualenv. That is what makes "format on save" and "the CI
-- format check" agree by construction rather than by luck.

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        python = { "ruff_format", "ruff_organize_imports" },
        go = { "gofumpt" },
        rust = { "rustfmt" },
        javascript = { "biome", "prettier", stop_after_first = true },
        typescript = { "biome", "prettier", stop_after_first = true },
        javascriptreact = { "biome", "prettier", stop_after_first = true },
        typescriptreact = { "biome", "prettier", stop_after_first = true },
        json = { "biome", "prettier", stop_after_first = true },
        jsonc = { "biome", "prettier", stop_after_first = true },
        css = { "biome", "prettier", stop_after_first = true },
        html = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        terraform = { "terraform_fmt" },
        hcl = { "terraform_fmt" },
      },
      format_on_save = function(bufnr)
        -- An escape hatch for the file you are mid-way through restructuring,
        -- and for a repo whose formatting you do not own.
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
      formatters = {
        -- Match .editorconfig: 4-space shell indent, indented case bodies.
        shfmt = { prepend_args = { "-i", "4", "-ci", "-sr" } },
      },
    },
    init = function()
      local map = require("util.map")
      map("n", "<leader>uf", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("format on save " .. (vim.g.disable_autoformat and "off" or "on"))
      end, "toggle format on save")
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        dockerfile = { "hadolint" },
        yaml = { "yamllint" },
        ["yaml.ansible"] = { "ansible_lint" },
        terraform = { "tflint" },
        go = { "golangcilint" },
      }

      -- Lint on write and on leaving insert, not on every keystroke: these are
      -- real processes, and shellcheck on a large script is not free.
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("dotfiles_lint", { clear = true }),
        callback = function()
          local names = lint.linters_by_ft[vim.bo.filetype] or {}
          local runnable = {}
          for _, name in ipairs(names) do
            local linter = lint.linters[name]
            -- Silently skip a linter this tier did not install.
            if linter and vim.fn.executable(linter.cmd or name) == 1 then
              runnable[#runnable + 1] = name
            end
          end
          if #runnable > 0 then
            lint.try_lint(runnable)
          end
        end,
      })
    end,
  },
}
