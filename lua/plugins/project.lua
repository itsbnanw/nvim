-- project.nvim: project root detection; switches cwd per buffer so
-- telescope, git, and LSP operate on the right project.
vim.pack.add({ "https://github.com/ahmedkhalf/project.nvim" })

require("project_nvim").setup({
  detection_methods = { "pattern", "lsp" },
})
