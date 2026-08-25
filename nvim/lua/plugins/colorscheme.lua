-- The generated Dark 2026 port ships inside this config (lua/vscode2026),
-- so there is nothing to download -- we just make it load first.
return {
  {
    'LazyVim/LazyVim', enabled = false,
  },
  {
    name = 'vscode2026',
    dir = vim.fn.stdpath('config'),
    lazy = false,
    priority = 1000,
    config = function()
      require('vscode2026').setup({
        transparent = false,
        italic_comments = true,
        overrides = {},   -- put personal tweaks here; survives `make theme`
      })
      vim.cmd.colorscheme('vscode-2026-dark')
    end,
  },
}
