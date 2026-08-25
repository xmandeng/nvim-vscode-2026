#!/usr/bin/env python3
"""
Generate a Neovim colorscheme from a resolved VS Code theme JSON.

Fidelity notes:
  * TextMate scopes are resolved with real specificity rules (most dot-segments
    wins; ties broken by document order) rather than naive last-wins, because
    Dark 2026 layers a GitHub-ish palette over Dark+ and relies on Dark+'s more
    specific selectors showing through.
  * LSP semantic tokens are mapped through VS Code's built-in
    semantic-token-type -> TextMate scope defaults, so @lsp.type.* groups get
    the same colour Pylance/basedpyright produce in VS Code.
  * 8-digit #RRGGBBAA colours are alpha-composited over their backdrop, since
    terminals have no alpha channel.
"""
import json, sys, os, re

# ---------------------------------------------------------------- colour utils
def parse(c):
    if not c: return None
    c = c.lstrip('#')
    if len(c) == 3: c = ''.join(ch*2 for ch in c)
    if len(c) == 4: c = ''.join(ch*2 for ch in c)
    if len(c) == 6: return (int(c[0:2],16), int(c[2:4],16), int(c[4:6],16), 255)
    if len(c) == 8: return (int(c[0:2],16), int(c[2:4],16), int(c[4:6],16), int(c[6:8],16))
    return None

def hexs(rgb):
    return '#%02X%02X%02X' % (rgb[0], rgb[1], rgb[2])

def blend(fg, bg):
    """Composite fg (may have alpha) over opaque bg."""
    f, b = parse(fg), parse(bg)
    if not f: return None
    if not b: return hexs(f)
    a = f[3] / 255.0
    return hexs(tuple(round(f[i]*a + b[i]*(1-a)) for i in range(3)))

def mix(c1, c2, t):
    a, b = parse(c1), parse(c2)
    return hexs(tuple(round(a[i]*(1-t) + b[i]*t) for i in range(3)))

# ------------------------------------------------------- TextMate scope engine
class Scopes:
    def __init__(self, token_colors):
        self.rules = []   # (selector, order, settings)
        for order, rule in enumerate(token_colors):
            sc = rule.get('scope', [])
            if isinstance(sc, str):
                sc = [s.strip() for s in sc.split(',') if s.strip()]
            st = rule.get('settings', {}) or {}
            for sel in sc:
                self.rules.append((sel.strip(), order, st))

    def match(self, scope):
        """Resolve one TextMate scope string -> settings dict.

        Ranking key is (direct, specificity, order):
          * direct selectors always outrank descendant ones. We resolve a bare
            scope with no ancestor stack, so `markup.heading entity.name` must
            not hijack a plain `entity.name` token the way naive matching does.
          * then most dot-segments wins (`keyword.control` beats `keyword`),
          * then document order, so later files in the include chain win ties.
        """
        best = None  # ((direct, specificity, order), settings)
        for sel, order, st in self.rules:
            if ' ' in sel:
                tail = sel.split()[-1]
                if not self._prefix(tail, scope):
                    continue
                key = (0, len(tail.split('.')), order)
            else:
                if not self._prefix(sel, scope):
                    continue
                key = (1, len(sel.split('.')), order)
            if best is None or key > best[0]:
                best = (key, st)
        return best[1] if best else {}

    @staticmethod
    def _prefix(sel, scope):
        if sel == scope: return True
        return scope.startswith(sel + '.')

    def style(self, *scopes):
        """First scope that resolves to a foreground wins; merge fontStyle."""
        for s in scopes:
            st = self.match(s)
            if st.get('foreground'):
                out = {'fg': st['foreground'].upper()}
                fs = st.get('fontStyle', '') or ''
                if 'bold' in fs: out['bold'] = True
                if 'italic' in fs: out['italic'] = True
                if 'underline' in fs: out['underline'] = True
                if 'strikethrough' in fs: out['strikethrough'] = True
                return out
        return {}

# ------------- VS Code default semantic-token-type -> TextMate scope fallbacks
SEMANTIC = {
    'namespace': ['entity.name.namespace', 'entity.name.type.namespace'],
    'type': ['entity.name.type'],
    'class': ['entity.name.type.class', 'entity.name.class'],
    'enum': ['entity.name.type.enum'],
    'interface': ['entity.name.type.interface'],
    'struct': ['entity.name.type.struct'],
    'typeParameter': ['entity.name.type.parameter'],
    'parameter': ['variable.parameter'],
    'variable': ['variable.other.readwrite', 'variable'],
    'property': ['variable.other.property', 'variable.other'],
    'enumMember': ['variable.other.enummember'],
    'decorator': ['entity.name.decorator', 'meta.decorator', 'entity.name.function'],
    'event': ['variable.other.event'],
    'function': ['entity.name.function'],
    'method': ['entity.name.function.member', 'entity.name.function'],
    'macro': ['entity.name.function.macro', 'entity.name.function'],
    'label': ['entity.name.label'],
    'comment': ['comment'],
    'string': ['string'],
    'keyword': ['keyword'],
    'number': ['constant.numeric'],
    'regexp': ['constant.regexp', 'string.regexp'],
    'operator': ['keyword.operator'],
    'modifier': ['storage.modifier'],
    'selfParameter': ['variable.language.self', 'variable.language'],
    'clsParameter': ['variable.language.cls', 'variable.language'],
    'builtinConstant': ['constant.language'],
    'magicFunction': ['support.function.magic', 'entity.name.function'],
}
# semantic modifier -> scope transform
SEM_MOD = {
    'defaultLibrary': {
        'function': ['support.function'], 'method': ['support.function'],
        'class': ['support.class', 'entity.name.type.class'],
        'type': ['support.type'], 'variable': ['support.variable'],
        'namespace': ['support.module', 'entity.name.namespace'],
    },
    'readonly': {
        'variable': ['variable.other.constant'],
        'property': ['variable.other.constant.property', 'variable.other.constant'],
    },
}

# ------------------------------------------------------------------- generator
def build(theme):
    C = theme['colors']
    S = Scopes(theme['tokenColors'])
    sem_override = {k: v.upper() for k, v in (theme.get('semanticTokenColors') or {}).items()
                    if isinstance(v, str)}

    def c(key, fallback=None, over=None):
        """UI colour by VS Code key, alpha-composited over `over` (or editor bg).

        The fallback goes through the same normalisation as a real theme value.
        Terminals have no alpha channel, so an 8-digit #RRGGBBAA that reaches
        nvim_set_hl raises "Invalid highlight color" and aborts the whole
        colorscheme -- fallbacks must be composited too, not passed through.
        """
        v = C.get(key)
        if v is None:
            v = fallback
        if v is None:
            return None
        p = parse(v)
        if p is None:
            return None
        if p[3] != 255:
            return blend(v, over or C.get('editor.background', '#121314'))
        return hexs(p)

    bg      = c('editor.background', '#121314')
    fg      = c('editor.foreground', '#BBBEBF')
    sidebg  = c('sideBar.background', bg)
    panelbg = c('editorWidget.background', bg)
    statbg  = c('statusBar.background', sidebg)

    # ---- named palette exposed to hand-written lua ----
    P = {
        'bg': bg, 'fg': fg,
        'bg_sidebar': sidebg,
        'bg_panel': panelbg,
        'bg_statusline': statbg,
        'bg_float': c('editorSuggestWidget.background', panelbg),
        'bg_tab_active': c('tab.activeBackground', bg),
        'bg_tab_inactive': c('tab.inactiveBackground', sidebg),
        'fg_tab_active': c('tab.activeForeground', fg),
        'fg_tab_inactive': c('tab.inactiveForeground', '#8C8C8C'),
        'border': c('editorWidget.border', c('panel.border', '#2B2B2B')),
        'cursor': c('editorCursor.foreground', fg),
        'cursorline': c('editor.lineHighlightBackground', bg),
        'selection': c('editor.selectionBackground', '#264F78'),
        'selection_inactive': c('editor.inactiveSelectionBackground', '#3A3D41'),
        'search': c('editor.findMatchHighlightBackground', '#3A5F7A'),
        'search_cur': c('editor.findMatchBackground', '#515C6A'),
        'linenr': c('editorLineNumber.foreground', '#858889'),
        'linenr_active': c('editorLineNumber.activeForeground', fg),
        'indent': c('editorIndentGuide.background1', c('editorIndentGuide.background', '#404040')),
        'indent_active': c('editorIndentGuide.activeBackground1', c('editorIndentGuide.activeBackground', '#707070')),
        'whitespace': c('editorWhitespace.foreground', '#3B3B3B'),
        'accent': c('focusBorder', '#0078D4'),
        'sel_list': c('list.activeSelectionBackground', '#04395E', over=sidebg),
        'sel_list_fg': c('list.activeSelectionForeground', fg),
        'hover_list': c('list.hoverBackground', '#2A2D2E', over=sidebg),
        'error': c('editorError.foreground', '#F14C4C'),
        'warn': c('editorWarning.foreground', '#CCA700'),
        'info': c('editorInfo.foreground', '#3794FF'),
        'hint': c('editorHint.foreground', '#B2B2B2'),
        'git_add': c('gitDecoration.addedResourceForeground', '#81B88B'),
        'git_change': c('gitDecoration.modifiedResourceForeground', '#E2C08D'),
        'git_delete': c('gitDecoration.deletedResourceForeground', '#C74E39'),
        'git_untracked': c('gitDecoration.untrackedResourceForeground', '#73C991'),
        'git_ignored': c('gitDecoration.ignoredResourceForeground', '#8C8C8C'),
        'bracket1': c('editorBracketHighlight.foreground1', '#FFD700'),
        'bracket2': c('editorBracketHighlight.foreground2', '#DA70D6'),
        'bracket3': c('editorBracketHighlight.foreground3', '#179FFF'),
        'match_bg': c('editorBracketMatch.background', '#0064001A'),
        'match_border': c('editorBracketMatch.border', '#888888'),
        'breadcrumb': c('breadcrumb.foreground', '#A9A9A9'),
        'breadcrumb_focus': c('breadcrumb.focusForeground', fg),
        'scrollbar': c('scrollbarSlider.background', '#79797966', over=bg),
        'word_hl': c('editor.wordHighlightBackground', '#575757B8', over=bg),
        'diff_add': c('diffEditor.insertedTextBackground', '#9CCC2C33', over=bg),
        'diff_del': c('diffEditor.removedTextBackground', '#FF000033', over=bg),
        'stat_debug': c('statusBar.debuggingBackground', '#CC6633'),
        'stat_debug_fg': c('statusBar.debuggingForeground', '#FFFFFF'),
        'dap_stop': c('editor.stackFrameHighlightBackground', '#FFFF0033', over=bg),
        'dap_bp': c('debugIcon.breakpointForeground', '#E51400'),
        'inlay_fg': c('editorInlayHint.foreground', '#969696'),
        'inlay_bg': c('editorInlayHint.background', bg),
        'menu_sel': c('menu.selectionBackground', '#0078D4'),
        'title_bg': c('titleBar.activeBackground', sidebg),
    }
    # terminal ANSI (VS Code omits these in 2026-dark -> derive from syntax palette)
    ansi_default = {
        'black': '#0C0C0C', 'red': '#FF7B72', 'green': '#7EE787', 'yellow': '#D7BA7D',
        'blue': '#79C0FF', 'magenta': '#D2A8FF', 'cyan': '#4EC9B0', 'white': '#BBBEBF',
        'bright_black': '#8B949E', 'bright_red': '#FFA198', 'bright_green': '#7EE787',
        'bright_yellow': '#D7BA7D', 'bright_blue': '#79C0FF', 'bright_magenta': '#D2A8FF',
        'bright_cyan': '#4EC9B0', 'bright_white': '#F0F6FC',
    }
    ansi = {}
    for name, dflt in ansi_default.items():
        key = 'terminal.ansi' + ''.join(w.capitalize() for w in name.split('_'))
        key = key[0].lower() + key[1:] if False else 'terminal.ansi' + \
              (name.replace('bright_', 'Bright').replace('_', '') if name.startswith('bright_')
               else name.capitalize())
        if name.startswith('bright_'):
            key = 'terminal.ansiBright' + name.split('_', 1)[1].capitalize()
        else:
            key = 'terminal.ansi' + name.capitalize()
        ansi[name] = c(key, dflt)
    P['ansi'] = ansi
    return P, S, sem_override, C

def highlights(P, S, sem_override, C):
    g = {}
    sc = S.style
    fg, bg = P['fg'], P['bg']

    def put(name, **kw):
        g[name] = {k: v for k, v in kw.items() if v is not None}
    def link(name, target):
        g[name] = {'link': target}
    def syn(name, *scopes, **extra):
        st = sc(*scopes)
        if not st and 'fg' not in extra:
            return
        st.update(extra)
        g[name] = st

    # ------------------------------------------------------------ editor chrome
    put('Normal', fg=fg, bg=bg)
    put('NormalNC', fg=fg, bg=bg)
    put('NormalFloat', fg=fg, bg=P['bg_float'])
    put('FloatBorder', fg=P['border'], bg=P['bg_float'])
    put('FloatTitle', fg=fg, bg=P['bg_float'], bold=True)
    put('ColorColumn', bg=P['cursorline'])
    put('Conceal', fg=P['linenr'])
    put('Cursor', fg=bg, bg=P['cursor'])
    put('lCursor', fg=bg, bg=P['cursor'])
    put('CursorIM', fg=bg, bg=P['cursor'])
    put('TermCursor', fg=bg, bg=P['cursor'])
    put('CursorLine', bg=P['cursorline'])
    put('CursorColumn', bg=P['cursorline'])
    put('CursorLineNr', fg=P['linenr_active'], bg=P['cursorline'], bold=True)
    put('LineNr', fg=P['linenr'])
    put('LineNrAbove', fg=P['linenr'])
    put('LineNrBelow', fg=P['linenr'])
    put('SignColumn', fg=P['linenr'], bg=bg)
    put('FoldColumn', fg=P['linenr'], bg=bg)
    put('Folded', fg=fg, bg=C.get('editor.foldBackground') and P['selection_inactive'] or P['cursorline'])
    put('EndOfBuffer', fg=bg)
    put('NonText', fg=P['whitespace'])
    put('Whitespace', fg=P['whitespace'])
    put('SpecialKey', fg=P['whitespace'])
    put('Directory', fg=P['ansi']['blue'])
    put('Title', fg=P['ansi']['blue'], bold=True)
    put('WinSeparator', fg=P['border'], bg=bg)
    link('VertSplit', 'WinSeparator')
    put('Visual', bg=P['selection'])
    put('VisualNOS', bg=P['selection_inactive'])
    put('Search', bg=P['search'], fg=fg)
    put('IncSearch', bg=P['search_cur'], fg=fg)
    put('CurSearch', bg=P['search_cur'], fg=fg)
    put('Substitute', bg=P['search_cur'], fg=fg)
    put('MatchParen', bg=P['match_bg'], fg=P['bracket1'], bold=True)
    put('QuickFixLine', bg=P['sel_list'])
    put('StatusLine', fg=fg, bg=P['bg_statusline'])
    put('StatusLineNC', fg=P['fg_tab_inactive'], bg=P['bg_statusline'])
    put('TabLine', fg=P['fg_tab_inactive'], bg=P['bg_tab_inactive'])
    put('TabLineFill', bg=P['bg_tab_inactive'])
    put('TabLineSel', fg=P['fg_tab_active'], bg=P['bg_tab_active'])
    put('WinBar', fg=P['breadcrumb'], bg=bg)
    put('WinBarNC', fg=P['breadcrumb'], bg=bg)
    put('Pmenu', fg=fg, bg=P['bg_float'])
    put('PmenuSel', fg=P['sel_list_fg'], bg=P['sel_list'], bold=True)
    put('PmenuKind', fg=P['ansi']['cyan'], bg=P['bg_float'])
    put('PmenuKindSel', fg=P['ansi']['cyan'], bg=P['sel_list'])
    put('PmenuExtra', fg=P['fg_tab_inactive'], bg=P['bg_float'])
    put('PmenuExtraSel', fg=P['fg_tab_inactive'], bg=P['sel_list'])
    put('PmenuSbar', bg=P['bg_panel'])
    put('PmenuThumb', bg=P['scrollbar'])
    put('WildMenu', fg=P['sel_list_fg'], bg=P['sel_list'])
    put('ErrorMsg', fg=P['error'])
    put('WarningMsg', fg=P['warn'])
    put('ModeMsg', fg=fg, bold=True)
    put('MoreMsg', fg=P['ansi']['blue'])
    put('Question', fg=P['ansi']['blue'])
    put('MsgArea', fg=fg)
    put('MsgSeparator', fg=P['border'])
    put('DiffAdd', bg=P['diff_add'])
    put('DiffChange', bg=P['diff_add'])
    put('DiffDelete', bg=P['diff_del'])
    put('DiffText', bg=P['selection'])
    link('diffAdded', 'DiffAdd'); link('diffRemoved', 'DiffDelete')

    # ------------------------------------------------------------ legacy syntax
    syn('Comment', 'comment', italic=True)
    syn('Constant', 'variable.other.constant', 'constant')
    syn('String', 'string')
    syn('Character', 'constant.character')
    syn('Number', 'constant.numeric')
    syn('Boolean', 'constant.language.boolean', 'constant.language')
    syn('Float', 'constant.numeric')
    syn('Identifier', 'variable.other.readwrite', 'variable')
    syn('Function', 'entity.name.function')
    syn('Statement', 'keyword')
    syn('Conditional', 'keyword.control.conditional', 'keyword.control')
    syn('Repeat', 'keyword.control.loop', 'keyword.control')
    syn('Label', 'entity.name.label')
    syn('Operator', 'keyword.operator')
    syn('Keyword', 'keyword')
    syn('Exception', 'keyword.control.exception', 'keyword.control')
    syn('PreProc', 'meta.preprocessor', 'keyword.control.directive')
    syn('Include', 'keyword.control.import', 'keyword.control')
    syn('Define', 'keyword.control.directive', 'keyword.control')
    syn('Macro', 'entity.name.function.preprocessor')
    syn('Type', 'entity.name.type', 'storage.type')
    syn('StorageClass', 'storage.modifier')
    syn('Structure', 'entity.name.type.struct', 'entity.name.type')
    syn('Typedef', 'entity.name.type')
    syn('Special', 'constant.character.escape')
    syn('SpecialChar', 'constant.character.escape')
    syn('Tag', 'entity.name.tag')
    put('Delimiter', fg=fg)
    syn('SpecialComment', 'comment.line.documentation', 'comment', italic=True)
    syn('Debug', 'invalid')
    put('Underlined', fg=P['ansi']['blue'], underline=True)
    put('Ignore', fg=P['linenr'])
    put('Error', fg=P['error'])
    put('Todo', fg=bg, bg=P['warn'], bold=True)
    put('Added', fg=P['git_add']); put('Changed', fg=P['git_change']); put('Removed', fg=P['git_delete'])

    # --------------------------------------------------------- treesitter (@..)
    TS = {
        '@comment': ['comment'],
        '@comment.documentation': ['comment.line.documentation', 'comment'],
        '@string': ['string'],
        '@string.documentation': ['string.quoted.docstring', 'string'],
        '@string.regexp': ['string.regexp'],
        '@string.escape': ['constant.character.escape'],
        '@string.special': ['constant.other.placeholder', 'string'],
        '@string.special.url': ['markup.underline.link', 'string.other.link'],
        '@character': ['constant.character'],
        '@character.special': ['constant.character.escape'],
        '@number': ['constant.numeric'],
        '@number.float': ['constant.numeric'],
        '@boolean': ['constant.language.boolean', 'constant.language'],
        '@float': ['constant.numeric'],
        '@function': ['entity.name.function'],
        '@function.call': ['entity.name.function'],
        '@function.builtin': ['support.function'],
        '@function.macro': ['entity.name.function.preprocessor', 'entity.name.function'],
        '@function.method': ['entity.name.function.member', 'entity.name.function'],
        '@function.method.call': ['entity.name.function.member', 'entity.name.function'],
        '@constructor': ['entity.name.type.class', 'entity.name.function'],
        '@parameter': ['variable.parameter'],
        '@variable.parameter': ['variable.parameter'],
        '@variable.parameter.builtin': ['variable.language'],
        '@keyword': ['keyword'],
        '@keyword.function': ['storage.type.function', 'storage.type'],
        '@keyword.operator': ['keyword.operator.wordlike', 'keyword.operator.expression', 'keyword'],
        '@keyword.return': ['keyword.control.flow', 'keyword.control'],
        '@keyword.conditional': ['keyword.control.conditional', 'keyword.control'],
        '@keyword.repeat': ['keyword.control.loop', 'keyword.control'],
        '@keyword.exception': ['keyword.control.exception', 'keyword.control'],
        '@keyword.import': ['keyword.control.import', 'keyword.control'],
        '@keyword.type': ['storage.type', 'keyword'],
        '@keyword.modifier': ['storage.modifier'],
        '@keyword.coroutine': ['keyword.control.flow', 'keyword.control'],
        '@keyword.directive': ['keyword.control.directive', 'meta.preprocessor'],
        '@conditional': ['keyword.control.conditional', 'keyword.control'],
        '@repeat': ['keyword.control.loop', 'keyword.control'],
        '@exception': ['keyword.control.exception', 'keyword.control'],
        '@include': ['keyword.control.import', 'keyword.control'],
        '@type': ['entity.name.type'],
        '@type.builtin': ['support.type', 'entity.name.type'],
        '@type.definition': ['entity.name.type'],
        '@type.qualifier': ['storage.modifier'],
        '@constant': ['variable.other.constant', 'constant'],
        '@constant.builtin': ['constant.language'],
        '@constant.macro': ['entity.name.function.preprocessor'],
        '@namespace': ['entity.name.namespace'],
        '@module': ['entity.name.namespace'],
        '@module.builtin': ['support.module', 'entity.name.namespace'],
        '@field': ['variable.other.property', 'variable.other'],
        '@property': ['variable.other.property', 'variable.other'],
        '@variable': ['variable.other.readwrite', 'variable.other'],
        '@variable.builtin': ['variable.language'],
        '@variable.member': ['variable.other.property', 'variable.other'],
        '@operator': ['keyword.operator'],
        '@attribute': ['entity.other.attribute-name', 'meta.decorator'],
        '@attribute.builtin': ['support.type', 'entity.other.attribute-name'],
        '@label': ['entity.name.label'],
        '@tag': ['entity.name.tag'],
        '@tag.attribute': ['entity.other.attribute-name'],
        '@tag.delimiter': ['punctuation.definition.tag'],
        '@markup.heading': ['markup.heading'],
        '@markup.link': ['markup.underline.link', 'string.other.link'],
        '@markup.raw': ['markup.inline.raw'],
        '@markup.list': ['punctuation.definition.list.begin.markdown', 'markup.list'],
        '@markup.quote': ['markup.quote'],
        '@diff.plus': ['markup.inserted'],
        '@diff.minus': ['markup.deleted'],
        '@diff.delta': ['markup.changed'],
    }
    for name, scopes in TS.items():
        syn(name, *scopes)
    put('@punctuation.delimiter', fg=fg)
    put('@punctuation.bracket', fg=fg)
    put('@punctuation.special', fg=P['ansi']['blue'])
    g['@markup.strong'] = {'bold': True}
    g['@markup.italic'] = {'italic': True}
    g['@markup.underline'] = {'underline': True}
    g['@markup.strikethrough'] = {'strikethrough': True}
    link('@text', 'Normal'); link('@none', 'Normal')
    # python specifics VS Code renders distinctly
    syn('@variable.builtin.python', 'variable.language.special.self.python', 'variable.language')
    syn('@string.documentation.python', 'string.quoted.docstring.multi.python', 'string')

    # ------------------------------------------------ LSP semantic token groups
    for typ, scopes in SEMANTIC.items():
        if typ in sem_override:
            put('@lsp.type.' + typ, fg=sem_override[typ].upper())
        else:
            syn('@lsp.type.' + typ, *scopes)
    for mod, table in SEM_MOD.items():
        for typ, scopes in table.items():
            syn('@lsp.typemod.%s.%s' % (typ, mod), *scopes)
    g['@lsp.mod.deprecated'] = {'strikethrough': True}
    g['@lsp.mod.readonly'] = {}
    # let treesitter win where LSP adds nothing useful
    for grp in ['@lsp.type.operator', '@lsp.type.keyword', '@lsp.type.comment',
                '@lsp.type.string', '@lsp.type.number']:
        g[grp] = {}

    # ------------------------------------------------------------- diagnostics
    put('DiagnosticError', fg=P['error']); put('DiagnosticWarn', fg=P['warn'])
    put('DiagnosticInfo', fg=P['info']);  put('DiagnosticHint', fg=P['hint'])
    put('DiagnosticOk', fg=P['git_add'])
    for lvl, col in [('Error', P['error']), ('Warn', P['warn']), ('Info', P['info']),
                     ('Hint', P['hint']), ('Ok', P['git_add'])]:
        put('DiagnosticVirtualText' + lvl, fg=col, bg=mix(bg, col, 0.10))
        put('DiagnosticUnderline' + lvl, undercurl=True, sp=col)
        put('DiagnosticSign' + lvl, fg=col, bg=bg)
        put('DiagnosticFloating' + lvl, fg=col, bg=P['bg_float'])
    put('DiagnosticUnnecessary', fg=P['linenr'])
    put('DiagnosticDeprecated', strikethrough=True, sp=P['warn'])
    put('LspReferenceText', bg=P['word_hl']); put('LspReferenceRead', bg=P['word_hl'])
    put('LspReferenceWrite', bg=P['word_hl'], underline=True)
    put('LspInlayHint', fg=P['inlay_fg'], bg=mix(bg, P['inlay_fg'], 0.08), italic=True)
    put('LspSignatureActiveParameter', fg=P['ansi']['blue'], bold=True)
    put('LspCodeLens', fg=P['linenr'], italic=True)
    put('LspInfoBorder', fg=P['border'])
    return g

def plugin_highlights(P, g):
    """Highlight groups for the plugin set, keyed off the same VS Code palette."""
    fg, bg = P['fg'], P['bg']
    side, float_bg = P['bg_sidebar'], P['bg_float']
    def put(n, **kw): g[n] = {k: v for k, v in kw.items() if v is not None}
    def link(n, t): g[n] = {'link': t}

    # ---- neo-tree (the Explorer sidebar) ----
    put('NeoTreeNormal', fg=C_SIDEBAR_FG(P), bg=side)
    put('NeoTreeNormalNC', fg=C_SIDEBAR_FG(P), bg=side)
    put('NeoTreeEndOfBuffer', fg=side, bg=side)
    put('NeoTreeWinSeparator', fg=P['border'], bg=side)
    put('NeoTreeVertSplit', fg=P['border'], bg=side)
    put('NeoTreeRootName', fg=fg, bold=True)
    put('NeoTreeDirectoryName', fg=C_SIDEBAR_FG(P))
    put('NeoTreeDirectoryIcon', fg=P['ansi']['blue'])
    put('NeoTreeFileName', fg=C_SIDEBAR_FG(P))
    put('NeoTreeFileNameOpened', fg=fg)
    put('NeoTreeIndentMarker', fg=P['indent'])
    put('NeoTreeExpander', fg=P['linenr'])
    put('NeoTreeCursorLine', bg=P['hover_list'])
    put('NeoTreeTitleBar', fg=fg, bg=side)
    put('NeoTreeFloatBorder', fg=P['border'], bg=float_bg)
    put('NeoTreeFloatTitle', fg=fg, bg=float_bg)
    put('NeoTreeGitAdded', fg=P['git_add'])
    put('NeoTreeGitModified', fg=P['git_change'])
    put('NeoTreeGitDeleted', fg=P['git_delete'])
    put('NeoTreeGitUntracked', fg=P['git_untracked'])
    put('NeoTreeGitIgnored', fg=P['git_ignored'])
    put('NeoTreeGitConflict', fg=P['error'])
    put('NeoTreeGitStaged', fg=P['git_add'])
    put('NeoTreeDimText', fg=P['linenr'])
    put('NeoTreeMessage', fg=P['linenr'], italic=True)
    put('NeoTreeTabActive', fg=fg, bg=side, bold=True)
    put('NeoTreeTabInactive', fg=P['fg_tab_inactive'], bg=P['bg_tab_inactive'])
    put('NeoTreeTabSeparatorActive', fg=side, bg=side)
    put('NeoTreeTabSeparatorInactive', fg=P['bg_tab_inactive'], bg=P['bg_tab_inactive'])

    # ---- telescope (Ctrl+P / Ctrl+Shift+P quick-open) ----
    put('TelescopeNormal', fg=fg, bg=float_bg)
    put('TelescopeBorder', fg=P['border'], bg=float_bg)
    put('TelescopeTitle', fg=fg, bg=float_bg, bold=True)
    put('TelescopePromptNormal', fg=fg, bg=P['bg_panel'])
    put('TelescopePromptBorder', fg=P['border'], bg=P['bg_panel'])
    put('TelescopePromptTitle', fg=bg, bg=P['accent'], bold=True)
    put('TelescopePromptPrefix', fg=P['accent'])
    put('TelescopePromptCounter', fg=P['linenr'])
    put('TelescopeResultsNormal', fg=fg, bg=float_bg)
    put('TelescopeResultsBorder', fg=P['border'], bg=float_bg)
    put('TelescopeResultsTitle', fg=float_bg, bg=float_bg)
    put('TelescopePreviewNormal', fg=fg, bg=float_bg)
    put('TelescopePreviewBorder', fg=P['border'], bg=float_bg)
    put('TelescopePreviewTitle', fg=bg, bg=P['git_add'], bold=True)
    put('TelescopeSelection', fg=P['sel_list_fg'], bg=P['sel_list'])
    put('TelescopeSelectionCaret', fg=P['accent'], bg=P['sel_list'])
    put('TelescopeMultiSelection', fg=P['ansi']['yellow'], bg=P['sel_list'])
    put('TelescopeMatching', fg=P['ansi']['blue'], bold=True)
    put('TelescopeResultsDiffAdd', fg=P['git_add'])
    put('TelescopeResultsDiffChange', fg=P['git_change'])
    put('TelescopeResultsDiffDelete', fg=P['git_delete'])

    # ---- bufferline (editor tabs) ----
    ta, ti = P['bg_tab_active'], P['bg_tab_inactive']
    put('BufferLineFill', bg=ti)
    put('BufferLineBackground', fg=P['fg_tab_inactive'], bg=ti)
    put('BufferLineBufferVisible', fg=P['fg_tab_inactive'], bg=ti)
    put('BufferLineBufferSelected', fg=P['fg_tab_active'], bg=ta, bold=True)
    put('BufferLineSeparator', fg=ti, bg=ti)
    put('BufferLineSeparatorVisible', fg=ti, bg=ti)
    put('BufferLineSeparatorSelected', fg=ti, bg=ta)
    put('BufferLineIndicatorSelected', fg=P['accent'], bg=ta)
    put('BufferLineIndicatorVisible', fg=ti, bg=ti)
    put('BufferLineModified', fg=P['git_change'], bg=ti)
    put('BufferLineModifiedVisible', fg=P['git_change'], bg=ti)
    put('BufferLineModifiedSelected', fg=P['git_change'], bg=ta)
    put('BufferLineCloseButton', fg=P['fg_tab_inactive'], bg=ti)
    put('BufferLineCloseButtonVisible', fg=P['fg_tab_inactive'], bg=ti)
    put('BufferLineCloseButtonSelected', fg=P['fg_tab_active'], bg=ta)
    put('BufferLineTabSeparator', fg=ti, bg=ti)
    put('BufferLineTabSeparatorSelected', fg=ti, bg=ta)
    put('BufferLineOffsetSeparator', fg=P['border'], bg=side)
    for lvl, col in [('Error', P['error']), ('Warning', P['warn']),
                     ('Info', P['info']), ('Hint', P['hint'])]:
        put('BufferLineDiagnostic' + lvl, fg=P['fg_tab_inactive'], bg=ti)
        put('BufferLine%sSelected' % lvl, fg=col, bg=ta, bold=True)
        put('BufferLine%sVisible' % lvl, fg=P['fg_tab_inactive'], bg=ti)
        put('BufferLine%sDiagnostic' % lvl, fg=col, bg=ti)
        put('BufferLine%sDiagnosticSelected' % lvl, fg=col, bg=ta, bold=True)
        put('BufferLine%sDiagnosticVisible' % lvl, fg=col, bg=ti)

    # ---- gitsigns (gutter) ----
    put('GitSignsAdd', fg=P['git_add'], bg=bg)
    put('GitSignsChange', fg=P['git_change'], bg=bg)
    put('GitSignsDelete', fg=P['git_delete'], bg=bg)
    put('GitSignsCurrentLineBlame', fg=P['linenr'], italic=True)
    put('GitSignsAddInline', bg=P['diff_add'])
    put('GitSignsDeleteInline', bg=P['diff_del'])

    # ---- indent-blankline ----
    put('IblIndent', fg=P['indent'])
    put('IblScope', fg=P['indent_active'])
    put('IblWhitespace', fg=P['whitespace'])

    # ---- nvim-dap / dap-ui (the Run & Debug panel) ----
    put('DapBreakpoint', fg=P['dap_bp'], bg=bg)
    put('DapBreakpointCondition', fg=P['dap_bp'], bg=bg)
    put('DapBreakpointRejected', fg=P['linenr'], bg=bg)
    put('DapLogPoint', fg=P['info'], bg=bg)
    put('DapStopped', fg=P['warn'], bg=bg)
    put('DapStoppedLine', bg=P['dap_stop'])
    put('DapUINormal', fg=fg, bg=side)
    put('DapUIVariable', fg=P['ansi']['cyan'])
    put('DapUIScope', fg=P['ansi']['blue'], bold=True)
    put('DapUIType', fg=P['ansi']['magenta'])
    put('DapUIValue', fg=fg)
    put('DapUIModifiedValue', fg=P['warn'], bold=True)
    put('DapUIDecoration', fg=P['border'])
    put('DapUIThread', fg=P['git_add'])
    put('DapUIStoppedThread', fg=P['warn'])
    put('DapUIFrameName', fg=fg)
    put('DapUISource', fg=P['ansi']['yellow'])
    put('DapUILineNumber', fg=P['linenr'])
    put('DapUIFloatBorder', fg=P['border'], bg=float_bg)
    put('DapUIWatchesEmpty', fg=P['linenr'])
    put('DapUIWatchesValue', fg=P['git_add'])
    put('DapUIWatchesError', fg=P['error'])
    put('DapUIBreakpointsPath', fg=P['ansi']['blue'])
    put('DapUIBreakpointsInfo', fg=P['git_add'])
    put('DapUIBreakpointsCurrentLine', fg=P['warn'], bold=True)
    put('DapUIBreakpointsLine', fg=P['linenr'])
    put('DapUIBreakpointsDisabledLine', fg=P['linenr'])
    put('DapUIStepOver', fg=P['accent']); put('DapUIStepInto', fg=P['accent'])
    put('DapUIStepBack', fg=P['accent']); put('DapUIStepOut', fg=P['accent'])
    put('DapUIStop', fg=P['error']); put('DapUIPlayPause', fg=P['git_add'])
    put('DapUIRestart', fg=P['git_add']); put('DapUIUnavailable', fg=P['linenr'])
    put('DapUIPlayPauseNC', fg=P['git_add'], bg=side)
    put('DapUIRestartNC', fg=P['git_add'], bg=side)
    put('DapUIStopNC', fg=P['error'], bg=side)
    put('DapUIWinSelect', fg=P['accent'], bold=True)

    # ---- blink.cmp / nvim-cmp (IntelliSense) ----
    put('BlinkCmpMenu', fg=fg, bg=float_bg)
    put('BlinkCmpMenuBorder', fg=P['border'], bg=float_bg)
    put('BlinkCmpMenuSelection', fg=P['sel_list_fg'], bg=P['sel_list'])
    put('BlinkCmpLabel', fg=fg)
    put('BlinkCmpLabelMatch', fg=P['ansi']['blue'], bold=True)
    put('BlinkCmpLabelDeprecated', fg=P['linenr'], strikethrough=True)
    put('BlinkCmpLabelDetail', fg=P['linenr'])
    put('BlinkCmpLabelDescription', fg=P['linenr'])
    put('BlinkCmpDoc', fg=fg, bg=float_bg)
    put('BlinkCmpDocBorder', fg=P['border'], bg=float_bg)
    put('BlinkCmpSignatureHelp', fg=fg, bg=float_bg)
    put('BlinkCmpSignatureHelpBorder', fg=P['border'], bg=float_bg)
    put('BlinkCmpSignatureHelpActiveParameter', fg=P['ansi']['blue'], bold=True)
    put('BlinkCmpGhostText', fg=P['linenr'], italic=True)
    kind_colors = {
        'Text': fg, 'Method': P['ansi']['magenta'], 'Function': P['ansi']['magenta'],
        'Constructor': P['ansi']['magenta'], 'Field': P['ansi']['blue'],
        'Variable': P['ansi']['blue'], 'Class': P['ansi']['cyan'],
        'Interface': P['ansi']['cyan'], 'Module': P['ansi']['cyan'],
        'Property': P['ansi']['blue'], 'Unit': P['ansi']['cyan'],
        'Value': P['ansi']['green'], 'Enum': P['ansi']['cyan'],
        'Keyword': P['ansi']['red'], 'Snippet': P['ansi']['yellow'],
        'Color': P['ansi']['green'], 'File': fg, 'Reference': P['ansi']['blue'],
        'Folder': fg, 'EnumMember': P['ansi']['blue'], 'Constant': P['ansi']['blue'],
        'Struct': P['ansi']['cyan'], 'Event': P['ansi']['yellow'],
        'Operator': fg, 'TypeParameter': P['ansi']['cyan'],
    }
    for k, col in kind_colors.items():
        put('BlinkCmpKind' + k, fg=col)
        put('CmpItemKind' + k, fg=col)
    put('CmpItemAbbr', fg=fg)
    put('CmpItemAbbrMatch', fg=P['ansi']['blue'], bold=True)
    put('CmpItemAbbrDeprecated', fg=P['linenr'], strikethrough=True)
    put('CmpItemMenu', fg=P['linenr'])

    # ---- which-key, trouble, notify, noice, misc ----
    put('WhichKey', fg=P['ansi']['magenta'])
    put('WhichKeyGroup', fg=P['ansi']['blue'])
    put('WhichKeyDesc', fg=fg)
    put('WhichKeySeparator', fg=P['linenr'])
    put('WhichKeyFloat', bg=float_bg)
    put('WhichKeyBorder', fg=P['border'], bg=float_bg)
    put('WhichKeyValue', fg=P['linenr'])
    put('TroubleNormal', fg=fg, bg=side)
    put('TroubleText', fg=fg)
    put('TroubleCount', fg=P['ansi']['magenta'], bg=P['sel_list'])
    put('TroubleFile', fg=P['ansi']['blue'])
    put('TroubleSource', fg=P['linenr'])
    for lvl, col in [('ERROR', P['error']), ('WARN', P['warn']), ('INFO', P['info']),
                     ('DEBUG', P['linenr']), ('TRACE', P['ansi']['magenta'])]:
        put('Notify%sBorder' % lvl, fg=col)
        put('Notify%sIcon' % lvl, fg=col)
        put('Notify%sTitle' % lvl, fg=col, bold=True)
        put('Notify%sBody' % lvl, fg=fg, bg=float_bg)
    put('NoiceCmdlinePopup', fg=fg, bg=float_bg)
    put('NoiceCmdlinePopupBorder', fg=P['border'], bg=float_bg)
    put('NoiceCmdlineIcon', fg=P['accent'])
    put('NoiceConfirmBorder', fg=P['border'], bg=float_bg)
    put('FlashLabel', fg=bg, bg=P['ansi']['magenta'], bold=True)
    put('MiniIndentscopeSymbol', fg=P['indent_active'])
    put('RainbowDelimiterYellow', fg=P['bracket1'])
    put('RainbowDelimiterViolet', fg=P['bracket2'])
    put('RainbowDelimiterBlue', fg=P['bracket3'])
    return g

def C_SIDEBAR_FG(P):
    return P.get('_sidebar_fg') or P['fg']

# ------------------------------------------------------------------ lua output
def lua_value(v, indent=2):
    pad = ' ' * indent
    if isinstance(v, dict):
        if not v: return '{}'
        items = ', '.join('%s = %s' % (k, lua_value(x, indent)) for k, x in sorted(v.items()))
        return '{ %s }' % items
    if isinstance(v, bool): return 'true' if v else 'false'
    if isinstance(v, str): return '"%s"' % v
    return str(v)

HEX_RE = re.compile(r'^#[0-9A-F]{6}$')

def validate(P, groups):
    """Fail at generation time rather than shipping a colourscheme that
    aborts halfway through nvim_set_hl and leaves Normal unset."""
    bad = []
    for k, v in P.items():
        if k == 'ansi':
            for ak, av in v.items():
                if not HEX_RE.match(av or ''):
                    bad.append('palette.ansi.%s = %r' % (ak, av))
        elif not k.startswith('_') and not HEX_RE.match(v or ''):
            bad.append('palette.%s = %r' % (k, v))
    for name, spec in groups.items():
        for key in ('fg', 'bg', 'sp'):
            val = spec.get(key)
            if val is not None and val != 'NONE' and not HEX_RE.match(val):
                bad.append('%s.%s = %r' % (name, key, val))
    if bad:
        raise SystemExit('invalid colours (must be #RRGGBB):\n  ' + '\n  '.join(bad))
    return True

def emit(P, groups, meta):
    L = []
    L.append('-- AUTO-GENERATED by tools/gen_colorscheme.py -- DO NOT EDIT BY HAND.')
    L.append('-- Source: %s (VS Code %s)' % (meta['theme'], meta['vscode']))
    L.append('-- Include chain: %s' % meta['chain'])
    L.append('-- Regenerate:  make theme')
    L.append('')
    L.append('local M = {}')
    L.append('')
    L.append('---VS Code palette, extracted verbatim from the theme JSON.')
    L.append('M.palette = {')
    for k in sorted(P):
        if k.startswith('_'): continue
        if k == 'ansi': continue
        L.append('  %s = "%s",' % (k, P[k]))
    L.append('  ansi = {')
    for k in ['black','red','green','yellow','blue','magenta','cyan','white',
              'bright_black','bright_red','bright_green','bright_yellow',
              'bright_blue','bright_magenta','bright_cyan','bright_white']:
        L.append('    %s = "%s",' % (k, P['ansi'][k]))
    L.append('  },')
    L.append('}')
    L.append('')
    L.append('---Highlight groups, resolved through TextMate scope specificity.')
    L.append('M.groups = {')
    for name in sorted(groups):
        spec = groups[name]
        key = name if re.match(r'^[A-Za-z_]\w*$', name) else '["%s"]' % name
        L.append('  %s = %s,' % (key, lua_value(spec)))
    L.append('}')
    L.append('')
    L.append('return M')
    return '\n'.join(L) + '\n'

def main():
    src = sys.argv[1]
    out = sys.argv[2]
    vscode_ver = sys.argv[3] if len(sys.argv) > 3 else 'unknown'
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    from resolve_theme import resolve
    theme, chain = resolve(src)
    P, S, sem, C = build(theme)
    P['_sidebar_fg'] = C.get('sideBar.foreground', P['fg']).upper() if C.get('sideBar.foreground') else P['fg']
    g = highlights(P, S, sem, C)
    g = plugin_highlights(P, g)
    validate(P, g)
    meta = {'theme': theme.get('name', '?'), 'vscode': vscode_ver, 'chain': ' -> '.join(chain)}
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, 'w').write(emit(P, g, meta))
    print('wrote %s  (%d palette entries, %d highlight groups)' % (out, len(P) - 1, len(g)))

if __name__ == '__main__':
    main()
