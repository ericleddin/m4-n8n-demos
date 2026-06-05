# M4 Docs – Hugo-Site

Statische Dokumentationsseite für die Konzept-Docs in `docs/llm_learning/` und `docs/n8n_learning/`. Gebaut mit [Hugo](https://gohugo.io) und dem Theme [hugo-theme-relearn](https://github.com/McShelby/hugo-theme-relearn).

---

## Voraussetzungen

| Tool | Zweck | Mindestversion |
|---|---|---|
| `hugo` (extended) | Build & Dev-Server | v0.162+ |
| `git` | Theme klonen via setup.sh | — |
| `lsof` | Port-Erkennung als Fallback in serve.sh | — |

Hugo installieren: https://gohugo.io/installation/

---

## Erstes Setup

```bash
cd docs/website
./setup.sh
```

Das Script prüft ob Hugo vorhanden ist und klont das Theme nach `themes/hugo-theme-relearn/` — nur beim ersten Mal nötig. Das Theme-Verzeichnis ist gitignored und wird nicht eingecheckt.

---

## Lokal starten

```bash
cd docs/website
./serve.sh
```

Interaktives Menü mit zwei Aktionen:

```
[1] Dev-Server starten    hugo server mit Live-Reload auf http://localhost:1313
[2] Build                 hugo --minify → public/
[s] Stop                  Laufenden Server beenden
[q] Abbrechen
```

### [1] Dev-Server

- Kein vorheriger Build nötig
- Änderungen in `docs/llm_learning/` und `docs/n8n_learning/` werden sofort sichtbar
- PID wird in `.hugo.pid` gespeichert und nach dem Start angezeigt
- Browser öffnet automatisch auf http://localhost:1313 (via `xdg-open`)
- Beenden mit Ctrl+C

### [2] Build

- Baut den statischen Output nach `public/`
- Sinnvoll vor einem Deploy, um den Produktions-Output zu prüfen

### Wenn ein Server läuft

`serve.sh` erkennt den laufenden Prozess via `.hugo.pid` (Fallback: Port-Scan) und zeigt:

```
[1] Dev-Server neu starten
[2] Build (hugo --minify)
[s] Stop
[q] Abbrechen
```

Hilfe:

```bash
./serve.sh --help
```

---

## Windows

`serve.sh` und `setup.sh` sind Bash-Skripte — auf Windows ohne Umweg nicht ausführbar. Hugo selbst läuft nativ auf Windows.

### Empfohlen: WSL2

Mit WSL2 (Windows Subsystem for Linux) funktioniert alles wie auf Linux/macOS — kein Anpassen nötig.

WSL2 einrichten: [learn.microsoft.com/windows/wsl/install](https://learn.microsoft.com/windows/wsl/install)

Danach im WSL-Terminal ganz normal:

```bash
cd docs/website
./setup.sh
./serve.sh
```

### Alternativ: nativ (CMD / PowerShell)

Hugo-Binary für Windows herunterladen: [gohugo.io/installation/windows](https://gohugo.io/installation/windows/)

Theme einmalig klonen (ersetzt `setup.sh`):

```powershell
git clone --depth 1 https://github.com/McShelby/hugo-theme-relearn.git themes/hugo-theme-relearn
```

Dev-Server starten (ersetzt `serve.sh [1]`):

```powershell
hugo server --port 1313
```

Statischen Build erzeugen (ersetzt `serve.sh [2]`):

```powershell
hugo --minify
```

---

## Manuell bauen

```bash
cd docs/website
hugo --minify
```

Output landet in `public/`. Der Ordner enthält reines HTML/CSS/JS — keine Laufzeitabhängigkeiten.

```bash
# Nur prüfen ob alles baut, ohne Output zu schreiben
hugo --dryRun
```

---

## Projektstruktur

```
docs/website/
├── setup.sh              # Theme klonen (einmalig)
├── serve.sh              # Interaktiver Start
├── hugo.toml             # Site-Konfiguration
├── content/
│   └── _index.md         # Startseite
├── themes/
│   └── hugo-theme-relearn/   # gitignored, via setup.sh geklont
└── public/               # gitignored, Build-Output

# Content kommt via Hugo Module Mounts direkt aus:
docs/llm_learning/        → content/llm_learning/
docs/n8n_learning/        → content/n8n_learning/
```

Änderungen an den Markdown-Dateien in `llm_learning/` oder `n8n_learning/` wirken sich direkt auf die Site aus — keine Kopien, eine Quelle.

---

## Hosting

### Option A: GitHub Pages (empfohlen für öffentliche Repos)

GitHub Action anlegen unter `.github/workflows/docs.yml`:

```yaml
name: Deploy Docs

on:
  push:
    branches: [main]
    paths: [docs/**]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: "latest"
          extended: true
      - run: |
          git clone --depth 1 https://github.com/McShelby/hugo-theme-relearn.git \
            docs/website/themes/hugo-theme-relearn
          rm -rf docs/website/themes/hugo-theme-relearn/.git
          cd docs/website && hugo --minify
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs/website/public
```

Danach unter *Settings → Pages → Source: gh-pages branch* aktivieren.

### Option B: Netlify

1. Repo mit Netlify verbinden
2. Build-Einstellungen:
   - **Base directory:** `docs/website`
   - **Build command:** `git clone --depth 1 https://github.com/McShelby/hugo-theme-relearn.git themes/hugo-theme-relearn && hugo --minify`
   - **Publish directory:** `docs/website/public`
3. Deploy — Netlify erkennt Hugo automatisch und deployed bei jedem Push

### Option C: Eigener Server

```bash
# Auf dem Server:
cd docs/website
./setup.sh
hugo --minify

# public/ per rsync übertragen
rsync -avz public/ user@server:/var/www/m4-docs/
```

Danach `public/` per nginx oder caddy servieren — keine weiteren Abhängigkeiten.

```nginx
server {
    listen 80;
    server_name docs.example.com;
    root /var/www/m4-docs;
    index index.html;
}
```

---

## Konfiguration

Alle Site-Einstellungen in `hugo.toml`. Relevante Parameter:

| Parameter | Wert | Bedeutung |
|---|---|---|
| `theme` | `hugo-theme-relearn` | Aktives Theme |
| `params.themeVariant` | `relearn-dark` | Dark Mode |
| `params.mermaidInitialize` | `{ "theme": "dark" }` | Mermaid Dark Theme |
| `defaultContentLanguage` | `de` | Sprache |

Weitere Theme-Optionen: https://mcshelby.github.io/hugo-theme-relearn/
