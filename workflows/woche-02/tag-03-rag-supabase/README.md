# Tag 3: RAG mit Supabase Vector Store

Ein Retrieval-Augmented-Generation-Workflow in zwei eigenständigen Pipelines: eine **Ingestion-Pipeline** lädt PDFs hoch, zerlegt sie in Chunks, erzeugt Embeddings mit OpenAI und speichert sie im Supabase Vector Store. Eine **Retrieval & Chat-Pipeline** nimmt Chat-Fragen entgegen; ein AI Agent entscheidet selbst, ob er den Vector Store als Tool nutzt, und antwortet mit dem gefundenen Kontext.

Das ist die **erste Agent-Demo des Kurses** — ab hier entscheidet das LLM autonom über den Ablauf.

## 📍 Architektur-Spektrum

**Agent** — der `@n8n/n8n-nodes-langchain.agent` ist als Orchestrator angeschlossen und bekommt den Vector Store als **Tool** (`retrieve-as-tool`-Modus), das er selbst aufrufen kann oder eben sein lässt. Bei "Hallo" macht der Agent keinen RAG-Lookup, bei einer inhaltlichen Frage zum Kursmaterial schon. Genau dieses *"das LLM entscheidet"* unterscheidet die Demo vom Workflow aus W2T2, wo das LLM nur ein gekapselter Verarbeitungs-Step war.

```
Prompt → Custom GPT → Workflow → [Agent] → Multi-Agent
                                    ▲
```

## 🎯 Was du lernst

- **Vector Stores in n8n** mit `@n8n/n8n-nodes-langchain.vectorStoreSupabase` (insert- und retrieve-Modus aus dem gleichen Node)
- Embeddings mit OpenAI `text-embedding-3-small` über den `embeddingsOpenAi`-Sub-Node
- **Default Data Loader + automatisches Chunking** — n8n übernimmt PDF-Zerlegung und Vektorisierung ohne expliziten Splitter
- **AI Agent als Orchestrator**: Chat-Trigger → Agent → Tool-Call → Antwort
- **Vector Store im `retrieve-as-tool`-Modus**: der Vector Store hängt als `ai_tool`-Sub-Node am Agent, nicht als deterministischer Schritt in der Main-Connection
- `formTrigger` mit File-Upload (`multipart/form-data`, `acceptFileTypes: .pdf`)
- **Klassisches RAG-Muster**: Ingest und Query als zwei separate, unverbundene Pipelines in derselben Workflow-Datei
- **Konzeptionell**: Warum der Vector Store als **Tool** und nicht als hartverdrahteter Step? Weil der Agent so selbst entscheiden kann, ob er suchen muss — bei "Danke" macht er keinen sinnlosen Datenbank-Roundtrip, bei einer Inhaltsfrage schon. Tools = optional, Pipeline-Steps = obligatorisch.

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| Supabase | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| OpenAI | `OpenAI Api` | https://platform.openai.com/api-keys |
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |

Hinweis: Im Workflow-JSON tauchen drei Credential-Referenzen auf (zwei OpenAI, ein OpenRouter) — ich habe beim Bauen mit zwei Test-Accounts gearbeitet. Für dich reicht **eine OpenAI-Credential**, die du in **beiden** `Embeddings OpenAI`-Sub-Nodes (Ingestion und Retrieval) auswählst, und **eine OpenRouter-Credential** für das Chat Model.

### Community Nodes

Keine — nur Core- und offizielle LangChain-Nodes (`Form Trigger`, `Extract from File`, `Chat Trigger`, `AI Agent`, `Embeddings OpenAI`, `Default Data Loader`, `Supabase Vector Store`, `OpenRouter Chat Model`).

### Supabase: pgvector RAG-Setup

Für RAG brauchst du in Supabase die `pgvector`-Extension, eine Tabelle `documents` mit `embedding`-Spalte und eine SQL-Function `match_documents`, die der Vector-Store-Node von n8n erwartet. Der einfachste Weg:

1. **Supabase-Projekt anlegen** unter https://supabase.com → **New Project**
2. Im Dashboard **SQL Editor → Quickstarts**: dort findest du einen Button **"LangChain"**. Ein Klick legt **Extension, Tabelle `documents` und Function `match_documents`** in einem Rutsch an — genau das Schema, das dieser Workflow erwartet.
3. **API-URL** und **Service Role Key** unter **Project Settings → API** kopieren — beides brauchst du gleich für das `Supabase Api` Credential in n8n.

Offizieller Hintergrund-Guide (falls du das Schema manuell verstehen willst): https://supabase.com/docs/guides/ai/langchain

**💡 Tipp: KI als Setup-Assistent nutzen**

Falls dir das Setup unklar ist, kannst du Claude (oder eine andere KI) fragen:

> Ich nutze Supabase zum ersten Mal für RAG und brauche ein pgvector-Setup für n8ns Vector Store Node. Erkläre mir Schritt für Schritt:
> 1. Was pgvector überhaupt ist und welches Problem es löst,
> 2. Wie ich die Extension in Supabase aktiviere,
> 3. Wie ich eine Tabelle `documents` mit einer `embedding`-Spalte (Vektor-Dimension passend zu `text-embedding-3-small`) anlege,
> 4. Wie ich die SQL-Function `match_documents` erstelle, die n8ns Supabase Vector Store Node aufruft,
> 5. Wo ich den Service Role Key finde, um ihn in n8ns `Supabase Api` Credential einzutragen.

So lernst du nebenbei, wie KI dich bei komplexeren Setup-Aufgaben unterstützt — eine Kern-Kompetenz für M4.

## 🧩 Die zwei Pipelines

Anders als bei den bisherigen Demos enthält dieser Workflow **zwei eigenständige, unverbundene Pipelines** in derselben Datei. Das ist das klassische RAG-Muster: Befüllen und Abfragen sind getrennte Lebenszyklen.

```
┌─────────────────────── 📥 INGESTION ────────────────────────┐
│  Form (PDF Upload) → Extract from File → Vector Store       │
│                              ↑                  ↑           │
│                       Default Data Loader  Embeddings OpenAI│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────── 💬 RETRIEVAL & CHAT ─────────────────┐
│  Chat Trigger → AI Agent                                    │
│                    ↑   ↘ (ai_tool)                          │
│         OpenRouter Chat   Vector Store (retrieve-as-tool)   │
│                                      ↑                      │
│                                Embeddings OpenAI            │
└─────────────────────────────────────────────────────────────┘
```

Die **Ingestion-Pipeline** läuft, wenn du im n8n-Formular eine PDF hochlädst — der Inhalt wird in `documents` geschrieben. Die **Chat-Pipeline** läuft, wann immer eine Chat-Nachricht eintrifft, und greift lesend auf dieselbe Tabelle zu.

## 🚀 Import & Setup

1. **Workflow importieren**: `workflow.json` über `Workflows → Add Workflow → Import from File`
2. **Supabase-Credential** anlegen und in **beiden** `Vector Store`-Nodes (Add + Get) auswählen
3. **OpenAI-Credential** anlegen und in **beiden** `Embeddings OpenAI`-Sub-Nodes auswählen (die importierte Datei zeigt zwei separate Referenzen — du kannst beide auf dieselbe Credential umstellen)
4. **OpenRouter-Credential** anlegen und im `OpenRouter Chat Model`-Sub-Node auswählen
5. **Modell wählen** (optional): Im `OpenRouter Chat Model`-Sub-Node ein Modell setzen, falls noch keines konfiguriert ist (z.B. `anthropic/claude-haiku-latest` oder `anthropic/claude-sonnet-4.6`)
6. **Workflow aktivieren** (Toggle oben rechts), damit Form- und Chat-Trigger live sind
7. **Test — Ingestion**:
   - Auf den `On form submission`-Node klicken → **Open form**
   - Eine PDF hochladen (z.B. ein Kapitel aus deinem Kursmaterial)
   - In Supabase prüfen, dass in `documents` neue Zeilen mit `embedding`-Vektor erscheinen
8. **Test — Chat**:
   - Auf den `When chat message received`-Node klicken → **Open chat**
   - Erst eine harmlose Frage stellen: *"Hallo, wer bist du?"* → der Agent sollte **kein** Tool nutzen
   - Dann eine inhaltliche Frage zum hochgeladenen PDF stellen → der Agent sollte den `Get Data from Supabase Vector Store`-Tool-Call auslösen und mit Kontext antworten

## 📤 Erwartetes Verhalten

- **Ingestion**: Pro Upload wird die PDF in mehrere Chunks zerlegt (Default Data Loader kümmert sich darum), jeder Chunk bekommt einen Embedding-Vektor (1536 Dimensionen bei `text-embedding-3-small`) und landet als Zeile in `documents`.
- **Chat ohne Wissensbedarf** (z.B. "Hallo"): Der Agent antwortet direkt, ohne Tool-Call. Im Execution-Log siehst du nur den `OpenRouter Chat Model`-Aufruf.
- **Chat mit Wissensbedarf** (z.B. "Was sagt Kapitel 3 über Tool-Use?"): Der Agent löst den `Get Data from Supabase Vector Store`-Tool-Call aus, bekommt die top-K relevantesten Chunks zurück und formuliert eine Antwort, die sich auf diese Chunks stützt.
- Der Agent hat **kein Memory** — Folgefragen verlieren den Kontext der vorherigen Antwort. Siehe Variationen.

## 💡 Variationen & Übungsideen

- **Conversation Memory ergänzen**: Der Agent vergisst nach jeder Frage den Kontext. Hänge einen `Window Buffer Memory`-Sub-Node an den Agent (Sub-Node-Connection-Slot **Memory**). Damit kann der Agent Folgefragen wie *"und was steht zu Tools im selben Kapitel?"* sinnvoll beantworten. Das ist die natürliche nächste Erweiterung — wird in der Live-Demo nachgezogen.
- **Multiple Files trennen**: Erweitere die Ingestion um ein zusätzliches Metadaten-Feld (z.B. `source` oder `chapter`) und filtere im Retrieval-Tool darauf, damit der Agent gezielt in einem Dokument suchen kann.
- **Tool-Description schärfen**: Die `toolDescription` am Vector Store entscheidet, ob der Agent das Tool nutzt. Experimentiere mit präziseren/laxeren Beschreibungen und beobachte, wie sich das Tool-Routing ändert.
- **System-Prompt am Agent setzen** (saubere Praxis): Der Agent läuft aktuell ohne expliziten System-Prompt. Gib ihm eine Rolle ("Du bist ein Tutor für den M4-Kurs … antworte nur basierend auf den gefundenen Chunks, sonst sag dass du es nicht weißt") und teste, ob er weniger halluziniert.
- **Embeddings-Modell wechseln**: Tausche `text-embedding-3-small` (1536 Dim.) gegen `text-embedding-3-large` (3072 Dim.) — **Achtung**: die `documents`-Tabelle muss die Dimension matchen, sonst stürzt der Insert ab. Gute Übung im Umgang mit Schema-Konsistenz.

---

📚 **Vertiefung**: Tiefergehende Erklärung des RAG-Patterns und der Agent-Architektur findest du in [docs/n8n_learning/llm_agent_tools_intro.md](../../../docs/n8n_learning/llm_agent_tools_intro.md) (Abschnitt 4.2).
