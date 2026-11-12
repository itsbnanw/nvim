-- bufferline: VSCode-style tab bar across the top.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/akinsho/bufferline.nvim" })

require("bufferline").setup({
  options = {
    mode = "buffers",
    numbers = "none",
    close_command = "bdelete!",
    right_mouse_command = "bdelete!",
    show_buffer_close = true,
    offsets = {
      {
        filetype = "NvimTree",
        text = "Explorer",
        highlight = "Directory",
        padding = 1,
      },
    },
  },
})
