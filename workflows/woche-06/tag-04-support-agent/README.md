# Tag 4: Support-Agent – Prompt-Testing & Storno-Freigabe

Derselbe 5-Tool-Voltbox-Agent wie an Tag 3, hier in **zwei Rollen**: `workflow.json` führt zuverlässig den **Freigabe-Schritt vor der destruktiven Aktion Stornierung** vor (Agent nennt Bestellnummer + Artikel → fragt nach Bestätigung → storniert erst nach „Ja"), `workflow-prompt-testing.json` ist die **Spielwiese**, in der du den System-Prompt iterierst und beobachtest, wie sich Tool-Routing und genau dieser Freigabe-Guard verändern. Didaktischer Fokus: Wie der Prompt die Tool-Wahl steuert — und wie man das reproduzierbar testet statt „sieht gut aus".

## 📍 Architektur-Spektrum

**Agent** — ein `agent`-Node wählt autonom aus fünf Tools. Der Prompt steuert die Auswahl (inkl. der Storno-Freigabe), nicht eine fest verdrahtete Logik; genau deshalb ist er das Objekt, an dem hier getestet wird.

```
Prompt → Custom GPT → Workflow → [Agent] → Multi-Agent
                                    ▲
```

## 🎯 Was du lernst

- Den **Freigabe-Schritt vor einer destruktiven Aktion** vorführen: `bestellung_stornieren` setzt `orders.status` auf `storniert` erst, nachdem der Agent Bestellnummer + Artikel genannt und der Kunde ausdrücklich „Ja" bestätigt hat — ein mehrstufiger Bestätigungs-Dialog statt sofortiger Ausführung
- Eine **Prompt-Regressions-Suite** aufbauen: pro Quelle/Tool eine feste Testfrage (RAG, API, Grundwissen, Ticket, Eskalation, Storno) und nach jeder Prompt-Änderung durchspielen, um Regressionen sofort zu sehen
- **A/B am gleichen Agent**: die unveränderte Referenz (`workflow.json`) gegen die Sandbox-Kopie (`workflow-prompt-testing.json`) stellen und dieselbe Frage in beiden vergleichen, ohne die Referenz zu verlieren
- Dass die fünf Tools rein über **Tool-Beschreibung + System-Prompt** geroutet werden: RAG (`vectorStoreSupabase` als `retrieve-as-tool`), API-Read (`supabaseTool` `getAll` auf `orders`), Ticket-Insert und Storno-Update (`supabaseTool`) sowie die echte Mail-Eskalation (`resendTool`)
- Konzeptionell: dass ein **prompt-basierter Guard** für destruktive Aktionen nicht garantiert hält — in der Testing-Kopie hebelst du ihn mit einer einzigen Umformulierung aus; genau das motiviert, in Produktion einen deterministischen Freigabe-Schritt (Human-in-the-Loop) statt einer Prompt-Regel zu setzen

## 🧰 Voraussetzungen

### Datenbank & Wissensbasis (aus Tag 3)

Dieser Workflow ist die **Konsumenten-Seite** — er enthält keine Ingestion-Pipeline und setzt voraus, dass die Supabase-Tabellen aus Tag 3 existieren und befüllt sind:

- `data/supabase_setup.sql` aus `workflows/woche-06/tag-03-support-agent/` im Supabase-SQL-Editor ausführen (legt `documents`, `match_documents`, `orders` mit 7 Demo-Bestellungen `VB-10001`–`VB-10007` und `tickets` an)
- Die 5 Voltbox-PDFs aus demselben `data/`-Ordner über die Ingestion-Pipeline von Tag 3 in `documents` laden — sonst liefert `search_knowledge_base` keine Treffer

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenAI (Chat `gpt-4o-mini`) | `OpenAI` (Basis-URL ggf. → OpenRouter) | https://platform.openai.com/api-keys |
| OpenAI (Embeddings `text-embedding-3-small`) | `OpenAI` | https://platform.openai.com/api-keys |
| Supabase (`documents`/`orders`/`tickets`) | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| Resend (Eskalations-Mail) | `Resend API` | https://resend.com/api-keys |

Chat-Modell und Embeddings sind beide vom n8n-Typ `OpenAI`. Im Kurs läuft das Chat-Modell über **OpenRouter** (Basis-URL der Credential auf `https://openrouter.ai/api/v1`), die Embeddings über **echtes OpenAI** — `text-embedding-3-small` liefert die 1536 Dimensionen, auf die `documents.embedding` ausgelegt ist. Wer es einfacher mag, nutzt ein einziges echtes OpenAI-Credential für beide.

### Community Nodes

- **`n8n-nodes-resend`** (Resend) — liefert den `resendTool`-Node für `Eskalation_an_Mensch`. In n8n unter `Settings → Community Nodes → Install` mit dem Paketnamen `n8n-nodes-resend` installieren.

Alle übrigen Nodes sind Core- bzw. mitgelieferte LangChain-Nodes.

## 📦 Workflow-Varianten

- **`workflow.json`** — die **Referenz / Storno-Freigabe-Demo**: behält den getunten System-Prompt. Starte sie, um den Freigabe-Flow vor der Stornierung wie vorgesehen ablaufen zu sehen — sie bleibt dein funktionierender Vergleichsstand.
- **`workflow-prompt-testing.json`** — die **Prompt-Spielwiese**: hier änderst du den System-Prompt und vergleichst das Verhalten gegen die Referenz. Architektonisch dieselbe Position (Agent) mit denselben fünf Tools.

Beim Import sind beide **identisch** (gleicher Agent, gleicher Prompt) — der Unterschied ist die *Rolle*: In der Referenz lässt du den Prompt in Ruhe und führst den Freigabe-Flow vor; in der Kopie experimentierst du. So bleibt immer ein funktionierender Referenzstand erhalten, auch wenn du den Guard in der Kopie zerlegst.

## 🚀 Import & Setup

1. **Voraussetzung Tag 3**: Stelle sicher, dass `supabase_setup.sql` ausgeführt und die 5 PDFs ingestet sind (siehe „Voraussetzungen"). Ohne befüllte `documents` antwortet der RAG-Pfad leer.
2. **Beide Workflows importieren**: `workflow.json` und `workflow-prompt-testing.json` über `Workflows → Add Workflow → Import from File` einlesen.
3. **Resend-Community-Node installieren**: `Settings → Community Nodes → Install` → Paketname `n8n-nodes-resend`.
4. **Credentials zuweisen** (in **beiden** Workflows — nach dem Import sind die Nodes ohne Credential):
   - `OpenAI` (Chat, ggf. OpenRouter-Basis-URL) → Node `OpenAI Chat Model`
   - `OpenAI` (Embeddings) → Node `Embeddings OpenAI`
   - `Supabase API` → `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen`, `bestellung_stornieren`
   - `Resend API` → `Eskalation_an_Mensch`
5. **Eskalations-Empfänger setzen** (in beiden Workflows): im Node `Eskalation_an_Mensch` das `to`-Feld von `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` auf deine eigene Adresse ändern. `from` bleibt `onboarding@resend.dev` (Resend-Sandbox; für eigene Absender eine Domain in Resend verifizieren).
6. **Test**: unten im Editor auf `Chat` (Node `Kundenanfrage (Chat)`) klicken. In `workflow.json` spielst du die Test-Fragen-Suite aus „Erwartetes Verhalten" durch — besonders den Storno-Freigabe-Dialog. In `workflow-prompt-testing.json` änderst du dann den System-Prompt und führst dieselbe Suite erneut aus.

## 📤 Erwartetes Verhalten

Der Agent wählt pro Frage anhand der Tool-Beschreibungen und der Routing-Regeln im System-Prompt die passende Quelle. Im Zentrum von `workflow.json` steht der **Storno-Freigabe-Dialog** — eine destruktive Aktion, die erst nach ausdrücklicher Bestätigung ausgeführt wird:

> **Du**: „Bitte storniere meine Bestellung VB-10006."
> **Agent**: nennt `VB-10006` (Solarpanel SP100, KFZ-Ladekabel) und fragt ausdrücklich nach Bestätigung — storniert noch **nicht**.
> **Du**: „Ja"
> **Agent**: setzt `orders.status` auf `storniert` und bestätigt. (Bei „Nein"/Unklarheit: keine Stornierung.)

Die übrige **Test-Fragen-Suite** deckt die restlichen Tools plus das prompt-interne Grundwissen ab — sie ist dein Messinstrument: Nach jeder Prompt-Änderung in der Kopie spielst du sie durch und prüfst im Execution-Log, ob noch das richtige Tool greift.

- **RAG** (`search_knowledge_base`): „Ab welchem Bestellwert ist der Versand innerhalb Deutschlands kostenlos?" → 50 €
- **Bestellstatus** (`bestellstatus_abfragen`): „Wo ist meine Bestellung VB-10001?" → Anna Becker, Versandt, Tracking `DHL-00347711992`; fehlt die Nummer, fragt der Agent zuerst danach
- **Grundwissen** (System-Prompt, **kein Tool**): „Wie erreiche ich den Support?" → support@voltbox.de, Mo–Fr 9–17 Uhr
- **Ticket** (`Ticket_erstellen`): „Mein Display zeigt einen Fehler, den ich nicht lösen kann — bitte kümmert euch darum, meine Bestellnummer ist VB-10004." → Agent legt ein Ticket an und nennt die Ticket-ID
- **Eskalation** (`Eskalation_an_Mensch`): „Meine Max 1500 (VB-10002) kam defekt an und ich brauche dringend Ersatz — das ist eine Beschwerde!" → dringend → Ticket **und** echte Eskalations-Mail

Der didaktische Kern: `workflow.json` zeigt den Freigabe-Schritt so, wie er laufen soll. Verändere in `workflow-prompt-testing.json` die Bestätigungs-Regel und spiele den Storno-Dialog erneut durch — du siehst direkt, wie fragil ein prompt-basierter Guard ist.

## 💡 Variationen & Übungsideen

- **Storno-Guard aushebeln**: entferne in der Kopie probeweise die Regel „Storniere ERST nach klarem ‚Ja'" und prüfe, ob der Agent jetzt ohne Rückfrage storniert — der direkte Beleg, warum ein Prompt-Gate für destruktive Aktionen nicht reicht
- Lege deine Test-Fragen-Suite als feste Liste an und führe sie als **Vorher/Nachher-Vergleich** bei jeder Prompt-Iteration durch — eine simple Regressions-Disziplin, die ad-hoc-Testen schlägt
- Verschlechtere bewusst eine Tool-Beschreibung (z.B. `search_knowledge_base` vage formulieren) und beobachte, wie der Agent bei Wissensfragen das falsche Tool greift oder gar keins — dann reparieren
- **Saubere Praxis**: ersetze den prompt-basierten Storno-Guard durch einen echten **Human-in-the-Loop** (Sub-Workflow mit Send-and-Wait-/Approval-Node), sodass die Stornierung unabhängig vom Modell erst nach expliziter Freigabe ausführt — und versioniere deine Prompt-Iterationen (z.B. `# v2 – 2026-06-25` als Kommentar oben im System-Prompt)

---

Tiefergehende Erklärung zu Agents, Tools und Tool-Routing in `docs/n8n_learning/llm_agent_tools_intro.md`.
