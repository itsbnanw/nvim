-- VSCode-like editing behavior: always-insert emulation, word-wise
-- Ctrl+arrow motion, Shift-selection, and system-clipboard editing.
-- The emulation is buffer-local: only real editing buffers get it, so UI
-- buffers (file explorer, help, quickfix, terminal) keep native keys.
-- Disable everything by commenting out `require("config.vscode")` in init.lua.

-- Insertmode emulation (ported from :h vim_diff) ------------------------------

local augroup = vim.api.nvim_create_augroup("config.vscode", { clear = true })

-- Only buffers meant for editing text get the emulation. 'buftype' excludes
-- help/quickfix/terminal/etc.; the filetype check excludes explorers like
-- mini.files that leave buftype empty.
local function is_editable_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  return not vim.bo[buf].filetype:match("^minifiles")
end

local setup_buffer_maps

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = augroup,
  callback = function(ev)
    local buf = ev.buf or vim.api.nvim_get_current_buf()
    if is_editable_buffer(buf) then
      setup_buffer_maps(buf)
      vim.cmd.startinsert()
    else
      -- UI buffers (explorer, help, ...) stay in Normal mode where their
      -- own navigation mappings work; this also drops Insert when the
      -- explorer is opened from an editing buffer.
      vim.cmd.stopinsert()
    end
  end,
})

vim.api.nvim_create_autocmd("CmdwinEnter", {
  group = augroup,
  callback = function()
    vim.keymap.set("n", "<C-c>", "<C-c>", { buffer = true })
    vim.keymap.set("i", "<C-c>", "<C-c>", { buffer = true })
  end,
})

vim.on_key(function(key)
  if key ~= "\27" then
    return
  end
  if not is_editable_buffer() then
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

-- Word motion and selection ---------------------------------------------------

-- Failed motions (e.g. j on the last line) beep and abort the rest of a fed
-- typeahead. If that happens after "v" but before "<C-g>", or aborts the
-- auto-switch back from Select, the selection is stranded in Visual mode
-- where typing runs Vim commands instead of replacing the selection. This
-- scheduled check converts it back to Select. ModeChanged "s:v" catches the
-- Select->Visual extension case; select_from_insert calls it directly.
local function ensure_select()
  vim.schedule(function()
    local mode = vim.api.nvim_get_mode().mode
    if mode == "v" or mode == "V" or mode == "\22" then
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<C-g>", true, true, true),
        "nx",
        false
      )
    end
  end)
end

vim.api.nvim_create_autocmd("ModeChanged", {
  group = augroup,
  pattern = "s:v",
  callback = function()
    if is_editable_buffer() then
      ensure_select()
    end
  end,
})

-- <S-PageUp>/<S-PageDown> extend the selection by a page like VSCode.
-- "Page" is the window height minus two (same as <PageDown>), but
-- <C-f>/<PageDown> only scroll in Visual mode, so j/k repeats move the
-- cursor instead and keep the column. String rhs cannot compute the
-- count, so these are Lua callbacks that toggle Select->Visual (<C-g>),
-- feed the repeats, and toggle back.
local function page_count()
  return math.max(1, vim.api.nvim_win_get_height(0) - 2)
end

local function extend_page(down)
  -- Deferred like ensure_select: feedkeys "nx" only behaves inside a
  -- scheduled callback, not directly in a mapping.
  vim.schedule(function()
    local keys = page_count() .. (down and "j" or "k")
    local mode = vim.api.nvim_get_mode().mode
    local tc = vim.api.nvim_replace_termcodes
    local in_select = mode == "s" or mode == "S"
    if in_select then
      vim.api.nvim_feedkeys(tc("<C-g>", true, true, true), "nx", false)
    end
    vim.api.nvim_feedkeys(keys, "nx", false)
    if in_select then
      vim.api.nvim_feedkeys(tc("<C-g>", true, true, true), "nx", false)
    end
    ensure_select()
  end)
end

-- Same, started from Insert mode: leave Insert, select via Visual, convert
-- to Select. The <Esc> goes through "m" (remap) so the safe insert-<Esc>
-- mapping above cancels any completion popup first. Esc steps the cursor
-- back onto the char left of the caret, so rightward selections take a
-- leading "l" to anchor on the char right of the caret; "w" is paired with
-- "h" so the selection stops before the next word's first char.
local function select_from_insert(pre, motion)
  -- Esc lands the cursor on the char left of the caret, except at column 0
  -- where it cannot step back and stays on the first char. A leading "l"
  -- compensates for the step-back, so it must be dropped at column 0 and
  -- rightward selections abort at end of line ("l" would wrap to the next
  -- line via 'whichwrap').
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local linelen = #vim.api.nvim_get_current_line()
  if pre:sub(1, 1) == "l" then
    if col >= linelen then
      return
    elseif col == 0 then
      pre = pre:sub(2)
    end
  elseif col == 0 and (motion == "" or motion:match("^[b0h]")) then
    -- Line-local leftward motions have nothing to select at column 0;
    -- motions that leave the line (k, j, gg, G, |, ...) still work.
    return
  end
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
  ensure_select()
end

-- <S-PageUp>/<S-PageDown> from Insert: same page-sized motions as the
-- extension maps, through the usual select_from_insert path. "l"/""
-- pre and the trailing adjuster mirror <S-Down>/<S-Up>.
local function page_motion(down)
  return page_count() .. (down and "jh" or "kl")
end

-- Same selections started from Normal mode: enter Insert at the cursor
-- first, so Normal-mode Shift+arrows behave exactly like the Insert path
-- (previously "v{motion}" anchored on the cursor char, adding one extra
-- character on the left of every selection).
local function select_from_normal(pre, motion)
  vim.api.nvim_feedkeys("i", "n", false)
  select_from_insert(pre, motion)
end

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

-- Plain PageUp/PageDown move the cursor about a page like VSCode: the
-- caret travels and the view scrolls only enough to keep it visible
-- (the built-in <PageDown> scrolls first and parks the cursor at the
-- screen edge instead). "<C-o>" runs the counted j/k as a single Normal
-- command and returns to Insert; from Normal we enter Insert first.
local function page_goto(down)
  local keys = "<C-o>" .. page_count() .. (down and "j" or "k")
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, true, true),
    "n",
    false
  )
end

local function toggle_terminal()
  if vim.bo.buftype == "terminal" then
    vim.cmd("bd!")
  else
    vim.cmd("terminal")
  end
end

local function goto_line()
  local line = tonumber(vim.fn.input("Line: "))
  if line then
    vim.api.nvim_win_set_cursor(0, { math.max(1, line), 0 })
  end
end

-- Keymaps ---------------------------------------------------------------------
-- Registered buffer-locally per editable buffer by the BufWinEnter autocmd
-- above, so UI buffers keep their native mappings.

setup_buffer_maps = function(buf)
  local function set(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf })
  end

  set("i", "<Esc>", "<C-X><C-Z><C-[>")
  set("i", "<C-c>", "<C-X><C-Z>")
  set("i", "<C-l>", "<C-X><C-Z><C-]><Esc>")
  set("i", "<C-z>", "<C-X><C-Z><Cmd>suspend<CR>")
  set("n", "<C-c>", "<Esc>")
  set("s", "<C-c>", "<Esc>")
  set("n", "<C-\\><C-G>", "<C-\\><C-N><Cmd>startinsert<CR>")
  set("c", "<C-\\><C-G>", "<C-\\><C-N><Cmd>startinsert<CR>")
  set("i", "<C-\\><C-G>", "<C-X><C-Z>")

  -- Clipboard ---------------------------------------------------------------

  -- Copy keeps the selection like VSCode: yank, gv reselects the same area,
  -- <C-g> converts back to Select mode.
  set("v", "<C-c>", '"+ygv<C-g>')
  set("v", "<C-x>", '"+d<Cmd>startinsert<CR>')
  set("i", "<C-v>", "<C-r>+")
  set("n", "<C-v>", '"+gp<Cmd>startinsert<CR>')
  set("v", "<C-v>", '"+pa')

  -- Ctrl+arrows: word-wise motion in Normal/Visual/Select (Insert is
  -- built-in).
  for _, mode in ipairs({ "n", "v" }) do
    set(mode, "<C-Left>", "b")
    set(mode, "<C-Right>", "w")
  end

  -- Shift(+Ctrl)+arrows in Visual/Select: extend the selection. "v"
  -- mappings also cover Select mode (auto-switch to Visual for the motion,
  -- then back).
  set("v", "<C-S-Left>", "b")
  set("v", "<C-S-Right>", "w")
  set("v", "<C-S-Home>", "gg")
  set("v", "<C-S-End>", "G")
  set("v", "<S-Left>", "h")
  set("v", "<S-Right>", "l")
  set("v", "<S-Up>", "k")
  set("v", "<S-Down>", "j")
  set("v", "<S-Home>", "0")
  -- "$h" not "$": in Visual mode "$" leaves the cursor one past the last
  -- char and the inclusive selection swallows the line break; "h" steps
  -- back onto the last char so only line content is selected.
  set("v", "<S-End>", "$h")

  set("v", "<S-PageDown>", function()
    extend_page(true)
  end)
  set("v", "<S-PageUp>", function()
    extend_page(false)
  end)

  -- From Insert mode: leave Insert, select via Visual, convert to Select.
  set("i", "<C-S-Left>", function()
    select_from_insert("", "b")
  end)
  set("i", "<C-S-Right>", function()
    select_from_insert("l", "wh")
  end)
  set("i", "<C-S-Home>", function()
    select_from_insert("", "gg")
  end)
  set("i", "<C-S-End>", function()
    select_from_insert("l", "G")
  end)
  set("i", "<S-Left>", function()
    select_from_insert("", "")
  end)
  set("i", "<S-Right>", function()
    select_from_insert("l", "")
  end)
  set("i", "<S-Home>", function()
    select_from_insert("", "0")
  end)
  set("i", "<S-End>", function()
    select_from_insert("l", "$h")
  end)
  -- Vertical selections keep the caret column: anchor on the char left of
  -- the caret, move up a line, then step right onto the caret column.
  -- "vkl" also degrades gracefully on the first line (k fails, l still
  -- selects).
  set("i", "<S-Up>", function()
    select_from_insert("", "kl")
  end)
  set("i", "<S-Down>", function()
    select_from_insert("l", "jh")
  end)
  set("i", "<S-PageDown>", function()
    select_from_insert("l", page_motion(true))
  end)
  set("i", "<S-PageUp>", function()
    select_from_insert("", page_motion(false))
  end)

  -- From Normal mode: enter Insert first so the selection path matches the
  -- Insert-mode behavior exactly.
  set("n", "<C-S-Left>", function()
    select_from_normal("", "b")
  end)
  set("n", "<C-S-Right>", function()
    select_from_normal("l", "wh")
  end)
  set("n", "<C-S-Home>", function()
    select_from_normal("", "gg")
  end)
  set("n", "<C-S-End>", function()
    select_from_normal("l", "G")
  end)
  set("n", "<S-Left>", function()
    select_from_normal("", "")
  end)
  set("n", "<S-Right>", function()
    select_from_normal("l", "")
  end)
  set("n", "<S-Up>", function()
    select_from_normal("", "kl")
  end)
  set("n", "<S-Down>", function()
    select_from_normal("l", "jh")
  end)
  set("n", "<S-Home>", function()
    select_from_normal("", "0")
  end)
  set("n", "<S-End>", function()
    select_from_normal("l", "$h")
  end)
  set("n", "<S-PageDown>", function()
    select_from_normal("l", page_motion(true))
  end)
  set("n", "<S-PageUp>", function()
    select_from_normal("", page_motion(false))
  end)

  -- Plain cursor keys collapse the selection and resume Insert (VSCode:
  -- an unshifted arrow ends the selection and keeps you typing). "v"
  -- covers Visual+Select.
  for _, map in ipairs({
    { "<Right>", "l" },
    { "<Left>", "h" },
    { "<Down>", "j" },
    { "<Up>", "k" },
    { "<Home>", "0" },
  }) do
    set("v", map[1], function()
      collapse_select(map[2])
    end)
  end

  -- <End> is special: "$" leaves the Normal cursor on the last char and
  -- startinsert ("i") would park the caret one char short of EOL. "a"
  -- appends after the last char instead, matching the Insert-mode <End>.
  set("v", "<End>", function()
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Esc>$a", true, true, true),
      "n",
      false
    )
  end)

  -- Plain PageUp/PageDown move the cursor about a page like VSCode: the
  -- caret travels and the view scrolls only enough to keep it visible
  -- (the built-in <PageDown> scrolls first and parks the cursor at the
  -- screen edge instead).
  set("i", "<PageDown>", function()
    page_goto(true)
  end)
  set("i", "<PageUp>", function()
    page_goto(false)
  end)
  set("n", "<PageDown>", function()
    vim.api.nvim_feedkeys("i", "n", false)
    page_goto(true)
  end)
  set("n", "<PageUp>", function()
    vim.api.nvim_feedkeys("i", "n", false)
    page_goto(false)
  end)
  for _, map in ipairs({
    { "<PageDown>", "j" },
    { "<PageUp>", "k" },
  }) do
    set("v", map[1], function()
      collapse_select(page_count() .. map[2])
    end)
  end

  -- Delete/Backspace with a selection removes it and resumes Insert like
  -- VSCode. "_d" keeps the text out of registers and the system clipboard
  -- (Delete is not Cut); <Cmd>startinsert returns to Insert at the deletion
  -- point, same pattern as <C-x> above.
  set("v", "<Del>", '"_d<Cmd>startinsert<CR>')
  set("v", "<BS>", '"_d<Cmd>startinsert<CR>')

  -- Editor keys ---------------------------------------------------------------

  set({ "i", "n" }, "<C-s>", "<Cmd>w<CR>")
  set("i", "<C-z>", "<C-o>u")
  set("n", "<C-z>", "u")
  set("i", "<C-y>", "<C-o><C-r>")
  set("n", "<C-y>", "<C-r>")
  set("i", "<C-f>", "<C-o>/")
  set("n", "<C-f>", "/")
  set("i", "<S-Tab>", "<C-d>")

  for _, mode in ipairs({ "n", "v" }) do
    set(mode, "<C-Home>", "gg")
    set(mode, "<C-End>", "G")
  end

  set({ "n", "i" }, "<C-`>", toggle_terminal)
  set({ "n", "i" }, "<C-g>", goto_line)

  set("n", "<M-Right>", "w")
  set("n", "<M-Left>", "b")
  set("v", "<M-Right>", "w")
  set("v", "<M-Left>", "b")
  set("i", "<M-Right>", "<C-Right>")
  set("i", "<M-Left>", "<C-Left>")
end
