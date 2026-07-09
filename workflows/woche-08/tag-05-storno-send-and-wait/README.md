# Tag 5: Storno mit Send and Wait

Human-in-the-Loop in seiner einfachsten Form: ein deterministischer Workflow pausiert vor einer irreversiblen Aktion (Bestellung löschen) und wartet per Gmail-`Send and Wait` auf die menschliche Freigabe. Erst nach dem Klick auf „Freigeben" läuft der Flow weiter. Didaktischer Fokus: die gefährliche Aktion liegt **hinter** der Freigabe — kein Klick, keine Löschung, hart im Ablauf verdrahtet.

## 📍 Architektur-Spektrum

**Workflow** — eine feste, vorab definierte Pipeline: Trigger → Anfrage → Freigabe-Wait → `IF` → löschen oder nichts tun. Kein Agent entscheidet etwas; die Freigabe ist ein deterministischer Pause-Punkt im Flow. Das ist bewusst die konservative HITL-Variante.

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- Die `Send and Wait`-Operation des `Gmail`-Nodes: der Workflow verschickt eine Mail mit Freigeben-/Ablehnen-Buttons und **pausiert** (Status „Waiting"), bis der Mensch klickt
- Die Freigabe-Antwort auswerten: das Ergebnis landet in `$json.data.approved`, ein `IF`-Node verzweigt auf `true`/`false`
- Eine irreversible Aktion (`Code`-Node „Bestellung löschen") **erst nach** bestätigter Freigabe ausführen — der Ablehnungs-Zweig macht bewusst nichts
- Einen `Set`-Node als hartcodierte Storno-Anfrage nutzen, um die Demo ohne externe Datenquelle startklar zu halten
- Konzeptionell: **HITL als Sicherheitsmechanismus** — die Kopplung „Aktion hinter Freigabe" ist hier fest im Flow verdrahtet (kein Modell, kein Prompt kann sie umgehen). Der Preis: eine Mail, ein Approver, kein Audit-Trail (siehe Kontrast in `../tag-05-storno-agent/`)

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| Gmail (Send and Wait) | `Gmail OAuth2` | https://console.cloud.google.com → OAuth-Client |

### Community Nodes

Keine — `Gmail` (inkl. `Send and Wait`), `Manual Trigger`, `Set`, `IF` und `Code` sind Core-Nodes.

## 🚀 Import & Setup

1. **Workflow importieren**: `Workflows → Add Workflow → Import from File` → `workflow.json`
2. **Gmail-Credential anlegen**: `Credentials → Add Credential → Gmail OAuth2` und im Node „Freigabe anfordern (Send and Wait)" auswählen
3. **Empfänger setzen**: im selben Node das Feld `To` — Platzhalter `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` durch deine eigene Freigabe-Adresse ersetzen (dorthin geht die Freigabe-Mail)
4. **Test**: „Demo starten" (Manual Trigger) → `Execute workflow`. Der Flow bleibt auf „Waiting". Mail öffnen, „Storno freigeben" oder „Ablehnen" klicken — der Workflow läuft dann im entsprechenden Zweig weiter.

## 📤 Erwartetes Verhalten

Beim Start setzt der `Set`-Node eine feste Storno-Anfrage (`VB-1002`, Voltbox Pro 2000, 2499 EUR). Der Gmail-Node verschickt eine Freigabe-Mail mit zwei Buttons und hält die Execution auf „Waiting" — unbegrenzt, bis der Mensch entscheidet. Bei **Freigabe** (`$json.data.approved = true`) läuft der `Code`-Node „Bestellung löschen" und meldet die simulierte Löschung. Bei **Ablehnung** greift der Zweig „Abgelehnt – keine Aktion": es wird nichts gelöscht. Die Löschung ist strukturell unerreichbar ohne vorherigen Klick.

## 💡 Variationen & Übungsideen

- `approvalType` von `double` (Freigeben **und** Ablehnen) auf einen Button oder auf Freitext-Antwort umstellen und das Auswerten in `$json.data` anpassen
- Statt des simulierten `Code`-Löschens eine echte `Supabase`-/`Postgres`-Operation einsetzen (Status auf `storniert`) — dann ist die Freigabe der Schutz vor einem echten irreversiblen Write
- Ein Timeout am `Send and Wait` setzen und einen Eskalations-Zweig bauen, falls niemand innerhalb von X Stunden entscheidet
- Die Freigabe-Mail um die vollständigen Bestelldetails und einen Deep-Link ins System erweitern, damit der Approver mit Kontext entscheidet
- **Saubere Praxis**: Die Freigabe-Logik gehört in Produktion **in** das Schreib-Tool selbst (wie im Sub-Workflow-Pattern), nicht nur davor im Flow — vergleiche die Agent-Variante in `../tag-05-storno-agent/`, wo genau dieser Tradeoff der Lernpunkt ist

---

Tiefergehende Erklärung zu Datenfluss-Verzweigungen (`IF`) in `docs/n8n_learning/n8n_datenfluss_kompendium.md`. Die Kontrast-Demo — dieselbe Freigabe, aber von einem Agenten gehalten (HITL-Plattform mit Dashboard und Audit-Trail) — liegt in `../tag-05-storno-agent/`.
