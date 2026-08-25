#!/usr/bin/env python3
"""Resolve a VS Code theme JSON through its `include` chain into one flat theme."""
import json, os, sys, re

def strip_jsonc(s):
    # remove // and /* */ comments and trailing commas
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    s = re.sub(r'(?<![:"\w])//[^\n]*', '', s)
    s = re.sub(r',(\s*[}\]])', r'\1', s)
    return s

def load(path):
    return json.loads(strip_jsonc(open(path, encoding='utf-8-sig').read()))

def resolve(path, _seen=None):
    _seen = _seen or []
    d = load(path)
    chain = [os.path.basename(path)]
    if 'include' in d:
        parent, pchain = resolve(os.path.join(os.path.dirname(path), d['include']), _seen)
        chain = pchain + chain
        colors = dict(parent.get('colors', {})); colors.update(d.get('colors', {}))
        tokens = parent.get('tokenColors', []) + d.get('tokenColors', [])
        sem = dict(parent.get('semanticTokenColors', {})); sem.update(d.get('semanticTokenColors', {}))
        d = {**parent, **d, 'colors': colors, 'tokenColors': tokens, 'semanticTokenColors': sem}
    return d, chain

if __name__ == '__main__':
    src = sys.argv[1]
    theme, chain = resolve(src)
    theme['_chain'] = chain
    out = sys.argv[2] if len(sys.argv) > 2 else None
    if out:
        json.dump(theme, open(out, 'w'), indent=2)
        print(f"wrote {out}")
    print("chain:", " -> ".join(chain))
    print("colors:", len(theme['colors']), "tokenColors:", len(theme['tokenColors']),
          "semantic:", len(theme.get('semanticTokenColors', {})))
