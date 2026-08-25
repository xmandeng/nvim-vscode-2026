# nvim-vscode-2026

A Neovim configuration that reproduces the look and feel of VS Code's **Dark 2026**
theme, with a Python language server, a debugger, and a file tree.

The colours are not hand-matched. They are **generated from the VS Code theme JSON**
shipped inside the VS Code app bundle, resolved through the same TextMate scope rules
VS Code itself uses. Regenerating after a VS Code update is one command.

```
make theme
```

## What you get

| VS Code | Here |
|---|---|
| Dark 2026 colour theme | generated port, 504 highlight groups |
| Pylance | **basedpyright** (types, hovers, inlay hints) |
| Ruff extension | **ruff** LSP (lint, format, organise imports) |
| Explorer sidebar | neo-tree — <kbd>Ctrl</kbd>+<kbd>B</kbd> |
| Run & Debug | nvim-dap + debugpy — <kbd>F5</kbd>/<kbd>F9</kbd>/<kbd>F10</kbd>/<kbd>F11</kbd> |
| Go to File | Telescope — <kbd>Ctrl</kbd>+<kbd>P</kbd> |
| Command Palette | Telescope — <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> |
| Editor tabs | bufferline |
| Breadcrumbs | dropbar |
| Problems panel | trouble — <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> |
| Integrated terminal | toggleterm — <kbd>Ctrl</kbd>+<kbd>`</kbd> |
| Source control gutter | gitsigns |

## Install

```bash
git clone https://github.com/xmandeng/nvim-vscode-2026.git
cd nvim-vscode-2026
./bootstrap.sh
```

`bootstrap.sh` backs up any existing `~/.config/nvim`, links this one in, then installs
plugins, language servers and treesitter parsers. To try it without touching your
current setup:

```bash
./bootstrap.sh --appname nvim-vsc
NVIM_APPNAME=nvim-vsc nvim
```

**Requirements:** Neovim 0.10+ (0.11+ recommended), git, a C compiler and `make`,
Node.js (basedpyright), Python 3, ripgrep, and a [Nerd Font](https://www.nerdfonts.com).

## Documentation

- [docs/INSTALL.md](docs/INSTALL.md) — prerequisites, per-platform notes, side-by-side installs
- [docs/KEYBINDINGS.md](docs/KEYBINDINGS.md) — the full VS Code keymap and its limits
- [docs/CUSTOMIZING.md](docs/CUSTOMIZING.md) — overriding colours, adding servers, regenerating
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — when colours or icons look wrong
- [docs/THEME.md](docs/THEME.md) — how the colour port actually works

## Terminal colours

The editor background only looks right on a terminal using the same palette.
`terminal/` holds generated schemes for Alacritty, Kitty, Ghostty, WezTerm and tmux.

## Layout

```
nvim/
  init.lua                     entry point
  lua/config/                  options, keymaps, autocmds, icons, lazy bootstrap
  lua/plugins/                 one file per concern
  lua/vscode2026/
    generated.lua              GENERATED -- do not edit
    init.lua                   loader, overrides, terminal ANSI
  colors/vscode-2026-dark.lua  :colorscheme entry point
tools/
  resolve_theme.py             flattens the VS Code `include` chain
  gen_colorscheme.py           TextMate scope resolution -> Lua highlight groups
  gen_terminal.py              palette -> terminal emulator configs
terminal/                      generated terminal schemes
```

## Licence

MIT
