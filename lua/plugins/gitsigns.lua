-- gitsigns: git signs in the gutter, hunk actions, and line blame.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })

require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns

    local function map(mode, lhs, rhs, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, lhs, rhs, opts)
    end

    -- Navigation
    map("n", "]h", gs.next_hunk)
    map("n", "[h", gs.prev_hunk)
    -- Actions
    map({ "n", "v" }, "gs", gs.stage_hunk)
    map({ "n", "v" }, "gr", gs.reset_hunk)
    map("n", "gp", gs.preview_hunk)
    map("n", "gb", function()
      gs.blame_line()
    end)
  end,
})
