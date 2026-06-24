# Tag 3: RAG optimiert – Ingestion, Metadaten-Filter & Hybrid Search

Drei deterministische Workflows, die die Stellschrauben hinter dem RAG-Tool aus Tag 3 sichtbar machen: Die Ingestion-Pipeline zeigt Chunk-Größe/Overlap, Embedding-Modell und Metadaten beim Befüllen; der Retrieval-Inspektor misst, was ein Metadaten-Filter beim Abrufen bringt; der Hybrid-Inspektor stellt semantische Vektorsuche und wörtliche Stichwortsuche gegenüber. Didaktischer Fokus: RAG nicht als Black Box, sondern als Menge konkret einstellbarer Hebel.

## 📍 Architektur-Spektrum

**Workflow** — alle drei Dateien sind deterministische Pipelines: Embeddings und Vektor-Operationen kommen vor, aber kein `agent`-Node entscheidet über den Ablauf. Bewusster Kontrast zum Agent aus `../tag-03-support-agent/`: hier wird die Mechanik unter dem RAG-Tool freigelegt.

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- Die vier RAG-Optimierungs-Hebel benennen und drei davon in der Ingestion einstellen: **Chunk-Größe/Overlap** (`textSplitterRecursiveCharacterTextSplitter`, hier 800/100), **Embedding-Modell** (`embeddingsOpenAi`) und **Metadaten** (`documentDefaultDataLoader` setzt `kategorie` aus dem Dateinamen)
- PDFs robust einlesen mit `extractFromFile` (operation `pdf`) statt über den Default-Loader — umgeht den `pdf-parse-v1`-Bug
- Den vierten Hebel auf der Retrieval-Seite messen: `vectorStoreSupabase` im `load`-Modus mit `metadata`-Filter auf `kategorie` durchsucht gezielt eine Kategorie statt der ganzen Basis
- Such**strategien** gegenüberstellen: semantische Vektorsuche (`vectorStoreSupabase`, Top-K nach Bedeutung) vs. wörtliche Stichwortsuche (`supabase` `getAll` mit `content ILIKE`) — und warum produktive Systeme als **Hybrid Search** beides kombinieren. In beiden Inspektoren führt `merge` (combineByPosition) die parallelen Stränge zusammen, ein `code`-Node macht den Unterschied über die Trefferzahl messbar
- Konzeptionell: warum Ingestion und Retrieval denselben `documents`-Store und dieselbe Embedding-Dimension teilen müssen — und dass Metadaten beim Schreiben gesetzt werden müssen, damit der Filter beim Lesen überhaupt greift

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenAI (Embeddings `text-embedding-3-small`) | `OpenAI` | https://platform.openai.com/api-keys |
| Supabase (pgvector + `documents`/`match_documents`) | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |

Alle drei Workflows brauchen nur Embeddings und Supabase — kein Chat-Modell, kein Resend. Die Embeddings laufen über echtes OpenAI (`text-embedding-3-small`, 1536 Dimensionen), passend zur `documents.embedding`-Spalte (`vector(1536)`).

### Community Nodes

Keine — nur Core-Nodes (`formTrigger`, `extractFromFile`, `set`, `merge`, `code`, `supabase`) und mitgelieferte LangChain-Nodes (`vectorStoreSupabase`, `embeddingsOpenAi`, `documentDefaultDataLoader`, `textSplitterRecursiveCharacterTextSplitter`).

### Geteilte Daten (aus Tag 3)

Dieses Demo hat **keinen eigenen `data/`-Ordner** — es nutzt denselben Vektorstore und dieselbe Wissensquelle wie `../tag-03-support-agent/`:

- **Schema**: `documents` + Funktion `match_documents` aus `../tag-03-support-agent/data/supabase_setup.sql` (Abschnitt 1)
- **Wissensquelle**: die 5 PDFs aus `../tag-03-support-agent/data/` — `Voltbox_FAQ.pdf`, `Voltbox_Produktkatalog.pdf`, `Voltbox_Rueckgabe_und_Garantie.pdf`, `Voltbox_Versand_und_Lieferung.pdf`, `Voltbox_Zahlung_und_Rechnung.pdf`

**Wichtig**: Die Tag-3-Ingestion setzt **keine** `kategorie`-Metadaten. Damit der Filter-Strang im Inspektor Treffer liefert, müssen die PDFs über die Ingestion-Pipeline **dieses** Demos geladen werden (sie leitet `kategorie` aus dem Dateinamen ab).

## 📦 Workflow-Varianten

- **`workflow-ingestion.json`** — Form-Upload einer PDF → `extractFromFile` → Recursive Splitter (800/100) + Data Loader (`kategorie` aus Dateiname) → `embeddingsOpenAi` → Insert in `documents`. Befüllt die Wissensbasis **mit** Kategorie-Metadaten.
- **`workflow-retrieval-inspektor.json`** — Manual-Trigger, eine Frage im Set-Node, zwei parallele `vectorStoreSupabase`-Retrievals (ohne Filter vs. Filter `kategorie=Rueckgabe_und_Garantie`), `code`-Node vergleicht die Trefferzahl pro Strang.
- **`workflow-hybrid-inspektor.json`** — Manual-Trigger, Frage + Suchbegriff im Set-Node, zwei parallele Stränge `Vektorsuche` (`vectorStoreSupabase`, semantisch/Top-K) und `Stichwortsuche` (`supabase` `getAll` mit `content ILIKE`), `code`-Node vergleicht die Trefferzahl pro Suchstrategie.

Alle drei stehen auf dem Spektrum bei **Workflow**.

## 🚀 Import & Setup

1. **Schema sicherstellen**: `documents` + `match_documents` müssen existieren. Falls Tag 3 noch nicht eingerichtet ist, Abschnitt 1 von `../tag-03-support-agent/data/supabase_setup.sql` im Supabase-SQL-Editor ausführen (aktiviert pgvector, legt `documents` + `match_documents` an, Dimension 1536).
2. **Workflows importieren**: `workflow-ingestion.json`, `workflow-retrieval-inspektor.json` und `workflow-hybrid-inspektor.json` einzeln über `Workflows → Add Workflow → Import from File` einlesen.
3. **Credentials zuweisen** (nach dem Import sind die Nodes ohne Credential):
   - `OpenAI account` (Typ `OpenAI`) → die `Embeddings OpenAI`-Nodes in **allen drei** Workflows
   - `Supabase account` (Typ `Supabase API`) → `In Wissensdatenbank speichern` (Ingestion), `Retrieval_ohne_Filter`/`Retrieval_mit_Filter` (Retrieval-Inspektor) sowie `Vektorsuche`/`Stichwortsuche` (Hybrid-Inspektor)
4. **Wissensbasis mit Kategorien befüllen**: im Ingestion-Workflow den Form-Trigger `Dokument hochladen` öffnen (Test-URL im Node) und die **5 PDFs aus `../tag-03-support-agent/data/` einzeln** hochladen — pro Upload genau ein PDF, Dateiname-Schema `Voltbox_<Kategorie>.pdf`. Die `kategorie` wird automatisch aus dem Namen abgeleitet (z.B. `Rueckgabe_und_Garantie`).
   - Hinweis: Enthält `documents` bereits Chunks aus der Tag-3-Ingestion (ohne `kategorie`), verfälschen diese den Vergleich. Für eine saubere Messung `documents` vorher leeren (`truncate documents;`) und alle 5 PDFs über diese Pipeline neu laden.
5. **Test**: in einem der Inspektoren im Set-Node eine Frage eintragen (`Frage` im Retrieval-Inspektor bzw. `Frage und Suchbegriff` im Hybrid-Inspektor) und oben auf `Execute Workflow` klicken.

## 📤 Erwartetes Verhalten

- **Ingestion**: Pro Upload extrahiert `extractFromFile` den PDF-Text, der Recursive Splitter zerlegt ihn in Chunks (800 Zeichen, 100 Overlap), der Data Loader hängt `kategorie` (aus dem Dateinamen) als Metadatum an, und jeder Chunk wird mit seinem Embedding in `documents` geschrieben.
- **Retrieval-Inspektor**: Die Frage aus dem Set-Node geht parallel an beide Stränge. `Retrieval_ohne_Filter` durchsucht die gesamte Basis, `Retrieval_mit_Filter` nur Chunks mit `kategorie=Rueckgabe_und_Garantie`. Der `Vergleich`-Node gibt `{ treffer_ohne, treffer_mit }` aus; die Laufzeit jeder Supabase-Node steht im Output-Header (`Success in XXX ms`).
- Bei der Default-Frage „Kann ich eine Lieferung zurückschicken?" liefern beide Stränge Treffer. Da beide auf das Top-k der Node begrenzt sind, ist die **Trefferzahl** oft gleich — der Unterschied liegt in der **Präzision** (der gefilterte Strang gibt ausschließlich Chunks aus der Rückgabe-Kategorie zurück, der ungefilterte mischt ggf. Chunks anderer Kategorien bei) und in der Laufzeit.
- **Hybrid-Inspektor**: Frage und Suchbegriff gehen parallel an `Vektorsuche` (semantisch, Top-K nach Bedeutung, mit Embedding-Call) und `Stichwortsuche` (`content ILIKE %suchbegriff%`, alle wörtlichen Erwähnungen, ohne Embedding). Der `Vergleich`-Node gibt pro Strategie ein Label samt Trefferzahl aus. Bei der Default-Frage „Was kann die Pro 800?" (Suchbegriff `Pro 800`) findet die Vektorsuche die bedeutungsnächsten Chunks (sortiert), die Stichwortsuche alle Chunks mit der wörtlichen Zeichenkette (unsortiert) — die Vektorsuche ist relevanter sortiert, aber durch den Embedding-Call langsamer (Laufzeit im Output-Header). Hinweis: Suchbegriff ohne Komma eingeben — ein Komma bricht den PostgREST-Filter der Stichwortsuche.

## 💡 Variationen & Übungsideen

- Im Ingestion-Workflow Chunk-Größe/Overlap im Recursive Splitter variieren (z.B. 400/50 vs. 1200/200), neu laden und im Inspektor beobachten, wie sich Trefferinhalt und Laufzeit ändern
- Im Inspektor eine Frage stellen, deren Antwort **nicht** in `Rueckgabe_und_Garantie` liegt (z.B. „Was kostet der Versand?") — dann liefert der gefilterte Strang thematisch falsche Treffer: der Filter ist ein Präzisions-Hebel mit Kehrseite
- Den `Vergleich`-Code erweitern, sodass er zusätzlich `content` und `metadata.kategorie` der Treffer beider Stränge ausgibt — dann wird der Präzisionsunterschied auch bei gleicher Trefferzahl sichtbar
- Im Hybrid-Inspektor einen Suchbegriff wählen, der semantisch passt, aber wörtlich nicht im Text vorkommt (z.B. Frage „tragbare Stromversorgung fürs Camping", Suchbegriff `Powerstation`) — findet die Stichwortsuche nichts, die Vektorsuche aber schon, ist das der Kern des Hybrid-Search-Arguments
- **Saubere Praxis**: den Ingestion-`formTrigger` für den öffentlichen Einsatz absichern (Authentifizierung), damit nicht jeder anonym Dokumente in die Wissensbasis schreiben kann; und den `kategorie`-Filterwert im Inspektor aus dem Set-Node beziehen, statt ihn im Retrieval-Node hart zu verdrahten

---

Tiefergehende Erklärung zu RAG, Embeddings und Vektor-Retrieval in `docs/n8n_learning/llm_agent_tools_intro.md`. Die Grundlagen des Supabase-Vektorstores zeigt `workflows/woche-02/tag-03-rag-supabase/`, den vollständigen Agent, der dieses RAG-Tool produktiv nutzt, `workflows/woche-06/tag-03-support-agent/`.
