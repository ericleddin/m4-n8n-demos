# CLAUDE.md — Konventionen für `m4-n8n-demos`

Diese Datei dokumentiert die Konventionen dieses Repositories. Sie wird von Claude Code automatisch als Projekt-Kontext geladen und ist gleichzeitig menschen-lesbare Dokumentation für alle Beitragenden.

**Maintainer:** Eric Leddin (Syntax Institut)
**Kontext:** Begleitendes Repository zu *Modul 4 – KI Experte: Automatisierte Workflows & Agenten*

---

## 1. Was dieses Repo enthält

Dieses Repository sammelt n8n-Workflows als Live-Demos für den Kurs M4. Jeder Workflow:

- liegt in einem eigenen Ordner unter `workflows/woche-<XX>/tag-<YY>-<slug>/`
- besteht aus zwei Dateien: `workflow.json` (importierbarer n8n-Export) und `README.md` (didaktische Einordnung)
- ist von hardcoded API-Keys bereinigt (Platzhalter `<<REPLACE_WITH_...>>` statt echter Keys)
- wird von Studierenden lokal in ihrer eigenen n8n-Instanz importiert

---

## 2. Standard-Workflow für neue Demos

Für jeden neuen Workflow gilt diese Pipeline:

1. **Export aus n8n** als `.json`, Dateiname-Schema: `W<X>T<Y> - <Titel>.json` (Details siehe Abschnitt 3)
2. **Datei in `inbox/` legen** — der Ordner ist gitignored, daher safe für Rohdaten mit echten Keys
3. **Inbox-Skript laufen lassen:**
   ```bash
   python scripts/scan_secrets.py inbox
   ```
   Das Skript bereinigt Secrets, erzeugt `<name>.cleaned.json`, archiviert das Original nach `inbox/_processed/`.
4. **Zielordner anlegen** nach Schema (Abschnitt 3), die `.cleaned.json` dorthin verschieben und in `workflow.json` umbenennen.
5. **README erstellen** nach Pflicht-Vorlage (Abschnitt 4).
6. **Commit pro Workflow**, Message-Format siehe Abschnitt 7.
7. **Push.**

Bei Batch-Verarbeitung mehrerer Workflows: vor den Commits einmal `git status` zeigen und auf Bestätigung warten. Aus `inbox/` darf dabei nichts auftauchen (Sicherheitscheck).

---

## 3. Filename → Folder-Mapping

### Eingabe-Schema

n8n-Exporte folgen dem Schema:
```
W<X>T<Y> - <Titel>.json
```
- `X` = Wochennummer (1-10)
- `Y` = Tag innerhalb der Woche (1-5)
- `<Titel>` = Anzeigename des Workflows in n8n

### Mapping-Regeln

**Woche und Tag** werden zero-padded auf 2 Stellen:
- `W1` → `woche-01`
- `T2` → `tag-02`

**Slug** aus dem Titel nach folgenden Regeln in dieser Reihenfolge:

1. Lowercase
2. Umlaute auflösen: `ä→ae`, `ö→oe`, `ü→ue`, `Ä→ae`, `Ö→oe`, `Ü→ue`, `ß→ss`
3. Alle Zeichen außer `[a-z0-9]` durch `-` ersetzen
4. Mehrfach-`-` zu einzelnem `-` zusammenziehen
5. Führende und abschließende `-` entfernen

### Beispiele

| Original-Dateiname | Zielordner |
|---|---|
| `W1T2 - Daten & APIs.json` | `workflows/woche-01/tag-02-daten-apis/` |
| `W1T3 - Einstieg ins Workflow-Design.json` | `workflows/woche-01/tag-03-einstieg-ins-workflow-design/` |
| `W2T1 - RAG für Anfänger.json` | `workflows/woche-02/tag-01-rag-fuer-anfaenger/` |
| `W3T4 - Multi-Agent Setup.json` | `workflows/woche-03/tag-04-multi-agent-setup/` |

### Edge Cases

- **Mehrere Workflows am gleichen Tag**: dem Slug ein unterscheidendes Suffix anhängen, z.B. `tag-02-daten-apis-basics` und `tag-02-daten-apis-advanced`.
- **Dateinamen, die nicht dem Schema entsprechen**: nicht raten, sondern beim User nachfragen.

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

(Der Pfeil ▲ steht direkt unter der zutreffenden Position. Spaces im ASCII-Diagramm so wählen, dass der Pfeil bündig sitzt.)

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

### Inhaltliche Leitplanken

- **Beschreibung**: 1-2 Sätze, sagt was der Workflow technisch und didaktisch macht
- **Was du lernst**: 3-5 Bullets, aus tatsächlich verwendeten Nodes ableiten (Mapping in Abschnitt 6), nicht generisch
- **Credentials-Tabelle**: nur Services, die im Workflow tatsächlich vorkommen
- **Setup**: jeden Platzhalter `<<REPLACE_WITH_...>>` namentlich erwähnen
- **Variationen**: 3-4 Bullets, müssen zum konkreten Workflow passen. Mindestens eine sollte eine **"saubere Praxis"-Verbesserung** sein (z.B. "hardcoded Key zu echter Credential refactoren").

---

## 5. Architektur-Spektrum: Positionierung

Jeder Workflow wird auf dem Spektrum eingeordnet:

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
```

### Heuristiken

**Prompt** — eine einzelne LLM-Anfrage, optional mit Daten-Vorverarbeitung. Kein Tool-Use, keine Agent-Logik.
- *Indikator:* Genau ein LLM-Node (`chainLlm`, `openAi`, `anthropic`), kein Agent-Node, keine Tool-Connections.

**Custom GPT** — LLM mit System-Prompt und Persona; ggf. mit fest verdrahteten Daten-Sources. Aber: keine autonomen Tool-Aufrufe.
- *Indikator:* LLM-Node mit explizitem System-Prompt, evtl. vorher HTTP-Request für Kontext.

**Workflow** — deterministische Mehr-Step-Pipeline. HTTP-Requests, Transformationen, IF/Switch-Verzweigungen, Set-Nodes. LLM kommt vor, entscheidet aber nicht über den Ablauf.
- *Indikator:* Mehrere unterschiedliche Node-Typen, deterministische Connections, evtl. LLM als Datenverarbeitungs-Step.

**Agent** — LLM wählt autonom aus einer Tool-Palette aus. Tools können HTTP-Calls, Sub-Workflows oder Vector-DBs sein.
- *Indikator:* `@n8n/n8n-nodes-langchain.agent` oder vergleichbarer Agent-Node mit Tool-Connections.

**Multi-Agent** — mehrere Agents kooperieren, z.B. via Sub-Workflows, Hand-off-Patterns oder gemeinsamer Memory.
- *Indikator:* Mehr als ein Agent-Node, ggf. Hierarchie- oder Koordinations-Node.

### Bei Grenzfällen

Im Zweifel die **niedrigere** Position wählen. Lieber konservativ einordnen — der pädagogische Wert "Workflow vs. Agent" liegt darin, klar zu unterscheiden, was wirklich agentisch ist.

---

## 6. "Was du lernst" — Mapping von Nodes zu Lernzielen

Wenn der Workflow folgende Nodes enthält, sollte mindestens ein Bullet darauf eingehen:

| Node-Typ | Lernziel-Beispiel |
|---|---|
| `httpRequest` | HTTP-Requests gegen externe APIs absetzen |
| `set` | Daten aus JSON-Responses extrahieren und transformieren |
| `if` / `switch` | Bedingte Verzweigungen in Workflows |
| `code` | JavaScript/Python in n8n-Pipelines |
| `merge` | Mehrere Datenströme zusammenführen |
| `splitInBatches` | Große Datenmengen batchweise verarbeiten |
| `webhook` | n8n-Workflows als externe API bereitstellen |
| `agent` / `chainLlm` | LLM-Integration via LangChain in n8n |
| `vectorStore*` | RAG-Pattern mit Embeddings und Vektor-Suche |
| `memoryBuffer*` | Konversations-Kontext über Turns hinweg |

Plus mindestens ein **konzeptionelles** Lernziel pro Workflow, das über die reine Node-Mechanik hinausgeht. Beispiele:

- "Unterschied zwischen Credential-Referenz und hardcoded Key"
- "Wann ein Agent statt eines Workflows die richtige Wahl ist"
- "Pattern für parallele vs. sequenzielle API-Calls"
- "Wieso Vector-Stores für unstrukturierte Daten besser sind als SQL"

---

## 7. Commit-Messages

### Pro neuem Workflow

```
Add W<X>/T<Y> - <Titel> workflow (<Kurz-Charakterisierung>)
```

Beispiele:
- `Add W1/T2 - Daten & APIs workflow (parallel API calls demo)`
- `Add W2/T3 - RAG mit Supabase workflow (vector store integration)`
- `Add W3/T1 - Tool-Use Agent workflow (single-agent with HTTP tools)`

### Sonstige Commits

Für Repo-weite Änderungen (Doku, Skripte, Setup): konventionelles Format ohne `Add W…/T…`-Präfix. Beispiele:
- `Update CLAUDE.md with multi-agent heuristics`
- `Fix Bearer token regex in scan_secrets.py`

---

## 8. Tonalität & Sprache

- **Deutsch** durchgängig, **du-Form**
- **Concise** — keine Füllsätze, keine Sales-Sprache
- **Konkret** — Beispiele statt Abstraktionen
- Keine Emojis im Fließtext, nur in den vorgegebenen Header-Markern (📍 🎯 🧰 🚀 📤 💡)
- Inline-Code für n8n-Node-Typen und Credential-Namen: `` `httpRequest` ``, `` `OpenRouter Api` ``

---

## 9. Sicherheit

- **`inbox/` ist gitignored** — Rohdaten mit echten Keys können dort safe liegen.
- **`scan_secrets.py` ist Pflicht** vor jedem Commit eines neuen Workflows.
- Wenn `git status` Dateien aus `inbox/` zeigt (außer `.gitkeep` und `README.md`): STOP, `.gitignore` prüfen.
- **Niemals** echte API-Keys in Commit-Messages oder PR-Beschreibungen.

---

## 10. Wenn etwas unklar ist

Bei Mehrdeutigkeit oder fehlenden Informationen: **fragen, nicht raten.** Lieber ein kurzer Klärungs-Round-Trip als eine inkonsistente README, die später korrigiert werden muss.

Diese Konventionen entwickeln sich weiter — wenn beim Verarbeiten neuer Workflows ein Pattern fehlt oder ein Edge Case auftaucht, ist die richtige Reaktion: Konvention in CLAUDE.md ergänzen, committen, dann fortfahren.
