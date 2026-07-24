-- lua/util/map.lua — the keymap helper, and the reason `dotfiles help` is complete.
--
-- Decision #37 declined which-key, so the mnemonic namespace structure of
-- decision #43 has to carry discoverability on its own, and `dotfiles help` has
-- to know every binding. 35-nvim-sync gets that list by asking a running Neovim
-- for `vim.api.nvim_get_keymap`, filtered to entries that carry a description.
--
-- Which makes an undescribed keymap invisible to help. So this helper REFUSES
-- to create one: `desc` is a required argument and omitting it is an error at
-- config-load time, not a silent gap discovered months later.
--
--     local map = require("util.map")
--     map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>", "blame this line")

local M = {}

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param desc string        REQUIRED — see above
---@param opts table|nil
local function map(mode, lhs, rhs, desc, opts)
  if type(desc) ~= "string" or desc == "" then
    error(
      ("keymap %q has no description. Every mapping must be discoverable from "):format(lhs)
        .. "`dotfiles help`, which is built from descriptions."
    )
  end
  opts = vim.tbl_extend("force", { silent = true, noremap = true, desc = desc }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Namespace headers (decision #43). Purely cosmetic without which-key, but they
-- document the intended shape of the keymap in one place, and `dotfiles help`
-- groups by the same letter.
M.namespaces = {
  f = "files",
  g = "git",
  c = "code",
  s = "search",
  b = "buffers",
  x = "diagnostics",
  u = "toggles",
  d = "debug",
}

return setmetatable(M, {
  __call = function(_, ...)
    return map(...)
  end,
})
