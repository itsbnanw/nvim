# Personal Neovim config

Requires Neovim 0.12+. Plugins are managed by built-in `vim.pack`.

## Language support

Mason manages executables; nvim-lspconfig supplies definitions. LSP and completion
use Neovim's built-in APIs, not a completion framework.

| Language | Mason package | Project/toolchain requirements |
| --- | --- | --- |
| C | `clangd` | GCC or Clang to build/run; standalone `.c` files work |
| Go | `gopls` | Go on PATH, including while installing gopls |
| Rust | `rust-analyzer` | Rust/Cargo and standard-library sources (`rust-src`) |
| Zig | `zls` | Zig; match the Zig/ZLS release series |
| HTML | `html-lsp` | Node.js; standalone files work |
| CSS, SCSS, Less | `css-lsp` | Node.js; standalone files work |
| JS/TS, React JSX/TSX | `vtsls` | Node.js; project dependencies and types |
| Angular templates | `angular-language-server` | Node.js, `angular.json`, installed project dependencies |

Install/manage servers with `:Mason`, then restart Neovim. Mason manages editor
servers, not language toolchains. Missing Go/Cargo/Zig prevents that server from
starting, with an actionable warning; word/path completion remains available.

Node and Bun projects use the same VSCode-based JS/TS server (`vtsls`); a project's
installed TypeScript version is preferred over the bundled version. Install the
appropriate types in each project (`@types/node`, `@types/bun`, React types), not globally. Project
`tsconfig.json`/`jsconfig.json` controls resolution. No Bun runtime is bundled.

Angular runs alongside the TS server, only in an `angular.json` workspace. Its
maintained nvim-lspconfig definition probes project TypeScript first, then Mason's
dependencies. Older Angular projects may need a matching server version installed
through Mason (`:MasonInstall angular-language-server@<version>`). No project
dependencies are installed or upgraded by this config.

### Completion behavior

- LSP results come first, then paths, then buffer words. Matching case is preferred
  before the server's own ranking (e.g. `printf` before `PRI...` macros).
- Buffer words are limited to five matches per source, not entire unloaded files.
  Distinct LSP import/overload choices are preserved rather than blindly deduplicated.
- Automatic suggestions require three consecutive word characters, including
  member names and path components. Spaces and punctuation such as `;` do not
  trigger them. Ctrl+Space can request suggestions at any prefix length.
- Up/Down highlight suggestions; Enter accepts only a selected suggestion.
- The menu shows at most ten rows; additional results remain scrollable.
- Enter without a selection inserts a newline, preserving autopairs behavior.
- Ctrl+Space requests completion; Escape dismisses it and stays in Insert mode.
- Tab/Shift+Tab keep their editing behavior. No snippet engine or tabstops.
- HTML/CSS require snippet capability to return ordinary completions. Their
  template-shaped results are converted to plain tag/attribute/property names;
  accepting `class` inserts `class`, not a template with placeholders.
- Accepting an LSP suggestion may insert its required `#include` or import.
- Diagnostics use underlines and gutter signs, without inline messages. They
  refresh when typing pauses (native `CursorHoldI`) or you leave Insert mode,
  not on each keystroke. Use `:lua vim.diagnostic.open_float()` to read a message.
- No formatting-on-save or additional navigation shortcuts are configured.

Check the current buffer's server with `:checkhealth vim.lsp`.

### Choosing a C standard

No C standard is forced globally. To match an exercise, put a `.clangd` file in
its folder, for example:

```yaml
CompileFlags:
  Add: [-std=c17]
```

Use `c89`, `c99`, `c11`, `c17`, or `c23` as appropriate, and pass the same
`-std=...` flag to your compiler. Supported features depend on each tool's version;
one file is analyzed under one standard at a time.
