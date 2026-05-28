#!/usr/bin/env bash
set -euo pipefail

SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SITE_DIR/themes/hugo-theme-relearn"
THEME_REPO="https://github.com/McShelby/hugo-theme-relearn.git"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { echo -e "${CYAN}▸ $*${RESET}"; }
success() { echo -e "${GREEN}✓ $*${RESET}"; }

echo -e "${BOLD}Setup – M4 Docs${RESET}"
echo ""

# ── Hugo prüfen ───────────────────────────────────────────────────────────────
if ! command -v hugo &>/dev/null; then
    echo "✗ hugo nicht gefunden. Installation: https://gohugo.io/installation/" >&2
    exit 1
fi
success "hugo $(hugo version | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+')"

# ── Theme klonen wenn nicht vorhanden ─────────────────────────────────────────
if [ -f "$THEME_DIR/theme.toml" ]; then
    success "Theme bereits vorhanden ($THEME_DIR)"
else
    info "Klone hugo-theme-relearn …"
    rm -rf "$THEME_DIR"
    git clone --depth 1 "$THEME_REPO" "$THEME_DIR"
    rm -rf "$THEME_DIR/.git"
    success "Theme geklont → themes/hugo-theme-relearn"
fi

echo ""
success "Setup abgeschlossen. Starten mit: ./serve.sh"
