# Langfuse vs. LangSmith

> Beide Tools sind **LLM Observability Platforms** — sie tracken, evaluieren und debuggen
> KI-Anwendungen. Die Wahl hängt von Hosting, Budget und Framework-Bindung ab.

---

## Was machen diese Tools überhaupt?

Wenn du eine LLM-App baust, willst du wissen:

- Was wurde an das Modell geschickt? (Prompt)
- Was kam zurück? (Response)
- Wie lange hat es gedauert? (Latenz)
- Wie viele Tokens wurden verbraucht? (Kosten)
- Wo ist die Chain / der Agent abgebogen? (Tracing)
- War die Antwort gut? (Evaluation)

Genau das leisten Langfuse und LangSmith.

---

## Vergleich auf einen Blick

| Kriterium | **Langfuse** | **LangSmith** |
|---|---|---|
| **Open Source** | ✅ MIT-Lizenz | ❌ Closed Source |
| **Self-Hosting** | ✅ Docker Compose, Kubernetes | ❌ Nur Cloud |
| **Managed Cloud** | ✅ (Hobby-Tier kostenlos) | ✅ (ab $39/Monat) |
| **Datenschutz / DSGVO** | ✅ Vollständig kontrollierbar | ⚠️ Daten bei Langchain Inc. |
| **Framework-Agnostisch** | ✅ OpenAI, Anthropic, Ollama, … | ⚠️ Optimiert für LangChain |
| **LangChain-Integration** | ✅ (CallbackHandler) | ✅ (native, tief integriert) |
| **OpenTelemetry (OTel)** | ✅ OTel-Ingestion nativ | ⚠️ Begrenzt |
| **Prompt Management** | ✅ Versionierung, A/B-Testing | ✅ |
| **Evaluierungen** | ✅ manuell + LLM-as-judge + custom | ✅ manuell + automatisch |
| **Datasets & Testing** | ✅ | ✅ |
| **Preis (Self-Host)** | 🆓 kostenlos | n/a |
| **Preis (Cloud)** | Hobby: Free / Pro: ~$49/Monat | Developer: $39 / Plus: $99/Monat |

---

## Architektur

### Langfuse (Self-Hosted)
```
Deine App
    │  SDK (Python / TS)
    ▼
Langfuse Server (Next.js + Worker)
    ├── PostgreSQL  → Metadaten, User, Projekte
    ├── ClickHouse  → Event-Daten (Traces, Spans) — hochskalierbar
    ├── Redis       → Queues, Caching
    └── MinIO/S3    → Blob Storage (z.B. große Prompts)
```

> ClickHouse ist der Schlüssel: Langfuse kann damit **Milliarden von Traces**
> effizient speichern und abfragen. Ideal für Produktion.

### LangSmith
```
Deine App
    │  LangChain SDK / LangSmith SDK
    ▼
LangSmith Cloud (Langchain Inc.)
    └── Managed Infrastruktur (intern unbekannt)
```

---

## Integration — Codebeispiel

### Langfuse mit OpenAI (Python)

```python
from langfuse.openai import openai  # Drop-in Replacement

response = openai.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Was ist LLM Tracing?"}],
)
# → Automatisch in Langfuse geloggt, kein weiterer Code nötig
```

### Langfuse manuell (mehr Kontrolle)

```python
from langfuse import Langfuse

langfuse = Langfuse()

trace = langfuse.trace(name="meine-pipeline")
span = trace.span(name="llm-call")

# ... dein LLM-Call ...

span.end(output=response.choices[0].message.content)
trace.update(output="Ergebnis")
```

### LangSmith mit LangChain

```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__..."

from langchain_openai import ChatOpenAI
# → ab hier automatisch geloggt
```

---

## Wann welches Tool?

### Nimm **Langfuse** wenn…
- ✅ du **self-hosten** willst (Datenschutz, DSGVO, eigene Infra)
- ✅ du **framework-agnostisch** arbeitest (OpenAI direkt, Anthropic, Ollama, etc.)
- ✅ du kostenbewusst bist (Self-Hosting ist gratis)
- ✅ du in einer **regulierten Branche** arbeitest (Medizin, Finanzen, Behörden)
- ✅ du die Infrastruktur verstehen und kontrollieren willst

### Nimm **LangSmith** wenn…
- ✅ du **tief in LangChain/LangGraph** arbeitest
- ✅ du keine eigene Infra verwalten willst
- ✅ dein Team bereits LangChain-SDK nutzt und nahtlose Integration wichtig ist

---

## Alternativen im Überblick

| Tool | Besonderheit |
|---|---|
| **Helicone** | Proxy-basiert (kein SDK nötig), einfachster Einstieg |
| **Braintrust** | Fokus auf Evals, sehr gutes Dataset-Management |
| **Phoenix (Arize)** | Open Source, stark bei ML + LLM Observability, OTel-nativ |
| **Weave (W&B)** | Weights & Biases Ecosystem, gut für ML-Teams |
| **Traceloop** | OpenTelemetry-first, Auto-Instrumentation |

---

## Fazit

> **Für Lernzwecke und eigene Projekte: Langfuse self-hosted ist der beste Start.**
> Du verstehst die Architektur, hast volle Kontrolle, und es kostet nichts.
> LangSmith lohnt sich wenn du produktiv mit LangChain/LangGraph arbeitest
> und keinen Ops-Aufwand willst.
