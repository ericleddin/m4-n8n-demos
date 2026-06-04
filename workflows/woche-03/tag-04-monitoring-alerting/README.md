# Tag 4: Monitoring & Alerting

Drei Demos zum operativen Betrieb von Workflows: strukturiertes **Logging** mit Kosten-Tracking (A), **Alerting** über den Error-Output eines Nodes (B) und das zentrale **Error-Workflow-Pattern** von n8n (C). Fokus ist Operations-Disziplin — Workflows beobachtbar machen und Fehler nicht still verschlucken, sondern melden.

## 📍 Architektur-Spektrum

**Workflow** — alle drei Demos sind deterministische Pipelines (`set`, `code`, `httpRequest`, `errorTrigger`, `supabase`). Demo A nutzt ein LLM nur als Daten-Step (der geloggt wird), es entscheidet nicht über den Ablauf.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- **Logging-Pattern** (A): pro Lauf einen strukturierten Eintrag bauen (Zeitstempel, Status, Dauer, Tokens) und in eine DB schreiben — Workflows werden beobachtbar
- **Kosten-Tracking** (A): aus der `usage`-Struktur der LLM-Antwort (`prompt_tokens`/`completion_tokens`) × Preis-pro-Token die Kosten je Call berechnen
- **Error-Output statt Crash** (B): einen Node mit `onError: continueErrorOutput` so verdrahten, dass ein Fehler auf den zweiten Output läuft und einen Alert-Pfad auslöst, statt den Workflow abzubrechen
- **Zentrales Error-Workflow-Pattern** (C): ein `errorTrigger`-Workflow, der über das Error-Workflow-Setting beliebig vielen anderen Workflows zugewiesen wird und bei deren Fehlern automatisch startet
- Datenbank-Schreiben aus n8n mit dem `supabase`-Node (A) und Alert-Mails per `httpRequest` gegen die Resend-API (B, C)
- Konzeptionell: der Unterschied zwischen **lokalem** Fehler-Handling (Error-Output am Node, B) und **zentralem** Fehler-Handling (ein Handler für viele Workflows, C) — und warum der `errorTrigger` nur bei aktivierten, automatisch getriggerten Workflows feuert, nicht bei manuellem „Execute"

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |
| Supabase | `Supabase API` | Supabase Dashboard → Project Settings → API |
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |

- **Demo A** braucht OpenRouter (LLM-Call) und Supabase (Log-Tabelle).
- **Demo B** und **Demo C** brauchen Resend (Alert-Mail).

### Community Nodes

Keine — nur Core-Nodes (`Manual Trigger`, `Schedule Trigger`, `Error Trigger`, `Set`, `Code`, `HTTP Request`, `Supabase`).

## 📦 Enthaltene Workflows

Drei eigenständige Demos zum selben Tagesthema (kein Haupt-/Bonus-Verhältnis). Demo C besteht aus einem zusammengehörigen Paar:

- **`workflow-a-logging-kosten-tracking.json`** — Happy-Path: ein echter LLM-Call, danach baut ein `code`-Node einen Log-Eintrag (Dauer, Tokens, Kosten) und schreibt ihn nach Supabase (`demo_logs`).
- **`workflow-b-alerting-bei-fehler.json`** — ein API-Call läuft bewusst auf eine 404-URL. Über `onError: continueErrorOutput` wird der Fehler abgefangen (statt zu crashen) und löst eine Alert-Mail aus.
- **`workflow-c-error-workflow-zentral.json`** — der **Handler**: startet über einen `errorTrigger`, baut aus dem Fehler-Kontext eine Alert-Mail und verschickt sie via Resend. Einmal gebaut, beliebig vielen Workflows zuweisbar.
- **`workflow-c-fehler-erzeuger.json`** — der **Auslöser** zu C: ein `scheduleTrigger` (jede Minute) ruft `https://httpstat.us/500` ohne Error-Handling → der Workflow schlägt fehl und triggert den zentralen Handler.

> **Wie das Paar in Demo C zusammenhängt:** In den Workflow-Settings des Fehler-Erzeugers ist unter „Error Workflow" der zentrale Workflow eingetragen. n8n speichert diese Verknüpfung über die **interne Workflow-ID**. Beim Import in deine eigene Instanz bekommt der zentrale Workflow eine **neue** ID — die exportierte Verknüpfung ist dann ungültig und muss einmalig neu gesetzt werden (Setup-Schritt 5).

## 🌐 Companion-Files

- **`data/demo_logs.sql`** — `CREATE TABLE`-Statement für die Log-Tabelle aus Demo A. Vor dem ersten Lauf im Supabase SQL Editor ausführen.

## 🚀 Import & Setup

1. **Alle vier JSON-Dateien importieren** über `Workflows → Add Workflow → Import from File`.
2. **Demo A — Tabelle anlegen**: `data/demo_logs.sql` im Supabase SQL Editor ausführen. Danach Supabase-Credential (`Supabase API`) anlegen und im Node `Log in Supabase schreiben` auswählen, sowie OpenRouter-Credential (`OpenRouter Api`) im Node `LLM Call (OpenRouter)`.
3. **Demo B — Empfänger setzen**: Resend-Credential (`HTTP Bearer Auth`) im Node `Alert-Mail (Resend)` auswählen und den Platzhalter `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` (Body-Feld `to`) durch deine E-Mail ersetzen. Absender `onboarding@resend.dev` ist der Resend-Test-Modus und kann so bleiben.
4. **Demo C — Empfänger setzen**: dasselbe Resend-Credential im Node `Alert-Mail (Resend)` des zentralen Workflows auswählen und dort ebenfalls `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` ersetzen.
5. **Demo C — Verknüpfung herstellen** (Kern der Demo): Fehler-Erzeuger öffnen → `Settings` (Drei-Punkte-Menü oben rechts) → unter `Error Workflow` den Workflow `W3T4 - Error Workflow (zentral)` auswählen. Ohne diesen Schritt läuft der Erzeuger zwar in den Fehler, der zentrale Workflow wird aber nicht benachrichtigt.
6. **Demo C — aktivieren**: den Fehler-Erzeuger über den „Active"-Toggle einschalten. Der `errorTrigger` feuert **nur** bei aktivierten, automatisch getriggerten Läufen — ein manueller „Execute Workflow" löst den Error-Workflow **nicht** aus.
7. **Test**:
   - **A** und **B** je über ihren `Manual Trigger` starten.
   - **C** läuft automatisch: warten, bis der Schedule (jede Minute) den Erzeuger startet.

## 📤 Erwartetes Verhalten

- **Demo A**: Der LLM-Call läuft, der `code`-Node berechnet Dauer (jetzt − `startTime`), Token-Verbrauch und Kosten. Geschrieben wird eine Zeile nach `demo_logs` mit `timestamp`, `node_name`, `status`, `duration_ms`, `tokens_used`. In der Supabase-Tabelle erscheint pro Lauf ein neuer Eintrag.
- **Demo B**: Der 404-Call schlägt fehl, läuft aber über den Error-Output weiter. Der `set`-Node sammelt Fehlermeldung, URL und Zeitstempel, der Resend-Node verschickt die Alert-Mail. Der Workflow endet **erfolgreich** — er hat den Fehler kontrolliert behandelt.
- **Demo C**: Sobald der Erzeuger aktiv ist, startet ihn der Schedule jede Minute. Der HTTP-500-Call wirft (kein Error-Handling) → der Lauf schlägt fehl → n8n startet automatisch den zugewiesenen Error-Workflow, dessen `errorTrigger` den Fehler-Kontext erhält (Workflow-Name, Fehlermeldung, Node, Link zum Lauf) und eine Alert-Mail verschickt.

> **Vor einem Vortrag**: Den Schedule in Demo C von „jede Minute" auf ein ruhigeres Intervall (z.B. stündlich) stellen oder den Erzeuger nach der Demo deaktivieren — sonst Dauerfeuer an Alert-Mails.

## 💡 Variationen & Übungsideen

- **Kosten persistieren** (A): Der `code`-Node berechnet bereits `cost_usd`, schreibt es aber nicht in die DB — die Tabelle hat dafür keine Spalte. Ergänze `cost_usd numeric` in `demo_logs` und ein entsprechendes Feld-Mapping im Supabase-Node, um Kosten dauerhaft auszuwerten.
- **Fehler mitloggen** (A→B): `demo_logs` hat eine `error_message`-Spalte, die der Happy-Path nicht nutzt. Kombiniere das Logging aus A mit dem Error-Output aus B, um auch fehlgeschlagene Läufe mit `status = 'error'` und Fehlertext zu protokollieren.
- **Alert-Kanal tauschen** (B/C): statt E-Mail an einen Slack- oder Discord-Webhook posten — nur der letzte Node ändert sich.
- **Ein Handler für viele** (C): einen zweiten produktiven Workflow demselben zentralen Error-Workflow zuweisen und zeigen, dass ein Handler für beliebig viele Workflows reicht.
- **Saubere Praxis**: lokales (B) und zentrales (C) Fehler-Handling gegenüberstellen — wann reicht ein Error-Output am Node, wann braucht es den zentralen Alert über alle Workflows hinweg?
