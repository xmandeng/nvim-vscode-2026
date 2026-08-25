-- Editing behaviours VS Code gives you out of the box.
return {
  -- Ctrl+/ toggle line comment, Shift+Alt+A block comment
  {
    'numToStr/Comment.nvim',
    keys = {
      { '<C-_>', mode = { 'n', 'i', 'v' } },   -- many terminals send Ctrl+_ for Ctrl+/
      { '<C-/>', mode = { 'n', 'i', 'v' } },
      { 'gc', mode = { 'n', 'v' } },
    },
    config = function()
      require('Comment').setup()
      local api = require('Comment.api')
      local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
      local function toggle_line() api.toggle.linewise.current() end
      local function toggle_visual()
        vim.api.nvim_feedkeys(esc, 'nx', false)
        api.toggle.linewise(vim.fn.visualmode())
      end
      for _, lhs in ipairs({ '<C-_>', '<C-/>' }) do
        vim.keymap.set('n', lhs, toggle_line, { desc = 'Toggle comment', silent = true })
        vim.keymap.set('v', lhs, toggle_visual, { desc = 'Toggle comment', silent = true })
        vim.keymap.set('i', lhs, function()
          toggle_line()
        end, { desc = 'Toggle comment', silent = true })
      end
      vim.keymap.set('n', '<M-S-a>', function() api.toggle.blockwise.current() end,
        { desc = 'Toggle block comment', silent = true })
      vim.keymap.set('v', '<M-S-a>', function()
        vim.api.nvim_feedkeys(esc, 'nx', false)
        api.toggle.blockwise(vim.fn.visualmode())
      end, { desc = 'Toggle block comment', silent = true })
    end,
  },

  -- auto-close brackets and quotes
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = { check_ts = true, fast_wrap = { map = '<M-e>' } },
  },

  -- rainbow brackets, using the theme's editorBracketHighlight colours
  {
    'HiPhish/rainbow-delimiters.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('rainbow-delimiters.setup').setup({
        highlight = { 'RainbowDelimiterYellow', 'RainbowDelimiterViolet', 'RainbowDelimiterBlue' },
      })
    end,
  },

  -- TODO/FIXME highlighting, like the VS Code TODO Highlight extension
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = 'nvim-lua/plenary.nvim',
    opts = { signs = false },
    keys = {
      { '<leader>ft', '<Cmd>TodoTelescope<CR>', desc = 'Find TODOs' },
    },
  },

  -- session persistence, so reopening a folder restores your editors
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    opts = {},
    keys = {
      { '<leader>qs', function() require('persistence').load() end, desc = 'Restore session' },
      { '<leader>ql', function() require('persistence').load({ last = true }) end, desc = 'Restore last session' },
    },
  },
}
