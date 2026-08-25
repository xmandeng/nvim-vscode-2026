-- Integrated terminal on Ctrl+` , using the theme's ANSI palette.
return {
  {
    'akinsho/toggleterm.nvim',
    keys = {
      { '<C-`>', desc = 'Toggle Terminal' },
      { '<leader>tt', desc = 'Toggle Terminal' },
    },
    opts = function()
      local p = require('vscode2026').palette()
      return {
        open_mapping = { [[<C-`>]], [[<leader>tt]] },
        direction = 'horizontal',
        size = 14,
        shade_terminals = false,      -- keep the exact terminal.background colour
        start_in_insert = true,
        persist_size = true,
        persist_mode = false,
        float_opts = { border = 'single' },
        highlights = {
          Normal = { guibg = p.bg_sidebar },
          NormalFloat = { guibg = p.bg_float },
          FloatBorder = { guifg = p.border, guibg = p.bg_float },
        },
        on_open = function()
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = 'no'
          vim.opt_local.list = false
        end,
      }
    end,
    config = function(_, opts)
      require('toggleterm').setup(opts)
      -- Ctrl+` and Esc behave the way they do in VS Code's panel
      vim.keymap.set('t', '<C-`>', '<Cmd>ToggleTerm<CR>', { desc = 'Toggle Terminal', silent = true })
      vim.keymap.set('t', '<C-\\><C-n>', [[<C-\><C-n>]], { desc = 'Terminal normal mode' })
      vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], { silent = true })
      vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], { silent = true })
      vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], { silent = true })
      vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], { silent = true })
    end,
  },
}
