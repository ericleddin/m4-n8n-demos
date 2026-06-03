# Lokale LLMs mit Ollama

> Ollama lässt dich Open-Source-LLMs auf deinem eigenen Rechner oder Server laufen —
> ohne API-Key, ohne Kosten pro Call, ohne dass Daten dein System verlassen.

---

## Warum lokale LLMs?

| | **Cloud-API (OpenAI etc.)** | **Lokal (Ollama)** |
|---|---|---|
| **Kosten** | Pro Token | Hardware einmalig |
| **Datenschutz** | Daten beim Anbieter | Daten bleiben lokal |
| **DSGVO** | Abhängig von Anbieter | Vollständige Kontrolle |
| **Offline** | ❌ Internet nötig | ✅ |
| **Qualität** | Besser (Stand 2026) | Gut genug für viele Fälle |
| **Setup** | API-Key, fertig | Hardware, Installation |
| **Skalierung** | Unbegrenzt | Begrenzt durch Hardware |

**Wann Ollama sinnvoll ist:**
- Sensible Daten (Patientendaten, Verträge, interne Dokumente)
- Entwicklung & Testing (keine API-Kosten beim Experimentieren)
- Edge-Szenarien ohne Internetverbindung
- Lernen: Modelle verstehen ohne Kosten

---

## Hardware-Anforderungen

LLMs brauchen vor allem **RAM** (CPU-Betrieb) oder **VRAM** (GPU-Betrieb):

| Modell | Größe | Min. RAM (CPU) | VRAM (GPU) | Geschwindigkeit |
|---|---|---|---|---|
| **Phi-4** | 14B | 16 GB | 8 GB | Schnell, überraschend gut |
| **Mistral 7B** | 7B | 8 GB | 6 GB | Sehr schnell, solide |
| **Llama 3.2 3B** | 3B | 4 GB | 3 GB | Sehr schnell, kleinere Aufgaben |
| **Llama 3.3 70B** | 70B | 64 GB | 40 GB | Langsam auf CPU, gut auf GPU |
| **Qwen 2.5 14B** | 14B | 16 GB | 8 GB | Stark bei Code & Deutsch |

> GPU-Betrieb ist 10–50× schneller als CPU.
> Ohne GPU ist Ollama für Produktion meist zu langsam — aber für Entwicklung reicht es.

---

## Installation & Setup

### Direkt auf dem System

```
Linux / macOS:
curl -fsSL https://ollama.com/install.sh | sh

Windows:
→ Installer von ollama.com herunterladen
```

### Als Docker Container

```yaml
services:
  ollama:
    image: ollama/ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama    # Modelle persistent speichern
    # GPU-Support (NVIDIA):
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

volumes:
  ollama_data:
```

---

## Modelle laden und verwalten

```
Modell herunterladen:
ollama pull mistral          # Mistral 7B (~4 GB)
ollama pull llama3.3         # Llama 3.3 70B (~40 GB)
ollama pull phi4             # Phi-4 14B (~9 GB)
ollama pull nomic-embed-text # Embedding-Modell für RAG

Verfügbare Modelle anzeigen:
ollama list

Modell entfernen:
ollama rm mistral

Modelle suchen:
→ ollama.com/library
```

---

## Ollama API — kompatibel mit OpenAI

Ollama hat eine OpenAI-kompatible API — du kannst bestehenden Code oft ohne Änderung nutzen:

```
OpenAI SDK mit Ollama:
  Base URL: http://localhost:11434/v1
  API Key:  "ollama"  (beliebig, wird nicht geprüft)
  Model:    "llama3.3" / "mistral" / "phi4"
```

Das bedeutet: jeder Code der mit dem OpenAI SDK geschrieben ist, funktioniert mit Ollama durch Änderung von zwei Werten.

---

## Ollama in n8n einbinden

In n8n Chat Model Node:

```
Provider:  Ollama
Base URL:  http://localhost:11434
           (oder http://ollama:11434 wenn Docker Compose)
Model:     llama3.3
```

Für Embeddings (RAG in n8n):

```
Embeddings Node:
Provider:  Ollama
Model:     nomic-embed-text
```

---

## Ollama mit Langfuse tracken

Da Ollama eine OpenAI-kompatible API hat, funktioniert Langfuse genauso:

```
LiteLLM als Zwischenschicht:
  config.yaml:
    model_list:
      - model_name: ollama/llama3.3
        litellm_params:
          model: ollama/llama3.3
          api_base: http://ollama:11434

→ Alle Ollama-Calls werden automatisch in Langfuse geloggt
```

---

## Modellwahl für typische Aufgaben

| Aufgabe | Empfehlung | Warum |
|---|---|---|
| Chat / Assistenz | Llama 3.3 8B oder Phi-4 | Gute Balance Qualität/Speed |
| Code-Generierung | Qwen 2.5 Coder oder Phi-4 | Stärke bei Code |
| Deutsch-Texte | Mistral oder Qwen 2.5 | Bessere Deutsch-Unterstützung |
| RAG-Embeddings | nomic-embed-text | Speziell für Embeddings optimiert |
| Sehr schnelle Antworten | Llama 3.2 3B | Minimal, schnell |
| Beste Qualität lokal | Llama 3.3 70B | Wenn Hardware vorhanden |

---

## Grenzen von lokalen Modellen (Stand 2026)

```
Lokale Modelle sind gut für:           Noch besser mit Cloud-Modellen:
──────────────────────────             ──────────────────────────────
Einfache Konversation                  Komplexes Multi-Step Reasoning
Text-Klassifikation                    Sehr langer Kontext (>32k Token)
Zusammenfassungen                      Neuestes Wissen (Training-Cutoff)
Struktur aus Text extrahieren          Hochpräzise Fakten
Code-Snippets                          Komplexe Code-Architektur
Datenschutz-kritische Aufgaben         Schnelle Inferenz ohne GPU
```

> Die Qualitätslücke wird kleiner — Phi-4 und Llama 3.3 sind bereits für viele
> Produktions-Anwendungen gut genug.
