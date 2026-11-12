-- solarized-osaka: dark colorscheme by craftzdog (devsalife).
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.
-- setup() must run before :colorscheme per the theme's docs.

vim.pack.add({
  "https://github.com/craftzdog/solarized-osaka.nvim",
  "https://github.com/folke/tokyonight.nvim",
  "https://github.com/catppuccin/nvim",
  "https://github.com/rebelot/kanagawa.nvim",
  "https://github.com/rose-pine/neovim",
})

require("solarized-osaka").setup({})

vim.cmd("colorscheme solarized-osaka")
