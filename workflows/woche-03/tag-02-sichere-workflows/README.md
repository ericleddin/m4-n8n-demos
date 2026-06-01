# Tag 2: Sichere Workflows

Drei eigenständige Security-Demos: Credentials sauber speichern statt hardcoden, Token-Refresh bei abgelaufenem Access Token, und PII-Anonymisierung vor dem LLM-Aufruf (DSGVO). Woche 3 bewegt sich bewusst nicht entlang der Architektur-Achse — der Fokus ist Engineering-Disziplin, hier konkret: sicherer Umgang mit Secrets und personenbezogenen Daten.

## 📍 Architektur-Spektrum

**Workflow** — deterministische Pipelines (HTTP, `if`, `code`). Die PII-Demo nutzt ein LLM nur als Zusammenfassungs-Step nach der Anonymisierung, ohne Tool-Use.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- Secrets **nie hardcoden**: Vorher/Nachher mit Klartext-Key im Header vs. `HTTP Bearer Auth`-Credential (Demo A)
- Token-Refresh-Pattern: 401 mit `if` erkennen → Token tauschen → ursprünglichen Call wiederholen (Demo B)
- PII vor dem LLM mit einem `code`-Node maskieren (Regex auf E-Mail und Name) und nur den anonymisierten Text weitergeben — **Datenminimierung** (Demo C)
- Konzeptionell: warum der Credential-Store dem Klartext überlegen ist (beim Export/Teilen/Versionieren reisen Klartext-Keys mit) und die drei DSGVO-Prüfschritte (Was sind die Daten? Wo werden sie verarbeitet? Ist es verhältnismäßig?)

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |

Nur **Demo A** (Resend, „Nachher"-Call) und **Demo C** (OpenRouter) brauchen Credentials. **Demo B** ist komplett gemockt und macht keine echten API-Calls.

> **Hinweis zum „Vorher"-Beispiel in Demo A**: Der hartcodierte `Bearer sk-live-…Geheim456` ist ein **bewusst gefälschter** Key — das Anti-Pattern, das die Demo zeigt. Kein echter Secret, nicht ersetzen, er gehört zur Lektion.

### Community Nodes

Keine — nur Core- und LangChain-Nodes (`Manual Trigger`, `Set`, `HTTP Request`, `If`, `Code` + `AI Agent` / `OpenRouter Chat Model`).

## 📦 Enthaltene Workflows

Gleichrangige Beispiele zum selben Thema (kein Haupt-/Bonus-Verhältnis):

- **`workflow-a-credentials-sicher-speichern.json`** — Vorher/Nachher: derselbe API-Call einmal mit Klartext-Key im Header (schlecht), einmal über den verschlüsselten Credentials-Store (gut).
- **`workflow-b-token-refresh.json`** — simuliert eine 401-Antwort, erkennt sie per `if`, tauscht den Token (Mock) und wiederholt den Call. Alles gemockt, keine echten Endpunkte.
- **`workflow-c-pii-anonymisierung.json`** — eine Kundenbeschwerde wird vor dem LLM anonymisiert (Name und E-Mail maskiert); das LLM sieht nur den anonymisierten Text.

## 🚀 Import & Setup

1. **Alle drei JSON-Dateien importieren** über `Workflows → Add Workflow → Import from File`.
2. **Demo A**: Resend-Credential (`HTTP Bearer Auth`) anlegen und im Node `API-Call ueber Credentials-Store` auswählen. Den Node `API-Call mit hartcodiertem Key` bewusst unverändert lassen — er zeigt das Anti-Pattern.
3. **Demo C**: OpenRouter-Credential (`OpenRouter Api`) anlegen und im Node `OpenRouter Modell` auswählen.
4. **Demo B**: keine Einrichtung nötig — direkt lauffähig.
5. **Test**: jede Demo einzeln über ihren `Manual Trigger` starten.

## 📤 Erwartetes Verhalten

- **Demo A**: Beide HTTP-Calls laufen ab demselben Trigger. Exportierst du den Workflow, siehst du den Klartext-Key im „Vorher"-Node — beim „Nachher"-Node fehlt der Wert, weil er im Credential liegt.
- **Demo B**: Die simulierte Antwort hat Status 401. Die `if`-Weiche schickt den Ablauf in den Refresh-Pfad (Token erneuern → Call wiederholen → 200). Setzt du die Simulation auf 200, geht es direkt in die Verarbeitung.
- **Demo C**: Der `code`-Node maskiert E-Mail und Name und gibt nur `anonymizedText` weiter; das LLM fasst zusammen, ohne je die PII gesehen zu haben.

## 💡 Variationen & Übungsideen

- **Demo A**: einen weiteren Node von Klartext-Header auf ein Credential umstellen — saubere Praxis direkt erlebbar.
- **Demo B**: die simulierte Antwort von 401 auf 200 ändern und den direkten Pfad zeigen; danach den Mock-Refresh gegen einen echten OAuth2-Token-Endpunkt umbauen.
- **Demo C**: weitere PII-Typen (Telefonnummer, IBAN, Adresse) per Regex ergänzen und prüfen, ob wirklich nur das Nötigste beim LLM ankommt.
- Den hartcodierten „Vorher"-Key aus Demo A durch eine echte n8n-Credential ersetzen und den Unterschied im Export vergleichen (saubere Praxis).

---

Tiefergehende Erklärung der `if`-Weiche (Token-Refresh) in `docs/n8n_learning/n8n_datenfluss_kompendium.md`, zum `code`-Node (PII-Maskierung) in `docs/n8n_learning/n8n_developer_guide.md`.
