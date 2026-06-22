# Tag 2: Support-Agent – Tools & Memory

Derselbe Voltbox-Agent wie an Tag 1, jetzt mit **vier Tools** (FAQ, Bestellstatus, Ticket, Eskalation per E-Mail) und **Memory** für Folgefragen. Didaktischer Fokus: Die Tool-**Beschreibung** steuert die autonome Tool-Wahl, und Memory macht mehrstufige Dialoge möglich.

## 📍 Architektur-Spektrum

**Agent** — ein `agent`-Node wählt aus vier Tools autonom aus. Die Tool-Beschreibung (nicht eine fest verdrahtete Logik) bestimmt, welches Tool zum Einsatz kommt.

```
Prompt → Custom GPT → Workflow → [Agent] → Multi-Agent
                                    ▲
```

## 🎯 Was du lernst

- Mehrere Tools an einen Agent hängen (`toolCode` für FAQ/Bestellstatus/Ticket, `resendTool` für die E-Mail-Eskalation) und die Auswahl per **Tool-Beschreibung + System-Prompt** steuern
- Den Unterschied zwischen **Mock-Tools** (Bestellstatus, Ticket — fester JS-Code) und einer **echten Aktion** (`Eskalation_an_Mensch` schickt eine reale Resend-Mail)
- **Conversation Memory** (`memoryBufferWindow`) anbinden, damit Folgefragen den Kontext kennen
- In der Variante: **persistente Memory** (`memoryPostgresChat` → Supabase), die Sessions und n8n-Neustarts überlebt
- Konzeptionell: warum eine präzise Tool-Beschreibung die Zuverlässigkeit der Tool-Wahl bestimmt — und wie man beobachtet, ob der Agent das richtige Tool greift

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenAI | `OpenAI` | https://platform.openai.com/api-keys |
| Resend | `Resend API` | https://resend.com/api-keys |
| Postgres (Supabase) — nur `workflow-persistent-memory.json` | `Postgres` | https://supabase.com/dashboard → Project Settings → Database |

Der `OpenAI Chat Model`-Node ist der native OpenAI-Node; alternativ ein OpenAI-kompatibler Anbieter wie **OpenRouter** über die Basis-URL der Credential (so läuft der Kurs).

### Community Nodes

- **`n8n-nodes-resend`** (Resend) — liefert den `resendTool`-Node für `Eskalation_an_Mensch`. In n8n unter `Settings → Community Nodes → Install` mit dem Paketnamen `n8n-nodes-resend` installieren.

Alle übrigen Nodes sind Core- bzw. mitgelieferte LangChain-Nodes.

## 📦 Workflow-Varianten

- **`workflow.json`** — Hauptversion mit `Conversation Memory` (In-RAM Window Buffer, 10 Nachrichten). Der Verlauf gilt nur für die laufende n8n-Session und ist nach einem Neustart weg.
- **`workflow-persistent-memory.json`** — identischer Agent, aber `Persistent Memory` über `Postgres Chat Memory` (Supabase). Der Verlauf wird in der Tabelle `n8n_chat_histories` gespeichert und überlebt Sessions sowie n8n-Neustarts. Architektonisch dieselbe Position (Agent) — nur die Memory-Schicht unterscheidet sich.

Die Tabelle `n8n_chat_histories` wird vom `Postgres Chat Memory`-Node **automatisch angelegt** — kein manuelles `CREATE TABLE` nötig, du brauchst nur eine Postgres-Verbindung zu deiner Supabase-DB.

## 🚀 Import & Setup

1. **Workflows importieren**: `workflow.json` und `workflow-persistent-memory.json` über `Workflows → Add Workflow → Import from File` einlesen
2. **Resend-Community-Node installieren**: `Settings → Community Nodes → Install` → Paketname `n8n-nodes-resend`
3. **OpenAI-Credential** anlegen und im Node `OpenAI Chat Model` (in beiden Workflows) auswählen
4. **Resend-Credential** (`Resend API`) anlegen und im Node `Eskalation_an_Mensch` (in beiden Workflows) auswählen
5. **Empfänger-E-Mail eintragen**: im Node `Eskalation_an_Mensch` das `to`-Feld von `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` auf deine eigene Adresse ändern (in beiden Workflows). `from` bleibt `onboarding@resend.dev` (Resend-Sandbox; für eigene Domains in Resend verifizieren)
6. **Nur für `workflow-persistent-memory.json`**: ein `Postgres`-Credential zu deiner Supabase-DB anlegen (Verbindungsdaten unter Project Settings → Database) und im Node `Persistent Memory` auswählen
7. **Test**: unten im Editor auf `Chat` klicken und die Folgefrage-Sequenz aus „Erwartetes Verhalten" durchspielen

## 📤 Erwartetes Verhalten

Der Agent wählt das Tool anhand der Beschreibungen und Regeln im System-Prompt:

- **Info-Frage** (Versand, Zahlung, …) → `FAQ_Suche`
- **Konkrete Bestellung** → `Bestellstatus_pruefen` (Mock, kennt die Nummern 10001–10004; fehlt die Nummer, fragt der Agent zuerst danach)
- **Nicht dringendes Problem für einen Menschen** → `Ticket_erstellen` (Mock, gibt eine `VB-…`-Ticketnummer zurück)
- **Dringend / Beschwerde / ausdrücklicher Wunsch nach einem Menschen** → `Eskalation_an_Mensch` (echter Resend-Versand an deine Adresse)

**Memory-Test**: erst „Wo ist Bestellung 10001?", dann „Und wann kommt sie an?" — dank Memory nutzt der Agent die Bestellnummer aus dem Verlauf, ohne erneut zu fragen. Bei `workflow.json` lebt dieser Verlauf nur in der laufenden Session; bei `workflow-persistent-memory.json` bleibt er in Supabase erhalten, sodass der Agent den Verlauf auch nach einem n8n-Neustart noch kennt.

`Bestellstatus_pruefen` und `Ticket_erstellen` sind bewusst Code-Mocks — in Tag 3 werden sie durch eine echte Datenquelle bzw. API ersetzt.

## 💡 Variationen & Übungsideen

- Stelle `Bestellstatus_pruefen` oder `Ticket_erstellen` vom Mock auf einen echten DB-/API-Call um (Vorgriff auf Tag 3) und vergleiche, ob die Tool-Wahl gleich bleibt
- Ergänze ein fünftes Tool (z.B. „Retoure anstoßen") und beobachte, wie allein die Tool-Beschreibung die Auswahl steuert
- Variiere `contextWindowLength` der `Conversation Memory` und finde heraus, ab wann der Agent frühere Nachrichten „vergisst"
- **Saubere Praxis**: in `workflow-persistent-memory.json` einen `sessionKey` pro Kunde setzen, damit sich die Verläufe verschiedener Nutzer nicht vermischen — und den `chatTrigger` für den öffentlichen Einsatz absichern

---

Tiefergehende Erklärung zu Agents, Tools und Memory in `docs/n8n_learning/llm_agent_tools_intro.md`.
