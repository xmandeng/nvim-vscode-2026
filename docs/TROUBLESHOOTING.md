# Troubleshooting

## Colours

### Everything is washed out, or the background is wrong

The terminal is not in true colour. Check:

```vim
:lua print(vim.o.termguicolors)   " must be true
:echo $COLORTERM                  " should be truecolor or 24bit
```

Under tmux, add to `~/.tmux.conf`:

```tmux
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
```

Over SSH, `TERM` must survive the hop — `xterm-256color` at minimum.

### The editor background does not match the terminal background

Expected until you apply the matching terminal scheme; see `terminal/` and
[INSTALL.md](INSTALL.md#terminal-colours). The editor background is `#121314`.

### A specific token is the wrong colour

Put the cursor on it and run `:Inspect`. That shows the treesitter capture, the LSP
semantic token, and which highlight group won. Then compare with VS Code: open the
same file there and run **Developer: Inspect Editor Tokens and Scopes** from the
command palette.

If Neovim and VS Code report the same scope but different colours, that is a real
port bug — the resolution rules are described in [THEME.md](THEME.md).
If they report *different scopes*, the difference is the parser (treesitter vs
TextMate grammar), not the theme.

### Colours changed after a VS Code update

Regenerate:

```bash
make theme && make terminal
```

## Icons

### Boxes, question marks, or blank gaps where icons should be

The terminal font is not a Nerd Font. Install one and select it in the terminal
profile — Neovim cannot fix this from inside.

Verify the codepoints are intact:

```vim
:lua print(vim.inspect(require('config.icons').diagnostics))
```

If any value prints as `""`, the file was corrupted in transit. Icons are defined
by codepoint via `nr2char()` in `nvim/lua/config/icons.lua` precisely to avoid this;
the literal glyphs live in the Unicode Private Use Area and are routinely stripped
by copy/paste, shell heredocs and some editors.

### Icons are the wrong glyph

The config targets Nerd Fonts **v3**. A v2 font has different codepoints for the
codicon range. Update the font, or edit the codepoints in `icons.lua`.

## Keybindings

### Ctrl+Shift+<key> does nothing

Your terminal does not implement the kitty keyboard protocol, so it cannot
distinguish <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> from
<kbd>Ctrl</kbd>+<kbd>P</kbd>. Use the `<leader>` equivalents (press <kbd>Space</kbd>
to browse), or switch to Kitty, Ghostty, WezTerm, or Alacritty 0.13+.

### Ctrl+/ does nothing

Most terminals send <kbd>Ctrl</kbd>+<kbd>_</kbd> instead; both are mapped. If neither
fires, use `gcc` (line) or `gc` in visual mode.

## Python

### No diagnostics, no completion

```vim
:LspInfo        " is anything attached?
:Mason          " is basedpyright installed?
:checkhealth vim.lsp
```

basedpyright needs **Node.js**. `:Mason` will show the install failing without it.

### basedpyright reports far more errors than VS Code

VS Code runs Pylance in `standard` mode. If you changed `typeCheckingMode` to
`recommended`, that is the difference — basedpyright's `recommended` is much
stricter than anything Pylance does by default.

### Imports from my own package are unresolved

basedpyright is not finding the interpreter or the source root. Activate the venv
before launching Neovim, or add a `pyrightconfig.json`:

```json
{ "venvPath": ".", "venv": ".venv", "extraPaths": ["src"] }
```

### Ruff and basedpyright disagree / duplicate diagnostics

Some overlap is expected — both flag undefined names, for instance, exactly as the
two extensions do in VS Code. basedpyright's `disableOrganizeImports` is already set
so the two do not fight over import order.

## Debugging

### "command ... of adapter python exited with 1"

The adapter interpreter has no `debugpy`. This config uses Mason's dedicated venv:

```vim
:lua print(vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python')
```

If that path does not exist, run `:Mason` and install **debugpy**.

### F5 does nothing

Nothing to debug for the current filetype. `:lua print(vim.inspect(require('dap').configurations[vim.bo.filetype]))`
should list four Python configurations. If the buffer is not Python, register an
adapter for that language — see [CUSTOMIZING.md](CUSTOMIZING.md).

### Breakpoints are hollow / never hit

The debuggee is running different code than the file you set the breakpoint in —
usually a stale install of the package. Run from the project root, and prefer an
editable install (`pip install -e .`).

## Plugins

### A plugin failed to build

```vim
:Lazy            " L shows the log for the failed plugin
:Lazy! sync
```

`telescope-fzf-native` needs `make` and a C compiler; treesitter parsers need a C
compiler. On a host without one, both degrade rather than break — search falls back
to the pure-Lua sorter and highlighting falls back to Vim regex.

### Everything broke after an update

```bash
git -C <repo> checkout lazy-lock.json   # if you track it
nvim --headless "+Lazy! restore" +qa
```

`lazy-lock.json` pins every plugin to a known-good commit. Committing it is what
makes an install reproducible across hosts.

## Getting a clean report

```vim
:checkhealth
```

and

```bash
nvim --headless "+Lazy! sync" +qa
```

Startup timing, if it feels slow:

```vim
:Lazy profile
```
