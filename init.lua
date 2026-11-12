vim.loader.enable()

require("config.options")
require("config.vscode")
require("plugins.colorscheme")
require("plugins.autopairs")
require("plugins.bufferline")
require("plugins.gitsigns")
require("plugins.lualine")
require("plugins.nvim-tree")
require("plugins.telescope")

-- <C-q> quits all windows and exits, like closing the editor. :confirm
-- makes unsaved buffers offer to save first.
vim.keymap.set({ "n", "i", "v", "s", "x" }, "<C-q>", "<Cmd>confirm qa<CR>")
