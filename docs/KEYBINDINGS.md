# Keybindings

VS Code chords are mapped where a terminal can express them and where they do not
hide a core Vim key: <kbd>Ctrl</kbd>+<kbd>W</kbd>, <kbd>Ctrl</kbd>+<kbd>A</kbd>, <kbd>Ctrl</kbd>+<kbd>Z</kbd>, <kbd>Ctrl</kbd>+<kbd>Y</kbd>, <kbd>Ctrl</kbd>+<kbd>N</kbd>, <kbd>Ctrl</kbd>+<kbd>B</kbd>, <kbd>Ctrl</kbd>+<kbd>T</kbd>, `gi` and `gr` keep their Vim meaning. Every one also has a
`<leader>` equivalent (leader is <kbd>Space</kbd>) that works in any terminal.
Press <kbd>Space</kbd> in normal mode to browse them interactively.

## A terminal caveat you should read first

Terminals traditionally encode <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>
identically to <kbd>Ctrl</kbd>+<kbd>X</kbd>. Distinguishing them needs the
**kitty keyboard protocol**, supported by Kitty, Ghostty, WezTerm, and
Alacritty 0.13+. In a terminal without it, the <kbd>Ctrl</kbd>+<kbd>Shift</kbd>
bindings below silently do nothing (or trigger the plain <kbd>Ctrl</kbd> binding).

Check yours: `:lua print(vim.fn.has('nvim-0.10') == 1 and vim.o.term or '?')` and
press the chord in insert mode — if nothing is inserted and nothing happens, the
terminal is collapsing it. Use the `<leader>` equivalent instead.

<kbd>Ctrl</kbd>+<kbd>/</kbd> is the other common casualty; most terminals send
<kbd>Ctrl</kbd>+<kbd>_</kbd>, which is mapped alongside it.

## File

| Action | Key | Always-works alternative |
|---|---|---|
| Save | <kbd>Ctrl</kbd>+<kbd>S</kbd> | `:w` |
| New file | — | `:enew` |
| Close editor | — | `:bd` |
| Go to File | <kbd>Ctrl</kbd>+<kbd>P</kbd> | <kbd>Space</kbd> `ff` |
| Command Palette | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd> | <kbd>Space</kbd> `fc` |
| Recent files | — | <kbd>Space</kbd> `fr` |
| Open editors | — | <kbd>Space</kbd> `fb` |

There is no auto-save: a file is written when you save it. Saving formats the
file and sorts its imports, but does not apply ruff's fixes, so an import you have
just added is never removed before you use it. Apply a fix with
<kbd>Space</kbd> `ca` on the flagged line.

## Edit

| Action | Key |
|---|---|
| Undo / Redo | `u` / <kbd>Ctrl</kbd>+<kbd>R</kbd> |
| Select all | `ggVG` |
| Toggle line comment | <kbd>Ctrl</kbd>+<kbd>/</kbd> |
| Toggle block comment | <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>A</kbd> |
| Move line up / down | <kbd>Alt</kbd>+<kbd>↑</kbd> / <kbd>Alt</kbd>+<kbd>↓</kbd> |
| Duplicate line | <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>↓</kbd> |
| Indent / outdent selection | <kbd>Tab</kbd> / <kbd>Shift</kbd>+<kbd>Tab</kbd> (visual mode) |
| Expand / shrink selection | <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>→</kbd> / <kbd>←</kbd> |
| Format document | <kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>F</kbd> |
| Trigger suggestion | <kbd>Ctrl</kbd>+<kbd>Space</kbd> |

**Not mapped:** <kbd>Ctrl</kbd>+<kbd>D</kbd> multi-cursor. Neovim has no true
multi-cursor; the idiomatic equivalents are `:%s/old/new/gc` and the dot-repeat
workflow (`ciw` then `n.`). Add [multicursor.nvim](https://github.com/jake-stewart/multicursor.nvim)
if you want it.

## Navigation

| Action | Key |
|---|---|
| Go to Definition | <kbd>F12</kbd> or `gd` |
| Go to References | <kbd>Shift</kbd>+<kbd>F12</kbd> or `grr` |
| Go to Implementation | `gri` |
| Go to Type Definition | `gy` or `grt` |
| Go to Symbol (file) | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>O</kbd> or `gO` |
| Go to Symbol (workspace) | <kbd>Space</kbd> `fS` |
| Search across files | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F</kbd> |
| Next / previous editor | <kbd>Alt</kbd>+<kbd>→</kbd> / <kbd>Alt</kbd>+<kbd>←</kbd> |
| Go to editor *n* | <kbd>Alt</kbd>+<kbd>1</kbd>…<kbd>9</kbd> |
| Focus editor group | <kbd>Ctrl</kbd>+<kbd>H</kbd>/<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd> |
| Split editor right | <kbd>Ctrl</kbd>+<kbd>\\</kbd> |

## Language features

| Action | Key |
|---|---|
| Show hover | <kbd>K</kbd> |
| Signature help | <kbd>Ctrl</kbd>+<kbd>K</kbd> (insert mode) |
| Rename symbol | <kbd>F2</kbd> or `grn` |
| Quick fix / code action | <kbd>Ctrl</kbd>+<kbd>.</kbd> or <kbd>Space</kbd> `ca` |
| Next / previous problem | <kbd>F8</kbd> / <kbd>Shift</kbd>+<kbd>F8</kbd> |
| Problems panel | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> |
| Toggle inlay hints | <kbd>Space</kbd> `uh` |

## Panels

| Action | Key |
|---|---|
| Toggle Explorer | <kbd>Space</kbd> `e` |
| Focus Explorer / reveal file | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> |
| Integrated terminal | <kbd>Ctrl</kbd>+<kbd>`</kbd> |
| Source control | <kbd>Space</kbd> `ge` |
| Outline | <kbd>Space</kbd> `xs` |

Inside the Explorer: `a` add file, `A` add directory, `d` delete, `r` rename,
`c` copy, `x` cut, `p` paste, `H` toggle hidden files, `R` refresh.

## Debugging

| Action | Key |
|---|---|
| Start / continue | <kbd>F5</kbd> |
| Start, choosing a configuration | <kbd>Ctrl</kbd>+<kbd>F5</kbd> or <kbd>Space</kbd> `dS` |
| Stop | <kbd>Shift</kbd>+<kbd>F5</kbd> |
| Restart | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>F5</kbd> |
| Toggle breakpoint | <kbd>F9</kbd> |
| Conditional breakpoint | <kbd>Shift</kbd>+<kbd>F9</kbd> |
| Step over | <kbd>F10</kbd> |
| Step into | <kbd>F11</kbd> |
| Step out | <kbd>Shift</kbd>+<kbd>F11</kbd> |
| Toggle debug panel | <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> |
| Evaluate expression | <kbd>Space</kbd> `dw` |
| Debug REPL | <kbd>Space</kbd> `dr` |
| Debug nearest test | <kbd>Space</kbd> `dt` |

<kbd>F5</kbd> starts the first configuration (*Python: Current File*) without
prompting, as VS Code does. A `.vscode/launch.json` in the project is picked up
automatically.

## Git

| Action | Key |
|---|---|
| Next / previous change | `]c` / `[c` |
| Stage hunk | <kbd>Space</kbd> `hs` |
| Reset hunk | <kbd>Space</kbd> `hr` |
| Preview hunk | <kbd>Space</kbd> `hp` |
| Blame line | <kbd>Space</kbd> `hb` |
| Toggle inline blame | <kbd>Space</kbd> `ub` |
