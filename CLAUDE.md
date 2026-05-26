# CLAUDE.md — Konventionen für `m4-n8n-demos`

Diese Datei dokumentiert die Konventionen dieses Repositories. Sie wird von Claude Code automatisch als Projekt-Kontext geladen und ist gleichzeitig menschen-lesbare Dokumentation für alle Beitragenden.

**Maintainer:** Eric Leddin (Syntax Institut)
**Kontext:** Begleitendes Repository zu *Modul 4 – KI Experte: Automatisierte Workflows & Agenten*

---

## 1. Was dieses Repo enthält

Dieses Repository sammelt n8n-Workflows als Live-Demos für den Kurs M4. Jeder Workflow:

- liegt in einem eigenen Ordner unter `workflows/woche-<XX>/tag-<YY>-<slug>/`
- besteht mindestens aus zwei Dateien: `workflow.json` (importierbarer n8n-Export) und `README.md` (didaktische Einordnung)
- kann zusätzlich Varianten (`workflow-bonus.json`) und Companion-Files (Frontends, Scripts, Daten) enthalten
- ist von hardcoded API-Keys und persönlichen Daten bereinigt (Platzhalter `<<REPLACE_WITH_...>>` statt echter Werte)
- wird von Studierenden lokal in ihrer eigenen n8n-Instanz importiert

---

## 2. Standard-Workflow für neue Demos

Für jede neue Demo gilt diese Pipeline:

1. **Export aus n8n** als `.json`, Dateiname-Schema: siehe Abschnitt 3. Companion-Files (HTML, Scripts) folgen dem gleichen Präfix-Schema.
2. **Datei(en) in `inbox/` legen** — der Ordner ist gitignored, daher safe für Rohdaten mit echten Keys.
3. **Inbox-Skript laufen lassen:**
   ```bash
   python scripts/scan_secrets.py inbox
   ```
   Das Skript bereinigt Secrets und persönliche Daten, erzeugt `<name>.cleaned.<ext>`-Dateien und archiviert die Originale nach `inbox/_processed/`. Unterstützte Formate: `.json` und `.html`.
4. **Zielordner anlegen** nach Schema (Abschnitt 3) und alle zugehörigen Dateien dorthin verschieben.
5. **README erstellen** nach Pflicht-Vorlage (Abschnitt 4).
6. **Commit pro Demo** (alle Files einer Demo in einem Commit), Message-Format siehe Abschnitt 7.
7. **Push.**

Bei Batch-Verarbeitung mehrerer Demos: vor den Commits einmal `git status` zeigen und auf Bestätigung warten. Aus `inbox/` darf dabei nichts auftauchen (Sicherheitscheck).

---

## 3. Filename → Folder-Mapping

### Eingabe-Schemata

Alle Inbox-Dateien folgen einem dieser drei Schemata:

**Hauptworkflow:**
```
W<X>T<Y> - <Title>.json
```

**Workflow-Variante** (mehrere Workflows am gleichen Tag, z.B. erweiterte Version):
```
W<X>T<Y> - <Title> (<Variant>).json
```

**Companion-File** (Frontend, Script, Daten):
```
W<X>T<Y> - <Title> - <SubName>.<ext>
```

Wobei:
- `<X>` = Wochennummer (1–10), `<Y>` = Tag innerhalb der Woche (1–5)
- `<Title>` = identisch über Hauptworkflow und alle zugehörigen Files (Linking-Mechanismus → bestimmt den Zielordner)
- `<Variant>` = z.B. `Bonus`, `Advanced` — wird zum Datei-Suffix
- `<SubName>` = z.B. `kontakt`, `dashboard` — wird zum Companion-Filename
- ` - ` (Space-Dash-Space) ist reservierter Separator und darf nicht innerhalb von `<Title>`, `<Variant>`, `<SubName>` vorkommen

### Mapping-Regeln

**Woche und Tag** werden zero-padded auf 2 Stellen:
- `W1` → `woche-01`
- `T2` → `tag-02`

**Slug** aus `<Title>` nach folgenden Regeln in dieser Reihenfolge:

1. Lowercase
2. Umlaute auflösen: `ä→ae`, `ö→oe`, `ü→ue`, `Ä→ae`, `Ö→oe`, `Ü→ue`, `ß→ss`
3. Alle Zeichen außer `[a-z0-9]` durch `-` ersetzen
4. Mehrfach-`-` zu einzelnem `-` zusammenziehen
5. Führende und abschließende `-` entfernen

### Mapping-Tabelle

| Original-Dateiname | Zielpfad |
|---|---|
| `W1T2 - Daten & APIs.json` | `workflows/woche-01/tag-02-daten-apis/workflow.json` |
| `W2T1 - Daten senden.json` | `workflows/woche-02/tag-01-daten-senden/workflow.json` |
| `W2T1 - Daten senden (Bonus).json` | `workflows/woche-02/tag-01-daten-senden/workflow-bonus.json` |
| `W2T1 - Daten senden - kontakt.html` | `workflows/woche-02/tag-01-daten-senden/frontend/kontakt.html` |
| `W3T2 - Tool-Agent (Advanced).json` | `workflows/woche-03/tag-02-tool-agent/workflow-advanced.json` |
| `W3T2 - Tool-Agent - seed.sql` | `workflows/woche-03/tag-02-tool-agent/data/seed.sql` |

### Companion-File Unterordner nach Extension

| Extension(s) | Unterordner |
|---|---|
| `.html` | `frontend/` |
| `.js`, `.ts`, `.py` (eigenständige Scripts) | `scripts/` |
| `.sql`, `.csv`, `.json` (Daten, Seeds, Schemas) | `data/` |

Bei Bedarf neue Kategorien hier ergänzen, nicht ad-hoc erfinden.

### Edge Cases

- **Dateinamen, die keinem Schema entsprechen**: nicht raten, sondern beim User nachfragen
- **Mehrere Varianten in einer Demo**: `workflow-bonus.json`, `workflow-advanced.json` etc. nebeneinander im gleichen Ordner

---

## 4. README-Struktur (Pflicht-Vorlage)

Jede Workflow-README folgt exakt dieser Struktur. Reihenfolge der Sektionen, Emoji-Header und Tonalität sind verbindlich.

### Referenz-Implementierung

`workflows/woche-01/tag-02-daten-apis/README.md` ist die kanonische Vorlage. Bei Unsicherheit immer dort spicken.

### Skelett

````markdown
# Tag <Y>: <Titel>

<1-2 Sätze: was tut der Workflow, welcher pädagogische Hauptfokus.>

## 📍 Architektur-Spektrum

**<Position>** — <kurze Begründung, 1 Satz>.

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                          ▲
```

(Der Pfeil ▲ steht direkt unter der zutreffenden Position.)

## 🎯 Was du lernst

- <konkretes Lernziel>
- <konkretes Lernziel>
- <konkretes Lernziel>

## 🧰 Voraussetzungen

### Benötigte Credentials

<Tabelle Service | n8n Credential-Typ | Key holen unter — ODER "Keine Credentials nötig">

### Community Nodes

<Liste der nötigen Custom-Nodes ODER "Keine — nur Core-Nodes (...)">

## 🚀 Import & Setup

1. <Schritt mit n8n-UI-Bezug>
2. <Schritt für jede benötigte Credential>
3. <Schritt für jeden manuell zu ersetzenden Platzhalter>
4. **Test**: <wie startet man den Workflow>

## 📤 Erwartetes Verhalten

<Was passiert beim Start, vom Trigger bis zum Output, 3-5 Sätze oder Bullets.>

## 💡 Variationen & Übungsideen

- <relevante Idee>
- <relevante Idee>
- <relevante Idee>
````

### Erweiterungen bei Multi-File-Demos

Wenn die Demo mehrere Workflow-Varianten oder Companion-Files enthält, ergänze die README um diese Sektionen **in dieser Reihenfolge** zwischen "Voraussetzungen" und "Import & Setup":

````markdown
## 📦 Workflow-Varianten

Wenn mehr als ein `workflow*.json` existiert:

- **`workflow.json`** — <Hauptzweck, 1 Satz>
- **`workflow-bonus.json`** — <was ist anders, 1 Satz>

## 🌐 Companion-Files

Wenn `frontend/`, `scripts/` oder `data/`-Ordner existieren:

- **`frontend/kontakt.html`** — <was es ist, wofür>
- **`scripts/seed.js`** — <was es macht>
- **`data/contacts.sql`** — <was es enthält>
````

Im Setup-Abschnitt: für jede Companion-Datei einen eigenen Schritt erklären (z.B. "öffne `frontend/kontakt.html` lokal in einem Editor und ersetze `<<REPLACE_WITH_YOUR_N8N_HOST>>` durch die URL deiner n8n-Instanz").

### Inhaltliche Leitplanken

- **Beschreibung**: 1-2 Sätze, sagt was die Demo technisch und didaktisch macht
- **Was du lernst**: 3-5 Bullets, aus tatsächlich verwendeten Nodes ableiten (Mapping in Abschnitt 6), nicht generisch
- **Credentials-Tabelle**: nur Services, die im Workflow tatsächlich vorkommen
- **Setup**: jeden Platzhalter `<<REPLACE_WITH_...>>` namentlich erwähnen, inkl. derer in Companion-Files
- **Variationen**: 3-4 Bullets, müssen zur konkreten Demo passen. Mindestens eine sollte eine **"saubere Praxis"-Verbesserung** sein (z.B. "Webhook-Auth aktivieren", "hardcoded Werte zu echten Credentials refactoren").

---

## 5. Architektur-Spektrum: Positionierung

Jeder Workflow wird auf dem Spektrum eingeordnet:

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
```

### Heuristiken

**Prompt** — eine einzelne LLM-Anfrage, optional mit Daten-Vorverarbeitung. Kein Tool-Use, keine Agent-Logik.
- *Indikator:* Genau ein LLM-Node, kein Agent-Node, keine Tool-Connections.

**Custom GPT** — LLM mit System-Prompt und Persona; ggf. mit fest verdrahteten Daten-Sources. Aber: keine autonomen Tool-Aufrufe.
- *Indikator:* LLM-Node mit explizitem System-Prompt, evtl. vorher HTTP-Request für Kontext.

**Workflow** — deterministische Mehr-Step-Pipeline. HTTP-Requests, Transformationen, IF/Switch-Verzweigungen, Set-Nodes, Datenbank-Operationen. LLM kommt vor, entscheidet aber nicht über den Ablauf.
- *Indikator:* Mehrere unterschiedliche Node-Typen, deterministische Connections, evtl. LLM als Datenverarbeitungs-Step.

**Agent** — LLM wählt autonom aus einer Tool-Palette aus. Tools können HTTP-Calls, Sub-Workflows oder Vector-DBs sein.
- *Indikator:* `@n8n/n8n-nodes-langchain.agent` oder vergleichbarer Agent-Node mit Tool-Connections.

**Multi-Agent** — mehrere Agents kooperieren, z.B. via Sub-Workflows, Hand-off-Patterns oder gemeinsamer Memory.
- *Indikator:* Mehr als ein Agent-Node, ggf. Hierarchie- oder Koordinations-Node.

### Bei Grenzfällen

Im Zweifel die **niedrigere** Position wählen. Lieber konservativ einordnen — der pädagogische Wert "Workflow vs. Agent" liegt darin, klar zu unterscheiden, was wirklich agentisch ist.

Bei **mehreren Workflow-Varianten in einer Demo** die Position des **Hauptworkflows** angeben. Falls die Variante eine andere Position einnimmt, in der `📦 Workflow-Varianten`-Sektion erwähnen.

---

## 6. "Was du lernst" — Mapping von Nodes zu Lernzielen

Wenn der Workflow folgende Nodes enthält, sollte mindestens ein Bullet darauf eingehen:

| Node-Typ | Lernziel-Beispiel |
|---|---|
| `httpRequest` | HTTP-Requests gegen externe APIs absetzen |
| `webhook` | n8n-Workflows als externe API bereitstellen |
| `formTrigger` | n8n-natives Webformular als Trigger nutzen |
| `set` | Daten aus JSON-Responses extrahieren und transformieren |
| `if` / `switch` | Bedingte Verzweigungen in Workflows |
| `code` | JavaScript/Python in n8n-Pipelines |
| `merge` | Mehrere Datenströme zusammenführen |
| `splitInBatches` | Große Datenmengen batchweise verarbeiten |
| `supabase` / `postgres` / `mysql` | Datenbank-Operationen aus n8n |
| `agent` / `chainLlm` | LLM-Integration via LangChain in n8n |
| `vectorStore*` | RAG-Pattern mit Embeddings und Vektor-Suche |
| `memoryBuffer*` | Konversations-Kontext über Turns hinweg |

Plus mindestens ein **konzeptionelles** Lernziel pro Workflow, das über die reine Node-Mechanik hinausgeht. Beispiele:

- "Unterschied zwischen Credential-Referenz und hardcoded Key"
- "Wann ein Agent statt eines Workflows die richtige Wahl ist"
- "Pattern für parallele vs. sequenzielle API-Calls"
- "Upsert-Pattern: Suchen → IF → Update oder Insert"
- "Wieso Vector-Stores für unstrukturierte Daten besser sind als SQL"

---

## 7. Commit-Messages

### Pro neuer Demo

```
Add W<X>/T<Y> - <Titel> demo (<Kurz-Charakterisierung>)
```

Beispiele:
- `Add W1/T2 - Daten & APIs workflow (parallel API calls demo)`
- `Add W2/T1 - Daten senden demo (form + webhook + Supabase + HTML frontend)`
- `Add W2/T3 - RAG mit Supabase demo (vector store integration)`

Bei Multi-File-Demos: ein Commit umfasst alle Dateien (Hauptworkflow, Varianten, Companion-Files, README).

### Sonstige Commits

Für Repo-weite Änderungen (Doku, Skripte, Setup): konventionelles Format ohne `Add W…/T…`-Präfix. Beispiele:
- `Update CLAUDE.md with multi-file demo conventions`
- `Add HTML scanning support to scan_secrets.py`

---

## 8. Tonalität & Sprache

- **Deutsch** durchgängig, **du-Form**
- **Concise** — keine Füllsätze, keine Sales-Sprache
- **Konkret** — Beispiele statt Abstraktionen
- Keine Emojis im Fließtext, nur in den vorgegebenen Header-Markern (📍 🎯 🧰 📦 🌐 🚀 📤 💡)
- Inline-Code für n8n-Node-Typen und Credential-Namen: `` `httpRequest` ``, `` `OpenRouter Api` ``

---

## 9. Sicherheit

- **`inbox/` ist gitignored** — Rohdaten mit echten Keys können dort safe liegen.
- **`scan_secrets.py` ist Pflicht** vor jedem Commit. Unterstützt `.json` und `.html`-Dateien.
- Das Skript ersetzt zwei Kategorien:
  - **Secrets** (API-Keys, JWTs, Bearer-Tokens) → `<<REPLACE_WITH_<SERVICE>_KEY>>`
  - **Persönliche Patterns** (Maintainer-E-Mail, eigene n8n-Hosts) → `<<REPLACE_WITH_YOUR_...>>`
- **Neue Maintainer ergänzen** ihre persönlichen Patterns in `scripts/scan_secrets.py` unter `PERSONAL_PATTERNS`. Beispiele dort dienen als Template.
- Wenn `git status` Dateien aus `inbox/` zeigt (außer `.gitkeep` und `README.md`): STOP, `.gitignore` prüfen.
- **Niemals** echte API-Keys in Commit-Messages oder PR-Beschreibungen.

---

## 10. Wenn etwas unklar ist

Bei Mehrdeutigkeit oder fehlenden Informationen: **fragen, nicht raten.** Lieber ein kurzer Klärungs-Round-Trip als eine inkonsistente README, die später korrigiert werden muss.

Diese Konventionen entwickeln sich weiter — wenn beim Verarbeiten neuer Workflows ein Pattern fehlt oder ein Edge Case auftaucht, ist die richtige Reaktion: Konvention in CLAUDE.md ergänzen, committen, dann fortfahren.
