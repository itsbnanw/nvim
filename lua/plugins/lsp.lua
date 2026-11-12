-- nvim-lspconfig supplies server definitions; Neovim's native LSP activates them.
-- Installed by the built-in vim.pack manager; sources live under the
-- data dir's site/pack/core/opt and are tracked by nvim-pack-lock.json.

vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

vim.diagnostic.config({
  underline = true,
  signs = true,
  virtual_text = false,
  virtual_lines = false,
  update_in_insert = false,
  severity_sort = true,
})

vim.lsp.config("*", {
  capabilities = {
    textDocument = {
      completion = {
        completionItem = { snippetSupport = false },
      },
    },
  },
})

-- The C pilot also works outside repositories, without a compilation database.
-- Leave compiler flags and the C standard to clangd and folder-local .clangd files.
vim.lsp.config("clangd", {
  filetypes = { "c" },
  workspace_required = false,
  cmd = { "clangd", "--function-arg-placeholders=0", "--header-insertion=iwyu" },
})

-- No new plugins are needed for Go, Rust, Zig, or the Node/Bun/React stack.
-- Prefer the nearest JS/TS project, even when Neovim was launched elsewhere.
vim.lsp.config("vtsls", {
  root_dir = function(buf, on_dir)
    on_dir(vim.fs.root(buf, { "tsconfig.json", "jsconfig.json", "package.json", ".git" })
      or vim.fs.dirname(vim.api.nvim_buf_get_name(buf)))
  end,
  settings = {
    vtsls = { autoUseWorkspaceTsdk = true },
    javascript = { suggest = { completeFunctionCalls = false } },
    typescript = { suggest = { completeFunctionCalls = false } },
  },
})

-- Angular augments vtsls for templates; it must not start in ordinary TS projects.
-- nvim-lspconfig supplies project-first TypeScript and Angular probe locations.
vim.lsp.config("angularls", {
  root_markers = { "angular.json" },
  workspace_required = true,
})

for _, name in ipairs({ "html", "cssls" }) do
  vim.lsp.config(name, {
    workspace_required = false,
    capabilities = {
      textDocument = {
        completion = {
          completionItem = { snippetSupport = true },
        },
      },
    },
  })
end

-- A language server is not a compiler/toolchain. Avoid startup errors while a
-- language's toolchain is absent; nothing downloads toolchains in the background.
for name, tool in pairs({ gopls = "go", rust_analyzer = "cargo", zls = "zig" }) do
  local config = vim.lsp.config[name]
  local root_dir = config.root_dir
  vim.lsp.config(name, {
    root_dir = function(buf, on_dir)
      if vim.fn.executable(tool) ~= 1 then
        vim.notify_once(name .. " needs " .. tool .. " installed and on PATH", vim.log.levels.WARN)
        return
      end
      if vim.fn.executable(config.cmd[1]) ~= 1 then
        local package = name == "rust_analyzer" and "rust-analyzer" or name
        vim.notify_once("Install " .. name .. " with :MasonInstall " .. package, vim.log.levels.WARN)
        return
      end
      if root_dir then
        root_dir(buf, on_dir)
      else
        on_dir(vim.fs.root(buf, config.root_markers) or vim.fs.dirname(vim.api.nvim_buf_get_name(buf)))
      end
    end,
  })
end

local group = vim.api.nvim_create_augroup("config.lsp", { clear = true })

-- Always-insert editing rarely triggers InsertLeave. Show cached diagnostics
-- after an idle pause instead of leaving them invisible until a pane switch.
vim.api.nvim_create_autocmd("CursorHoldI", {
  group = group,
  callback = function(ev)
    if require("config.completion").supports(ev.buf) then
      vim.diagnostic.show(nil, ev.buf, nil, { update_in_insert = true })
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local completion = require("config.completion")
    if client and completion.supports(ev.buf) and client:supports_method("textDocument/completion", ev.buf) then
      -- 'autocomplete' requests LSP and other sources together via 'complete'.
      -- Do not also enable a competing server-trigger-character popup.
      vim.lsp.completion.enable(true, client.id, ev.buf, {
        autotrigger = false,
        cmp = completion.compare,
        convert = completion.convert,
      })
      completion.setup(ev.buf)
    end
  end,
})

vim.lsp.enable({ "clangd", "gopls", "rust_analyzer", "zls", "html", "cssls", "vtsls", "angularls" })
