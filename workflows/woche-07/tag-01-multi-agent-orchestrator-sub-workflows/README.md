# Tag 1: Multi-Agent-Orchestrator (Sub-Workflows)

Ein Orchestrator-Agent beantwortet keine Fachfragen selbst, sondern routet jede Anfrage per Call-Workflow-Tool an einen von zwei spezialisierten Sub-Agents (Auskunft/read vs. Aktion/write), die als eigenständige, isoliert testbare Workflows liegen. Didaktischer Fokus: ein Monolith-Agent wird in ein koordiniertes Agenten-Team zerlegt — Trennung von Routing und Fachkompetenz.

## 📍 Architektur-Spektrum

**Multi-Agent** — drei `agent`-Nodes kooperieren: ein Orchestrator entscheidet autonom über das Routing, zwei Spezialisten-Agents arbeiten in separaten Workflows mit je eigenem Modell, Memory-Kontext und Tool-Set. Die Koordination läuft über `toolWorkflow` (Call-Workflow-Tool).

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                                              ▲
```

## 🎯 Was du lernst

- Einen Agenten als Tool eines anderen Agenten aufrufen: `toolWorkflow` (Call-Workflow-Tool) übergibt `query` an einen Sub-Workflow mit `executeWorkflowTrigger` und gibt dessen Antwort zurück
- Routing von Fachkompetenz trennen: der Orchestrator-Prompt klassifiziert nur (Auskunft vs. Aktion) und delegiert — die eigentliche Arbeit machen die Spezialisten
- Read-Agent vs. Write-Agent: der Auskunfts-Agent kombiniert RAG (`vectorStoreSupabase` als Tool) + strukturierte API-Abfrage (`supabaseTool` auf `orders`), der Aktions-Agent kapselt die Seiteneffekt-Tools (`tickets` schreiben, Resend-Mail, `orders` stornieren)
- Warum Zustand im Orchestrator lebt: `memoryBufferWindow` hält den Gesprächsverlauf, die Sub-Workflows sind zustandslos — die mehrstufige Storno-Bestätigung steuert deshalb der Orchestrator, nicht der Aktions-Agent
- Konzeptionell: wann ein Multi-Agent-Setup einem Single-Agent mit vielen Tools überlegen ist (isolierte Testbarkeit, Wiederverwendung, getrennte Modelle/Prompts pro Rolle) — und wann es überengineert ist

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter/OpenAI (Chat `gpt-4o-mini`) | `OpenAI` | https://openrouter.ai/keys bzw. https://platform.openai.com/api-keys |
| OpenAI (Embeddings `text-embedding-3-small`) | `OpenAI` | https://platform.openai.com/api-keys |
| Supabase (pgvector + `orders`/`tickets`) | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| Resend (Eskalations-Mail) | `Resend API` | https://resend.com/api-keys |

Chat-Modell und Embeddings sind beide vom n8n-Typ `OpenAI`. Im Export läuft das Chat-Modell über OpenRouter, die Embeddings über echtes OpenAI — wer es einfacher mag, nutzt ein einziges echtes OpenAI-Credential für beide (`gpt-4o-mini` ist ein echtes OpenAI-Modell). Details zur OpenRouter-Variante siehe `../../woche-06/tag-03-support-agent/README.md`.

### Community Nodes

- **`n8n-nodes-resend`** (Resend) — liefert den `resendTool`-Node für `Eskalation_an_Mensch` im Aktions-Agent. In n8n unter `Settings → Community Nodes → Install` mit dem Paketnamen `n8n-nodes-resend` installieren.

Alle übrigen Nodes sind Core- bzw. mitgelieferte LangChain-Nodes (`agent`, `toolWorkflow`, `executeWorkflowTrigger`, `lmChatOpenAi`, `memoryBufferWindow`, `vectorStoreSupabase`, `embeddingsOpenAi`, `supabaseTool`).

### Geteilte Daten (aus Woche 6, Tag 3)

Dieses Demo hat **keinen eigenen `data/`-Ordner** — es nutzt denselben Supabase-Store und dieselbe Wissensquelle wie der Support-Agent aus Woche 6:

- **Schema**: `documents` + `match_documents`, `orders` (Demo-Bestellungen `VB-10001`–`VB-10007`) und `tickets` aus `../../woche-06/tag-03-support-agent/data/supabase_setup.sql`
- **Wissensquelle**: die 5 PDFs aus `../../woche-06/tag-03-support-agent/data/` — über die Ingestion-Pipeline `../../woche-06/tag-03-support-agent-rag-optimiert/workflow-ingestion.json` in den `documents`-Store geladen

## 📦 Workflow-Varianten

Drei Workflows bilden zusammen die Demo — alle drei importieren und (in dieser Reihenfolge) verknüpfen:

- **`workflow.json`** — der **Orchestrator** (Hauptworkflow). Chat-Trigger → Orchestrator-Agent mit `memoryBufferWindow` und zwei `toolWorkflow`-Nodes (`Auskunfts_Agent`, `Aktions_Agent`). Zur Veranschaulichung zeigt der Canvas die beiden Sub-Agents zusätzlich als (nicht verdrahtete) Vorschau-Inseln daneben.
- **`subworkflow-auskunfts-agent.json`** — der **Auskunfts-Agent** (read-only): `executeWorkflowTrigger` → Agent mit RAG-Tool `search_knowledge_base` (Supabase Vector Store) + `bestellstatus_abfragen` (`orders`).
- **`subworkflow-aktions-agent.json`** — der **Aktions-Agent** (write): `executeWorkflowTrigger` → Agent mit `Ticket_erstellen` (`tickets`), `Eskalation_an_Mensch` (Resend) + `bestellung_stornieren` (`orders`).

## 🚀 Import & Setup

1. **Schema & Wissensbasis sicherstellen**: Falls Woche 6 / Tag 3 noch nicht eingerichtet ist, `../../woche-06/tag-03-support-agent/data/supabase_setup.sql` im Supabase-SQL-Editor ausführen (legt `documents`, `orders`, `tickets` an) und die 5 PDFs über die Ingestion-Pipeline in `documents` laden.
2. **Sub-Workflows zuerst importieren**: `subworkflow-auskunfts-agent.json` und `subworkflow-aktions-agent.json` über `Workflows → Add Workflow → Import from File` einlesen — sie müssen existieren, bevor der Orchestrator sie referenzieren kann.
3. **Orchestrator importieren**: `workflow.json` einlesen.
4. **Sub-Workflows neu verknüpfen** (wichtig): Die zwei `toolWorkflow`-Nodes (`Auskunfts_Agent`, `Aktions_Agent`) zeigen nach dem Import auf interne Workflow-IDs der Quell-Instanz. In jedem der beiden Nodes unter `Workflow` den jeweils importierten Sub-Workflow neu auswählen.
5. **Credentials zuweisen** (nach dem Import sind die Nodes ohne Credential):
   - `OpenAI`/OpenRouter → alle `lmChatOpenAi`-Nodes (Orchestrator + beide Sub-Agents)
   - `OpenAI` → die `Embeddings OpenAI`-Node im Auskunfts-Agent
   - `Supabase API` → `search_knowledge_base`, `bestellstatus_abfragen` (Auskunfts-Agent) sowie `Ticket_erstellen`, `bestellung_stornieren` (Aktions-Agent)
   - `Resend API` → `Eskalation_an_Mensch` (Aktions-Agent)
6. **Platzhalter ersetzen**: Im Aktions-Agent (und in der Vorschau im Orchestrator) `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` im `Eskalation_an_Mensch`-Node durch deine Empfänger-Adresse für Eskalations-Mails ersetzen.
7. **Test**: Im Orchestrator den Chat öffnen und eine der Beispielfragen aus der Sticky Note stellen (z.B. „Wo ist meine Bestellung VB-10001?" → Auskunft, „Bitte storniere VB-10002" → Aktion mit Bestätigung).

## 📤 Erwartetes Verhalten

- Eine Wissens- oder Statusfrage („Wie lange dauert der Versand?", „Wo ist VB-10001?") routet der Orchestrator an den **Auskunfts-Agent**: der zieht RAG-Treffer bzw. die Bestellzeile und antwortet read-only.
- Ein Aktionswunsch („Meine Powerstation ist defekt, ich brauche dringend Hilfe!") routet an den **Aktions-Agent**, der ein Ticket anlegt und/oder eine Eskalations-Mail über Resend verschickt und die Ticket-ID zurückmeldet.
- **Stornierung** ist zweistufig: Bei „Bitte storniere VB-10002" fragt der **Orchestrator selbst** zuerst nach ausdrücklicher Bestätigung und nennt die Bestellnummer — erst nach einem klaren „Ja" im nächsten Turn ruft er den Aktions-Agent mit einem bestätigten Storno-Auftrag auf. Der Kontext über beide Turns lebt im `memoryBufferWindow` des Orchestrators, weil die Sub-Workflows zustandslos sind.
- Der Orchestrator gibt die Antwort des Spezialisten unverändert und auf Deutsch zurück; er beantwortet selbst nichts fachlich.

## 💡 Variationen & Übungsideen

- Einen dritten Spezialisten andocken (z.B. einen „Retouren-Agent" als weiterer Sub-Workflow) und im Orchestrator als drittes Call-Workflow-Tool plus eine Routing-Zeile im Prompt ergänzen — zeigt, wie das Muster horizontal skaliert
- Pro Sub-Agent ein anderes Modell/Temperatur wählen (z.B. günstiges Modell für reine Auskunft, stärkeres für den Aktions-Agent) — der Sinn getrennter `lmChatOpenAi`-Nodes wird messbar
- Den Auskunfts-Agent isoliert testen: über seinen `executeWorkflowTrigger` direkt mit einem `query` ausführen, ohne den Orchestrator — demonstriert die isolierte Testbarkeit des Musters
- Mit demselben Anliegen den Single-Agent aus `../../woche-06/tag-03-support-agent/` und diesen Orchestrator vergleichen: wann lohnt die Aufteilung, wann ist sie Overhead?
- **Saubere Praxis**: Den Storno-Sonderfall nicht nur per Prompt absichern — den `bestellung_stornieren`-Aufruf zusätzlich an ein bestätigtes Flag im Handoff koppeln (siehe Tag 2), damit eine Prompt-Schwäche nicht zu einer ungewollten irreversiblen Aktion führt

---

Tiefergehende Erklärung zu Agenten und Tool-Use in `docs/n8n_learning/llm_agent_tools_intro.md`; die Einordnung von Multi-Agent-Mustern (Router-Agent vs. echtes Multi-Agent-Framework) in `docs/n8n_learning/ai_agent_ecosystem_overview.md` (Abschnitt 5). Der zugrundeliegende Single-Agent: `../../woche-06/tag-03-support-agent/`.
