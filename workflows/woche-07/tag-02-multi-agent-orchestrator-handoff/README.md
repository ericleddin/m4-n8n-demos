# Tag 2: Multi-Agent-Orchestrator (Handoff)

Dieselbe Orchestrator-Architektur wie Tag 1, aber die Übergabe an den Auskunfts-Agent ist ein **strukturiertes Handoff**: statt nur einen rohen Text-String durchzureichen, baut der Orchestrator gezielt drei Felder (`anfrage`, `sprache`, `prioritaet`), die der Spezialist auswertet. Didaktischer Fokus: Message Passing zwischen Agenten — die richtigen Felder gezielt übergeben statt der ganzen Konversations-History.

## 📍 Architektur-Spektrum

**Multi-Agent** — wie Tag 1 ein Orchestrator plus zwei Spezialisten-Agents in eigenen Workflows. Der Unterschied liegt im Kommunikationsmuster, nicht in der Topologie: der Orchestrator klassifiziert die Anfrage und füllt ein typisiertes Handoff-Objekt.

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                                              ▲
```

## 🎯 Was du lernst

- Strukturiertes Handoff statt String-Durchreichung: der `executeWorkflowTrigger` des Auskunfts-Agents definiert die Input-Felder `anfrage`, `sprache`, `prioritaet`; der Orchestrator füllt sie per `$fromAI()` im `toolWorkflow`-Node
- Message Passing als bewusste Design-Entscheidung: der Orchestrator erkennt Sprache und Priorität und formuliert die `anfrage` neu — der Empfänger bekommt genau die Felder, die er nutzt, nicht die rohe History
- Felder, die im Empfänger ankommen: der Auskunfts-Agent-Prompt liest `{{ $json.sprache }}` (antwortet in derselben Sprache) und `{{ $json.prioritaet }}` (Hinweis auf den Support-Kanal bei „hoch")
- Asymmetrie mit Absicht: der Auskunfts-Agent bekommt drei strukturierte Felder, der Aktions-Agent bewusst nur ein einfaches `query` — Struktur lohnt sich dort, wo der Empfänger die Felder wirklich verwertet
- Konzeptionell: der Trade-off zwischen einem schlanken String-Interface (Tag 1) und einem typisierten Kontrakt (Tag 2) — mehr Robustheit und Mehrsprachigkeit gegen mehr Kopplung zwischen Orchestrator und Spezialist

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter/OpenAI (Chat `gpt-4o-mini`) | `OpenAI` | https://openrouter.ai/keys bzw. https://platform.openai.com/api-keys |
| OpenAI (Embeddings `text-embedding-3-small`) | `OpenAI` | https://platform.openai.com/api-keys |
| Supabase (pgvector + `orders`/`tickets`) | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| Resend (Eskalations-Mail) | `Resend API` | https://resend.com/api-keys |

Credential-Setup identisch zu Tag 1 (`../tag-01-multi-agent-orchestrator-sub-workflows/README.md`): Chat und Embeddings beide vom Typ `OpenAI`, optional getrennt OpenRouter (Chat) / OpenAI (Embeddings).

### Community Nodes

- **`n8n-nodes-resend`** (Resend) — liefert den `resendTool`-Node für `Eskalation_an_Mensch` im Aktions-Agent (`Settings → Community Nodes → Install`, Paketname `n8n-nodes-resend`).

Alle übrigen Nodes sind Core- bzw. mitgelieferte LangChain-Nodes.

### Geteilte Daten (aus Woche 6, Tag 3)

Kein eigener `data/`-Ordner — gleicher Supabase-Store und gleiche Wissensquelle wie Tag 1 und der Support-Agent aus Woche 6:

- **Schema**: `documents` + `match_documents`, `orders` (`VB-10001`–`VB-10007`), `tickets` aus `../../woche-06/tag-03-support-agent/data/supabase_setup.sql`
- **Wissensquelle**: die 5 PDFs aus `../../woche-06/tag-03-support-agent/data/`, geladen über `../../woche-06/tag-03-support-agent-rag-optimiert/workflow-ingestion.json`

## 📦 Workflow-Varianten

- **`workflow.json`** — der **Orchestrator** (Hauptworkflow). Routet UND baut das Handoff: für `Auskunfts_Agent` füllt er per `$fromAI()` die Felder `anfrage`, `sprache`, `prioritaet`; für `Aktions_Agent` nur ein einfaches `query`.
- **`subworkflow-auskunfts-agent.json`** — der **Auskunfts-Agent** (read-only): `executeWorkflowTrigger` mit den drei Input-Feldern → Agent mit `search_knowledge_base` (RAG) + `bestellstatus_abfragen` (`orders`). Der Prompt wertet `sprache` und `prioritaet` aus.
- **`subworkflow-aktions-agent.json`** — der **Aktions-Agent** (write): `executeWorkflowTrigger` mit einfachem `query` → Agent mit `Ticket_erstellen`, `Eskalation_an_Mensch` (Resend), `bestellung_stornieren`.

## 🚀 Import & Setup

1. **Schema & Wissensbasis sicherstellen**: wie Tag 1 — `../../woche-06/tag-03-support-agent/data/supabase_setup.sql` ausführen und die PDFs in `documents` laden (entfällt, wenn Tag 1 bereits eingerichtet wurde; beide Demos teilen denselben Store).
2. **Sub-Workflows zuerst importieren**: `subworkflow-auskunfts-agent.json` und `subworkflow-aktions-agent.json` einlesen.
3. **Orchestrator importieren**: `workflow.json` einlesen.
4. **Sub-Workflows neu verknüpfen**: in den `toolWorkflow`-Nodes `Auskunfts_Agent` und `Aktions_Agent` den jeweils importierten Sub-Workflow neu auswählen. Prüfen, dass im `Auskunfts_Agent`-Node die drei Felder (`anfrage`, `sprache`, `prioritaet`) im Mapping erscheinen und per `$fromAI()` gefüllt werden.
5. **Credentials zuweisen**:
   - `OpenAI`/OpenRouter → alle `lmChatOpenAi`-Nodes
   - `OpenAI` → die `Embeddings OpenAI`-Node im Auskunfts-Agent
   - `Supabase API` → `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen`, `bestellung_stornieren`
   - `Resend API` → `Eskalation_an_Mensch`
6. **Platzhalter ersetzen**: `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` im `Eskalation_an_Mensch`-Node des Aktions-Agents durch deine Empfänger-Adresse ersetzen.
7. **Test**: Im Orchestrator den Chat öffnen. Eine englischsprachige oder dringende Anfrage stellen (z.B. „My power station is defective, I need help urgently!") und beobachten, dass der Auskunfts-Agent in derselben Sprache antwortet und bei hoher Priorität auf den Support-Kanal hinweist.

## 📤 Erwartetes Verhalten

- Bei einer Auskunfts-/Statusfrage baut der Orchestrator das Handoff: er bestimmt `sprache` aus der Kundennachricht, klassifiziert `prioritaet` (`hoch` bei Dringlichkeit/Beschwerde/Defekt, sonst `normal`) und formuliert die `anfrage` klar. Diese drei Felder gehen an den Auskunfts-Agent.
- Der Auskunfts-Agent **antwortet in der übergebenen Sprache** (deutsche Frage → deutsche Antwort, englische → englische) und hängt bei `prioritaet=hoch` einen Hinweis auf `support@voltbox.de` an — gesteuert allein über die Handoff-Felder, nicht über die rohe History.
- Aktionswünsche (Ticket, Eskalation) gehen mit einfachem `query` an den Aktions-Agent — identisch zu Tag 1.
- **Stornierung** läuft wie in Tag 1 zweistufig über den Orchestrator (Bestätigung im `memoryBufferWindow`, Storno-Aufruf erst nach klarem „Ja").

## 💡 Variationen & Übungsideen

- Ein viertes Handoff-Feld ergänzen (z.B. `kundentyp` „Privat"/„Gewerbe") — im `executeWorkflowTrigger` als Input definieren, im Orchestrator-Tool per `$fromAI()` füllen und im Agent-Prompt auswerten
- Mit einer englischen und einer deutschen Variante derselben Frage testen, dass `sprache` korrekt durchgereicht wird — der sichtbarste Effekt des strukturierten Handoffs
- Das Handoff-Muster auch auf den Aktions-Agent übertragen (z.B. Feld `bestaetigt: true/false` für den Storno) und mit dem bewusst einfachen `query`-Interface aus diesem Demo vergleichen — wann zahlt Struktur, wann ist sie Overhead?
- Tag 1 und Tag 2 direkt nebeneinander laufen lassen: dieselbe mehrsprachige/dringende Anfrage an beide Orchestratoren, um den Unterschied String-Durchreichung vs. typisiertes Handoff zu erleben
- **Saubere Praxis**: Die Handoff-Felder typisieren und validieren — z.B. `prioritaet` auf `normal`/`hoch` beschränken (im Prompt erzwingen oder per nachgelagertem `set`/`if` prüfen), damit der Spezialist sich auf einen festen Wertebereich verlassen kann statt auf freien LLM-Text

---

Tiefergehende Erklärung zu Agenten und Tool-Use in `docs/n8n_learning/llm_agent_tools_intro.md`; zur Einordnung von Multi-Agent-Mustern `docs/n8n_learning/ai_agent_ecosystem_overview.md` (Abschnitt 5). Das String-basierte Pendant: `../tag-01-multi-agent-orchestrator-sub-workflows/`.
