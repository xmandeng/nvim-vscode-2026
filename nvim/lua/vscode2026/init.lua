-- vscode2026: applies the generated Dark 2026 palette to Neovim.
--
-- Everything colour-bearing lives in generated.lua, which is produced from the
-- actual VS Code theme JSON by tools/gen_colorscheme.py. Keep manual tweaks in
-- `opts.overrides` rather than editing the generated file, so `make theme`
-- stays a safe no-diff operation.

local M = {}

M.config = {
  transparent = false,
  italic_comments = true,
  overrides = {},
}

---@param opts table|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

function M.load()
  if vim.g.colors_name then
    vim.cmd('hi clear')
  end
  vim.o.termguicolors = true
  vim.o.background = 'dark'
  vim.g.colors_name = 'vscode-2026-dark'

  local theme = require('vscode2026.generated')
  local groups = vim.deepcopy(theme.groups)
  local p = theme.palette

  if M.config.transparent then
    for _, name in ipairs({ 'Normal', 'NormalNC', 'SignColumn', 'FoldColumn', 'EndOfBuffer' }) do
      if groups[name] then groups[name].bg = 'NONE' end
    end
  end
  if not M.config.italic_comments then
    for _, name in ipairs({ 'Comment', '@comment', '@lsp.type.comment' }) do
      if groups[name] then groups[name].italic = nil end
    end
  end

  groups = vim.tbl_deep_extend('force', groups, M.config.overrides or {})

  -- Set each group independently: one bad colour (typically from a user
  -- override) must not abort the loop and leave Normal unset.
  local failed = {}
  for name, spec in pairs(groups) do
    local ok, err = pcall(vim.api.nvim_set_hl, 0, name, spec)
    if not ok then
      failed[#failed + 1] = string.format('%s: %s', name, err)
    end
  end
  if #failed > 0 then
    vim.schedule(function()
      vim.notify('vscode2026: skipped invalid highlight group(s):\n' ..
        table.concat(failed, '\n'), vim.log.levels.WARN)
    end)
  end

  -- :terminal uses the theme's ANSI palette so shell output matches the editor.
  local a = p.ansi
  vim.g.terminal_color_0,  vim.g.terminal_color_8  = a.black, a.bright_black
  vim.g.terminal_color_1,  vim.g.terminal_color_9  = a.red, a.bright_red
  vim.g.terminal_color_2,  vim.g.terminal_color_10 = a.green, a.bright_green
  vim.g.terminal_color_3,  vim.g.terminal_color_11 = a.yellow, a.bright_yellow
  vim.g.terminal_color_4,  vim.g.terminal_color_12 = a.blue, a.bright_blue
  vim.g.terminal_color_5,  vim.g.terminal_color_13 = a.magenta, a.bright_magenta
  vim.g.terminal_color_6,  vim.g.terminal_color_14 = a.cyan, a.bright_cyan
  vim.g.terminal_color_7,  vim.g.terminal_color_15 = a.white, a.bright_white
end

---Palette accessor for statusline / plugin config.
function M.palette()
  return require('vscode2026.generated').palette
end

return M
