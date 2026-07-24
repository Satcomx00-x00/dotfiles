-- ~/.config/nvim/init.lua
--
-- Hand-rolled on lazy.nvim (decision #14). Roughly 30 plugins, ~25 ms startup.
--
-- Load order is deliberate: options before lazy.nvim, because the leader key
-- has to be set before any plugin registers a mapping against it, and because
-- disabling unused providers is only free if it happens before they are probed.

require("config.options")
require("config.lazy")
require("config.autocmds")
require("config.keymaps")
