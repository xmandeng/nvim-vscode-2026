-- Gutter decorations + inline blame, matching VS Code's SCM colours.
return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '┃' }, change = { text = '┃' },
        delete = { text = '' }, topdelete = { text = '' },
        changedelete = { text = '~' }, untracked = { text = '┆' },
      },
      current_line_blame = true,
      current_line_blame_opts = { delay = 400, virt_text_pos = 'eol' },
      current_line_blame_formatter = '      <author>, <author_time:%R> · <summary>',
      preview_config = { border = 'single' },
      on_attach = function(buf)
        local gs = require('gitsigns')
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
        end
        map('n', ']c', function() gs.nav_hunk('next') end, 'Next change')
        map('n', '[c', function() gs.nav_hunk('prev') end, 'Previous change')
        map('n', '<leader>hs', gs.stage_hunk, 'Stage hunk')
        map('n', '<leader>hr', gs.reset_hunk, 'Reset hunk')
        map('n', '<leader>hp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>hb', function() gs.blame_line({ full = true }) end, 'Blame line')
        map('n', '<leader>hd', gs.diffthis, 'Diff this')
        map('n', '<leader>ub', gs.toggle_current_line_blame, 'Toggle blame')
      end,
    },
  },
}
