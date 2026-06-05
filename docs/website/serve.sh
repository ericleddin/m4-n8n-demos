#!/usr/bin/env bash

PORT=1313
SITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SITE_DIR/.hugo.pid"

# ── Farben ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}▸ $*${RESET}"; }
success() { echo -e "${GREEN}✓ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠ $*${RESET}"; }
error()   { echo -e "${RED}✗ $*${RESET}" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ── Prozess-Erkennung ─────────────────────────────────────────────────────────
# Primär: PID-File. Fallback: Port-Scan.
server_pid() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "$pid"
            return 0
        fi
        rm -f "$PID_FILE"   # veraltetes PID-File entfernen
    fi
    # Fallback: Port belegt?
    lsof -ti tcp:"$PORT" 2>/dev/null | head -1
}

server_running() {
    [[ -n "$(server_pid)" ]]
}

show_status() {
    local pid
    pid=$(server_pid)
    if [[ -n "$pid" ]]; then
        echo -e "  Status: ${GREEN}läuft${RESET}  •  PID $pid  •  http://localhost:$PORT"
    else
        echo -e "  Status: ${RED}gestoppt${RESET}"
    fi
}

# ── Stop ──────────────────────────────────────────────────────────────────────
do_stop() {
    local pid
    pid=$(server_pid)
    if [[ -z "$pid" ]]; then
        warn "Kein laufender Server gefunden."
        return 0
    fi
    info "Beende Server (PID $pid) …"
    kill "$pid" 2>/dev/null || true
    local i=0
    while kill -0 "$pid" 2>/dev/null && [[ $i -lt 30 ]]; do
        sleep 0.1
        (( i++ )) || true
    done
    # Notfalls SIGKILL
    if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
    success "Server beendet."
}

# ── Dev-Server ────────────────────────────────────────────────────────────────
do_dev() {
    header "Dev-Server"
    if server_running; then
        warn "Server läuft bereits (PID $(server_pid))."
        read -rp "Neu starten? [j/N] " yn
        [[ "$yn" =~ ^[jJyY]$ ]] || { info "Abgebrochen."; return; }
        do_stop
    fi

    cd "$SITE_DIR"
    info "Starte hugo server auf Port $PORT …"
    echo ""

    # Sauberes Cleanup bei Ctrl+C / SIGTERM
    trap 'echo ""; info "Stopping …"; kill "$hugo_pid" 2>/dev/null; rm -f "$PID_FILE"; exit 0' INT TERM

    hugo server --bind 0.0.0.0 --port "$PORT" &
    hugo_pid=$!
    echo "$hugo_pid" > "$PID_FILE"

    sleep 1
    if ! kill -0 "$hugo_pid" 2>/dev/null; then
        rm -f "$PID_FILE"
        error "Server konnte nicht gestartet werden."
        trap - INT TERM
        exit 1
    fi

    success "Server läuft  •  PID $hugo_pid  •  http://localhost:$PORT"
    echo -e "${YELLOW}  Beenden mit Ctrl+C${RESET}\n"

    # Browser öffnen
    if command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:$PORT" &>/dev/null &
    fi

    wait "$hugo_pid"
    rm -f "$PID_FILE"
    trap - INT TERM
}

# ── Build ─────────────────────────────────────────────────────────────────────
do_build() {
    header "Build → public/"
    cd "$SITE_DIR"
    info "Starte hugo --minify …"
    echo ""
    if hugo --minify; then
        echo ""
        success "Build abgeschlossen → public/"
    else
        echo ""
        error "Hugo-Build fehlgeschlagen."
        exit 1
    fi
}

# ── Help ──────────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo -e "${BOLD}Verwendung:${RESET} ./serve.sh"
    echo ""
    echo "Interaktives Menü für die M4-Docs Hugo-Site."
    echo ""
    echo -e "${BOLD}Aktionen:${RESET}"
    echo "  [1] Dev-Server starten    hugo server mit Live-Reload"
    echo "  [2] Build                 hugo --minify → public/"
    echo "  [s] Stop                  Laufenden Server beenden"
    echo "  [q] Abbrechen"
    echo ""
    echo -e "${BOLD}Voraussetzungen:${RESET}"
    echo "  hugo    (getestet mit v0.162+)"
    echo "  lsof    (für Port-Erkennung als Fallback)"
    exit 0
fi

# ── Hauptmenü ─────────────────────────────────────────────────────────────────
cd "$SITE_DIR"

header "Hugo – M4 Docs"
show_status
echo ""

if server_running; then
    echo "  [1] Dev-Server neu starten"
    echo "  [2] Build (hugo --minify)"
    echo "  [s] Stop"
    echo "  [q] Abbrechen"
else
    echo "  [1] Dev-Server starten"
    echo "  [2] Build (hugo --minify)"
    echo "  [q] Abbrechen"
fi

echo ""
read -rp "Auswahl: " choice

case "$choice" in
    1)   do_dev ;;
    2)   do_build ;;
    s|S) do_stop ;;
    *)   info "Abgebrochen." ;;
esac
