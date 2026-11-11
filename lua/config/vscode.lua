-- VSCode-like editing behavior: always-insert emulation, word-wise
-- Ctrl+arrow motion, Shift-selection, and system-clipboard editing.
-- Disable everything by commenting out `require("config.vscode")` in init.lua.

-- Options -------------------------------------------------------------------

vim.opt.clipboard:append("unnamedplus")
vim.opt.whichwrap:append("h,l")

-- Insertmode emulation (ported from :h vim_diff) ------------------------------

local augroup = vim.api.nvim_create_augroup("config.vscode", { clear = true })

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup,
  callback = function()
    vim.cmd.startinsert()
  end,
})

vim.api.nvim_create_autocmd("CmdwinEnter", {
  group = augroup,
  callback = function()
    vim.keymap.set("n", "<C-c>", "<C-c>", { buffer = true })
    vim.keymap.set("i", "<C-c>", "<C-c>", { buffer = true })
  end,
})

vim.keymap.set("i", "<Esc>", "<C-X><C-Z><C-[>")
vim.keymap.set("i", "<C-c>", "<C-X><C-Z>")
vim.keymap.set("i", "<C-l>", "<C-X><C-Z><C-]><Esc>")
vim.keymap.set("i", "<C-z>", "<C-X><C-Z><Cmd>suspend<CR>")
vim.keymap.set("n", "<C-c>", "<Esc>")
vim.keymap.set("s", "<C-c>", "<Esc>")
vim.keymap.set("n", "<C-\\><C-G>", "<C-\\><C-N><Cmd>startinsert<CR>")
vim.keymap.set("c", "<C-\\><C-G>", "<C-\\><C-N><Cmd>startinsert<CR>")
vim.keymap.set("i", "<C-\\><C-G>", "<C-X><C-Z>")

vim.on_key(function(key)
  if key ~= "\27" then
    return
  end
  local mode = vim.api.nvim_get_mode().mode
  if mode:find("^[nvV\22sS\19]") and vim.fn.getcmdtype() == "" then
    vim.schedule(function()
      vim.cmd.startinsert()
    end)
  end
end)

-- Clipboard ------------------------------------------------------------------

-- In Select mode a ":smap" rhs would treat printable chars as replacement
-- text, so copy/cut/paste live only in "v" (Visual+Select): :vmap auto-switches
-- to Visual for the command, then returns to Select.
if vim.fn.maparg("<C-c>", "s") ~= "" then
  vim.keymap.del("s", "<C-c>")
end
-- Copy keeps the selection like VSCode: yank, gv reselects the same area,
-- <C-g> converts back to Select mode.
vim.keymap.set("v", "<C-c>", '"+ygv<C-g>')
vim.keymap.set("v", "<C-x>", '"+d<Cmd>startinsert<CR>')
vim.keymap.set("i", "<C-v>", "<C-r>+")
vim.keymap.set("n", "<C-v>", '"+gp<Cmd>startinsert<CR>')
vim.keymap.set("v", "<C-v>", '"+pa')

-- Word motion and selection ---------------------------------------------------

-- Ctrl+arrows: word-wise motion in Normal/Visual/Select (Insert is built-in).
for _, mode in ipairs({ "n", "v" }) do
  vim.keymap.set(mode, "<C-Left>", "b")
  vim.keymap.set(mode, "<C-Right>", "w")
end

-- Shift+arrows in Normal: start a Select-mode selection (v + motion + <C-g>
-- converts Visual to Select, giving type-over-selection like VSCode).
vim.keymap.set("n", "<C-S-Left>", "vb<C-g>")
vim.keymap.set("n", "<C-S-Right>", "vw<C-g>")
vim.keymap.set("n", "<S-Left>", "vh<C-g>")
vim.keymap.set("n", "<S-Right>", "vl<C-g>")
vim.keymap.set("n", "<C-S-Home>", "vgg<C-g>")
vim.keymap.set("n", "<C-S-End>", "vG<C-g>")
vim.keymap.set("n", "<S-Up>", "vk<C-g>")
vim.keymap.set("n", "<S-Down>", "vj<C-g>")
vim.keymap.set("n", "<S-Home>", "v0<C-g>")
vim.keymap.set("n", "<S-End>", "v$<C-g>")

-- Shift(+Ctrl)+arrows in Visual/Select: extend the selection. "v" mappings
-- also cover Select mode (auto-switch to Visual for the motion, then back).
vim.keymap.set("v", "<C-S-Left>", "b")
vim.keymap.set("v", "<C-S-Right>", "w")
vim.keymap.set("v", "<C-S-Home>", "gg")
vim.keymap.set("v", "<C-S-End>", "G")
vim.keymap.set("v", "<S-Left>", "h")
vim.keymap.set("v", "<S-Right>", "l")
vim.keymap.set("v", "<S-Up>", "k")
vim.keymap.set("v", "<S-Down>", "j")
vim.keymap.set("v", "<S-Home>", "0")
vim.keymap.set("v", "<S-End>", "$")

-- Same, started from Insert mode: leave Insert, select via Visual, convert
-- to Select. The <Esc> goes through "m" (remap) so the safe insert-<Esc>
-- mapping above cancels any completion popup first. Esc steps the cursor
-- back onto the char left of the caret, so rightward selections take a
-- leading "l" to anchor on the char right of the caret; "w" is paired with
-- "h" so the selection stops before the next word's first char.
local function select_from_insert(pre, motion)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Esc>", true, true, true),
    "m",
    false
  )
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(pre .. "v" .. motion .. "<C-g>", true, true, true),
    "n",
    false
  )
end

vim.keymap.set("i", "<C-S-Left>", function()
  select_from_insert("", "b")
end)
vim.keymap.set("i", "<C-S-Right>", function()
  select_from_insert("l", "wh")
end)
vim.keymap.set("i", "<C-S-Home>", function()
  select_from_insert("", "gg")
end)
vim.keymap.set("i", "<C-S-End>", function()
  select_from_insert("l", "G")
end)
vim.keymap.set("i", "<S-Left>", function()
  select_from_insert("", "")
end)
vim.keymap.set("i", "<S-Right>", function()
  select_from_insert("l", "")
end)
vim.keymap.set("i", "<S-Home>", function()
  select_from_insert("", "0")
end)
vim.keymap.set("i", "<S-End>", function()
  select_from_insert("l", "$")
end)
-- Vertical selections keep the caret column: position at the char right of
-- the caret first ("l"), move across the line break in Normal mode for Up
-- ("k"), then extend with j and trim the extra char with h.
vim.keymap.set("i", "<S-Up>", function()
  select_from_insert("lk", "jh")
end)
vim.keymap.set("i", "<S-Down>", function()
  select_from_insert("l", "jh")
end)

-- Plain cursor keys collapse the selection and resume Insert (VSCode: an
-- unshifted arrow ends the selection and keeps you typing). "v" covers
-- Visual+Select; <Esc> leaves either to Normal, the motion moves, and the
-- scheduled startinsert returns to Insert.
local function collapse_select(motion)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Esc>" .. motion, true, true, true),
    "n",
    false
  )
  vim.schedule(function()
    vim.cmd.startinsert()
  end)
end

for _, map in ipairs({
  { "<Right>", "l" },
  { "<Left>", "h" },
  { "<Down>", "j" },
  { "<Up>", "k" },
  { "<End>", "$" },
  { "<Home>", "0" },
}) do
  vim.keymap.set("v", map[1], function()
    collapse_select(map[2])
  end)
end

-- Editor keys -----------------------------------------------------------------

vim.keymap.set({ "i", "n" }, "<C-s>", "<Cmd>w<CR>")
vim.keymap.set("i", "<C-z>", "<C-o>u")
vim.keymap.set("n", "<C-z>", "u")
vim.keymap.set("i", "<C-y>", "<C-o><C-r>")
vim.keymap.set("n", "<C-y>", "<C-r>")
vim.keymap.set("i", "<C-f>", "<C-o>/")
vim.keymap.set("n", "<C-f>", "/")
vim.keymap.set("i", "<S-Tab>", "<C-d>")

for _, mode in ipairs({ "n", "v" }) do
  vim.keymap.set(mode, "<C-Home>", "gg")
  vim.keymap.set(mode, "<C-End>", "G")
end

local function toggle_terminal()
  if vim.bo.buftype == "terminal" then
    vim.cmd("bd!")
  else
    vim.cmd("terminal")
  end
end
vim.keymap.set({ "n", "i" }, "<C-`>", toggle_terminal)

local function goto_line()
  local line = tonumber(vim.fn.input("Line: "))
  if line then
    vim.api.nvim_win_set_cursor(0, { math.max(1, line), 0 })
  end
end
vim.keymap.set({ "n", "i" }, "<C-g>", goto_line)

vim.keymap.set("n", "<M-Right>", "w")
vim.keymap.set("n", "<M-Left>", "b")
vim.keymap.set("v", "<M-Right>", "w")
vim.keymap.set("v", "<M-Left>", "b")
vim.keymap.set("i", "<M-Right>", "<C-Right>")
vim.keymap.set("i", "<M-Left>", "<C-Left>")
