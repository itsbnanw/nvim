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

-- Meta-picker: <C-S-p> lists every telescope builtin picker; type to
-- filter and <CR> runs it (a command palette for pickers).
local function pickers_picker()
  local builtin = require("telescope.builtin")
  local names = {}
  for name, value in pairs(builtin) do
    if type(value) == "function" then
      table.insert(names, name)
    end
  end
  table.sort(names)

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    :new({}, {
      prompt_title = "Telescope pickers",
      finder = finders.new_table({ results = names }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        map({ "i", "n" }, "<CR>", function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local name = type(entry) == "table" and (entry.value or entry.ordinal) or entry
          if name then
            local ok, err = pcall(builtin[name])
            if not ok then
              vim.notify(
                "telescope picker failed: " .. name .. " (" .. tostring(err) .. ")",
                vim.log.levels.ERROR
              )
            end
          end
        end)
        return true
      end,
    })
    :find()
end

vim.keymap.set({ "n", "i" }, "<C-S-p>", pickers_picker)
