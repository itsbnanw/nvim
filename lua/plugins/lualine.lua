-- lualine: VSCode-style status line along the bottom.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

-- Defaults already mirror the VSCode status bar: mode, branch, diff,
-- diagnostics | filename | filetype/encoding | position.
require("lualine").setup({
  options = {
    theme = "auto",
    globalstatus = false,
    disabled_filetypes = { statusline = { "NvimTree" } },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
})
