vim.loader.enable()

require("config.options")
require("config.vscode")
require("plugins.colorscheme")
require("plugins.autopairs")
require("plugins.bufferline")
require("plugins.gitsigns")
require("plugins.lualine")
-- Mason adds its executables to PATH before native LSP servers are enabled.
require("plugins.mason")
require("plugins.lsp")
require("plugins.nvim-tree")
require("plugins.telescope")
require("plugins.smoothcursor")
require("plugins.scrollbar")
require("plugins.project")
require("plugins.snacks")

-- <C-q> quits all windows and exits, like closing the editor. :confirm
-- makes unsaved buffers offer to save first.
vim.keymap.set({ "n", "i", "v", "s", "x" }, "<C-q>", "<Cmd>confirm qa<CR>")
