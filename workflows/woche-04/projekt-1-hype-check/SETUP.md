# Hype-Check – Setup

> ⚠️ **Ist-Zustand-Hinweis:** Diese Anleitung beschreibt ein generalisiertes Setup.
> Du brauchst **eigene Accounts** bei den unten genannten Diensten und eine
> **eigene n8n-Instanz** (Cloud oder self-hosted). Es gibt keine geteilte
> Infrastruktur – alle URLs, Keys und Adressen sind durch deine eigenen zu ersetzen.

## Voraussetzungen

| Dienst | Wofür | Kosten |
|---|---|---|
| n8n-Instanz | Workflow-Ausführung | Cloud-Trial oder self-hosted |
| [OpenRouter](https://openrouter.ai) | LLM-Aufrufe (`openai/gpt-4o-mini`) | Pay-per-Use, Cent-Beträge |
| [Tavily](https://tavily.com) | Websuche zur Verifikation | Free Tier: 1000 Calls/Monat |
| [Resend](https://resend.com) | Ergebnis-Mail | Free Tier; Test-Mode reicht |
| [Supabase](https://supabase.com) | Logging | Free Tier |

## Schritte

### 1. Supabase-Tabelle anlegen

Im Supabase SQL Editor deines Projekts:

```sql
create table if not exists public.hype_check_runs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  input_type text not null,
  input_kurz text,
  quelle_url text,
  hype_score int,
  verifikation_aktiv boolean,
  status text not null,
  fehler text
);
alter table public.hype_check_runs enable row level security;
```

Hinweis: Der n8n-Supabase-Node nutzt den Service-Role-Key und umgeht RLS –
Inserts funktionieren ohne zusätzliche Policy.

### 2. Workflow importieren

n8n → Workflows → **Import from File** → `workflow.json`

### 3. Credentials anlegen und zuweisen

| Credential-Typ in n8n | Dienst | Zuweisen in Nodes |
|---|---|---|
| OpenRouter | OpenRouter API Key | „LLM 1: Claims extrahieren", „LLM 2: Einordnung erstellen" |
| Bearer Auth | Tavily API Key | „Tavily: Claim recherchieren" |
| Bearer Auth | Resend API Key | „Resend: Ergebnis-Mail" |
| Supabase | Projekt-URL + Service Key | alle drei „Log:"-Nodes |

### 4. Platzhalter ersetzen

Im Node **„Resend: Ergebnis-Mail"**: `DEINE-RESEND-VERIFIZIERTE-ADRESSE` durch die
E-Mail-Adresse ersetzen, mit der dein Resend-Account verifiziert ist.
(Resend Test-Mode sendet ausschließlich an diese Adresse, Absender bleibt
`onboarding@resend.dev`.)

### 5. Workflow publizieren

Workflow **aktivieren/publizieren**. Wichtig: Nach jeder Änderung erneut
publizieren – der Produktiv-Webhook bedient nur die publizierte Version.

### 6. Frontend konfigurieren

In `frontend/index.html` die Konstante anpassen:

```javascript
const WEBHOOK_URL = 'https://DEINE-N8N-INSTANZ/webhook/hype-check';
```

Danach die Datei lokal im Browser öffnen – kein Server nötig
(CORS ist über den Webhook-Header abgedeckt).

### 7. Smoke-Test

```bash
curl -X POST https://DEINE-N8N-INSTANZ/webhook/hype-check \
  -H "Content-Type: application/json" \
  -d '{"input": "BREAKING: KI ersetzt bis 2027 alle Bürojobs!", "email": ""}'
```

Erwartung: JSON mit `claims`, `hype_score` und `takeaways` nach ~20–40 s.
Danach die Fälle aus `TESTING.md` durchgehen.
