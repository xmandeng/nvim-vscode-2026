-- Install the language servers and the debugger through Mason, for bootstrap.sh.
-- Run inside the config so Mason is set up:
--   nvim --headless -c 'luafile tools/install_servers.lua'
-- Exits 1 when any package fails or the install times out.
local want = { 'basedpyright', 'ruff', 'lua-language-server', 'debugpy' }

require('lazy').load({ plugins = { 'mason.nvim', 'mason-lspconfig.nvim' } })
local registry = require('mason-registry')

local pending, failed, refreshed = 0, {}, false
registry.refresh(function()
  for _, name in ipairs(want) do
    local ok, pkg = pcall(registry.get_package, name)
    if not ok then
      table.insert(failed, name .. ' (not in the Mason registry)')
    elseif not pkg:is_installed() then
      pending = pending + 1
      pkg:once('install:success', function()
        print('installed ' .. name)
        pending = pending - 1
      end)
      pkg:once('install:failed', function()
        table.insert(failed, name)
        pending = pending - 1
      end)
      pkg:install()
    end
  end
  refreshed = true
end)

local done = vim.wait(600000, function() return refreshed and pending == 0 end, 500)
if not done then table.insert(failed, 'timed out with ' .. pending .. ' still installing') end

if #failed > 0 then
  io.stderr:write('FAILED: ' .. table.concat(failed, ', ') .. '\n')
  vim.cmd('cquit 1')
end
vim.cmd('qall')
