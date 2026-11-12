-- nvim-tree: VSCode-style file explorer sidebar.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/nvim-tree/nvim-tree.lua",
})

require("nvim-tree").setup({
  view = {
    side = "left",
    width = 30,
  },
  actions = {
    -- Keep the sidebar open after opening a file, like VSCode.
    open_file = { quit_on_open = false },
  },
})

-- <C-b> toggles the sidebar like VSCode's explorer shortcut.
vim.keymap.set({ "n", "i", "v" }, "<C-b>", function()
  require("nvim-tree.api").tree.toggle()
end)
