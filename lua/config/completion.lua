-- Native 0.12 completion: LSP, paths, and a small loaded-buffer word fallback.
-- No completion framework or snippet engine; native completion gathers matches.

local M = {}

local filetypes = {
  c = true,
  go = true, gomod = true, gowork = true, gotmpl = true,
  rust = true,
  zig = true, zir = true,
  html = true, htmlangular = true,
  css = true, scss = true, less = true,
  javascript = true, javascriptreact = true,
  typescript = true, typescriptreact = true,
}

function M.supports(buf)
  return vim.bo[buf].buftype == "" and filetypes[vim.bo[buf].filetype] == true
end

local function lsp_item(candidate)
  if type(candidate.user_data) == "table" then
    return vim.tbl_get(candidate.user_data, "nvim", "lsp", "completion_item")
  end
end

-- Native completion merges async LSP responses with existing path/buffer items.
-- Keep LSP first, prefer matching case (printf before PRI... macros), then keep
-- the server's own sortText ordering. Do not collapse distinct import choices.
function M.compare(a, b)
  local item_a, item_b = lsp_item(a), lsp_item(b)
  local rank_a = item_a and 1 or (a.menu == "[path]" and 2 or 3)
  local rank_b = item_b and 1 or (b.menu == "[path]" and 2 or 3)
  if rank_a ~= rank_b then
    return rank_a < rank_b
  end
  local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1)
  local prefix = vim.fn.matchstr(before, [[\k\+$]])
  local case_a = vim.startswith((item_a and item_a.filterText) or a.word, prefix)
  local case_b = vim.startswith((item_b and item_b.filterText) or b.word, prefix)
  if case_a ~= case_b then
    return case_a
  end
  local sort_a = item_a and (item_a.sortText or item_a.label) or a.word
  local sort_b = item_b and (item_b.sortText or item_b.label) or b.word
  if sort_a ~= sort_b then
    return sort_a < sort_b
  end
  return (a.word .. (a.menu or "")) < (b.word .. (b.menu or ""))
end

-- HTML/CSS servers require snippet capability even for ordinary suggestions.
-- Turn template-shaped results into plain tag/attribute/property names BEFORE
-- native acceptance sees them: no placeholders, snippet expansion, or tabstops.
function M.convert(item)
  if item.insertTextFormat == vim.lsp.protocol.InsertTextFormat.Snippet then
    item.insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText
    item.insertText = item.label
    if item.textEdit then
      item.textEdit.newText = item.label
    end
    item.command = nil
    return { word = item.label }
  end
  return {}
end

-- Native 'autocomplete' also searches with empty prefixes after punctuation.
-- Require three consecutive word characters for automatic requests, including
-- member names and path components. Explicit Ctrl+Space has no minimum length.
vim.api.nvim_create_autocmd("InsertCharPre", {
  group = vim.api.nvim_create_augroup("config.completion", { clear = true }),
  callback = function(ev)
    if M.supports(ev.buf) then
      local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1)
      local prefix = vim.fn.matchstr(before .. vim.v.char, [[\k\+$]])
      vim.bo[ev.buf].autocomplete = vim.fn.strchars(prefix) >= 3
    end
  end,
})

-- A small adapter lets native 'complete' use built-in filename completion.
-- Resolve relative paths beside the edited file, not Neovim's working directory.
function M.paths(findstart, base)
  if findstart == 1 then
    local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1)
    local path = before:match("[\"'`]([^\"'`]*)$")
      or before:match("([%w_./~%-]*[/~][%w_./~%-]*)$")
    return path and (#before - #path) or -2
  end

  local prefix = ""
  if not base:match("^[/~]") then
    prefix = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) .. "/"
  end
  local items = {}
  for _, path in ipairs(vim.fn.getcompletion(prefix .. base, "file")) do
    items[#items + 1] = { word = path:sub(#prefix + 1), menu = "[path]" }
  end
  return { words = items, refresh = "always" }
end

function M.setup(buf)
  if not M.supports(buf) then
    return
  end

  vim.bo[buf].completeopt = "menuone,noselect,popup"
  vim.bo[buf].complete = "o,Fv:lua.require'config.completion'.paths,.^5,b^5"
  vim.bo[buf].autocomplete = false

  -- Native Up/Down already highlight menu entries without inserting them.
  vim.keymap.set("i", "<C-Space>", function()
    return (vim.fn.pumvisible() == 1 and "<C-e>" or "") .. "<C-n>"
  end, { buffer = buf, expr = true, desc = "Request completion" })
  vim.keymap.set("i", "<Esc>", function()
    return vim.fn.pumvisible() == 1 and "<C-e>" or "<C-X><C-Z>"
  end, { buffer = buf, expr = true, desc = "Dismiss completion and keep Insert mode" })
  vim.keymap.set("i", "<CR>", function()
    local visible = vim.fn.pumvisible() == 1
    if visible and vim.fn.complete_info({ "selected" }).selected >= 0 then
      -- Native acceptance also applies LSP text edits (e.g. required includes).
      return vim.api.nvim_replace_termcodes("<C-y>", true, false, true)
    end
    local newline = require("nvim-autopairs").autopairs_cr()
    local cancel = visible and vim.api.nvim_replace_termcodes("<C-e>", true, false, true) or ""
    return cancel .. newline
  end, { buffer = buf, expr = true, replace_keycodes = false, desc = "Accept selection or newline" })
end

return M
