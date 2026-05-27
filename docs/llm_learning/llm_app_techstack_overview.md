# LLM-App Konzepte & Entscheidungshilfen

> Dieses Dokument erklärt das **Warum** hinter den Stack-Entscheidungen.
> Die konkreten Tool-Empfehlungen pro Größe und Sprache stehen in
> [best_practice_tech_stack_2026.md](best_practice_tech_stack_2026.md).

---

## Architektur einer LLM-App

```
┌─────────────────────────────────────────────────────────────────┐
│  FRONTEND / CLIENT                                              │
│  Chat-UI, Admin-Board, API-Consumer                             │
├─────────────────────────────────────────────────────────────────┤
│  BACKEND / ORCHESTRATION                                        │
│  API, Business Logic, LLM-Aufrufe, Prompt-Verwaltung           │
├─────────────────────────────────────────────────────────────────┤
│  LLM PROVIDER                                                   │
│  OpenAI, Anthropic, Ollama (lokal), Azure OpenAI, Bedrock       │
├──────────────────────────┬──────────────────────────────────────┤
│  WISSEN / GEDÄCHTNIS     │  DATEN & PERSISTENZ                  │
│  Vector DB, RAG          │  PostgreSQL, Redis, S3/MinIO         │
├──────────────────────────┴──────────────────────────────────────┤
│  OBSERVABILITY                                                  │
│  LLM Tracing · APM · Metrics · Logs                            │
├─────────────────────────────────────────────────────────────────┤
│  INFRA / DEPLOYMENT                                             │
│  Docker · Kubernetes · Cloud Provider                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Wachstumssignale — wann ist die nächste Stufe fällig?

Nicht nach Plan wachsen, sondern wenn der Schmerz auftaucht:

| Signal | Was du brauchst |
|---|---|
| Mehrere Nutzer gleichzeitig, LLM-Call blockt | Queue + Async (BullMQ / Celery) |
| Lange Wartezeiten in der UI | Streaming-Response |
| Eigene Dokumente sollen durchsuchbar sein | Vector DB + RAG-Pipeline |
| Team > 1 Person, "works on my machine" | CI/CD + Staging-Environment |
| Provider-Ausfall oder zu teuer | LiteLLM Gateway + Fallback-Routing |
| Gleiche Fragen kommen oft | Semantisches Caching |
| Logs und Metriken unübersichtlich | OpenTelemetry + Grafana Stack |
| Compliance-Anfragen, DSGVO-Audit | EU-Hosting, Audit Logs, Datenlöschung |

---

## Warum LiteLLM?

Ohne Gateway ist jeder Provider-Wechsel eine Code-Änderung:

```
Ohne LiteLLM:                      Mit LiteLLM:
──────────────────────             ──────────────────────────────
if provider == "openai":           response = litellm.completion(
    openai.chat(...)                   model="gpt-4o",
elif provider == "anthropic":          # oder morgen:
    anthropic.messages(...)            model="claude-sonnet-4-6",
elif provider == "ollama":             # oder lokal:
    requests.post(...)                 model="ollama/llama3",
                                       messages=[...]
                                   )
                                   # immer gleiche API
```

**Was LiteLLM noch kann:**
- Fallback-Routing: OpenAI down → automatisch zu Anthropic
- Cost Tracking: Kosten pro Modell und Projekt
- Semantisches Caching (siehe unten)
- Rate Limiting pro API-Key
- Läuft als eigenständiger Proxy-Service (1 Docker Container)

---

## pgvector vs. dedizierte Vector DB

```
pgvector (Postgres-Extension)      Qdrant / Weaviate / Pinecone
──────────────────────────         ────────────────────────────
Kein extra Service                 Extra Service, extra Kosten
Transaktionen möglich              Bessere Performance bei Millionen Vektoren
Joins mit normalen Daten           Spezialfunktionen (Hybrid Search, Filter)
Backup wie normale DB              Eigenes Backup / Managed Option
Reicht bis ~500k Dokumente         Skaliert auf Milliarden Vektoren
```

**Faustregel:**
- Unter 500k Vektoren → pgvector reicht, kein extra Service nötig
- Über 500k oder komplexe Filter → Qdrant (🇩🇪, DSGVO-freundlich)
- Managed ohne Ops → Pinecone oder Qdrant Cloud

---

## RAG-Pipeline — wie es zusammenhängt

RAG (Retrieval Augmented Generation) lässt das LLM auf **deinen eigenen Daten** antworten, ohne Fine-Tuning.

```
Einmalig (Indexierung):
Dokument → Text-Chunks → Embedding-Modell → Vektoren → Vector DB

Pro Anfrage (Retrieval):
User-Frage
    │
    ▼
Frage als Vektor (Embedding-Modell)
    │
    ▼
Vector DB: semantisch ähnliche Chunks finden
    │
    ▼
Chunks + Original-Frage → LLM-Prompt
    │
    ▼
Antwort auf Basis deiner Daten → User
    │
    ▼
Langfuse: Trace mit Chunks, Prompt, Antwort, Latenz, Kosten
```

**Wo es scheitert:**
- Chunks zu groß → zu viel irrelevanter Kontext
- Chunks zu klein → fehlendes Zusammenhang
- Embedding-Modell passt nicht zur Sprache (Deutsch!)
- Context Window voll → wichtige Chunks fallen raus

---

## Semantisches Caching — unterschätzter Kostenhebel

Normales Caching speichert exakte Anfragen. Semantisches Caching erkennt **bedeutungsgleiche** Anfragen:

```
User A: "Was ist der Unterschied zwischen RAG und Fine-Tuning?"
→ LLM-Call, kostet $0.02, Antwort im Cache

User B: "Erkläre RAG vs. Fine-Tuning"   ← semantisch gleich
→ Cache-Hit, kostet $0.00

Ersparnis: 40–70% der LLM-Kosten bei ähnlichen Anfragen
```

Funktioniert über Embedding-Ähnlichkeit: beide Fragen landen als Vektor nah beieinander → gleiche Antwort.

**Tool:** LiteLLM Proxy + Redis (eingebaut, kein Extra-Setup nötig)

---

## OpenTelemetry — alles verbinden

OTel ist kein Tool, sondern ein **Standard** (CNCF). Einmal instrumentiert, kannst du das Monitoring-Backend jederzeit wechseln.

```
App (FastAPI / Next.js)
    │  OTel SDK — automatisch: HTTP, DB-Queries, Redis-Calls
    ▼
OTel Collector
    ├──→ Prometheus   Metrics: Latenz, RPS, Fehlerrate
    ├──→ Loki         Logs: strukturiert, durchsuchbar
    ├──→ Tempo        Traces: Request-Pfad durch Services
    └──→ Langfuse     LLM-spezifische Traces
```

**Warum das wichtig ist:** Ohne OTel sitzt du später vor 4 verschiedenen SDKs und Datenformaten. Mit OTel: eine Instrumentierung, alle Tools bekommen ihre Daten.

---

## Fine-Tuning vs. RAG — wann was?

| | **RAG** | **Fine-Tuning** |
|---|---|---|
| **Daten ändern sich** | ✅ ideal | ❌ Neutraining nötig |
| **Fakten aktuell halten** | ✅ | ❌ |
| **Quellen nachvollziehbar** | ✅ | ❌ |
| **Schnell umsetzbar** | ✅ Tage | ❌ Wochen + GPU-Kosten |
| **Konsistenter Stil / Ton** | ⚠️ schwierig | ✅ |
| **Domänen-Vokabular** | ⚠️ mit Prompting | ✅ |
| **Sehr hohe Call-Frequenz** | ⚠️ Latenz durch Retrieval | ✅ schneller |
| **Wann sinnvoll** | **Standard-Fall** | **ab ~100k Calls/Tag** |

> Fine-Tuning ist ein Optimierungsschritt, kein Startpunkt.
> Fast alle Probleme lassen sich zuerst mit RAG + gutem Prompting lösen.

---

## Framework-Wahl — Lernkurve vs. Kontrolle

| Tool | Stärke | Wann nicht |
|---|---|---|
| **LangChain** | Riesiges Ökosystem, viele Tutorials, schneller Start | Wenn du debuggen musst — zu viel Magie |
| **LlamaIndex** | RAG-fokussiert, Dokument-Pipelines gut gelöst | Kein reines RAG-Projekt |
| **Pydantic AI** | Type-safe, Python-nativ, leichtgewichtig, gut debuggbar | TypeScript-Stack |
| **Vercel AI SDK** | Streaming + React Hooks out-of-the-box | Python-Backend |
| **Haystack** | Enterprise RAG, explizit für Deutsch optimiert | Kleine Projekte |
| **Direkter SDK-Call** | Volle Kontrolle, kein Overhead | Wenn viele Integrationen nötig |

> **Praxiserfahrung:** Viele Teams starten mit LangChain, ersetzen es später durch
> eigenen Code + LiteLLM. Die Abstraktion hilft beim Lernen, kostet in Produktion
> Debugbarkeit.

---

## Der rote Faden — was zuerst, was später

```
JETZT (MVP):
├── LLM direkt ansprechen                  simpel, funktioniert
├── Langfuse von Anfang an einbinden       Traces kosten nichts, helfen viel
├── Postgres für alles                     pgvector wenn RAG kommt
└── Sentry                                 5 Minuten, sofort Mehrwert

WENN ES WÄCHST:
├── LiteLLM Proxy einführen               Provider-Flexibilität + Fallback
├── Queue für async LLM-Jobs              keine HTTP-Timeouts mehr
├── Semantisches Caching                  Kosten senken
└── CI/CD + Staging                       kein "works on my machine" mehr

WENN ES SKALIERT:
├── Kubernetes                            erst dann, nicht früher
├── OpenTelemetry                         alles mit einem Standard verbinden
├── Managed Databases                     kein DB-Ops mehr selbst
└── Fine-Tuning evaluieren               lohnt erst ab ~100k Calls/Tag
```

---

## Was du mit Langfuse self-hosted bereits hast

```
✅ Langfuse     LLM Tracing, Evals, Prompt-Management
✅ PostgreSQL   Datenpersistenz
✅ ClickHouse   Skalierbare Event-Daten (Millionen Traces)
✅ Redis        Queue & Cache
✅ MinIO        S3-kompatibler Blob Storage

Nächste sinnvolle Schritte:
⬜ LiteLLM     LLM Gateway — 1 Docker Container
⬜ Sentry       Error Tracking — 5 Minuten Aufwand
⬜ pgvector     RAG wenn Dokumente ins Spiel kommen
⬜ Eine App die das alles nutzt 😄
```
