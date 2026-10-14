# Customising

## Tweaking colours

`nvim/lua/vscode2026/generated.lua` is **generated** — `make theme` overwrites it.
Put personal changes in the `overrides` table in
`nvim/lua/plugins/colorscheme.lua`, which is applied on top and survives regeneration:

```lua
require('vscode2026').setup({
  transparent = false,      -- drop the editor background (for a translucent terminal)
  italic_comments = true,
  overrides = {
    Comment = { fg = '#7A8188', italic = false },
    ['@lsp.type.parameter'] = { fg = '#9CDCFE' },
    CursorLine = { bg = '#1B1D1F' },
  },
})
```

The palette is available if you want to build on it rather than hard-code hex:

```lua
local p = require('vscode2026').palette()
-- p.bg, p.fg, p.accent, p.error, p.git_add, p.ansi.blue, ...
```

To see what a group is currently set to, put the cursor on the token and run
`:Inspect` — it reports the treesitter capture, the LSP semantic token, and the
highlight group actually winning.

## Porting a different VS Code theme

The generator is not hard-coded to Dark 2026:

```bash
make theme THEME="/Applications/Visual Studio Code.app/Contents/Resources/app/extensions/theme-defaults/themes/dark_modern.json"
make terminal
```

Any theme with a `colors` map and `tokenColors` works, including one from a
marketplace extension (look in `~/.vscode/extensions/<publisher>.<name>/themes/`).
The palette keys assume a dark theme; a light theme will generate but the
hand-written plugin groups that mix towards the background may need review.

## Changing the Python setup

`nvim/lua/plugins/lsp.lua` holds both servers.

**Stricter type checking** — basedpyright is set to `standard` to match what Pylance
reports. Its own default is `recommended`, which is considerably stricter:

```lua
analysis = { typeCheckingMode = 'recommended' },
```

**Whole-project diagnostics** instead of open files only:

```lua
analysis = { diagnosticMode = 'workspace' },
```

**Ruff configuration** is read from your project's `pyproject.toml` /
`ruff.toml` as usual — the LSP does not override it. `lineLength` in the config is
only a fallback for projects with no Ruff config.

**Virtual environments** — the debugger picks an interpreter in this order:
`$VIRTUAL_ENV`, `$CONDA_PREFIX`, then `.venv/`, `venv/`, `env/` in the project root,
then `python3` on `PATH`. basedpyright finds packages via `autoSearchPaths`; if it
misses your layout, add a `pyrightconfig.json` or a `[tool.pyright]` section.

## Adding a language server

```lua
-- nvim/lua/plugins/lsp.lua, at the top
local servers = { 'basedpyright', 'ruff', 'lua_ls', 'gopls' }
```

That list both installs and enables. A server installed some other way (by hand
in `:Mason`, or left over from an earlier config) is not started unless it is in
the list. Add a `vim.lsp.config('gopls', {...})`
block alongside the others if it needs settings. Because the colours are driven by
semantic tokens and treesitter captures rather than per-language rules, a new
language picks up Dark 2026 colours with no theme work.

## Adding a debug adapter

`nvim/lua/plugins/dap.lua`. Register the adapter and its configurations the usual
nvim-dap way; the <kbd>F5</kbd>/<kbd>F9</kbd>/<kbd>F10</kbd>/<kbd>F11</kbd> keys and
the dap-ui panels are language-agnostic and will just work.

Note the split that trips people up: the **adapter** interpreter must have `debugpy`
importable (this config uses Mason's dedicated venv), while the **debuggee**
interpreter is chosen per-configuration via `pythonPath`. Pointing the adapter at a
project venv without debugpy is what produces
*"adapter python exited with 1"*.

## Turning off format-on-save

Per session or per buffer:

```vim
:FormatDisable      " globally
:FormatDisable!     " this buffer only
:FormatEnable
```

Permanently: remove `format_on_save` from the conform spec in `lsp.lua`.

## Auto-save

There is none, on purpose. Saving runs format-on-save, so a timer that saves for
you would also reformat the file while you are still typing it.

## Adding plugins

Drop a new file in `nvim/lua/plugins/`. Everything in that directory is imported
automatically by lazy.nvim — no registration needed.
