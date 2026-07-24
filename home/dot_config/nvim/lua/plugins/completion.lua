-- lua/plugins/completion.lua — blink.cmp (decision #32).
--
-- Replaces nvim-cmp plus five source plugins with one Rust-backed engine.
-- Sub-millisecond filtering matters less for the typing feel than for what it
-- makes possible: completion can stay on without a debounce, because it never
-- blocks the UI.

return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*", -- prebuilt fuzzy binary; no cargo toolchain needed
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        -- Enter accepts, Tab moves through snippet placeholders. Deliberately
        -- NOT Tab-to-accept: Tab means indent far more often than it means
        -- "yes, that one".
        preset = "enter",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = {
          border = "rounded",
          draw = { treesitter = { "lsp" } },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        ghost_text = { enabled = false }, -- competes visually with inlay hints
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
