# How the colour port works

The goal is that a Python buffer in Neovim shows the *same hex values* VS Code shows,
not a close approximation. Three things make that non-trivial.

## 1. The theme is an inheritance chain

`2026-dark.json` does not contain a full theme. It has an `include` pointing at
`dark_modern.json`, which includes `dark_plus.json`, which includes `dark_vs.json`.

```
dark_vs.json -> dark_plus.json -> dark_modern.json -> 2026-dark.json
```

`tools/resolve_theme.py` walks that chain and flattens it: `colors` maps are merged
child-over-parent, and `tokenColors` arrays are **concatenated** parent-first, which
matters for the next step. The flattened result is 329 UI colours and 118 token rules.

## 2. Dark 2026 is a hybrid, and naive matching gets it wrong

Dark 2026 layers a GitHub-Dark-style palette over the classic Dark+ base:

| scope | colour | comes from |
|---|---|---|
| `keyword` | `#FF7B72` | 2026 Dark |
| `keyword.control` | `#C586C0` | Dark+ (survives) |
| `entity.name.function` | `#D2A8FF` | 2026 Dark |
| `support.function` | `#DCDCAA` | Dark+ (survives) |
| `string` | `#A5D6FF` | 2026 Dark |
| `variable.other` | `#C9D1D9` | 2026 Dark |

The Dark+ colours show through wherever Dark+ has a **more specific** selector. So
`import` (`keyword.control.import`) is pink `#C586C0`, while `def` (`storage.type`)
is red `#FF7B72` — in the same file, from the same theme.

Resolving "last rule wins" would paint everything the GitHub palette. `gen_colorscheme.py`
implements TextMate's actual ranking, `(direct, specificity, order)`:

- **direct** — a descendant selector like `markup.heading entity.name` only applies
  inside a markdown heading. We resolve bare scopes with no ancestor stack, so
  descendant selectors rank below direct ones. Without this, `markup.heading entity.name`
  hijacks every `entity.name.*` token and decorators come out blue instead of orange.
- **specificity** — more dot-segments wins, so `keyword.control` beats `keyword`.
- **order** — later files in the include chain win genuine ties.

## 3. Semantic tokens, not just treesitter

VS Code colours Python primarily from Pylance's *semantic tokens*, not from the
grammar. Neovim has the same mechanism: an LSP server that supports
`textDocument/semanticTokens` drives `@lsp.type.*` highlight groups.

`SEMANTIC` in `gen_colorscheme.py` encodes VS Code's built-in semantic-token-type →
TextMate-scope defaults (`class` → `entity.name.type.class`, `parameter` →
`variable.parameter`, and so on), plus modifier transforms (`*.defaultLibrary` →
`support.*`, `variable.readonly` → `variable.other.constant`). Each one is then
resolved through the same scope engine.

Neovim appends the filetype, producing `@lsp.type.class.python`; that falls back to
`@lsp.type.class` through the standard `@a.b.c` → `@a.b` → `@a` hierarchy.

## Alpha

VS Code themes use 8-digit `#RRGGBBAA` colours — `editor.selectionBackground` is
`#276782dd`. Terminals have no alpha channel, and passing an 8-digit value to
`nvim_set_hl` raises *"Invalid highlight color"* and aborts the colourscheme
mid-load. Every such colour is composited over its actual backdrop at generation
time: `#276782dd` over `#121314` becomes `#245C73`.

A validator runs before emission and refuses to write anything that is not
`#RRGGBB`, so this class of bug cannot reach your editor.

## Regenerating

```bash
make theme      # re-read the VS Code theme JSON and rewrite generated.lua
make terminal   # rewrite the terminal emulator palettes
make check      # parse-check every Lua file
```

`make theme` reads the theme from the VS Code app bundle on the current machine.
Point it elsewhere with `make theme THEME=/path/to/some-theme.json` — the generator
is not specific to Dark 2026 and will port any VS Code theme, though the palette
names in `generated.lua` assume a dark one.
