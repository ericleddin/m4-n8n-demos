# Tag 3: Testing

Zwei Testing-Demos plus eine Tabellen-Vorlage: systematische Testdaten (Happy / Edge / Fehler) durch denselben Workflow und ein Prompt-Regressionstest nach dem LLM-as-Judge-Prinzip. Woche 3 bewegt sich bewusst nicht entlang der Architektur-Achse — der Fokus ist Engineering-Disziplin, hier konkret: Qualität messbar und wiederholbar machen.

## 📍 Architektur-Spektrum

**Workflow** — deterministische Test-Pipelines. Der Regressionstest nutzt zwei LLMs (eines generiert, eines bewertet als Judge), aber ohne Tool-Use oder autonome Ablaufentscheidung.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- Testfälle systematisch in drei Kategorien aufbauen: **Happy Path / Edge Cases / Fehler** (Demo A)
- Validierung mit einer `if`-Weiche (gültig → verarbeiten, ungültig → abfangen), `merge` sammelt beide Pfade wieder ein
- Datengetrieben testen: 10 Fälle aus einem `code`-Node erzeugen und die Ergebnisse auszählen
- **LLM-as-Judge**: ein zweites LLM bewertet generierte Antworten gegen eine Baseline → PASS/FAIL (Demo B)
- Konzeptionell: warum ein LLM-Judge selbst **probabilistisch** ist und wo deterministische Checks ihn ergänzen müssen

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |

Nur **Demo B** braucht das OpenRouter-Credential (für Antwort- und Judge-Modell). **Demo A** läuft ohne Credentials.

### Community Nodes

Keine — nur Core- und LangChain-Nodes (`Manual Trigger`, `Code`, `If`, `Set`, `Merge` + `AI Agent` / `OpenRouter Chat Model`).

## 📦 Enthaltene Workflows

Gleichrangige Beispiele zum selben Thema (kein Haupt-/Bonus-Verhältnis):

- **`workflow-a-testdaten-happy-edge-fehler.json`** — erzeugt 10 Testfälle (3 Happy / 4 Edge / 3 Fehler), validiert sie und trennt per `if` gültige (→ verarbeiten) von ungültigen (→ abfangen & loggen); die Zusammenfassung zählt getestet / verarbeitet / abgefangen.
- **`workflow-b-prompt-regressionstest.json`** — Baseline aus 5 Fragen mit erwarteter Kernaussage; der Prompt-unter-Test beantwortet jede Frage, ein Judge-LLM vergleicht gegen die Baseline und vergibt PASS/FAIL.

## 🌐 Companion-Files

- **`data/test-tabelle-template.csv`** — leere Ergebnis-Tabelle (`Nr`, `Kategorie`, `Input`, `Erwarteter Output`, `Tatsaechlicher Output`, `Pass/Fail`, `Notiz`) zum manuellen Mitschreiben der Testläufe. Die 10 vorausgefüllten Fälle decken sich mit den Kategorien aus Demo A.

## 🚀 Import & Setup

1. **Beide JSON-Dateien importieren** über `Workflows → Add Workflow → Import from File`.
2. **Demo B**: OpenRouter-Credential (`OpenRouter Api`) anlegen und in den Nodes `Modell (Antwort)` und `Modell (Judge)` auswählen.
3. **Demo A**: keine Einrichtung nötig — direkt lauffähig.
4. **Optional**: `data/test-tabelle-template.csv` in einem Editor oder Spreadsheet öffnen, um deine Testläufe mitzuschreiben.
5. **Test**: jede Demo einzeln über ihren `Manual Trigger` starten.

## 📤 Erwartetes Verhalten

- **Demo A**: Aus dem `code`-Node fallen 10 Testfälle. Die Validierung prüft Absender + Body und normalisiert den Betreff; gültige Fälle gehen in die Mock-Verarbeitung, ungültige in den Fehlerpfad. Der `merge` führt beide zusammen, die Zusammenfassung zählt die drei Größen.
- **Demo B**: Jede der 5 Baseline-Fragen wird vom Prompt-unter-Test beantwortet, der Judge bewertet jede Antwort gegen die erwartete Kernaussage. Die Auswertung zählt bestanden / durchgefallen. Änderst du im Node `Antwort generieren` den System-Prompt (Live-Demo), kippt typischerweise Frage 1 auf FAIL.

## 💡 Variationen & Übungsideen

- **Demo A**: eigene Edge Cases ergänzen (z.B. HTML/Script im Body, sehr lange Betreffzeile) und prüfen, ob die Validierung sie hält.
- **Demo B**: den System-Prompt im Node `Antwort generieren` variieren und beobachten, welche Fragen kippen.
- **Demo B**: zusätzlich zum LLM-Judge **deterministische Checks** (Keyword-Match, Längen-/Format-Prüfung) einbauen — robustere, reproduzierbare Tests statt rein probabilistischer Bewertung (saubere Praxis).
- Die CSV-Vorlage mit echten Testlauf-Ergebnissen füllen und versionieren, um Regressionen über die Zeit sichtbar zu machen.

---

Tiefergehende Erklärung der `if`-/`merge`-Datenflüsse in `docs/n8n_learning/n8n_datenfluss_kompendium.md`, zu den `code`-Nodes (Testdaten, Auswertung) in `docs/n8n_learning/n8n_developer_guide.md`.
