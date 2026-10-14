-- VS Code keybindings.
--
-- Chords using Ctrl+Shift+<key> require a terminal that speaks the kitty
-- keyboard protocol (Alacritty >= 0.13, Kitty, Ghostty, WezTerm). In terminals
-- without it those chords are indistinguishable from plain Ctrl+<key>; the
-- <leader> equivalents listed alongside always work. See docs/KEYBINDINGS.md.
--
-- A VS Code chord is mapped only where it does not hide a core Vim key. Left to
-- Vim on purpose: Ctrl+W (window commands), Ctrl+A (increment), Ctrl+Z/Ctrl+Y
-- (suspend/scroll; undo is u, redo Ctrl+R), Ctrl+N, Ctrl+B (page up), Ctrl+T
-- (tag jump back), gi (resume insert) and gr (Neovim's grr/grn/gra/gri/grt).

local map = vim.keymap.set

local function nvi(lhs, rhs, desc)
  map({ 'n', 'v', 'i' }, lhs, rhs, { desc = desc, silent = true })
end

-- ── File ────────────────────────────────────────────────────────────────────
nvi('<C-s>', '<Cmd>write<CR>', 'Save file')
map('n', '<C-,>', '<Cmd>edit $MYVIMRC<CR>', { desc = 'Open settings', silent = true })

-- ── Edit ────────────────────────────────────────────────────────────────────
-- Alt+Up/Down move a line; Shift+Alt+Down copies it (VS Code exact behaviour)
map('n', '<M-Up>', '<Cmd>move .-2<CR>==', { desc = 'Move line up', silent = true })
map('n', '<M-Down>', '<Cmd>move .+1<CR>==', { desc = 'Move line down', silent = true })
map('i', '<M-Up>', '<Esc><Cmd>move .-2<CR>==gi', { desc = 'Move line up', silent = true })
map('i', '<M-Down>', '<Esc><Cmd>move .+1<CR>==gi', { desc = 'Move line down', silent = true })
map('v', '<M-Up>', ":move '<-2<CR>gv=gv", { desc = 'Move selection up', silent = true })
map('v', '<M-Down>', ":move '>+1<CR>gv=gv", { desc = 'Move selection down', silent = true })
map('n', '<M-S-Down>', '<Cmd>copy .<CR>', { desc = 'Duplicate line down', silent = true })
map('n', '<M-S-Up>', '<Cmd>copy .-1<CR>', { desc = 'Duplicate line up', silent = true })
map('v', '<M-S-Down>', ":copy '><CR>gv", { desc = 'Duplicate selection', silent = true })
-- indent/outdent keeping the selection, like VS Code's Tab/Shift+Tab
map('v', '<Tab>', '>gv', { desc = 'Indent', silent = true })
map('v', '<S-Tab>', '<gv', { desc = 'Outdent', silent = true })

-- ── Navigation ──────────────────────────────────────────────────────────────
map('n', '<C-Tab>', '<Cmd>BufferLineCycleNext<CR>', { desc = 'Next editor', silent = true })
map('n', '<C-S-Tab>', '<Cmd>BufferLineCyclePrev<CR>', { desc = 'Previous editor', silent = true })
map('n', '<M-Right>', '<Cmd>BufferLineCycleNext<CR>', { desc = 'Next editor', silent = true })
map('n', '<M-Left>', '<Cmd>BufferLineCyclePrev<CR>', { desc = 'Previous editor', silent = true })
for i = 1, 9 do
  map('n', '<M-' .. i .. '>', '<Cmd>BufferLineGoToBuffer ' .. i .. '<CR>',
    { desc = 'Go to editor ' .. i, silent = true })
end
-- split panes
map('n', '<C-\\>', '<Cmd>vsplit<CR>', { desc = 'Split editor right', silent = true })
map('n', '<C-h>', '<C-w>h', { desc = 'Focus left group' })
map('n', '<C-j>', '<C-w>j', { desc = 'Focus below group' })
map('n', '<C-k>', '<C-w>k', { desc = 'Focus above group' })
map('n', '<C-l>', '<C-w>l', { desc = 'Focus right group' })

-- ── Misc ────────────────────────────────────────────────────────────────────
map('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear highlight', silent = true })
map('n', '<C-Up>', '<C-y>', { desc = 'Scroll up', silent = true })
map('n', '<C-Down>', '<C-e>', { desc = 'Scroll down', silent = true })
-- Ctrl+= / Ctrl+- resize the focused group (VS Code zooms font; closest analogue)
map('n', '<C-=>', '<Cmd>resize +2<CR>', { desc = 'Grow group', silent = true })
map('n', '<C-->', '<Cmd>resize -2<CR>', { desc = 'Shrink group', silent = true })

-- Plugin-owned bindings live next to their plugin spec:
--   Ctrl+P / Ctrl+Shift+P / Ctrl+Shift+F  -> lua/plugins/finder.lua
--   Space e / Ctrl+Shift+E                -> lua/plugins/explorer.lua
--   Ctrl+`                                -> lua/plugins/terminal.lua
--   F5 F9 F10 F11 / Ctrl+Shift+D          -> lua/plugins/dap.lua
--   F12 Shift+F12 F2 Ctrl+. Ctrl+Shift+M  -> lua/plugins/lsp.lua
--   Ctrl+/                                -> lua/plugins/editor.lua
