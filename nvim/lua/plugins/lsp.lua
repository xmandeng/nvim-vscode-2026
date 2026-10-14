-- Language servers. Python is basedpyright (types, hovers, inlay hints) +
-- ruff (lint, format, organise imports) -- the same split as Pylance + the
-- Ruff extension in VS Code.

-- The only servers this config starts. Mason can hold others (left over from
-- an earlier setup, or installed by hand with :Mason); those stay installed
-- but are never enabled.
local servers = { 'basedpyright', 'ruff', 'lua_ls' }

return {
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    build = ':MasonUpdate',
    opts = function()
      local i = require('config.icons').mason
      return { ui = { border = 'single', icons = {
        package_installed = i.installed, package_pending = i.pending, package_uninstalled = i.uninstalled,
      } } }
    end,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
    opts = {
      ensure_installed = servers,
      automatic_enable = servers,
    },
  },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- ── server settings ────────────────────────────────────────────────────
      vim.lsp.config('basedpyright', {
        settings = {
          basedpyright = {
            -- basedpyright defaults to "recommended", which is far stricter than
            -- Pylance. "standard" reproduces what VS Code shows you today.
            analysis = {
              typeCheckingMode = 'standard',
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = 'openFilesOnly',
              inlayHints = {
                variableTypes = true,
                callArgumentNames = true,
                functionReturnTypes = true,
                genericTypes = false,
              },
            },
            -- ruff owns import organisation; stop the two fighting over it
            disableOrganizeImports = true,
          },
        },
      })

      vim.lsp.config('ruff', {
        init_options = {
          settings = {
            -- mirrors "ruff.fixAll": true and the [python] codeActionsOnSave block
            fixAll = true,
            organizeImports = true,
            lineLength = 88,
          },
        },
        on_attach = function(client)
          -- basedpyright gives better hovers; silence ruff's so they don't clash
          client.server_capabilities.hoverProvider = false
        end,
      })

      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
            diagnostics = { globals = { 'vim' } },
            telemetry = { enable = false },
            hint = { enable = true },
          },
        },
      })

      -- ── per-buffer keymaps: VS Code's editor commands ─────────────────────
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('vsc_lsp_attach', { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
          end

          map('n', '<F12>', vim.lsp.buf.definition, 'Go to Definition')
          map('n', 'gd', vim.lsp.buf.definition, 'Go to Definition')
          map('n', '<C-S-F12>', vim.lsp.buf.implementation, 'Go to Implementation')
          map('n', '<S-F12>', '<Cmd>Telescope lsp_references<CR>', 'Go to References')
          map('n', 'gy', vim.lsp.buf.type_definition, 'Go to Type Definition')
          map('n', 'gD', vim.lsp.buf.declaration, 'Go to Declaration')
          map('n', 'K', function() vim.lsp.buf.hover({ border = 'single' }) end, 'Show Hover')
          -- insert mode only: in normal mode Ctrl+K is "focus the window above"
          map('i', '<C-k>', function() vim.lsp.buf.signature_help({ border = 'single' }) end, 'Signature Help')
          map('n', '<F2>', vim.lsp.buf.rename, 'Rename Symbol')
          map({ 'n', 'v' }, '<C-.>', vim.lsp.buf.code_action, 'Quick Fix')
          map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'Code Action')
          map('n', '<F8>', function() vim.diagnostic.jump({ count = 1, float = true }) end, 'Next Problem')
          map('n', '<S-F8>', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Previous Problem')
          map('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end, 'Next Diagnostic')
          map('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end, 'Previous Diagnostic')

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then return end

          -- inlay hints, as VS Code shows for Python parameter names / types
          if client:supports_method('textDocument/inlayHint') then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
            map('n', '<leader>uh', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
            end, 'Toggle Inlay Hints')
          end

          -- highlight other occurrences of the symbol under the cursor
          if client:supports_method('textDocument/documentHighlight') then
            local grp = vim.api.nvim_create_augroup('vsc_lsp_hl_' .. buf, { clear = true })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              group = grp, buffer = buf, callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              group = grp, buffer = buf, callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },

  -- ── Problems panel (Ctrl+Shift+M) ───────────────────────────────────────────
  {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    opts = { focus = true, win = { border = 'single' } },
    keys = {
      { '<C-S-m>', '<Cmd>Trouble diagnostics toggle<CR>', desc = 'Problems' },
      { '<leader>xx', '<Cmd>Trouble diagnostics toggle<CR>', desc = 'Problems' },
      { '<leader>xX', '<Cmd>Trouble diagnostics toggle filter.buf=0<CR>', desc = 'Problems (buffer)' },
      { '<leader>xs', '<Cmd>Trouble symbols toggle<CR>', desc = 'Outline' },
    },
  },

  -- ── formatting: format-on-save + organizeImports, via ruff ─────────────────
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = 'ConformInfo',
    keys = {
      { '<M-S-f>', function() require('conform').format({ async = true, lsp_format = 'fallback' }) end,
        mode = { 'n', 'v' }, desc = 'Format Document' },
      { '<leader>cf', function() require('conform').format({ async = true, lsp_format = 'fallback' }) end,
        mode = { 'n', 'v' }, desc = 'Format Document' },
    },
    opts = {
      -- "editor.formatOnSave": true with ruff as the [python] formatter
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
        return { timeout_ms = 1000, lsp_format = 'fallback' }
      end,
      formatters_by_ft = {
        -- no ruff_fix: it deletes an import you have just typed but not used
        -- yet. Fixes stay one keystroke away as code actions (Space ca).
        python = { 'ruff_organize_imports', 'ruff_format' },
        lua = { 'stylua' },
        json = { 'prettier' }, jsonc = { 'prettier' },
        yaml = { 'prettier' }, markdown = { 'prettier' },
        sh = { 'shfmt' }, bash = { 'shfmt' },
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
      -- :FormatDisable / :FormatEnable to toggle format-on-save per session
      vim.api.nvim_create_user_command('FormatDisable', function(a)
        if a.bang then vim.b.disable_autoformat = true else vim.g.disable_autoformat = true end
      end, { bang = true, desc = 'Disable format on save' })
      vim.api.nvim_create_user_command('FormatEnable', function()
        vim.b.disable_autoformat, vim.g.disable_autoformat = false, false
      end, { desc = 'Enable format on save' })
    end,
  },
}
