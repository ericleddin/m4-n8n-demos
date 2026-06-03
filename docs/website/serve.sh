#!/usr/bin/env bash
set -euo pipefail

PORT=1313
SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$SITE_DIR/hugo_http.log"

# ── Farben ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ── Hilfsfunktionen ───────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}▸ $*${RESET}"; }
success() { echo -e "${GREEN}✓ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✗ $*${RESET}" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

port_in_use() { lsof -ti tcp:"$PORT" &>/dev/null; }

kill_server() {
    local pids
    pids=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        info "Beende Server (PID $pids) auf Port $PORT …"
        kill "$pids" 2>/dev/null
        sleep 1
        success "Server beendet."
    fi
}

open_browser() {
    if command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:$PORT" &>/dev/null &
    elif command -v open &>/dev/null; then
        open "http://localhost:$PORT" &
    fi
}

do_build() {
    info "Baue Site (hugo --minify) …"
    echo ""
    if hugo --minify; then
        echo ""
        success "Build abgeschlossen → public/"
    else
        echo ""
        error "Hugo-Build fehlgeschlagen."; exit 1
    fi
}

do_dev_server() {
    header "Dev-Server"
    info "Starte hugo server im Hintergrund …"
    hugo server --bind 0.0.0.0 --port "$PORT" >"$LOG" 2>&1 &
    local pid=$!
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        success "Server gestartet  •  PID $pid  •  http://localhost:$PORT"
        info "Log: $LOG  (tail -f hugo_http.log)"
        echo -e "${YELLOW}Beenden mit Ctrl+C${RESET}\n"
        open_browser
        tail -f "$LOG" & wait "$pid"
    else
        error "Server konnte nicht gestartet werden. Siehe $LOG"; exit 1
    fi
}

do_build_serve() {
    header "Build & Serve"
    do_build
    if ! command -v python3 &>/dev/null; then
        error "python3 nicht gefunden — kann public/ nicht servieren."
        info "Öffne public/index.html manuell im Browser."
        exit 1
    fi
    info "Starte python3 HTTP-Server im Hintergrund …"
    python3 -m http.server "$PORT" --directory public >"$LOG" 2>&1 &
    local pid=$!
    sleep 1
    if kill -0 "$pid" 2>/dev/null; then
        success "Server gestartet  •  PID $pid  •  http://localhost:$PORT"
        info "Log: $LOG  (tail -f hugo_http.log)"
        echo -e "${YELLOW}Beenden mit Ctrl+C${RESET}\n"
        open_browser
        tail -f "$LOG" & wait "$pid"
    else
        error "Server konnte nicht gestartet werden. Siehe $LOG"; exit 1
    fi
}

# ── Help ──────────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo -e "${BOLD}Verwendung:${RESET} ./serve.sh [OPTION]"
    echo ""
    echo "Interaktives Start-Script für die M4-Docs Hugo-Site."
    echo ""
    echo -e "${BOLD}Optionen:${RESET}"
    echo "  -h, --help    Diese Hilfe anzeigen"
    echo ""
    echo -e "${BOLD}Modi — kein Server läuft:${RESET}"
    echo "  [1] Dev-Server starten   hugo server mit Live-Reload auf http://localhost:$PORT"
    echo "                           Änderungen in den Docs werden sofort sichtbar."
    echo "  [2] Build & Serve        hugo --minify → public/, dann python3 HTTP-Server."
    echo "                           Simuliert statischen Produktions-Output."
    echo ""
    echo -e "${BOLD}Modi — Server läuft bereits:${RESET}"
    echo "  [1] Restart              Stop + hugo server neu starten (kein Rebuild)"
    echo "  [2] Rebuild & Restart    Stop + hugo --minify + python3 neu starten"
    echo "  [s] Stop                 Nur beenden, nicht neu starten"
    echo "  [o] Browser öffnen       Bestehenden Server weiter nutzen"
    echo "  [q] Abbrechen"
    echo ""
    echo "In beiden Fällen wird nach dem Start PID und URL angezeigt."
    echo ""
    echo -e "${BOLD}Voraussetzungen:${RESET}"
    echo "  hugo    (getestet mit v0.162+)"
    echo "  python3 (nur für Build & Serve)"
    echo "  lsof    (für Port-Erkennung)"
    exit 0
fi

cd "$SITE_DIR"

# ── Server läuft bereits ──────────────────────────────────────────────────────
if port_in_use; then
    warn "Port $PORT ist bereits belegt — ein Server läuft schon."
    info "Laufender Prozess: $(lsof -ti tcp:$PORT | tr '\n' ' '| sed 's/ $//')"
    echo ""
    echo "  [1] Restart              Stop + hugo server neu starten (kein Rebuild)"
    echo "  [2] Rebuild & Restart    Stop + hugo --minify + python3 neu starten"
    echo "  [s] Stop                 Nur beenden"
    echo "  [o] Browser öffnen       Bestehenden Server weiter nutzen"
    echo "  [q] Abbrechen"
    echo ""
    read -rp "Auswahl: " choice
    case "$choice" in
        1) kill_server; do_dev_server ;;
        2) kill_server; do_build_serve ;;
        s|S) kill_server ;;
        o|O) open_browser ;;
        *) info "Abgebrochen." ;;
    esac
    exit 0
fi

# ── Hauptmenü ─────────────────────────────────────────────────────────────────
header "Hugo – M4 Docs"
echo ""
echo "  [1] Dev-Server starten   hugo server — Live-Reload, kein Build nötig"
echo "  [2] Build & Serve        hugo --minify → statischen Output lokal servieren"
echo "  [q] Abbrechen"
echo ""
read -rp "Auswahl: " mode

case "$mode" in
    1) do_dev_server ;;
    2) do_build_serve ;;
    *) info "Abgebrochen." ;;
esac
