-- lua/plugins/lsp.lua — language servers for all four stacks (decision #15).
--
-- ── Where the servers come from (decision #45) ───────────────────────────────
-- Every server listed here is installed by MISE, from .chezmoidata/tools.toml,
-- and found on PATH. mason.nvim is present but installs only DAP adapters
-- (see plugins/dap.lua), because those are the only things with no meaning
-- outside the editor.
--
-- The split is by whether a tool has a CLI. Anything that does — shellcheck,
-- ruff, gopls, biome — is one binary shared by this editor, the shell, the
-- pre-commit hook and CI, so they can never disagree about whether your code is
-- clean. That disagreement is a real defect this repository previously had:
-- ruff installed twice, at two independently floating versions.
--
-- A server that is not installed is simply not enabled. A `minimal` machine has
-- none of them and this file quietly does nothing.

local map = require("util.map")

-- server name -> the executable mise provides
local servers = {
  -- shell / docker / make
  bashls = "bash-language-server",
  dockerls = "docker-langserver",
  -- python
  basedpyright = "basedpyright-langserver",
  ruff = "ruff",
  -- go
  gopls = "gopls",
  -- rust
  rust_analyzer = "rust-analyzer",
  -- typescript / web
  vtsls = "vtsls",
  biome = "biome",
  html = "vscode-html-language-server",
  cssls = "vscode-css-language-server",
  jsonls = "vscode-json-language-server",
  tailwindcss = "tailwindcss-language-server",
  -- infrastructure
  terraformls = "terraform-ls",
  tflint = "tflint",
  yamlls = "yaml-language-server",
  ansiblels = "ansible-language-server",
  helm_ls = "helm-ls",
  -- lua, for this config itself
  lua_ls = "lua-language-server",
}

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      -- Correct types and completion for the vim API while editing this config.
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } },
        },
      },
    },
    config = function()
      -- ── Per-buffer keymaps, attached only where a server is running ───────
      -- Namespace c (decision #43): "code action" is <leader>ca without looking.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("dotfiles_lsp_attach", { clear = true }),
        callback = function(event)
          local buf = event.buf
          local function bmap(mode, lhs, rhs, desc)
            map(mode, lhs, rhs, desc, { buffer = buf })
          end

          bmap("n", "gd", function()
            Snacks.picker.lsp_definitions()
          end, "go to definition")
          bmap("n", "gD", function()
            Snacks.picker.lsp_declarations()
          end, "go to declaration")
          bmap("n", "gr", function()
            Snacks.picker.lsp_references()
          end, "list references")
          bmap("n", "gI", function()
            Snacks.picker.lsp_implementations()
          end, "go to implementation")
          bmap("n", "gy", function()
            Snacks.picker.lsp_type_definitions()
          end, "go to type definition")
          bmap("n", "K", vim.lsp.buf.hover, "hover documentation")
          bmap("i", "<C-k>", vim.lsp.buf.signature_help, "signature help")

          bmap("n", "<leader>cr", vim.lsp.buf.rename, "rename symbol")
          bmap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "code action")
          bmap("n", "<leader>cd", vim.diagnostic.open_float, "line diagnostics")
          bmap("n", "<leader>cR", function()
            Snacks.picker.lsp_references()
          end, "references")

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Inlay hints, where the server supports them.
          if client and client:supports_method("textDocument/inlayHint") then
            bmap("n", "<leader>ch", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
            end, "toggle inlay hints")
          end

          -- ruff is a linter and formatter, not a source of hover text;
          -- basedpyright owns that. Without this they fight over every K.
          if client and client.name == "ruff" then
            client.server_capabilities.hoverProvider = false
          end
        end,
      })

      -- ── Server configuration ─────────────────────────────────────────────
      -- Neovim 0.11 (the pinned version, decision #20) reads these from
      -- vim.lsp.config and starts them with vim.lsp.enable.
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("blink.cmp").get_lsp_capabilities({}, false)
      )
      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            codeLens = { enable = true },
            hint = { enable = true, arrayIndex = "Disable" },
            format = { enable = false }, -- stylua does this, via conform
          },
        },
      })

      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "standard",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      })

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
            usePlaceholders = true,
            analyses = { unusedparams = true, shadow = true },
            hints = { parameterNames = true, rangeVariableTypes = true },
          },
        },
      })

      vim.lsp.config("rust_analyzer", {
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            procMacro = { enable = true },
          },
        },
      })

      -- SchemaStore plus the Kubernetes schema: the reason a bad manifest is
      -- caught while typing rather than by the cluster.
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            keyOrdering = false,
            format = { enable = true },
            validate = true,
            schemaStore = { enable = true, url = "https://www.schemastore.org/api/json/catalog.json" },
          },
        },
      })

      vim.lsp.config("vtsls", {
        settings = {
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              variableTypes = { enabled = false },
            },
          },
        },
      })

      -- ── Enable only what is actually installed ───────────────────────────
      -- The honest alternative to a wall of "server not found" errors on a
      -- machine that deliberately runs a lower tier.
      local enabled = {}
      for server, exe in pairs(servers) do
        if vim.fn.executable(exe) == 1 then
          enabled[#enabled + 1] = server
        end
      end
      table.sort(enabled)
      if #enabled > 0 then
        vim.lsp.enable(enabled)
      end
    end,
  },
}
