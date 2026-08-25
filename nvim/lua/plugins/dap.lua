-- Run & Debug. Keys match VS Code exactly:
--   F5 continue/start   Shift+F5 stop      Ctrl+Shift+F5 restart
--   F9 breakpoint       F10 step over      F11 step into   Shift+F11 step out
--   Ctrl+Shift+D toggles the debug panel
return {
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
      { 'theHamsta/nvim-dap-virtual-text', opts = { virt_text_pos = 'eol', commented = true } },
      { 'mfussenegger/nvim-dap-python' },
    },
    keys = {
      -- VS Code's F5 starts immediately; plain dap.continue() would pop a
      -- configuration picker every time. Continue an existing session, else
      -- launch the default configuration straight away.
      { '<F5>', function()
          local dap = require('dap')
          if dap.session() then
            dap.continue()
          else
            local cfgs = dap.configurations[vim.bo.filetype] or {}
            if #cfgs > 0 then dap.run(cfgs[1]) else dap.continue() end
          end
        end, desc = 'Debug: Start/Continue' },
      { '<C-F5>', function() require('dap').continue() end, desc = 'Debug: Start (choose config)' },
      { '<leader>dS', function() require('dap').continue() end, desc = 'Debug: Select configuration' },
      { '<S-F5>', function() require('dap').terminate() end, desc = 'Debug: Stop' },
      { '<C-S-F5>', function() require('dap').restart() end, desc = 'Debug: Restart' },
      { '<F9>', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
      { '<S-F9>', function()
          vim.ui.input({ prompt = 'Breakpoint condition: ' }, function(c)
            if c and c ~= '' then require('dap').set_breakpoint(c) end
          end)
        end, desc = 'Debug: Conditional Breakpoint' },
      { '<F10>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
      { '<F11>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
      { '<S-F11>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
      { '<C-S-d>', function() require('dapui').toggle() end, desc = 'Debug: Toggle Panel' },
      { '<leader>dd', function() require('dapui').toggle() end, desc = 'Debug: Toggle Panel' },
      { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Debug: REPL' },
      { '<leader>dl', function() require('dap').run_last() end, desc = 'Debug: Run Last' },
      { '<leader>dw', function() require('dapui').eval(nil, { enter = true }) end,
        mode = { 'n', 'v' }, desc = 'Debug: Evaluate' },
      { '<leader>dt', function() require('dap-python').test_method() end, desc = 'Debug: Test Method' },
      { '<leader>dc', function() require('dap-python').test_class() end, desc = 'Debug: Test Class' },
    },
    config = function()
      local dap, dapui = require('dap'), require('dapui')
      local p = require('vscode2026').palette()

      -- gutter icons, coloured from the theme's debug palette
      local icons = require('config.icons').dap
      vim.fn.sign_define('DapBreakpoint',
        { text = icons.breakpoint, texthl = 'DapBreakpoint', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointCondition',
        { text = icons.breakpoint_condition, texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
      vim.fn.sign_define('DapBreakpointRejected',
        { text = icons.breakpoint_rejected, texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
      vim.fn.sign_define('DapLogPoint',
        { text = icons.logpoint, texthl = 'DapLogPoint', linehl = '', numhl = '' })
      vim.fn.sign_define('DapStopped',
        { text = icons.stopped, texthl = 'DapStopped', linehl = 'DapStoppedLine', numhl = 'DapStopped' })

      -- ── Python adapter ───────────────────────────────────────────────────
      -- Prefer the project's own venv so breakpoints land in the right code.
      local function venv_python()
        local venv = os.getenv('VIRTUAL_ENV') or os.getenv('CONDA_PREFIX')
        if venv then return venv .. '/bin/python' end
        local cwd = vim.uv.cwd()
        for _, dir in ipairs({ '.venv', 'venv', 'env' }) do
          local candidate = cwd .. '/' .. dir .. '/bin/python'
          if vim.uv.fs_stat(candidate) then return candidate end
        end
        return vim.fn.exepath('python3') ~= '' and vim.fn.exepath('python3') or 'python'
      end

      -- The ADAPTER interpreter must have debugpy importable, which the
      -- project's own venv usually does not. Mason installs debugpy into a
      -- dedicated venv -- use that to run the adapter, and select the
      -- interpreter the *debuggee* runs under per-configuration via
      -- `pythonPath` below. Mixing these up is why sessions die instantly
      -- with "adapter python exited with 1".
      local function debugpy_python()
        local mason = vim.fn.stdpath('data') .. '/mason/packages/debugpy/venv/bin/python'
        if vim.uv.fs_stat(mason) then return mason end
        return venv_python()
      end

      require('dap-python').setup(debugpy_python())
      require('dap-python').test_runner = 'pytest'

      -- Replace dap-python's defaults rather than appending to them: it
      -- registers four of its own (file, file:args, attach, file:doctest),
      -- and an eight-entry picker is noise. This is the curated set.
      dap.configurations.python = {}
      table.insert(dap.configurations.python, {
        type = 'python', request = 'launch', name = 'Python: Current File',
        program = '${file}', console = 'integratedTerminal',
        cwd = '${workspaceFolder}', justMyCode = true,
        pythonPath = venv_python,
      })
      table.insert(dap.configurations.python, {
        type = 'python', request = 'launch', name = 'Python: Module',
        module = function() return vim.fn.input('Module name: ') end,
        console = 'integratedTerminal', cwd = '${workspaceFolder}',
        pythonPath = venv_python,
      })
      table.insert(dap.configurations.python, {
        type = 'python', request = 'launch', name = 'Python: File with Arguments',
        program = '${file}', console = 'integratedTerminal', cwd = '${workspaceFolder}',
        args = function()
          return vim.split(vim.fn.input('Arguments: '), ' ', { trimempty = true })
        end,
        pythonPath = venv_python,
      })
      table.insert(dap.configurations.python, {
        type = 'python', request = 'attach', name = 'Python: Attach (port 5678)',
        connect = { host = '127.0.0.1', port = 5678 },
        justMyCode = false,
      })

      -- A .vscode/launch.json in the project is picked up automatically by
      -- nvim-dap's providers; no explicit load_launchjs call is needed (and
      -- calling it now emits a deprecation warning).

      -- ── panel layout: variables/watches/stacks left, repl+console bottom ──
      dapui.setup({
        controls = { enabled = true, element = 'repl' },
        floating = { border = 'single', mappings = { close = { 'q', '<Esc>' } } },
        icons = { expanded = icons.expanded, collapsed = icons.collapsed, current_frame = icons.current_frame },
        layouts = {
          {
            position = 'left', size = 36,
            elements = {
              { id = 'scopes', size = 0.35 },
              { id = 'watches', size = 0.25 },
              { id = 'stacks', size = 0.25 },
              { id = 'breakpoints', size = 0.15 },
            },
          },
          {
            position = 'bottom', size = 10,
            elements = { { id = 'repl', size = 0.5 }, { id = 'console', size = 0.5 } },
          },
        },
      })

      -- open the panel on session start, close it when the session ends,
      -- and turn the status bar orange while stopped -- as VS Code does
      local function debug_statusline(on)
        if on then
          vim.api.nvim_set_hl(0, 'StatusLine', { fg = p.stat_debug_fg, bg = p.stat_debug })
        else
          vim.api.nvim_set_hl(0, 'StatusLine', { fg = p.fg, bg = p.bg_statusline })
        end
        pcall(function() require('lualine').refresh() end)
      end

      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open(); debug_statusline(true)
      end
      dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close(); debug_statusline(false)
      end
      dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close(); debug_statusline(false)
      end
    end,
  },
}
