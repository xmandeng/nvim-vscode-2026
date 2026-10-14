#!/usr/bin/env bash
# Install the VS Code Dark 2026 Neovim configuration on any host.
#
#   ./bootstrap.sh                     install to ~/.config/nvim (backs up any existing config)
#   ./bootstrap.sh --appname nvim-vsc  install side-by-side; launch with NVIM_APPNAME=nvim-vsc nvim
#   ./bootstrap.sh --copy              copy files instead of symlinking
#   ./bootstrap.sh --no-deps           skip plugin/LSP installation
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPNAME="nvim"
LINK_MODE="symlink"
INSTALL_DEPS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --appname) APPNAME="$2"; shift 2 ;;
    --copy)    LINK_MODE="copy"; shift ;;
    --no-deps) INSTALL_DEPS=0; shift ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET="$CONFIG_HOME/$APPNAME"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }

# ── prerequisites ───────────────────────────────────────────────────────────
command -v nvim >/dev/null || die "Neovim is not installed or not on PATH."
command -v git  >/dev/null || die "git is required."

NVIM_VER="$(nvim --version | head -1 | sed -E 's/^NVIM v([0-9.]+).*/\1/')"
NVIM_MAJOR="${NVIM_VER%%.*}"
NVIM_MINOR="$(echo "$NVIM_VER" | cut -d. -f2)"
if (( NVIM_MAJOR == 0 && NVIM_MINOR < 10 )); then
  die "Neovim $NVIM_VER found; this config needs 0.10 or newer (0.11+ recommended)."
fi
info "Neovim $NVIM_VER"

for tool in cc make; do
  command -v "$tool" >/dev/null || warn "$tool not found -- treesitter parsers and telescope-fzf-native may fail to build."
done
command -v python3 >/dev/null || warn "python3 not found -- the Python LSP and debugger need it."
command -v node    >/dev/null || warn "node not found -- basedpyright requires Node.js."
command -v rg      >/dev/null || warn "ripgrep (rg) not found -- Ctrl+Shift+F search will be slow or unavailable."

# ── back up an existing config ──────────────────────────────────────────────
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  if [[ -L "$TARGET" && "$(readlink "$TARGET")" == "$REPO_DIR/nvim" ]]; then
    info "$TARGET already points at this repo."
  else
    BACKUP="$TARGET.backup.$(date +%Y%m%d%H%M%S)"
    info "Backing up existing config to $BACKUP"
    mv "$TARGET" "$BACKUP"
  fi
fi

# state directories are per-appname, so a side-by-side install stays isolated
for d in "${XDG_DATA_HOME:-$HOME/.local/share}/$APPNAME" \
         "${XDG_STATE_HOME:-$HOME/.local/state}/$APPNAME" \
         "${XDG_CACHE_HOME:-$HOME/.cache}/$APPNAME"; do
  if [[ -e "$d" && "$APPNAME" != "nvim" ]]; then
    warn "existing state at $d (left in place)"
  fi
done

# ── install ─────────────────────────────────────────────────────────────────
mkdir -p "$CONFIG_HOME"
if [[ ! -e "$TARGET" ]]; then
  if [[ "$LINK_MODE" == "symlink" ]]; then
    ln -s "$REPO_DIR/nvim" "$TARGET"
    info "Linked $TARGET -> $REPO_DIR/nvim"
  else
    cp -R "$REPO_DIR/nvim" "$TARGET"
    info "Copied config to $TARGET"
  fi
fi

# ── plugins, parsers, language servers ──────────────────────────────────────
FAILED=0
if (( INSTALL_DEPS )); then
  # Plugins go to the commits in lazy-lock.json, never to the latest. The first
  # start clones lazy.nvim from its stable branch and records that commit in the
  # lock, so the lock is put back before `restore` pins every plugin to it.
  LOCK="$TARGET/lazy-lock.json"
  LOCK_COPY="$(mktemp)"
  cp "$LOCK" "$LOCK_COPY"
  info "Installing plugins at the versions in lazy-lock.json (a minute on first run)..."
  NVIM_APPNAME="$APPNAME" nvim --headless +qa 2>&1 | tail -3 || true
  cp "$LOCK_COPY" "$LOCK"
  NVIM_APPNAME="$APPNAME" nvim --headless "+Lazy! restore" +qa 2>&1 | tail -3 || true
  if ! cmp -s "$LOCK" "$LOCK_COPY"; then
    warn "lazy-lock.json changed during install; some plugins are not at the locked commit."
    FAILED=1
  fi
  rm -f "$LOCK_COPY"

  info "Installing language servers and the debugger..."
  if ! NVIM_APPNAME="$APPNAME" nvim --headless -c "luafile $REPO_DIR/tools/install_servers.lua"; then
    warn "language server install failed -- run :Mason to see why."
    FAILED=1
  fi

  info "Compiling treesitter parsers..."
  NVIM_APPNAME="$APPNAME" nvim --headless \
    -c 'lua require("lazy").load({plugins={"nvim-treesitter"}})' \
    -c 'TSUpdateSync python lua vim vimdoc query bash json yaml toml markdown markdown_inline regex diff' \
    +qa 2>&1 | tail -2 || true
fi

# ── done ────────────────────────────────────────────────────────────────────
if (( FAILED )); then
  warn "Installation finished with errors; see the warnings above."
else
  info "Installation complete."
fi
cat <<EOF

  Launch:        $([[ "$APPNAME" == "nvim" ]] && echo "nvim" || echo "NVIM_APPNAME=$APPNAME nvim")
  Health check:  :checkhealth
  Keybindings:   docs/KEYBINDINGS.md  (or press <Space> in normal mode)

  For matching terminal colours, see terminal/ in this repo.
  A Nerd Font is required for icons: https://www.nerdfonts.com

EOF

(( FAILED == 0 ))
