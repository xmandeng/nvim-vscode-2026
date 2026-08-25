# Regenerate the colourscheme from the VS Code theme JSON that is installed
# on this machine, so a VS Code update can be picked up in one command.

VSCODE_APP ?= /Applications/Visual Studio Code.app
THEMES     := $(VSCODE_APP)/Contents/Resources/app/extensions/theme-defaults/themes
THEME      ?= $(THEMES)/2026-dark.json
OUT        := nvim/lua/vscode2026/generated.lua
VSCODE_VER := $(shell defaults read "$(VSCODE_APP)/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo unknown)

.PHONY: theme terminal all check clean

all: theme terminal

## regenerate the Neovim colourscheme from the VS Code theme
theme:
	python3 tools/gen_colorscheme.py "$(THEME)" "$(OUT)" "$(VSCODE_VER)"

## regenerate terminal emulator palettes from the colourscheme
terminal:
	python3 tools/gen_terminal.py "$(OUT)" terminal

## parse-check every lua file
check:
	nvim -l tools/check.lua

clean:
	rm -f tools/*.resolved.json
