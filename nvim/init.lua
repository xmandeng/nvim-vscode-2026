-- VS Code Dark 2026 for Neovim
-- Entry point: options -> lazy.nvim (plugins) -> keymaps -> autocmds.

vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

require('config.options')
require('config.lazy')
require('config.keymaps')
require('config.autocmds')
