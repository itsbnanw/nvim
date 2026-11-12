-- Mason: manage language-server executables separately from LSP configuration.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/mason-org/mason.nvim" })

require("mason").setup({})
