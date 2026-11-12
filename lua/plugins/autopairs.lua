-- nvim-autopairs: auto-close brackets, quotes, and pairs like VSCode.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/windwp/nvim-autopairs" })

require("nvim-autopairs").setup({
  -- Respect strings/comments once treesitter parsers are installed;
  -- without parsers this degrades to pairing everywhere.
  check_ts = true,
})
