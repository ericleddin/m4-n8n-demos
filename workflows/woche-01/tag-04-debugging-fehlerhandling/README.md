# Tag 4: Debugging & Fehlerhandling

Robuster Daily-News-Workflow, der fünf RSS-Feeds parallel abruft, einzelne Feed-Ausfälle abfängt und separat meldet, alte Artikel filtert und nur bei genügend Inhalt ein zusammengefasstes HTML-Briefing per Email versendet.

## 📍 Architektur-Spektrum

**Workflow** — komplex, aber durchgehend deterministisch. Mehrere Verzweigungen, ein LLM-Step zur Zusammenfassung, kein agentisches Verhalten.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- **Per-Node-Error-Handling** mit `onError: continueErrorOutput` — jeder Feed bekommt einen Erfolgs- und einen Fehler-Branch, der Workflow läuft auch bei Teil-Ausfällen weiter
- **Mehrere Datenströme zusammenführen** mit dem `Merge`-Node (fünf Eingänge auf einen Stream)
- **Bedingte Verzweigungen**: `Filter`-Node für Zeit-Cutoff (nur Artikel der letzten 24 h) und `If`-Node für Schwellwert-Check (mindestens 3 Artikel)
- **Aggregation** vor LLM-Calls: der `Aggregate`-Node bündelt mehrere Items zu einer Liste, damit ein einziger LLM-Prompt alle News bekommt
- **Schedule-Trigger** für zeitgesteuerte Workflows (täglich 8 Uhr)
- Pattern für **resiliente Multi-Source-Pipelines**: bei Ausfall einzelner Quellen weiterlaufen statt komplett scheitern

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |

Die fünf RSS-Feeds (TechCrunch, Heise, MIT Technology Review, Wired, The Decoder) benötigen keine Authentifizierung.

### Community Nodes

Keine — `@n8n/n8n-nodes-langchain.chainLlm` und `@n8n/n8n-nodes-langchain.lmChatOpenRouter` sind Teil der LangChain-Integration in der n8n-Core-Distribution.

## 🚀 Import & Setup

1. **Workflow importieren**: in n8n auf `Workflows → Add Workflow → Import from File` und `workflow.json` auswählen
2. **OpenRouter-Credential anlegen**:
   - `Credentials → Add Credential → OpenRouter Api`
   - API-Key aus https://openrouter.ai/keys eintragen
   - Im Node "OpenRouter Chat Model" als Credential auswählen
3. **Resend-Credential anlegen**:
   - `Credentials → Add Credential → HTTP Bearer Auth`
   - API-Key aus https://resend.com/api-keys als Bearer-Token eintragen
   - In **allen sieben** Email-Nodes als Credential auswählen: `Email: Daily News`, `Email: Zu wenig KI-News heute`, sowie die fünf Feed-Fehler-Emails (`Email: techcrunch Fehler`, `Email: MIT Fehler`, `Email: Wired Fehler`, `Email: Decoder Fehler`, `Email: Heise Fehler`)
   - Die `to`-Adressen in den JSON-Bodies auf deine eigene Email anpassen
4. **Test**: Workflow manuell ausführen (`Execute workflow`) — der Schedule-Trigger feuert sonst erst um 8 Uhr morgens

## 📤 Erwartetes Verhalten

Beim Trigger (täglich 8 Uhr oder manuell) läuft die Pipeline:

1. **5 RSS-Feeds** werden parallel abgerufen (TechCrunch, Heise, MIT, Wired, Decoder)
2. **Pro Feed**: bei Erfolg → in den Merge-Node; bei Fehler (z.B. 404) → individuelle Fehler-Email an dich
3. **Merge** kombiniert alle erfolgreichen Feeds zu einem Stream
4. **Filter** verwirft alle Artikel, deren `pubDate` älter als 24 Stunden ist
5. **If < 3**: weniger als 3 aktuelle Artikel → Warn-Email statt Briefing; sonst weiter
6. **Aggregate** bündelt Titel und Links in eine Liste
7. **Basic LLM Chain** (mit OpenRouter Chat Model, `gpt-4o-mini`) fasst jede News in zwei Sätzen zusammen und gibt HTML zurück
8. **html body** (Set-Node) verpackt das HTML in ein Briefing-Layout mit Header und Datum
9. **Email: Daily News** versendet das fertige Briefing als HTML-Email

## 💡 Variationen & Übungsideen

- Schreib die fünf Feed-Fehler-Email-Nodes in **einen einzigen** Email-Node um, der den Feed-Namen dynamisch in Subject und Body einfügt — klassisches DRY-Refactor
- Ergänze einen Slack-Webhook neben der Fehler-Email für sofortige Benachrichtigung bei Feed-Ausfällen
- Erweitere den Schwellwert-Check: bei `< 5` Artikeln zusätzliche Backup-Feeds anwerfen, statt direkt zu warnen
- Refactore die hardcoded `to`-Adresse in allen Email-Nodes in eine **Workflow-Variable** oder eine Empfänger-Liste — saubere Praxis statt sieben Stellen anfassen
- Tausche den `Schedule Trigger` gegen einen `Webhook Trigger`, um das Briefing on-demand per HTTP-POST anzustoßen (z.B. aus einem Slack-Command)
