# Tag 3: Support-Agent – RAG, API & System Prompt

Derselbe Voltbox-Agent wie an Tag 1/2, jetzt mit **echten Datenquellen** statt Code-Mocks: Der Agent unterscheidet drei Wissensquellen — **RAG** (Wissensdatenbank), **API/DB** (Bestellstatus) und **System-Prompt** (Grundwissen) — und nutzt zusätzlich zwei **Action-Tools** (Ticket in die DB schreiben, Eskalation per Mail). Didaktischer Fokus: Wann braucht eine Frage welche Quelle, und wie befüllt man die RAG-Basis über eine Ingestion-Pipeline.

## 📍 Architektur-Spektrum

**Agent** — ein `agent`-Node wählt autonom aus vier Tools. Die Datei enthält zusätzlich einen deterministischen **Ingestion-Strang** (Form → Extract → Vector-Store-Insert); dieser ist für sich genommen ein `Workflow`, dient aber nur dazu, die Wissensbasis des Agents zu befüllen. Die Headline-Position ist deshalb der Agent.

```
Prompt → Custom GPT → Workflow → [Agent] → Multi-Agent
                                    ▲
```

## 🎯 Was du lernst

- Drei Wissensquellen an einen Agent anbinden und gegeneinander abgrenzen: **RAG** (`vectorStoreSupabase` im Modus `retrieve-as-tool` → unstrukturiertes Wissen aus `documents`), **API/DB** (`supabaseTool` → strukturierte Echtzeitdaten aus `orders`) und **System-Prompt** (stabiles Grundwissen ohne Tool-Aufruf)
- Eine **Ingestion-Pipeline** bauen: `formTrigger` (PDF-Upload) → `extractFromFile` → `documentDefaultDataLoader` (Chunking) → `embeddingsOpenAi` → `vectorStoreSupabase` (Insert in `documents` / `match_documents`)
- **Action-Tools** statt nur lesender Tools: `Ticket_erstellen` schreibt eine Zeile in die `tickets`-Tabelle, `Eskalation_an_Mensch` schickt über `resendTool` eine echte E-Mail
- Dass **Embedding-Dimension und Tabelle exakt zusammenpassen** müssen: `text-embedding-3-small` liefert 1536 Dimensionen, und genau darauf ist die `documents.embedding`-Spalte (`vector(1536)`) ausgelegt — sonst schlagen Insert und Retrieval fehl
- Konzeptionell: Warum dieselbe Anfrage je nach Typ eine andere Quelle braucht — und wie Routing-Regeln im System-Prompt zusammen mit den Tool-Beschreibungen die autonome Tool-Wahl steuern

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter (Chat-Modell `gpt-4o-mini`) | `OpenAI` (Basis-URL → OpenRouter) | https://openrouter.ai/keys |
| OpenAI (Embeddings `text-embedding-3-small`) | `OpenAI` | https://platform.openai.com/api-keys |
| Supabase (pgvector + `orders`/`tickets`) | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| Resend (Eskalations-Mail) | `Resend API` | https://resend.com/api-keys |

Chat-Modell und Embeddings sind beide vom n8n-Typ `OpenAI`, aber bewusst **zwei getrennte Credentials**: Das Chat-Modell läuft über **OpenRouter** (Credential `OpenRouter account`, in der OpenAI-Credential die Basis-URL auf `https://openrouter.ai/api/v1` setzen), die Embeddings über **echtes OpenAI** (Credential `OpenAI account`), da `text-embedding-3-small` direkt von OpenAI kommt. Wer es einfacher mag, kann auch ein einziges echtes OpenAI-Credential für beide Nodes verwenden — `gpt-4o-mini` ist ein echtes OpenAI-Modell.

### Community Nodes

- **`n8n-nodes-resend`** (Resend) — liefert den `resendTool`-Node für `Eskalation_an_Mensch`. In n8n unter `Settings → Community Nodes → Install` mit dem Paketnamen `n8n-nodes-resend` installieren.

Alle übrigen Nodes sind Core- bzw. mitgelieferte LangChain-Nodes.

## 🌐 Companion-Files

- **`data/supabase_setup.sql`** — legt alle drei Datenquellen an: `documents` + Funktion `match_documents` (RAG-Vektorstore, Dimension 1536), `orders` mit 7 Demo-Bestellungen (`VB-10001`–`VB-10007`) und `tickets` (Ziel des Action-Tools)
- **`data/Voltbox_FAQ.pdf`** — Nutzung & Pflege (Laden, Lagerung, X-Boost, Fehlerbehebung)
- **`data/Voltbox_Produktkatalog.pdf`** — Modelle (Mini 300 / Pro 800 / Max 1500), technische Daten, Solarpanels, Zubehör
- **`data/Voltbox_Rueckgabe_und_Garantie.pdf`** — Widerrufsrecht (30 Tage), Garantie (5 Jahre), RMA-Prozess
- **`data/Voltbox_Versand_und_Lieferung.pdf`** — Versandkosten, Lieferzeiten, Lieferregionen (DE/AT/CH)
- **`data/Voltbox_Zahlung_und_Rechnung.pdf`** — Zahlungsarten, Ratenkauf (ab 200 €), Stornierung

Die 5 PDFs sind die Demo-Wissensquelle für RAG — sie werden über den Ingestion-Form in den Vektorstore geladen (siehe Setup).

## 🚀 Import & Setup

1. **Datenbank vorbereiten**: `data/supabase_setup.sql` im Supabase-SQL-Editor ausführen. Das Skript aktiviert die `vector`-Extension (pgvector) und legt `documents`, `match_documents`, `orders` (inkl. 7 Demo-Bestellungen) und `tickets` an.
2. **Workflow importieren**: `workflow.json` über `Workflows → Add Workflow → Import from File` einlesen.
3. **Resend-Community-Node installieren**: `Settings → Community Nodes → Install` → Paketname `n8n-nodes-resend`.
4. **Credentials zuweisen** (alle Nodes sind nach dem Import ohne Credential):
   - `OpenRouter account` (Typ `OpenAI`) → Node `OpenAI Chat Model`
   - `OpenAI account` (Typ `OpenAI`) → beide `Embeddings OpenAI`-Nodes (Ingestion + RAG-Abfrage)
   - `Supabase account` (Typ `Supabase API`) → `Add to Supabase Vector Store`, `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen`
   - `Resend` (Typ `Resend API`) → `Eskalation_an_Mensch`
5. **Eskalations-Empfänger setzen**: im Node `Eskalation_an_Mensch` das `to`-Feld von `your-support@example.com` auf deine eigene Adresse ändern. Das `from` bleibt `onboarding@resend.dev` (Resend-Test-Mode/Sandbox; für eigene Absender eine Domain in Resend verifizieren).
6. **Wissensbasis befüllen**: den Form-Trigger `Voltbox-Dokument hochladen` öffnen (Test-URL im Node) und die **5 PDFs aus `data/` einzeln** hochladen — pro Upload genau ein PDF. Jeder Upload wird gechunkt, embedded und in `documents` gespeichert.
7. **Test**: unten im Editor auf `Chat` (Node `Kundenanfrage (Chat)`) klicken und die Fragen aus „Erwartetes Verhalten" durchspielen.

## 📤 Erwartetes Verhalten

Die Demo hat zwei Stränge: Der **Ingestion-Strang** befüllt einmalig die RAG-Basis (5 PDFs → `documents`). Im **Chat** wählt der Agent dann pro Frage anhand der Tool-Beschreibungen und der Routing-Regeln im System-Prompt die passende Quelle:

- **Wissensfrage** (Produkt, Versand, Rückgabe, Zahlung, Pflege) → `search_knowledge_base` (RAG aus `documents`)
- **Konkrete Bestellung mit Nummer** (`VB-XXXXX`) → `bestellstatus_abfragen` (DB-Abfrage auf `orders`); fehlt die Nummer, fragt der Agent zuerst danach
- **Grundwissen** (Support-Kontakt, Firmenname) → direkt aus dem System-Prompt, **ohne Tool**
- **Nicht lösbar / Kundenwunsch** → `Ticket_erstellen` (Insert in `tickets`, Agent nennt die Ticket-ID)
- **Dringend / Beschwerde / Defekt** → `Eskalation_an_Mensch` (echte Resend-Mail an deine Adresse), zusätzlich zum Ticket

**Testfragen je Quelle:**

- **RAG** (`search_knowledge_base`):
  - „Ab welchem Bestellwert ist der Versand innerhalb Deutschlands kostenlos?" → 50 €
  - „Wie lange habe ich Rückgaberecht, und wie lange gilt die Garantie auf eine Powerstation?" → 30 Tage Rückgabe, 5 Jahre Garantie
  - „Welches Modell empfehlt ihr fürs Camping mit Kühlbox und Werkzeug?" → Pro 800
  - „Darf ich die Powerstation im Flugzeug mitnehmen?" → nein (über 100 Wh = Gefahrgut)
- **orders** (`bestellstatus_abfragen`):
  - „Wo ist meine Bestellung VB-10001?" → Anna Becker, Versandt, Tracking `DHL-00347711992`, vsl. Lieferung 23.06.2026
  - „Wie ist der Status von VB-10002?" → In Bearbeitung
  - „Wo bleibt meine Bestellung?" (ohne Nummer) → Agent fragt nach der Bestellnummer
- **Grundwissen** (System-Prompt, kein Tool):
  - „Wie erreiche ich den Support?" → support@voltbox.de, Mo–Fr 9–17 Uhr
- **Ticket** (`Ticket_erstellen`):
  - „Mein Display zeigt einen Fehler, den ich nicht lösen kann — bitte kümmert euch darum, meine Bestellnummer ist VB-10004." → Agent legt ein Ticket an und nennt die Ticket-ID
- **Eskalation** (`Eskalation_an_Mensch`):
  - „Meine Max 1500 (VB-10002) kam defekt an und ich brauche dringend Ersatz — das ist eine Beschwerde!" → dringend → Ticket **und** echte Eskalations-Mail an die `to`-Adresse

## 💡 Variationen & Übungsideen

- Ein weiteres PDF hochladen (z.B. ein Datenblatt) und beobachten, dass der Agent es ohne Code-Änderung nutzt — allein durch erneutes Ingestion
- Im `Default Data Loader` Chunk-Größe und Overlap variieren und vergleichen, wie sich die Trefferqualität von `search_knowledge_base` ändert
- Pro Dokument ein `metadata`-Feld setzen (z.B. `{"quelle": "versand"}`) und `match_documents` per `filter` auf eine Quelle einschränken
- **Saubere Praxis**: den `chatTrigger` und den Ingestion-`formTrigger` für den öffentlichen Einsatz absichern (Authentifizierung), damit nicht jeder anonym den Agent nutzen oder Dokumente in die Wissensbasis schreiben kann — und den Sandbox-Absender `onboarding@resend.dev` durch eine in Resend verifizierte eigene Domain ersetzen

---

Tiefergehende Erklärung zu Agents, Tools und RAG in `docs/n8n_learning/llm_agent_tools_intro.md`. Die Grundlagen des Supabase-Vektorstores zeigt die Demo `workflows/woche-02/tag-03-rag-supabase/`.
