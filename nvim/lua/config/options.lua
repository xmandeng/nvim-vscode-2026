-- Editor options. Where a VS Code setting has a Neovim equivalent, the
-- originating settings.json key is named in a comment.
local o = vim.opt

o.termguicolors = true
o.mouse = 'a'
o.mousemoveevent = true
o.clipboard = 'unnamedplus'

-- gutter / rulers
o.number = true
o.relativenumber = false          -- VS Code shows absolute line numbers
o.signcolumn = 'yes:1'
o.cursorline = true               -- editor.renderLineHighlight
o.colorcolumn = ''
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false                    -- editor.wordWrap = "off"

-- whitespace rendering: "editor.renderWhitespace": "all"
--                      "editor.renderControlCharacters": true
o.list = true
o.listchars = {
  space = '·', tab = '→ ', trail = '·', extends = '›', precedes = '‹', nbsp = '␣',
}
local icons = require('config.icons')
o.fillchars = {
  eob = ' ', fold = ' ', foldsep = ' ', diff = '╱',
  foldopen = icons.fold.open, foldclose = icons.fold.closed,
}

-- indentation (VS Code defaults: 4 spaces, detected per file)
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.smartindent = true
o.breakindent = true

-- search
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.incsearch = true

-- files: "files.eol": "\n"
o.fileformats = 'unix,dos'
o.undofile = true
o.undolevels = 10000
o.swapfile = false
o.backup = false
o.writebackup = false
o.autoread = true

-- completion / UI responsiveness
o.updatetime = 200
o.timeoutlen = 400
o.completeopt = { 'menu', 'menuone', 'noselect' }
o.pumheight = 12                  -- VS Code suggest widget shows ~12 rows
o.winborder = 'single'
o.splitright = true               -- new editors open to the right
o.splitbelow = true
o.splitkeep = 'screen'
o.showmode = false                -- lualine renders the mode instead
o.laststatus = 3                  -- one global statusbar, like VS Code
o.showtabline = 2                 -- always show the editor tab strip
o.cmdheight = 1
o.confirm = true
o.title = true
-- "window.title": "${separator}${rootName}${separator}${dirty}${activeEditorMedium}"
o.titlestring = '%{fnamemodify(getcwd(), ":t")} — %{expand("%:~:.")}%{&modified ? " ●" : ""}'

-- folding via treesitter, but everything open on entry
o.foldmethod = 'expr'
o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
o.foldtext = ''
o.foldlevel = 99
o.foldlevelstart = 99

-- diagnostics presentation matched to VS Code's squiggles + gutter icons
vim.diagnostic.config({
  virtual_text = { spacing = 4, prefix = '●', source = 'if_many' },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.diagnostics.error,
      [vim.diagnostic.severity.WARN]  = icons.diagnostics.warn,
      [vim.diagnostic.severity.INFO]  = icons.diagnostics.info,
      [vim.diagnostic.severity.HINT]  = icons.diagnostics.hint,
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'single', source = 'if_many', header = '', prefix = '' },
})
