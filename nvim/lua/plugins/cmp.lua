-- IntelliSense. blink.cmp gives VS Code-shaped completion:
-- Ctrl+Space to trigger, Tab/Enter to accept, Ctrl+Shift+Space for signatures.
return {
  {
    'saghen/blink.cmp',
    event = { 'InsertEnter', 'CmdlineEnter' },
    version = '1.*',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      keymap = {
        preset = 'none',
        ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      completion = {
        accept = { auto_brackets = { enabled = true } },
        menu = {
          border = 'single',
          draw = { treesitter = { 'lsp' }, columns = {
            { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'kind' },
          } },
        },
        documentation = { auto_show = true, auto_show_delay_ms = 150, window = { border = 'single' } },
        ghost_text = { enabled = true },
        list = { selection = { preselect = false, auto_insert = true } },
      },
      signature = { enabled = true, window = { border = 'single' } },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
  },
}
