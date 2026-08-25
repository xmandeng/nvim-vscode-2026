-- Telescope == VS Code's quick-open family.
--   Ctrl+P        Go to File
--   Ctrl+Shift+P  Command Palette
--   Ctrl+Shift+F  Search across files
--   Ctrl+Shift+O  Go to Symbol in file
return {
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make', cond = vim.fn.executable('make') == 1 },
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<C-p>', '<Cmd>Telescope find_files<CR>', desc = 'Go to File' },
      { '<C-S-p>', '<Cmd>Telescope commands<CR>', desc = 'Command Palette' },
      { '<C-S-f>', '<Cmd>Telescope live_grep<CR>', desc = 'Search in Files' },
      { '<C-S-o>', '<Cmd>Telescope lsp_document_symbols<CR>', desc = 'Go to Symbol' },
      { '<C-t>', '<Cmd>Telescope lsp_workspace_symbols<CR>', desc = 'Go to Symbol in Workspace' },
      { '<leader>ff', '<Cmd>Telescope find_files<CR>', desc = 'Find files' },
      { '<leader>fg', '<Cmd>Telescope live_grep<CR>', desc = 'Live grep' },
      { '<leader>fb', '<Cmd>Telescope buffers<CR>', desc = 'Open editors' },
      { '<leader>fh', '<Cmd>Telescope help_tags<CR>', desc = 'Help' },
      { '<leader>fr', '<Cmd>Telescope oldfiles<CR>', desc = 'Recent files' },
      { '<leader>fc', '<Cmd>Telescope commands<CR>', desc = 'Commands' },
      { '<leader>fk', '<Cmd>Telescope keymaps<CR>', desc = 'Keymaps' },
      { '<leader>fd', '<Cmd>Telescope diagnostics<CR>', desc = 'Diagnostics' },
    },
    opts = function()
      local actions = require('telescope.actions')
      return {
        defaults = {
          prompt_prefix = ' ' .. require('config.icons').ui.search .. '  ',
          selection_caret = ' ' .. require('config.icons').ui.caret .. ' ',
          entry_prefix = '   ',
          -- VS Code's quick-open is a centred dropdown anchored near the top
          layout_strategy = 'horizontal',
          layout_config = {
            horizontal = { prompt_position = 'top', preview_width = 0.55, width = 0.86, height = 0.72 },
          },
          sorting_strategy = 'ascending',
          borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└' },
          winblend = 0,
          path_display = { 'truncate' },
          file_ignore_patterns = { '%.git/', '__pycache__/', '%.venv/', 'node_modules/' },
          mappings = {
            i = {
              ['<Esc>'] = actions.close,
              ['<C-j>'] = actions.move_selection_next,
              ['<C-k>'] = actions.move_selection_previous,
              ['<Down>'] = actions.move_selection_next,
              ['<Up>'] = actions.move_selection_previous,
              ['<C-u>'] = false,
            },
          },
        },
        pickers = {
          find_files = { hidden = true },
          buffers = { sort_mru = true, ignore_current_buffer = true },
        },
        extensions = {
          fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require('telescope')
      telescope.setup(opts)
      pcall(telescope.load_extension, 'fzf')
    end,
  },
}
