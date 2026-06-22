# Tag 1: Support-Agent

Ein einzelner KI-Agent als Voltbox-Kundenservice mit genau einem Tool (FAQ-Suche). Didaktischer Fokus: Tool-Nutzung ist eine **Entscheidung des Agents**, kein fest verdrahteter Schritt.

## 📍 Architektur-Spektrum

**Agent** — ein `agent`-Node entscheidet autonom, ob er das FAQ-Tool aufruft. Keine deterministische Verzweigung im Workflow.

```
Prompt → Custom GPT → Workflow → [Agent] → Multi-Agent
                                    ▲
```

## 🎯 Was du lernst

- Einen AI-Agent (`@n8n/n8n-nodes-langchain.agent`) mit System-Prompt (Rolle + Eskalationsregel) aufsetzen
- Ein **Code-Tool** (`toolCode`, JS) als Wissensquelle anbinden — Keyword-Match über fünf FAQ-Einträge
- Den `chatTrigger` als Chat-Einstieg in den Workflow nutzen
- Konzeptionell: **der Agent entscheidet selbst**, wann ein Tool nötig ist — bei Smalltalk ruft er keins auf, bei „Was kostet der Versand?" schon
- Konzeptionell: **ehrliche Eskalation statt Halluzination** — liefert das Tool `NICHT_GEFUNDEN`, verweist der Agent an den menschlichen Support, statt eine Antwort zu erfinden

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenAI | `OpenAI` | https://platform.openai.com/api-keys |

Der `OpenAI Chat Model`-Node ist der native OpenAI-Node. Du kannst stattdessen einen OpenAI-kompatiblen Anbieter wie **OpenRouter** nutzen, indem du in der Credential die Basis-URL anpasst (so läuft der Kurs).

### Community Nodes

Keine — nur Core- und mitgelieferte LangChain-Nodes (`Chat Trigger`, `AI Agent`, `OpenAI Chat Model`, `Code Tool`).

## 🚀 Import & Setup

1. **Workflow importieren**: in n8n auf `Workflows → Add Workflow → Import from File` und `workflow.json` auswählen
2. **OpenAI-Credential anlegen**: `Credentials → Add Credential → OpenAI`, deinen Key eintragen und im Node `OpenAI Chat Model` auswählen
3. **Test**: unten im Workflow-Editor auf `Chat` klicken und eine Frage stellen (z.B. „Was kostet der Versand?")

## 📤 Erwartetes Verhalten

Über das Chat-Fenster gestellte Fragen gehen an den `Support-Agent`. Bei Themen wie Versand, Lieferzeit, Rückgabe, Zahlung oder Kontakt ruft der Agent `FAQ_Suche` auf und antwortet mit dem Treffer. Bei Smalltalk („Hi, wie geht's?") antwortet er direkt — ohne Tool-Aufruf. Findet das Tool nichts (`NICHT_GEFUNDEN`, z.B. „Wo ist meine Bestellung #12345?"), gibt der Agent ehrlich zu, dazu keine Information zu haben, und verweist an `support@voltbox.de`.

## 💡 Variationen & Übungsideen

- Erweitere die FAQ im `FAQ_Suche`-Code um weitere Themen (z.B. Garantie, Reklamation) und beobachte, ob der Agent sie nutzt
- Ersetze das Keyword-Matching durch einen echten Vector-Store (Embeddings statt `includes`) — robuster gegenüber abweichenden Formulierungen
- Schärfe den System-Prompt so, dass der Agent bei Unsicherheit aktiv nach fehlenden Details fragt, statt sofort zu eskalieren
- **Saubere Praxis**: den `chatTrigger` für den öffentlichen Einsatz mit Authentifizierung absichern, statt den Endpunkt offen erreichbar zu lassen

---

Tiefergehende Erklärung zu Agents und Tools in `docs/n8n_learning/llm_agent_tools_intro.md`.
