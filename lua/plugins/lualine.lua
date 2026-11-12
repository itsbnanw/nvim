-- lualine: VSCode-style status line along the bottom.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

-- Defaults mirror the VSCode status bar: branch, diff, diagnostics |
-- filename | filetype/encoding | position. lualine_a is emptied to drop
-- the mode indicator (always-insert makes it noise).
require("lualine").setup({
  options = { theme = "auto" },
  sections = {
    lualine_a = {},
  },
})
