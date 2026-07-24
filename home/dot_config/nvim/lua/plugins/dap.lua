-- lua/plugins/dap.lua — debugging.
--
-- The ONLY place mason.nvim is used (decision #45). DAP adapters — codelldb,
-- debugpy, delve — have no meaning as CLI tools, so nothing outside the editor
-- wants them and there is no shared-binary argument for putting them in mise.
-- Everything with a CLI comes from mise; these do not, so they come from mason.
--
-- Namespace d (decision #43).

return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "toggle breakpoint",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "conditional breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "continue / start",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "step over",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "step out",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "terminate",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "toggle REPL",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "run the last configuration",
      },
    },
    dependencies = {
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },
        keys = {
          {
            "<leader>du",
            function()
              require("dapui").toggle({})
            end,
            desc = "toggle debug UI",
          },
          {
            "<leader>de",
            function()
              require("dapui").eval()
            end,
            desc = "evaluate expression",
            mode = { "n", "v" },
          },
        },
        opts = {},
        config = function(_, opts)
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup(opts)
          -- Open the UI when a session starts, close it when it ends. Doing
          -- this by hand every time is how nvim-dap gets a reputation.
          dap.listeners.after.event_initialized.dapui = function()
            dapui.open({})
          end
          dap.listeners.before.event_terminated.dapui = function()
            dapui.close({})
          end
          dap.listeners.before.event_exited.dapui = function()
            dapui.close({})
          end
        end,
      },
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = { "mason-org/mason.nvim" },
        cmd = { "DapInstall", "DapUninstall" },
        opts = {
          automatic_installation = true,
          handlers = {},
          ensure_installed = { "codelldb", "python", "delve" },
        },
      },
    },
    config = function()
      local dap = require("dap")
      -- Breakpoint signs use the shared semantic roles from theme.toml, via the
      -- diagnostic highlight groups colorscheme.lua defines.
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◐", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticInfo", linehl = "Visual" })

      -- A Go debug session that has to be configured by hand every time is a
      -- Go debug session that never happens.
      dap.configurations.go = dap.configurations.go
        or { { type = "go", name = "Debug this file", request = "launch", program = "${file}" } }
    end,
  },
}
