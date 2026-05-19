# Tag 2: Daten & APIs

Ein n8n-Workflow, der drei externe APIs parallel aufruft und die Ergebnisse extrahiert. Praktische Einführung in HTTP-Requests, Credential-Management und Daten-Extraktion.

## 📍 Architektur-Spektrum

**Workflow** — deterministische, vorab definierte Schritte. Kein Agent-Verhalten.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- HTTP-Requests gegen externe REST-APIs absetzen
- Drei verschiedene Authentifizierungs-Patterns vergleichen:
  - **Keine Auth** (Public API): `restcountries`
  - **Key im URL-Query-Parameter** (Anti-Pattern): `OpenWeatherMap`
  - **Credential-Referenz in n8n** (saubere Praxis): `OpenRouter`
- Daten aus JSON-Responses mit dem **Set-Node** extrahieren
- Parallele API-Aufrufe in einem Workflow strukturieren

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenWeatherMap | (Platzhalter in URL, manuell ersetzen) | https://openweathermap.org/api |
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |

`restcountries` benötigt keinen Key.

### Community Nodes

Keine — nur Core-Nodes (`Manual Trigger`, `HTTP Request`, `Set`).

## 🚀 Import & Setup

1. **Workflow importieren**: in n8n auf `Workflows → Add Workflow → Import from File` und `workflow.json` auswählen
2. **OpenRouter-Credential anlegen**:
   - `Credentials → Add Credential → OpenRouter Api`
   - API-Key aus https://openrouter.ai/keys eintragen
   - Im Node "API 3: OpenRouter" als Credential auswählen
3. **OpenWeatherMap-Key ersetzen**:
   - Im Node "API 2: openweathermap" auf das `URL`-Feld klicken
   - Den Platzhalter `<<REPLACE_WITH_OPENWEATHERMAP_APPID>>` durch deinen eigenen Key ersetzen
4. **Test**: Manual Trigger anklicken → `Execute workflow`

## 📤 Erwartetes Verhalten

Beim Klick auf `Execute workflow` starten drei parallele API-Aufrufe:

1. **restcountries** liefert Daten zu Deutschland → Set-Node extrahiert die Hauptstadt
2. **OpenWeatherMap** liefert aktuelle Wetterdaten für München
3. **OpenRouter** generiert eine kurze Wetter-Zusammenfassung auf Deutsch → Set-Node extrahiert den Text

## 💡 Variationen & Übungsideen

- Tausche das `de` in der `restcountries`-URL gegen ein anderes Länderkürzel (`fr`, `it`, ...)
- Verbinde die OpenWeatherMap-Daten dynamisch in den OpenRouter-Prompt, statt der hartcodierten Werte
- Füge einen 4. API-Call zur Speicherung in einer Datenbank (z.B. Supabase) hinzu
- Refactore den OpenWeatherMap-Key vom Platzhalter in eine **echte n8n-Credential** — saubere Praxis, im Workflow direkt erlebbar
