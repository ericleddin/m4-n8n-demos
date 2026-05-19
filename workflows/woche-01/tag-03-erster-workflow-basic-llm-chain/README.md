# Tag 3: Erster Workflow (Basic LLM Chain)

Variante des ersten end-to-end Workflows — derselbe Use-Case (Wetter → LLM → Email), aber der LLM-Aufruf läuft über die LangChain-Nodes `Basic LLM Chain` und `OpenRouter Chat Model` statt über einen direkten HTTP-POST.

## 📍 Architektur-Spektrum

**Workflow** — gleiche deterministische Pipeline. Das LLM bleibt ein Verarbeitungs-Step, der LangChain-Wrapper ändert daran nichts.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- **LangChain-Integration in n8n**: `Basic LLM Chain` als wiederverwendbarer Wrapper für LLM-Calls
- **Sub-Node-Architektur**: das Chat-Modell wird per `ai_languageModel`-Connection an die Chain gehängt, statt im Hauptpfad zu liegen
- **Trennung von Prompt-Logik und Modell-Konfiguration**: Prompt steckt in der `Basic LLM Chain`, Modell-Wahl im `OpenRouter Chat Model`
- Vergleich zur direkten HTTP-Variante (siehe `tag-03-erster-workflow`): kürzerer Prompt-Body, einheitliches Output-Format (`$json.text`), aber zusätzliche Node-Komplexität

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenWeatherMap | (Platzhalter in URL, manuell ersetzen) | https://openweathermap.org/api |
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |

### Community Nodes

Keine — `@n8n/n8n-nodes-langchain.chainLlm` und `@n8n/n8n-nodes-langchain.lmChatOpenRouter` sind Teil der LangChain-Integration in der n8n-Core-Distribution.

## 🚀 Import & Setup

1. **Workflow importieren**: in n8n auf `Workflows → Add Workflow → Import from File` und `workflow.json` auswählen
2. **OpenWeatherMap-Key ersetzen**:
   - Im Node "OpenWeatherMap" auf das `URL`-Feld klicken
   - Den Platzhalter `<<REPLACE_WITH_OPENWEATHERMAP_APPID>>` durch deinen eigenen Key ersetzen
3. **OpenRouter-Credential anlegen**:
   - `Credentials → Add Credential → OpenRouter Api`
   - API-Key aus https://openrouter.ai/keys eintragen
   - Im Node "OpenRouter Chat Model" als Credential auswählen
4. **Resend-Credential anlegen**:
   - `Credentials → Add Credential → HTTP Bearer Auth`
   - API-Key aus https://resend.com/api-keys als Bearer-Token eintragen
   - Im Node "Resend Email" als Credential auswählen
   - Die `to`-Adresse im JSON-Body des Resend-Nodes auf deine eigene Email anpassen
5. **Test**: Manual Trigger anklicken → `Execute workflow`

## 📤 Erwartetes Verhalten

Beim Klick auf `Execute workflow` läuft die Pipeline sequenziell durch:

1. **OpenWeatherMap** liefert aktuelle Wetterdaten für München
2. **Filter** (Set-Node) extrahiert Temperatur, Beschreibung und Stadt
3. **Basic LLM Chain** generiert das 3-Satz-Briefing — das angehängte **OpenRouter Chat Model** liefert die eigentliche LLM-Antwort
4. **Resend Email** schickt das Briefing an die hinterlegte Empfänger-Adresse

Wichtiger Unterschied zur direkten HTTP-Variante: Die LLM-Antwort liegt jetzt unter `$json.text` (statt `$json.choices[0].message.content`) — die Chain abstrahiert das provider-spezifische Response-Format weg.

## 💡 Variationen & Übungsideen

- Tausche das Chat-Modell aus: `OpenRouter Chat Model` durch `OpenAI Chat Model` oder `Anthropic Chat Model` ersetzen — die `Basic LLM Chain` bleibt unverändert. Erlebe Modell-Agnostik in der Praxis.
- Ergänze die `Basic LLM Chain` um einen **System-Prompt**, der das Briefing in einem festen Stil hält (z.B. "antworte ausschließlich als Frühaufsteher-Coach")
- Hänge einen `Structured Output Parser` an die Chain und lass das LLM JSON statt Freitext zurückgeben — Brücke zu nachgelagerten Verarbeitungs-Schritten
- Refactore den OpenWeatherMap-Key vom Platzhalter in eine **echte n8n-Credential** (HTTP Query Auth) — saubere Praxis statt URL-Parameter
