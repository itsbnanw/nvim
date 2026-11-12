-- telescope: fuzzy finder for files, buffers, grep, and commands.
-- plenary.nvim is a required dependency; telescope-fzf-native provides
-- the fzf sorter. Installed by the built-in vim.pack manager; sources
-- live under the data dir's site/pack/core/opt and are tracked by
-- nvim-pack-lock.json.

vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
})

require("telescope").setup({
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      case_mode = "smart_case",
    },
  },
})
require("telescope").load_extension("fzf")

-- VSCode shortcuts: <C-p> quick-open files, <C-S-f> search in files.
vim.keymap.set({ "n", "i" }, "<C-p>", function()
  require("telescope.builtin").find_files()
end)
vim.keymap.set({ "n", "i" }, "<C-S-f>", function()
  require("telescope.builtin").live_grep()
end)

-- Meta-picker: <C-S-p> lists every telescope picker (builtins plus
-- extensions) with source preview; <CR> runs it.
vim.keymap.set({ "n", "i" }, "<C-S-p>", function()
  require("telescope.builtin").builtin({ include_extensions = true })
end)
