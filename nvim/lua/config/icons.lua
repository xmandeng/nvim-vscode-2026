-- Nerd Font icons, defined by codepoint rather than as literal glyphs.
--
-- The glyphs live in the Unicode Private Use Area, where they are fragile:
-- copy/paste, shell heredocs and some editors silently drop them, leaving
-- empty strings that break options like `fillchars`. Building them with
-- nr2char() keeps this file pure ASCII and makes the codepoints greppable.
--
-- Codepoints are Nerd Fonts v3 codicons (nf-cod-*), matching VS Code's own
-- icon set. Requires a patched Nerd Font; see docs/INSTALL.md.

local function ch(cp) return vim.fn.nr2char(cp) end

return {
  diagnostics = {
    error = ch(0xEA87),   -- nf-cod-error
    warn  = ch(0xEA6C),   -- nf-cod-warning
    info  = ch(0xEA74),   -- nf-cod-info
    hint  = ch(0xEA61),   -- nf-cod-lightbulb
  },
  fold = {
    open   = ch(0xEAB4),  -- nf-cod-chevron_down
    closed = ch(0xEAB6),  -- nf-cod-chevron_right
  },
  explorer = {
    folder_closed = ch(0xEA83),  -- nf-cod-folder
    folder_open   = ch(0xEAF7),  -- nf-cod-folder_opened
    folder_empty  = ch(0xEA83),
    file          = ch(0xEA7B),  -- nf-cod-file
    expander_collapsed = ch(0xEAB6),
    expander_expanded  = ch(0xEAB4),
  },
  dap = {
    breakpoint           = ch(0xEA71),  -- nf-cod-circle_filled
    breakpoint_condition = ch(0xEA71),
    breakpoint_rejected  = ch(0xEABC),  -- nf-cod-circle_outline
    logpoint             = ch(0xEA71),
    stopped              = ch(0xEA9C),  -- nf-cod-arrow_right
    expanded             = ch(0xEAB4),
    collapsed            = ch(0xEAB6),
    current_frame        = ch(0xEA9C),
  },
  mason = {
    installed   = ch(0xEAB2),  -- nf-cod-check
    pending     = ch(0xEA71),
    uninstalled = ch(0xEA76),  -- nf-cod-close
  },
  ui = {
    search    = ch(0xEA6D),  -- nf-cod-search
    caret     = ch(0xEA9C),
    gear      = ch(0xEAF8),  -- nf-cod-gear
    git       = ch(0xE725),  -- nf-dev-git_branch
    separator = ch(0xEAB6),
  },
}
