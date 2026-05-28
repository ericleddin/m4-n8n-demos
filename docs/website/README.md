# M4 Docs – Hugo-Site

Statische Dokumentationsseite für die Konzept-Docs in `docs/llm_learning/` und `docs/n8n_learning/`. Gebaut mit [Hugo](https://gohugo.io) und dem Theme [hugo-theme-relearn](https://github.com/McShelby/hugo-theme-relearn).

---

## Voraussetzungen

| Tool | Zweck | Mindestversion |
|---|---|---|
| `hugo` (extended) | Build & Dev-Server | v0.120+ |
| `git` | Theme klonen via setup.sh | — |
| `python3` | Statischen Build lokal servieren (optional) | — |

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

Interaktives Menü mit zwei Modi:

### [1] Dev-Server

```
hugo server — Live-Reload auf http://localhost:1313
```

- Kein vorheriger Build nötig
- Änderungen in `docs/llm_learning/` und `docs/n8n_learning/` werden sofort sichtbar
- Server-Output läuft in `hugo_http.log`, parallel per `tail -f` in der Konsole
- PID wird nach dem Start angezeigt

### [2] Build & Serve

```
hugo --minify → public/   dann   python3 -m http.server
```

- Baut erst den statischen Output nach `public/`
- Serviert ihn lokal per Python HTTP-Server
- Simuliert den Produktions-Output — sinnvoll vor einem Deploy

### Wenn ein Server läuft

`serve.sh` erkennt ob Port 1313 belegt ist und bietet an:

```
[1] Restart              Stop + Dev-Server neu starten
[2] Rebuild & Restart    Stop + neu bauen + servieren
[s] Stop                 Nur beenden
[o] Browser öffnen       Bestehenden Server weiter nutzen
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
