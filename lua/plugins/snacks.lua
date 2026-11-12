-- snacks.nvim: modular UI suite. Only the modules adopted so far are
-- enabled; each config key auto-enables its module.
vim.pack.add({ "https://github.com/folke/snacks.nvim" })

require("snacks").setup({
  -- Animated smooth scrolling (replaces 'smoothscroll'; handles
  -- scrolloff and mouse wheel properly). Requires animate below.
  scroll = {},
  -- Animation framework used by scroll and other animated modules.
  animate = {},
  -- Fancy notification popups replacing plain vim.notify messages.
  notifier = {},
  -- Startup dashboard with recent files and quick actions. The default
  -- "startup" section needs lazy.nvim stats, so it is replaced with a
  -- recent-files list (we use vim.pack, not lazy).
  dashboard = {
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
      { section = "recent_files", title = "Recent Files", limit = 5, padding = 1 },
    },
  },
  -- Auto-disable heavy features (syntax, folds, plugins) on huge files.
  bigfile = {},
})
