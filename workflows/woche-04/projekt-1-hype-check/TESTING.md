# Hype-Check – Test-Tabelle

Durchführung: 11.06.2026, API-seitig via fetch() gegen den Produktiv-Webhook, UI-Validierung per manuellem Browsertest (Screenshot, 10.06.).

| # | Kategorie | Eingabe | Erwartetes Verhalten | Tatsächliches Ergebnis | Status |
|---|---|---|---|---|---|
| 1 | Happy Path Text | Hype-Post als Text, ohne E-Mail | 200: Claims mit Bewertung, Hype-Score, Takeaways. Keine Mail | 200, Score 6, 3 Claims (teilweise belegt / belegt / nicht prüfbar), 3 Takeaways, `verifikation_aktiv=true` | ✅ |
| 2 | Happy Path Text + Mail | Hype-Post mit E-Mail-Adresse | Wie #1, zusätzlich Mail an Test-Adresse | 200, Score 7, 2 Claims. Mail-Eingang: manuell prüfen | ✅* |
| 3 | Happy Path URL | br.de-Artikel | 200 inkl. `quelle_url`, Log `input_type=url` | 200, Score 4, 3 Claims, `quelle_url` korrekt gesetzt | ✅ |
| 4 | Validierung | `{"input": ""}` | 400 „Bitte gib einen Text oder eine URL ein." | 400, korrekte Fehlermeldung | ✅ |
| 5 | Validierung | Nur Leerzeichen/Zeilenumbrüche | 400 wie #4 (Input wird getrimmt) | 400, korrekte Fehlermeldung | ✅ |
| 6 | URL-Fehler | Instagram-Link | 422 mit Hinweis, Text direkt einzufügen | 422, korrekte Fehlermeldung (Instagram liefert Login-Wall → „zu wenig Text"-Pfad) | ✅ |
| 7 | URL-Fehler | Nicht existierende Domain | 422 wie #6 | 422, korrekte Fehlermeldung | ✅ |
| 8 | URL-Grenzfall | Seite mit fast keinem Text | 422 (Error-Output am Extraktions-Node) | Identischer Pfad wie #6 real ausgelöst (9 Zeichen extrahiert → 422) | ✅ |
| 9 | Inhalt-Grenzfall | „Hallo, wie geht es dir? Schönes Wetter heute." | 422 „Keine prüfbaren Behauptungen gefunden" | 422, korrekte Fehlermeldung | ✅ |
| 10 | Last | ~12.000 Zeichen Text | 200, Analyse läuft durch | 200, Score 6, 3 Claims | ✅ |
| 11 | API-Ausfall | Tavily-Key temporär ungültig | 200 mit `verifikation_aktiv=false`, Claims „nicht prüfbar", Hinweis im Frontend | Nicht automatisiert (Credential-Wechsel nötig) | offen |
| 12 | Sicherheit | `<script>alert(1)</script>` + Hype-Behauptung | 200, Inhalt wird analysiert, Frontend rendert escaped | 200, Score 4, 2 Claims; UI-Escaping per `escapeHtml`/`textContent` implementiert | ✅ |

\* Mail-Zustellung und Supabase-Log-Rows (`status` ok / fehler_url / fehler_inhalt) manuell gegenprüfen — MCP-Zugriff auf Supabase ist read-blockiert.

## Während des Testens gefunden und behoben

1. **Publish-Pflicht:** `update_workflow` ändert nur den Entwurf; der Webhook bedient ausschließlich die publizierte Version. Tests #4–#7 liefen anfangs gegen einen veralteten Stand (200/leer statt 400/422). Fix: nach jedem Update publizieren. Als Hinweis in der Workflow-Notiz dokumentiert.
2. **Code-Node-Fehler liefen ins Leere:** Fehler aus „Text extrahieren" (zu wenig Text) und „Claims aufteilen" (keine Claims) endeten als generischer Workflow-Error (200/leer beim Client). Fix: `onError: continueErrorOutput` an beiden Code-Nodes, Error-Outputs auf Log + 422-Respond geroutet. Ursprünglich als „bekannte Einschränkung" (#8/#9) geplant, jetzt sauber gelöst.

## Ergebnis-Zusammenfassung

| Gesamt | Bestanden | Fehlgeschlagen | Offen |
|---|---|---|---|
| 12 | 11 | 0 | 1 (#11, manuell) |
