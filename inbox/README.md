# Inbox – Workflow-Verarbeitungs-Eingang

Dieser Ordner ist **`.gitignored`** — Rohdaten landen hier nie im Repository.

## Ablauf

1. **Workflow aus n8n exportieren** (Workflows → ⋮ → Download) und die `.json`-Datei in diesen Ordner legen.
2. **Verarbeitungs-Skript laufen lassen:**
   ```bash
   python scripts/scan_secrets.py inbox
   ```
3. Das Skript:
   - scannt die Datei auf hardcoded API-Keys, Tokens etc.
   - schreibt eine bereinigte Version daneben als `<name>.cleaned.json`
   - verschiebt das Original in `inbox/_processed/` (Archiv)
4. **Bereinigte Version prüfen** — vor allem die `<<REPLACE_WITH_...>>`-Platzhalter anschauen.
5. **An den richtigen Ort verschieben:**
   ```
   workflows/woche-XX/tag-YY-name/workflow.json
   ```
6. **README für den Workflow schreiben** (Template kommt in Schritt 2).
7. Committen.

## Sicherheits-Hinweis

Du kannst hier auch ungeprüfte Workflows mit echten Keys reinlegen — der gesamte Ordner ist gitignored. Selbst ein versehentliches `git add .` kann nichts versehentlich committen.

Lediglich diese README und `.gitkeep` werden im Repo getrackt.
