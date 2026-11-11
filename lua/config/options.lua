-- Behavior
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.confirm = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.undofile = true
vim.opt.switchbuf = "useopen,uselast"
vim.opt.shortmess:append("I")
vim.opt.clipboard:append("unnamedplus")
vim.opt.whichwrap:append("h,l")

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.wrapscan = true

-- Indentation
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

-- Completion and wildmenu
vim.opt.completeopt:append("menuone")
vim.opt.completeopt:append("noselect")
vim.opt.completeopt:append("popup")
vim.opt.wildmode = "longest:full,full"

-- Display
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.listchars = {
  tab = "» ",
  trail = "·",
  nbsp = "␣",
}
vim.opt.fillchars = {
  horiz = "─",
  vert = "│",
  eob = " ",
  fold = "·",
  diff = "╱",
}
vim.opt.winborder = "single"
vim.opt.pumborder = "rounded"
