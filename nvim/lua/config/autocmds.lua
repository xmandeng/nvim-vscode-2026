-- Behavioural parity with the user's VS Code settings.json.
local aug = function(name) return vim.api.nvim_create_augroup('vsc_' .. name, { clear = true }) end

-- "files.autoSave": "afterDelay", "files.autoSaveDelay": 500,
-- "files.autoSaveWhenNoErrors": true, "files.autoSaveWorkspaceFilesOnly": true
local autosave = aug('autosave')
local timer, DELAY = nil, 500

local function should_autosave(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return false end
  if not vim.bo[buf].modifiable or vim.bo[buf].readonly then return false end
  if vim.bo[buf].buftype ~= '' then return false end
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then return false end
  -- autoSaveWorkspaceFilesOnly: only files under the current working directory
  local cwd = vim.uv.cwd()
  if cwd and not vim.startswith(vim.fs.normalize(name), vim.fs.normalize(cwd)) then
    return false
  end
  -- autoSaveWhenNoErrors: hold the save while the buffer has ERROR diagnostics
  local errs = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
  if #errs > 0 then return false end
  return true
end

vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
  group = autosave,
  desc = 'Auto-save after 500ms, matching files.autoSave=afterDelay',
  callback = function(ev)
    if timer then timer:stop() end
    timer = vim.defer_fn(function()
      if vim.bo[ev.buf].modified and should_autosave(ev.buf) then
        vim.api.nvim_buf_call(ev.buf, function() vim.cmd('silent! write') end)
      end
    end, DELAY)
  end,
})

-- reload when the file changes on disk (VS Code does this silently)
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave', 'CursorHold' }, {
  group = aug('checktime'),
  callback = function()
    if vim.o.buftype ~= 'nofile' then vim.cmd('checktime') end
  end,
})

-- highlight on yank — no VS Code equivalent, but it replaces the selection
-- flash you lose when leaving a GUI editor
vim.api.nvim_create_autocmd('TextYankPost', {
  group = aug('yank'),
  callback = function() vim.hl.on_yank({ higroup = 'Visual', timeout = 150 }) end,
})

-- "files.eol": "\n"
vim.api.nvim_create_autocmd('BufNewFile', {
  group = aug('eol'),
  callback = function() vim.bo.fileformat = 'unix' end,
})

-- restore the last cursor position, like VS Code reopening an editor
vim.api.nvim_create_autocmd('BufReadPost', {
  group = aug('lastpos'),
  callback = function(ev)
    local exclude = { 'gitcommit', 'gitrebase' }
    if vim.tbl_contains(exclude, vim.bo[ev.buf].filetype) then return end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close scratch/list buffers with a bare `q`
vim.api.nvim_create_autocmd('FileType', {
  group = aug('quickclose'),
  pattern = { 'help', 'qf', 'man', 'checkhealth', 'lspinfo', 'notify', 'dap-float' },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set('n', 'q', '<Cmd>close<CR>', { buffer = ev.buf, silent = true })
  end,
})

-- 2-space indent for the formats where VS Code's own defaults use 2
vim.api.nvim_create_autocmd('FileType', {
  group = aug('indent2'),
  pattern = { 'lua', 'json', 'jsonc', 'yaml', 'html', 'css', 'scss',
              'javascript', 'typescript', 'javascriptreact', 'typescriptreact',
              'markdown', 'toml', 'sh', 'bash' },
  callback = function()
    vim.bo.shiftwidth, vim.bo.tabstop, vim.bo.softtabstop = 2, 2, 2
  end,
})
