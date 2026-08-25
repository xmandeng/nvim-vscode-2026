-- neo-tree == VS Code's Explorer sidebar.
--   Ctrl+B        toggle
--   Ctrl+Shift+E  focus (reveals the current file)
return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  cmd = 'Neotree',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  keys = {
    { '<C-b>', '<Cmd>Neotree toggle left<CR>', desc = 'Toggle Explorer' },
    { '<C-S-e>', '<Cmd>Neotree focus reveal left<CR>', desc = 'Focus Explorer' },
    { '<leader>e', '<Cmd>Neotree toggle left<CR>', desc = 'Toggle Explorer' },
    { '<leader>ge', '<Cmd>Neotree float git_status<CR>', desc = 'Source control' },
  },
  opts = {
    close_if_last_window = true,
    popup_border_style = 'single',
    enable_git_status = true,
    enable_diagnostics = true,
    sort_case_insensitive = true,
    default_component_configs = {
      indent = {
        indent_size = 2,
        padding = 1,
        with_markers = true,
        indent_marker = '│',
        last_indent_marker = '└',
        with_expanders = true,
        expander_collapsed = require('config.icons').explorer.expander_collapsed,
        expander_expanded = require('config.icons').explorer.expander_expanded,
        expander_highlight = 'NeoTreeExpander',
      },
      icon = {
        folder_closed = require('config.icons').explorer.folder_closed,
        folder_open = require('config.icons').explorer.folder_open,
        folder_empty = require('config.icons').explorer.folder_empty,
        default = require('config.icons').explorer.file,
      },
      modified = { symbol = '●', highlight = 'NeoTreeModified' },
      git_status = {
        symbols = {
          added = 'A', modified = 'M', deleted = 'D', renamed = 'R',
          untracked = 'U', ignored = '', unstaged = '', staged = '', conflict = 'C',
        },
      },
    },
    window = {
      position = 'left',
      width = 32,
      mappings = {
        ['<space>'] = 'none',
        ['<CR>'] = 'open',
        ['<2-LeftMouse>'] = 'open',
        ['o'] = 'open',
        ['a'] = { 'add', config = { show_path = 'relative' } },
        ['A'] = 'add_directory',
        ['d'] = 'delete',
        ['r'] = 'rename',
        ['c'] = 'copy',
        ['x'] = 'cut_to_clipboard',
        ['p'] = 'paste_from_clipboard',
        ['R'] = 'refresh',
        ['H'] = 'toggle_hidden',
        ['<C-b>'] = function() vim.cmd('Neotree close') end,
      },
    },
    filesystem = {
      bind_to_cwd = true,
      follow_current_file = { enabled = true, leave_dirs_open = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false,
        hide_dotfiles = false,      -- VS Code shows dotfiles by default
        hide_gitignored = false,
        hide_by_name = { '.git', '__pycache__', '.pytest_cache', '.ruff_cache',
                         '.mypy_cache', '.venv', 'node_modules', '.DS_Store' },
      },
    },
    event_handlers = {
      {
        event = 'neo_tree_buffer_enter',
        handler = function()
          -- Explorer uses the sidebar background, not the editor background
          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = 'no'
          vim.opt_local.cursorline = true
          vim.opt_local.winhighlight =
            'Normal:NeoTreeNormal,NormalNC:NeoTreeNormalNC,CursorLine:NeoTreeCursorLine'
        end,
      },
    },
  },
}
