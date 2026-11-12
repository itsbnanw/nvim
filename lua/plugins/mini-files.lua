-- mini.files: file explorer as an editable buffer (mini.nvim suite).
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/echasnovski/mini.nvim" })

require("mini.files").setup({
  windows = {
    preview = true,
    width_focus = 30,
    width_preview = 30,
  },
  options = {
    use_git_vimgrep = true,
  },
})

-- <C-b> toggles the explorer like VSCode's sidebar shortcut. This takes
-- over the built-in Ctrl+B page-up; PageUp covers that.
local function toggle_files()
  local MiniFiles = require("mini.files")
  if MiniFiles.close() == nil then
    MiniFiles.open()
  end
end

vim.keymap.set({ "n", "i", "v" }, "<C-b>", toggle_files)
