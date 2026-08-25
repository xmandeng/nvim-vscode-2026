# Installing

## Prerequisites

| Requirement | Why | Check |
|---|---|---|
| Neovim 0.10+ (0.11+ recommended) | the config uses `vim.lsp.config` and `vim.diagnostic.jump` | `nvim --version` |
| git | plugin manager | `git --version` |
| C compiler + `make` | treesitter parsers, telescope-fzf-native | `cc --version` |
| Node.js | basedpyright runs on Node | `node --version` |
| Python 3 | the language server and debugger target it | `python3 --version` |
| ripgrep | powers search across files | `rg --version` |
| A Nerd Font | icons in the tree, tabs, gutter | see below |

`bootstrap.sh` warns about anything missing rather than failing outright, so you can
install it and re-run.

### macOS

```bash
brew install neovim git ripgrep node python@3.12
brew install --cask font-jetbrains-mono-nerd-font
```

### Debian / Ubuntu

```bash
sudo apt install -y git build-essential ripgrep python3 python3-venv
# Neovim in the distro repos is often too old -- prefer the release tarball:
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
# Node via nodesource or nvm
```

### Fedora

```bash
sudo dnf install -y neovim git gcc make ripgrep nodejs python3
```

## Install

```bash
git clone https://github.com/OWNER/nvim-vscode-2026.git ~/src/nvim-vscode-2026
cd ~/src/nvim-vscode-2026
./bootstrap.sh
```

The script backs up an existing `~/.config/nvim` to
`~/.config/nvim.backup.<timestamp>` before linking this one in. Nothing is deleted.

### Options

| Flag | Effect |
|---|---|
| `--appname NAME` | install to `~/.config/NAME`; launch with `NVIM_APPNAME=NAME nvim` |
| `--copy` | copy instead of symlinking (for hosts where the repo will not stay put) |
| `--no-deps` | skip plugin, LSP and parser installation |

### Side-by-side with an existing config

```bash
./bootstrap.sh --appname nvim-vsc
NVIM_APPNAME=nvim-vsc nvim
```

`NVIM_APPNAME` isolates config, data, state and cache directories, so the two
installs share nothing. Add an alias once you are happy:

```bash
alias vsc='NVIM_APPNAME=nvim-vsc nvim'
```

## Fonts

Icons come from a [Nerd Font](https://www.nerdfonts.com). Install one and set it as
your terminal font. The config uses Nerd Fonts **v3** codicon codepoints, defined in
`nvim/lua/config/icons.lua`.

If you see boxes or blanks where icons should be, the font is not a Nerd Font (or
your terminal is not using it). See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Terminal colours

The theme's editor background is `#121314`. On a terminal set to a different dark
background, splits and panels will not line up with the editor. Apply the matching
scheme from `terminal/`:

**Alacritty** — add to `~/.config/alacritty/alacritty.toml`:
```toml
general.import = ["~/.config/alacritty/vscode-2026-dark.toml"]
```

**Kitty** — `include vscode-2026-dark.conf` in `kitty.conf`.

**Ghostty** — put the file in `~/.config/ghostty/themes/` and set `theme = vscode-2026-dark`.

**WezTerm** — `colors = require("vscode-2026-dark")`.

**tmux** — `source-file ~/.config/tmux/vscode-2026-dark.conf`. Also make sure
true colour passes through:
```tmux
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
```

## Verify

```bash
nvim +checkhealth
```

Then open a Python file and confirm: `:LspInfo` shows **basedpyright** and **ruff**,
<kbd>Ctrl</kbd>+<kbd>B</kbd> opens the tree, <kbd>F9</kbd> then <kbd>F5</kbd> starts
a debug session.

## Uninstall

```bash
rm ~/.config/nvim && mv ~/.config/nvim.backup.<timestamp> ~/.config/nvim
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
```
