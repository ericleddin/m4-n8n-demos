# Tag 3: Erster Workflow

Ein end-to-end Workflow, der Wetterdaten abruft, mit einem LLM aufbereitet und das Ergebnis per Email versendet. Erste vollständige Pipeline aus API → LLM → Output, komplett über direkte HTTP-Requests.

## 📍 Architektur-Spektrum

**Workflow** — deterministische, vorab definierte Schritte. Das LLM ist ein Verarbeitungs-Step, kein Entscheider.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- HTTP-Requests gegen externe REST-APIs absetzen (Wetter, LLM-Provider, Email)
- Daten aus JSON-Responses mit dem **Set-Node** extrahieren und für den nächsten Step aufbereiten
- LLM-Aufrufe als reine HTTP-Calls direkt gegen die Provider-API (ohne LangChain-Wrapper)
- Drei verschiedene Authentifizierungs-Patterns in einem Workflow vergleichen:
  - **Key im URL-Query-Parameter** (Anti-Pattern): `OpenWeatherMap`
  - **Credential-Referenz** (`predefinedCredentialType`): `OpenRouter`
  - **Generische Bearer-Auth** (`httpBearerAuth`): `Resend`
- Sequenzielle Pipeline-Struktur: Output eines Nodes als Input des nächsten

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenWeatherMap | (Platzhalter in URL, manuell ersetzen) | https://openweathermap.org/api |
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |

### Community Nodes

Keine — nur Core-Nodes (`Manual Trigger`, `HTTP Request`, `Set`).

## 🚀 Import & Setup

1. **Workflow importieren**: in n8n auf `Workflows → Add Workflow → Import from File` und `workflow.json` auswählen
2. **OpenWeatherMap-Key ersetzen**:
   - Im Node "OpenWeatherMap" auf das `URL`-Feld klicken
   - Den Platzhalter `<<REPLACE_WITH_OPENWEATHERMAP_APPID>>` durch deinen eigenen Key ersetzen
3. **OpenRouter-Credential anlegen**:
   - `Credentials → Add Credential → OpenRouter Api`
   - API-Key aus https://openrouter.ai/keys eintragen
   - Im Node "OpenRouter" als Credential auswählen
4. **Resend-Credential anlegen**:
   - `Credentials → Add Credential → HTTP Bearer Auth`
   - API-Key aus https://resend.com/api-keys als Bearer-Token eintragen
   - Im Node "Resend Email" als Credential auswählen
   - Die `to`-Adresse im JSON-Body des Resend-Nodes auf deine eigene Email anpassen
5. **Test**: Manual Trigger anklicken → `Execute workflow`

## 📤 Erwartetes Verhalten

Beim Klick auf `Execute workflow` läuft die Pipeline sequenziell durch:

1. **OpenWeatherMap** liefert aktuelle Wetterdaten für München
2. **Filter** (Set-Node) extrahiert Temperatur, Beschreibung und Stadt aus der Response
3. **OpenRouter** ruft `gpt-4o-mini` per direktem HTTP-POST auf und generiert ein 3-Satz-Morgen-Briefing
4. **Resend Email** schickt das Briefing als Klartext-Email an die hinterlegte Empfänger-Adresse

## 💡 Variationen & Übungsideen

- Ersetze die hardcoded Stadt `Munich` in der OpenWeatherMap-URL durch einen Workflow-Input, der per Manual Trigger steuerbar ist
- Tausche `gpt-4o-mini` im OpenRouter-Body gegen ein anderes Modell (z.B. `anthropic/claude-sonnet-4`) und vergleiche die Briefings
- Refactore den OpenWeatherMap-Key vom Platzhalter in eine **echte n8n-Credential** (HTTP Query Auth) — saubere Praxis statt URL-Parameter
- Tausche den Manual Trigger gegen einen Schedule-Trigger, der dir das Briefing täglich um 7 Uhr automatisch zustellt
