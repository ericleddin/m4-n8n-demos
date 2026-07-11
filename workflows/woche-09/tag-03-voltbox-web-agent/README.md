# Tag 3: Voltbox Web-Agent

Der Voltbox-Support-Agent (RAG, Bestellstatus, Ticket, Eskalation) wird über einen `Webhook` als JSON-API bereitgestellt und von einem externen, statischen Chat-Widget aufgerufen. Didaktischer Fokus: einen n8n-Agenten aus dem n8n-Chat lösen und als echte Backend-API hinter eine eigene Web-Oberfläche hängen — inklusive CORS, Session-Memory über den Payload und sichtbaren Tool-Schritten im Frontend.

## 📍 Architektur-Spektrum

**Agent** — ein autonomer `agent`-Node wählt selbst aus vier Tools (Wissensdatenbank, Bestellstatus, Ticket, Eskalation). Webhook und `Respond to Webhook` sind nur die Transport-Schicht; die Entscheidungen trifft der Agent.

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                                    ▲
```

## 🎯 Was du lernst

- Einen Agenten als **HTTP-API** exponieren: `Webhook` (POST `voltbox-agent`, `responseMode: responseNode`) → Agent → `Respond to Webhook` gibt strukturiertes JSON (`{ reply, steps[] }`) zurück
- **CORS** für einen Browser-Client öffnen (`allowedOrigins` am Webhook), damit ein statisches Widget direkt per `fetch()` zugreifen kann
- **Session-Memory über den Payload steuern**: `memoryBufferWindow` mit `sessionKey` aus `body.sessionId` — das Frontend hält die `sessionId` in `localStorage`, der Agent behält so den Verlauf pro Browser
- Vier Tools kombinieren: `search_knowledge_base` (Supabase Vector Store, RAG), `bestellstatus_abfragen` und `Ticket_erstellen` (`supabaseTool`), `Eskalation_an_Mensch` (`httpRequestTool` gegen die Resend-API)
- Die Tool-Aufrufe transparent machen: `intermediateSteps` aus der Agent-Antwort ins JSON übernehmen und im Widget als „🔧 Agent-Schritte" anzeigen
- Konzeptionell: der Unterschied zwischen einem Agenten im n8n-Chat-Trigger und einem Agenten als **produktiver API-Endpoint** hinter einer eigenen Oberfläche

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Wo im Setup | Key holen unter |
|---------|---------------------|-------------|------------------|
| OpenRouter (Chat `gpt-4o-mini`) | `OpenRouter Api` | `OpenRouter Chat Model` | https://openrouter.ai/keys |
| OpenAI (Embeddings) | `OpenAI` | `Embeddings OpenAI` (RAG) | https://platform.openai.com/api-keys |
| Supabase (pgvector + `orders`/`tickets`) | `Supabase API` | `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen` | https://supabase.com/dashboard → Project Settings → API |
| Resend (Eskalations-Mail) | `Header Auth` / `Bearer Auth` | `Eskalation_an_Mensch` (HTTP) | https://resend.com/api-keys |

Die Eskalation läuft bewusst über einen generischen `httpRequestTool` mit `httpBearerAuth` gegen `https://api.resend.com/emails` — kein Community-Node nötig.

### Community Nodes

Keine — `agent`, `vectorStoreSupabase`, `embeddingsOpenAi`, `supabaseTool`, `httpRequestTool`, `memoryBufferWindow` sind mitgelieferte LangChain-Nodes; `Webhook` und `Respond to Webhook` sind Core-Nodes.

### Geteilte Daten (aus Woche 6, Tag 3)

Kein eigener `data/`-Ordner — dieselbe Supabase-Basis und Wissensquelle wie der Support-Agent aus Woche 6:

- **Schema**: `documents` + `match_documents`, `orders` (`VB-10001`–`VB-10007`), `tickets` aus `../../woche-06/tag-03-support-agent/data/supabase_setup.sql`
- **Wissensquelle**: die 5 PDFs aus `../../woche-06/tag-03-support-agent/data/`, geladen über die Ingestion-Pipeline `../../woche-06/tag-03-support-agent-rag-optimiert/workflow-ingestion.json`

## 🌐 Companion-Files

- **`frontend/index.html`** — statisches Chat-Widget (Vanilla HTML/CSS/JS, kein Build-Step). Dark-Theme-Chat, persistente `sessionId` via `crypto.randomUUID()` in `localStorage` (Key `voltbox_session`), „Agent denkt …"-Indikator und ein aufklappbares Panel „🔧 Agent-Schritte", das die Tool-Aufrufe aus `steps[]` sichtbar macht. Ruft den Webhook direkt per `fetch()` auf. Deploybar als statische Seite (z.B. `npx vercel --prod`).

## 🚀 Import & Setup

1. **Schema & Wissensbasis sicherstellen**: Falls Woche 6 / Tag 3 noch nicht eingerichtet ist, `../../woche-06/tag-03-support-agent/data/supabase_setup.sql` ausführen und die PDFs über die Ingestion-Pipeline in `documents` laden.
2. **Workflow importieren**: `workflow.json` einlesen.
3. **Credentials zuweisen**: `OpenRouter Api` → `OpenRouter Chat Model`; `OpenAI` → `Embeddings OpenAI`; `Supabase API` → `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen`; `Bearer Auth` (Resend-Key) → `Eskalation_an_Mensch`.
4. **Empfänger setzen**: im Node `Eskalation_an_Mensch` das `to`-Feld — Platzhalter `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` durch deine Empfänger-Adresse ersetzen.
5. **Workflow aktivieren**: Der `Webhook` liefert seine produktive URL `<host>/webhook/voltbox-agent` erst, wenn der Workflow **aktiv** ist.
6. **Frontend verbinden**: `frontend/index.html` in einem Editor öffnen und die Konstante `WEBHOOK_URL` — Platzhalter `<<REPLACE_WITH_YOUR_N8N_HOST>>` — durch den Host deiner n8n-Instanz ersetzen, sodass `<host>/webhook/voltbox-agent` herauskommt.
7. **Test**: `index.html` lokal im Browser öffnen und z.B. fragen „Wie lange dauert der Versand?" (RAG), „Wo ist meine Bestellung VB-10002?" (Bestellstatus) oder „Meine Powerstation ist defekt und ich brauche dringend Hilfe" (Ticket + Eskalation). Das Panel „🔧 Agent-Schritte" zeigt die genutzten Tools.

## 📤 Erwartetes Verhalten

Das Widget schickt `{ message, sessionId }` an den Webhook. Der Agent wählt pro Anfrage die passende Quelle: Wissensfragen über `search_knowledge_base` (RAG), konkrete Bestellungen (Nummer `VB-XXXXX`) über `bestellstatus_abfragen`, Grundwissen (Support-Zeiten, Kontakt) direkt aus dem System-Prompt. Ungelöste Anliegen führen zu einem Ticket (`Ticket_erstellen`, ID wird genannt), dringende Fälle zusätzlich zu einer Eskalations-Mail über Resend. Die Antwort kommt als `{ reply, steps[] }` zurück; dank der `sessionId` aus `localStorage` behält der Agent den Gesprächsverlauf über mehrere Nachrichten und Reloads hinweg.

## 💡 Variationen & Übungsideen

- Das Widget auf Vercel deployen und gegen die aktive n8n-Instanz laufen lassen — der Agent als echter, öffentlich erreichbarer Support-Bot
- Die `steps[]`-Anzeige um Latenz/Token-Angaben erweitern, um Tool-Nutzung und Kosten pro Turn sichtbar zu machen
- Ein Rate-Limit oder eine einfache Auth vor dem Webhook ergänzen, statt CORS komplett offen (`*`) zu lassen
- Streaming statt einer einzelnen JSON-Antwort einbauen, damit die Antwort im Widget tokenweise erscheint
- **Saubere Praxis**: `allowedOrigins` am Webhook von `*` auf die konkrete Frontend-Domain einschränken und den Webhook mit einem Token absichern (im Widget als Header mitschicken), damit nicht jeder mit der URL den Agenten — inklusive Ticket- und Mail-Versand — auslösen kann

---

Tiefergehende Erklärung zu Agenten und Tool-Use in `docs/n8n_learning/llm_agent_tools_intro.md`. Der zugrunde liegende Single-Agent (ohne Web-Frontend) liegt in `../../woche-06/tag-03-support-agent/`.
