-- Parse-check every Lua file in the config. Run with: nvim -l tools/check.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h') .. '/nvim'
local bad = 0
for name in vim.fs.dir(root, { depth = 10 }) do
  if name:match('%.lua$') then
    local path = root .. '/' .. name
    local fn, err = loadfile(path)
    if not fn then
      bad = bad + 1
      print('SYNTAX ERROR: ' .. path .. '\n  ' .. tostring(err))
    end
  end
end
if bad == 0 then
  print('OK: all Lua files parse')
else
  print('FAILED: ' .. bad .. ' file(s)')
  os.exit(1)
end
