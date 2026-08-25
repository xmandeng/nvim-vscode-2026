-- Syntax parsing. The generated theme maps every @capture to its VS Code
-- TextMate scope, so the colours here are the colours VS Code renders.
return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- Pinned to master deliberately. The default branch is now the `main`
    -- rewrite, which drops `nvim-treesitter.configs` and the ensure_installed/
    -- highlight options below, and which nvim-treesitter-context and
    -- rainbow-delimiters do not yet target.
    branch = 'master',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
        'python', 'lua', 'vim', 'vimdoc', 'query', 'bash', 'json', 'jsonc',
        'yaml', 'toml', 'markdown', 'markdown_inline', 'regex', 'diff',
        'gitcommit', 'gitignore', 'dockerfile', 'sql', 'html', 'css',
        'javascript', 'typescript', 'tsx',
      },
      auto_install = true,
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          -- Shift+Alt+Right / Left == VS Code's Expand/Shrink Selection
          init_selection = '<M-S-Right>',
          node_incremental = '<M-S-Right>',
          node_decremental = '<M-S-Left>',
          scope_incremental = false,
        },
      },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = 'nvim-treesitter/nvim-treesitter',
    opts = { max_lines = 3, multiline_threshold = 1, separator = nil },
  },
}
