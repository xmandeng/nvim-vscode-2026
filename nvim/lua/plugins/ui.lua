-- Editor tabs, status bar, breadcrumbs, indent guides: the VS Code chrome.
return {
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- ── editor tab strip ──────────────────────────────────────────────────────
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = function()
      return {
        options = {
          mode = 'buffers',
          themable = true,
          separator_style = 'thin',   -- VS Code tabs are square, not powerline
          always_show_bufferline = true,
          show_buffer_close_icons = true,
          show_close_icon = false,
          diagnostics = 'nvim_lsp',
          diagnostics_indicator = function(_, _, diag)
            local s = {}
            local ic = require('config.icons').diagnostics
            if diag.error then s[#s + 1] = ic.error .. ' ' .. diag.error end
            if diag.warning then s[#s + 1] = ic.warn .. ' ' .. diag.warning end
            return table.concat(s, ' ')
          end,
          indicator = { style = 'underline' },  -- VS Code underlines the active tab
          offsets = {
            {
              filetype = 'neo-tree',
              text = 'EXPLORER',
              text_align = 'left',
              separator = true,
              highlight = 'NeoTreeTitleBar',
            },
          },
          hover = { enabled = true, delay = 120, reveal = { 'close' } },
        },
      }
    end,
  },

  -- ── status bar ────────────────────────────────────────────────────────────
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = function()
      local p = require('vscode2026').palette()
      -- VS Code's status bar is one flat colour and turns orange while debugging.
      local base = { fg = p.fg_tab_inactive, bg = p.bg_statusline }
      local seg = { a = base, b = base, c = base, x = base, y = base, z = base }
      local theme = {
        normal = seg,
        insert = seg,
        visual = seg,
        replace = seg,
        command = seg,
        inactive = seg,
      }
      return {
        options = {
          theme = theme,
          globalstatus = true,
          component_separators = '',
          section_separators = '',
          disabled_filetypes = { statusline = { 'dashboard', 'alpha' } },
        },
        sections = {
          lualine_a = {
            { 'mode', fmt = function(m) return ' ' .. m:sub(1, 1) .. m:sub(2):lower() end },
          },
          lualine_b = {
            { 'branch', icon = require('config.icons').ui.git },
            {
              'diff',
              symbols = { added = '+', modified = '~', removed = '-' },
              diff_color = {
                added = { fg = p.git_add }, modified = { fg = p.git_change },
                removed = { fg = p.git_delete },
              },
            },
          },
          lualine_c = {
            {
              'diagnostics',
              symbols = {
                error = require('config.icons').diagnostics.error .. ' ',
                warn = require('config.icons').diagnostics.warn .. ' ',
                info = require('config.icons').diagnostics.info .. ' ',
                hint = require('config.icons').diagnostics.hint .. ' ',
              },
              diagnostics_color = {
                error = { fg = p.error }, warn = { fg = p.warn },
                info = { fg = p.info }, hint = { fg = p.hint },
              },
            },
          },
          lualine_x = {
            -- active LSP servers, like VS Code's language indicator
            {
              function()
                local names = {}
                for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                  names[#names + 1] = c.name
                end
                return #names > 0 and (require('config.icons').ui.gear .. ' ' .. table.concat(names, ', ')) or ''
              end,
              color = { fg = p.fg_tab_inactive },
            },
            { 'encoding' },
            { 'fileformat', symbols = { unix = 'LF', dos = 'CRLF', mac = 'CR' } },
            { 'filetype' },
          },
          lualine_y = {
            { function() return 'Spaces: ' .. vim.bo.shiftwidth end },
          },
          lualine_z = {
            { function() return 'Ln %l, Col %c' end },
          },
        },
        extensions = { 'neo-tree', 'lazy', 'nvim-dap-ui', 'quickfix', 'trouble' },
      }
    end,
  },

  -- ── breadcrumbs ───────────────────────────────────────────────────────────
  {
    'Bekaboo/dropbar.nvim',
    event = 'VeryLazy',
    opts = function()
      local p = require('vscode2026').palette()
      vim.api.nvim_set_hl(0, 'DropBarIconUISeparator', { fg = p.linenr })
      vim.api.nvim_set_hl(0, 'DropBarIconUIPickPivot', { fg = p.warn, bold = true })
      return {
        bar = {
          truncate = true,
          pick = { pivots = 'abcdefghijklmnopqrstuvwxyz' },
        },
        icons = { ui = { bar = { separator = ' ' .. require('config.icons').ui.separator .. ' ', extends = '…' } } },
        menu = {
          win_configs = { border = 'single' },
        },
      }
    end,
    keys = {
      { '<leader>;', function() require('dropbar.api').pick() end, desc = 'Pick breadcrumb' },
    },
  },

  -- ── indent guides ─────────────────────────────────────────────────────────
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      indent = { char = '│', highlight = 'IblIndent' },
      scope = { enabled = true, show_start = false, show_end = false, highlight = 'IblScope' },
      exclude = {
        filetypes = { 'help', 'lazy', 'mason', 'neo-tree', 'dashboard', 'dap-repl', 'checkhealth' },
      },
    },
  },

  -- ── keybinding discoverability ────────────────────────────────────────────
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = { preset = 'helix', win = { border = 'single' } },
  },
}
