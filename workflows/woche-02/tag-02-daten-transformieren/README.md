# Tag 2: Daten transformieren

Ein Workflow, der Kundenfeedback aus Supabase lädt, auf relevante Beschwerden filtert, sie zu einem Textblock aggregiert und Claude (via OpenRouter) eine Zusammenfassung mit den drei häufigsten Problemen schreiben lässt — anschließend per Resend als Report verschickt. Didaktischer Fokus: ein LLM als **Verarbeitungsschritt innerhalb einer deterministischen Pipeline** einsetzen, nicht als Entscheider.

## 📍 Architektur-Spektrum

**Workflow** — alle Schritte (Query → Filter → Aggregation → LLM-Call → Mail) sind vorab festgelegt; der LLM-Call ist ein gekapselter Transformationsschritt, kein Agent.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- Daten via `supabase`-Node aus einer Tabelle laden (`getAll`)
- Items mit dem `filter`-Node nach numerischen und Datums-Bedingungen filtern, inkl. relative Zeitangaben (`$now.minus({days: 7})`)
- Mehrere Items im `code`-Node (JavaScript) zu einem aggregierten Textblock zusammenführen
- LLM-Integration via LangChain: `chainLlm` als Hauptknoten mit `lmChatOpenRouter` als Sub-Node
- HTTP-Request gegen die Resend-API mit Bearer-Auth
- Konzeptionell: **LLM als Datenverarbeitungs-Step** in einem ansonsten deterministischen Pipeline-Flow — die Modell-Wahl und der Prompt sind hardcoded, das Modell entscheidet *nicht* über den Ablauf (Abgrenzung zum Agent)

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| Supabase | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |

### Community Nodes

Keine — nur Core- und LangChain-Nodes (`Manual Trigger`, `Supabase`, `Filter`, `Code`, `Basic LLM Chain`, `OpenRouter Chat Model`, `HTTP Request`).

### Supabase: Tabelle anlegen

Der Workflow liest aus einer Tabelle `feedback`. Falls du Supabase neu einrichtest:

1. Projekt anlegen unter https://supabase.com → **New Project**
2. Im Projekt-Dashboard auf **SQL Editor** und folgendes Schema ausführen:

```sql
   create table feedback (
     id uuid default gen_random_uuid() primary key,
     kunde text not null,
     bewertung int not null,
     kommentar text,
     erstellt_am timestamptz default now()
   );
```

3. **Demo-Daten einfügen**, damit der Filter (Bewertung ≤ 3, jünger als 7 Tage) etwas findet. Die Datensätze nutzen `now() - interval '...'` und bleiben damit zeitlos relevant:

```sql
   insert into feedback (kunde, bewertung, kommentar, erstellt_am) values
     ('Anna Müller',     2, 'Lieferung hat 3 Wochen gedauert',           now() - interval '1 day'),
     ('Thomas Berger',   1, 'Produkt war beschädigt angekommen',         now() - interval '2 days'),
     ('Sarah Klein',     3, 'Kundenservice hat nicht zurückgerufen',     now() - interval '3 days'),
     ('Michael Wagner',  1, 'Falsche Ware geliefert',                    now() - interval '4 days'),
     ('Lisa Hofmann',    2, 'Verpackung war zerrissen',                  now() - interval '5 days'),
     ('Peter Schmidt',   3, 'App funktioniert nicht richtig',            now() - interval '6 days'),
     ('Julia Bauer',     1, 'Produkt entspricht nicht der Beschreibung', now() - interval '7 days'),
     ('Stefan Maier',    5, 'Alles super, sehr schnelle Lieferung',      now() - interval '1 day'),
     ('Laura Fischer',   4, 'Guter Service, kleine Verzögerung',         now() - interval '2 days'),
     ('Klaus Werner',    2, 'Rückgabe war sehr kompliziert',             now() - interval '8 days'),
     ('Monika Schulz',   1, 'Nie wieder, komplette Katastrophe',         now() - interval '9 days'),
     ('Hans Zimmermann', 3, 'Mittelmäßige Qualität für den Preis',       now() - interval '2 days');
```

4. **API-URL** und **Service Role Key** findest du unter **Project Settings → API** — beides brauchst du gleich für das `Supabase Api` Credential in n8n.

**💡 Tipp: KI als Setup-Assistent nutzen**

Falls dir das Setup unklar ist, kannst du Claude (oder eine andere KI) fragen:

> Ich nutze Supabase zum ersten Mal und brauche eine Tabelle `feedback` mit den Spalten `id` (UUID, Primary Key, default `gen_random_uuid()`), `kunde` (text, not null), `bewertung` (int, not null), `kommentar` (text, nullable), `erstellt_am` (timestamptz, default `now()`). Erkläre mir Schritt für Schritt:
> 1. Wie ich ein neues Supabase-Projekt anlege,
> 2. Wie ich die Tabelle via SQL Editor erstelle,
> 3. Wie ich ein paar Demo-Datensätze mit `now() - interval '...'` einfüge, damit der Datums-Filter dauerhaft etwas findet,
> 4. Wo ich die API-URL und den Service Role Key finde, um sie in n8n unter `Supabase Api` zu hinterlegen.

So lernst du nebenbei, wie KI dich bei Setup-Aufgaben unterstützt — eine Kern-Kompetenz für M4.

## 🚀 Import & Setup

1. **Workflow importieren**: `workflow.json` über `Workflows → Add Workflow → Import from File` einlesen
2. **Supabase-Credential** anlegen und im Node `Feedback abfragen` auswählen
3. **OpenRouter-Credential** anlegen und im `OpenRouter Chat Model`-Node auswählen
4. **Resend-Credential** anlegen (`HTTP Bearer Auth` mit deinem Resend-API-Key) und im `Email: Feedback`-Node auswählen
5. **Notification-Empfänger eintragen**: im `Email: Feedback`-Node das `to`-Body-Parameter von `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` auf deine eigene E-Mail-Adresse ändern
6. **Test**: auf `When clicking 'Execute workflow'` klicken → `Execute workflow`

## 📤 Erwartetes Verhalten

1. Der Workflow lädt **alle** Zeilen aus `feedback`
2. Der `Filter`-Node lässt nur Zeilen passieren, die **beide** Bedingungen erfüllen: `bewertung <= 3` **und** `erstellt_am` jünger als 7 Tage
3. Der `Code`-Node verkettet die verbleibenden Items zu einem Textblock (`Feedback 1 (DD.MM.YYYY, Bewertung: X): "..."` pro Eintrag)
4. `Basic LLM Chain` schickt diesen Block mit der Instruktion "Fasse … zusammen und identifiziere die 3 häufigsten Probleme" an Claude Haiku via OpenRouter
5. Die Antwort wird als E-Mail-Body an deine Notification-Adresse versendet, Betreff: `Kundenfeedback Analyse – DD.MM.YYYY`

Wenn keine Zeile die Filter-Bedingung erfüllt, läuft der LLM-Call mit leerem Textblock — der spätere Report ist dann inhaltsleer. Siehe Variationen.

## 💡 Variationen & Übungsideen

- **Leeren Filter abfangen** (saubere Praxis): einen `if`-Node nach dem `Filter` einbauen, der den LLM-Call überspringt, wenn keine Items übrig sind — spart Tokens und vermeidet sinnlose Mails.
- **Kundenname personalisieren**: Die `kunde`-Spalte ist im Schema vorhanden, wird im Workflow aber nicht genutzt. Erweitere den `code`-Node so, dass der Kundenname mit ausgegeben wird, und passe den LLM-Prompt an, sodass der Report Kunden namentlich benennt ("Anna Müller (2 Sterne): ..."). Übung im Umgang mit Daten, die schon da sind, aber bisher nicht durchgereicht werden.
- Die Filter-Bedingungen aus hardcoded Werten (`3`, `7 Tage`) in `set`-Node-Variablen oder Workflow-Settings auslagern, damit sie ohne Code-Edit anpassbar sind.
- Statt Resend-Mail das Ergebnis zusätzlich in eine Supabase-Tabelle `reports` schreiben — so entsteht ein Audit-Trail.
- Den `Manual Trigger` durch einen `Schedule Trigger` ersetzen (täglich, wöchentlich) und den Workflow als automatisierten Reporting-Job laufen lassen.
- Das Modell von `claude-haiku-latest` auf ein größeres Modell wechseln und den Output qualitativ vergleichen — bei welcher Beschwerden-Menge lohnt sich der Wechsel?
