# Best-Practice Tech Stack 2026 — Development, Betrieb & LLM

> **Philosophie deines Dozenten:** *"Nimm den Cloud-Dienst"* ist fast immer richtig
> solange du lernst **was** dahinter steckt. Cloud spart Ops-Zeit — die du in
> Produkt und Features investierst. Kosten kommen erst wenn du skalierst.
>
> Diese Übersicht zeigt: Was nutzt die Szene 2026 — und warum?

---

## Struktur einer modernen KI-App

```
┌─────────────────────────────────────────────────────────────────┐
│  Frontend / Client                                              │
│  Next.js · React · Mobile (Expo)                                │
├─────────────────────────────────────────────────────────────────┤
│  Backend / API Layer                                            │
│  Next.js API Routes · FastAPI · tRPC                            │
├──────────────────────┬──────────────────────────────────────────┤
│  LLM Layer           │  Data Layer                             │
│  Provider · Gateway  │  Postgres · Vector DB · Cache           │
│  Orchestration       │  Object Storage · Queue                 │
├──────────────────────┴──────────────────────────────────────────┤
│  Observability                                                  │
│  LLM Tracing · APM · Logs · Metrics                            │
├─────────────────────────────────────────────────────────────────┤
│  Infra / Hosting / CI/CD                                        │
│  Cloud Provider · Container · Deploy Pipeline                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. LLM Provider — Das Herzstück

### Closed Source (beste Qualität, einfachster Start)

| Provider | Modelle | Stärke | EU-Datenschutz |
|---|---|---|---|
| **OpenAI** | GPT-4o, o3, o4-mini | Bestes Ökosystem, meiste Integrationen | ⚠️ US-Unternehmen, DPA möglich |
| **Anthropic** | Claude Sonnet 4.6, Opus 4.7 | Beste Reasoning & Safety | ⚠️ US-Unternehmen |
| **Google Gemini** | Gemini 2.5 Pro/Flash | Multimodal, langer Context (1M Token) | ⚠️ US-Unternehmen |
| **Mistral AI** | Mistral Large, Codestral | 🇪🇺 Französisch, DSGVO-freundlich | ✅ EU-Unternehmen, EU-Hosting |
| **Cohere** | Command R+ | RAG-optimiert, Enterprise-fokussiert | ✅ GDPR-konform, EU-Region |

### Open Source / Self-Hosted (volle Datenkontrolle)

| Modell | Stärke | Hosting |
|---|---|---|
| **Llama 3.3 / 4** (Meta) | Beste Open-Source-Qualität | Ollama, vLLM, Together AI |
| **Mistral 7B / 24B** | Effizient, sehr gut für Größe | Ollama, Hugging Face |
| **Qwen 2.5** (Alibaba) | Stark bei Code & Reasoning | Ollama, vLLM |
| **Phi-4** (Microsoft) | Klein, schnell, überraschend gut | Ollama |
| **DeepSeek R1** | Reasoning-Fokus | Ollama, Together AI |

### 🇪🇺 EU-konforme LLM-Optionen — wichtig für Produktion

```
Priorität 1 — EU-Unternehmen & EU-Hosting:
├── Mistral AI (Paris) → api.mistral.ai
├── Aleph Alpha (Heidelberg) → Luminous-Modelle, sehr DSGVO-fokussiert
└── DeepL (Köln) → spezialisiert auf Übersetzung/Dokumente

Priorität 2 — US-Anbieter mit EU-Hosting & DPA:
├── OpenAI → EU Data Residency (Enterprise)
├── Azure OpenAI → Hosting in swedencentral / germanywestcentral
├── Google Vertex AI → europe-west Region
└── AWS Bedrock → eu-central-1 (Frankfurt)

Priorität 3 — Self-Hosted (100% Kontrolle):
└── Ollama / vLLM + Open-Source-Modell auf eigenem Server
```

> **Faustregel für Deutschland:** Mistral AI oder Azure OpenAI (EU-Region) sind
> der pragmatischste Weg für DSGVO-Compliance ohne Self-Hosting.

---

## 2. LLM Gateway & Orchestrierung

Ein **Gateway** sitzt zwischen deiner App und den LLM-Providern —
für Routing, Fallbacks, Caching, Rate-Limiting.

| Tool | Typ | Stärke | Hosting |
|---|---|---|---|
| **LiteLLM** | Open Source Gateway | Unified API für 100+ Modelle, Fallback-Routing | Self-hosted / Cloud |
| **Portkey** | Managed Gateway | Observability, Guardrails, Caching | Cloud (EU-Region) |
| **OpenRouter** | Managed Gateway | Günstig, viele Modelle, einfacher Start | Cloud |
| **AWS Bedrock** | Cloud Service | Enterprise, viele Modelle, IAM-Integration | AWS EU |
| **Azure AI Foundry** | Cloud Service | OpenAI + andere Modelle, Enterprise DSGVO | Azure EU |

### Orchestrierung / Frameworks

| Tool | Stärke | Wann nutzen? |
|---|---|---|
| **LangChain** | Riesiges Ökosystem, viele Integrationen | Wenn schnell was bauen, viele Tutorials |
| **LlamaIndex** | RAG-fokussiert, Dokumenten-Pipelines | Wenn Hauptfeature RAG/Suche ist |
| **LangGraph** | Agents & Workflows als Graph | Komplexe Multi-Step Agents |
| **Pydantic AI** | Type-safe, Python-nativ, leichtgewichtig | Moderner Ansatz, weniger Magic |
| **Vercel AI SDK** | TypeScript/Next.js nativ | Frontend-nahe KI-Features, Streaming |
| **Direkter API-Call** | Kein Overhead, volle Kontrolle | Wenn nur 1-2 LLM-Calls nötig |

> **2026-Trend:** Viele Teams steigen von LangChain auf **direktere Ansätze**
> (Pydantic AI, direkter SDK-Call) um — weniger Magie, besser debuggbar.

---

## 3. Datenbank-Schicht

### Primäre Datenbank (relationale Daten)

| Tool | Typ | Wann | Cloud-Option |
|---|---|---|---|
| **PostgreSQL** | SQL | Standard für alles | Neon, Supabase, Railway |
| **Supabase** | Postgres + Auth + Realtime | Wenn schnell Fullstack-Backend nötig | ✅ EU-Hosting |
| **PlanetScale** | MySQL serverless | Schemaless-Migrations-Workflow | Cloud |
| **Turso** | SQLite distributed | Edge-Apps, sehr günstig | Cloud |

### Vector Database (für RAG / Embeddings)

```
RAG = Retrieval Augmented Generation
Deine Dokumente → Embeddings → Vector DB → bei Query: ähnliche Chunks finden
→ als Kontext an LLM geben → Antwort auf Basis deiner eigenen Daten
```

| Tool | Stärke | Hosting |
|---|---|---|
| **pgvector** | Postgres-Extension, kein extra Service | Self-hosted / Supabase |
| **Qdrant** | 🇩🇪 Deutsch, sehr performant, DSGVO | Self-hosted / Cloud (EU) |
| **Weaviate** | 🇳🇱 Niederländisch, DSGVO, GraphQL | Self-hosted / Cloud (EU) |
| **Pinecone** | Managed, einfachster Start | Cloud (EU-Region verfügbar) |
| **Chroma** | Lokal/einfach, gut zum Lernen | Self-hosted |
| **Milvus** | Open Source, hochskalierbar | Self-hosted / Zilliz Cloud |

> **Empfehlung Einstieg:** `pgvector` — du hast Postgres sowieso, kein extra Service.
> **Empfehlung Produktion EU:** Qdrant (🇩🇪) oder Weaviate (🇳🇱).

### Cache

| Tool | Use Case | Cloud |
|---|---|---|
| **Redis** | Session, Rate-Limiting, LLM-Response-Cache | Upstash (serverless, EU) |
| **Upstash** | Serverless Redis/Kafka, pay-per-request | ✅ EU-Region |

---

## 4. Backend & API

| Tool | Sprache | Stärke | Wann |
|---|---|---|---|
| **Next.js** (App Router) | TypeScript | Frontend + API in einem, Vercel-optimiert | Fullstack Web-Apps |
| **FastAPI** | Python | Schnell, automatisches OpenAPI, async | Python-LLM-Backends |
| **tRPC** | TypeScript | Type-safe API ohne Codegen, mit Next.js | Wenn Frontend + Backend TypeScript |
| **Hono** | TypeScript | Ultra-leichtgewichtig, Edge-optimiert | Serverless / Edge Functions |
| **Django + DRF** | Python | Batteries included, Admin-Panel | Wenn viel Datenmodell-Arbeit |

---

## 5. Auth & Identität

| Tool | Stärke | Hosting |
|---|---|---|
| **Clerk** | Beste DX, UI-Components inklusive | Cloud (EU-Region) |
| **Auth.js (NextAuth)** | Open Source, Next.js-nativ | Self-hosted |
| **Supabase Auth** | Integriert wenn Supabase als DB | Cloud (EU) |
| **Keycloak** | Enterprise, SAML/OIDC, vollständige Kontrolle | Self-hosted |
| **Zitadel** | 🇨🇭 Schweizer Alternative zu Keycloak | Self-hosted / Cloud |

> **DSGVO-Hinweis:** Clerk hat EU-Hosting, aber es ist ein US-Unternehmen.
> Für strikte Anforderungen: Keycloak oder Zitadel self-hosted.

---

## 6. Hosting & Deployment

### Frontend / Fullstack

| Platform | Stärke | Preis |
|---|---|---|
| **Vercel** | Beste Next.js-Integration, DX unschlagbar | Free Tier / ~$20/Monat |
| **Netlify** | Ähnlich Vercel, framework-agnostischer | Free Tier |
| **Cloudflare Pages** | Edge-global, sehr günstig | Free Tier |

### Backend / Container

| Platform | Stärke | Preis |
|---|---|---|
| **Railway** | Einfachstes Container-Hosting, Postgres inklusive | ~$5/Monat |
| **Render** | Ähnlich Railway, gute Free Tier | Free / ~$7/Monat |
| **Fly.io** | Docker überall, Edge-Locations, Entwicklerfreundlich | Pay-per-use |
| **Hetzner Cloud** | 🇩🇪 Günstigste VPS, DSGVO, sehr beliebt in EU | ab €4/Monat |
| **AWS ECS / Fargate** | Serverless Container, kein K8s nötig | Pay-per-use |
| **Google Cloud Run** | Serverless Container, einfacher als K8s | Pay-per-use |

### Kubernetes (wenn wirklich nötig)

```
Wann Kubernetes?
├── Du hast ein Ops-Team → ggf. sinnvoll
├── Du bist allein oder kleines Team → zu viel Overhead
└── Empfehlung: Railway / Render / Fly.io bis du wirklich skalieren musst
```

| Managed K8s | Provider | EU-Region |
|---|---|---|
| EKS | AWS | ✅ Frankfurt |
| GKE | Google | ✅ Europe |
| AKS | Azure | ✅ Germany |
| **Hetzner K3s** | Hetzner | ✅ 🇩🇪 günstig |

---

## 7. Observability (Zusammenfassung)

| Schicht | Tool | Typ | EU-Option |
|---|---|---|---|
| LLM Tracing | **Langfuse** | Self-hosted / Cloud | ✅ Self-hosted |
| Error Tracking | **Sentry** | Cloud | ✅ sentry.io EU |
| Metrics + Dashboards | **Grafana Cloud** | Cloud | ✅ EU-Region |
| Logs | **Grafana Loki** | Self-hosted / Cloud | ✅ |
| All-in-One | **Datadog** | Cloud | ✅ EU-Region |
| Uptime Monitoring | **Better Uptime** | Cloud | ✅ |
| Uptime (günstig) | **UptimeRobot** | Cloud | ✅ |

---

## 8. CI/CD & Developer Tooling

| Tool | Zweck | Empfehlung |
|---|---|---|
| **GitHub Actions** | CI/CD, Automation | Standard, kostenlos für Public Repos |
| **GitLab CI** | CI/CD, eigenes Hosting möglich | Gut für on-premise |
| **Doppler** | Secrets Management | Cloud, einfacher als Vault |
| **Infisical** | Secrets Management Open Source | Self-hosted / Cloud (EU) |
| **Turborepo** | Monorepo Build-Tool | Wenn Monorepo (wie Langfuse selbst) |

---

## 9. Queues & Background Jobs

| Tool | Stärke | Hosting |
|---|---|---|
| **BullMQ** | Redis-basiert, Node.js-nativ | Self-hosted mit Upstash |
| **Inngest** | Serverless Jobs, Event-driven, sehr gute DX | Cloud |
| **Trigger.dev** | Open Source, selbst hostbar, Background Jobs | Self-hosted / Cloud |
| **AWS SQS** | Managed Queue, hochzuverlässig | AWS EU |
| **CloudAMQP** | Managed RabbitMQ | Cloud (EU) |

---

## Stack-Empfehlungen nach Größe

> Gleiche Schicht, zwei Sprach-Welten — was identisch ist, steht in der Mitte.
> TS = TypeScript-Ökosystem · PY = Python-Ökosystem

### 🟢 Klein — Solo / Lernprojekt / MVP

**Ziel:** Schnell live kommen, wenig Ops-Aufwand · **Kosten:** ~€0–20/Monat · **Infra-Aufwand:** < 1 Tag

| Schicht | TypeScript | Gleich | Python |
|---|---|---|---|
| **LLM** | | OpenAI direkt (oder Mistral für EU) | |
| **Framework** | Vercel AI SDK | — | direkter `openai`-SDK-Call |
| **Backend** | Next.js API Routes | — | FastAPI |
| **Datenbank** | | Supabase (Postgres + Auth + pgvector) | |
| **Observability** | | Langfuse Cloud (Hobby = kostenlos) + Sentry Free | |
| **Auth** | Supabase Auth oder Clerk Free Tier | — | Supabase Auth |
| **Hosting** | Vercel + Railway | — | Railway / Render |
| **Secrets** | | .env lokal → Plattform-Env-Vars in Prod | |
| **CI/CD** | | GitHub Actions | |

---

### 🟡 Mittel — Team / Startup / ernstes Produkt

**Ziel:** Stabil, skalierbar, DSGVO-bewusst · **Kosten:** ~€50–200/Monat · **Infra-Aufwand:** ~1 Woche

| Schicht | TypeScript | Gleich | Python |
|---|---|---|---|
| **LLM** | | Azure OpenAI (EU) oder Mistral AI | |
| **Gateway** | | LiteLLM self-hosted (Fallback + Caching) | |
| **Framework** | Vercel AI SDK + tRPC | — | Pydantic AI oder LlamaIndex |
| **Backend** | Next.js | — | FastAPI |
| **ORM** | Prisma | — | SQLAlchemy / Tortoise |
| **Datenbank** | | Postgres auf Hetzner oder Railway | |
| **Vector DB** | | pgvector (Einstieg) → Qdrant Cloud EU (Wachstum) | |
| **Cache** | | Upstash Redis (EU-Region) | |
| **Queue** | Inngest oder BullMQ | — | Celery + Redis oder Trigger.dev |
| **Observability** | | Langfuse self-hosted + Sentry + Grafana Cloud | |
| **Auth** | Clerk oder Auth.js | — | Keycloak self-hosted oder Zitadel |
| **Hosting** | Vercel (Frontend) + Fly.io | — | Hetzner VPS + Docker Compose |
| **CI/CD** | | GitHub Actions + Doppler (Secrets) | |

---

### 🔴 Groß — Scale / Enterprise

**Ziel:** Hochverfügbarkeit, Compliance, Multi-Team · **Kosten:** €500–5000+/Monat · **Infra-Aufwand:** dediziertes Platform-Team

| Schicht | TypeScript | Gleich | Python |
|---|---|---|---|
| **LLM** | | AWS Bedrock (EU) + eigene Fine-Tuned Modelle | |
| **Gateway** | | Portkey oder LiteLLM Cluster | |
| **Framework** | Vercel AI SDK / NestJS | — | FastAPI Microservices |
| **Datenbank** | | RDS PostgreSQL (Multi-AZ) + ClickHouse (Analytics) | |
| **Vector DB** | | Weaviate Cluster oder Pinecone Enterprise | |
| **Cache** | | ElastiCache Redis Cluster | |
| **Queue** | | AWS SQS + SNS | |
| **Storage** | | AWS S3 (eu-central-1) | |
| **Observability** | | Datadog oder Langfuse self-hosted + Grafana Stack + Sentry | |
| **Tracing** | | OpenTelemetry → OTel Collector → Grafana Tempo | |
| **Auth** | | Keycloak Cluster oder Okta / Azure AD | |
| **Hosting** | | AWS ECS Fargate / EKS (eu-central-1) oder Azure AKS | |
| **CI/CD** | | GitHub Actions + ArgoCD (GitOps) + Infisical | |
| **Security** | | AWS WAF + Cloudflare + Snyk (Code Scanning) | |

---

## Cloud-Dienste die die Szene 2026 als "gut" bewertet

### 🏆 Community-Favoriten

| Dienst | Warum geliebt |
|---|---|
| **Hetzner Cloud** | Günstigste performante VPS, 🇩🇪, DSGVO, riesige Dev-Community |
| **Supabase** | "Firebase aber open source und mit echtem SQL", sehr gute DX |
| **Vercel** | Deploy in 30 Sekunden, Preview-Deployments, Next.js-Heimat |
| **Railway** | "Heroku wie es hätte sein sollen", einfachstes Container-Hosting |
| **Upstash** | Serverless Redis/Kafka, pay-per-request, kein idle cost |
| **Fly.io** | Docker global deployen, Entwickler lieben die CLI |
| **Cloudflare** | CDN + Workers (Edge Computing) + R2 (günstiger S3-Ersatz) |
| **Neon** | Serverless Postgres, branching wie Git für DBs |
| **Trigger.dev** | Background Jobs die sich wie normaler Code anfühlen |
| **Inngest** | Event-driven Functions, sehr gute DX, kein Infra-Wissen nötig |

### 🇪🇺 EU-Fokus (DSGVO-bewusste Community)

| Dienst | Land | Besonderheit |
|---|---|---|
| **Hetzner** | 🇩🇪 | VPS, Object Storage, günstigster performanter Anbieter |
| **Scaleway** | 🇫🇷 | Cloud-Plattform, KI-Inferenz (H100s), komplett EU |
| **OVHcloud** | 🇫🇷 | Größter EU-Cloud-Anbieter, sehr günstig |
| **IONOS** | 🇩🇪 | Managed Kubernetes, S3-kompatibler Storage |
| **Mistral AI** | 🇫🇷 | LLM-Provider, EU-Datenschutz by design |
| **Qdrant** | 🇩🇪 | Vector DB, Open Source, EU-first |
| **Zitadel** | 🇨🇭 | Auth-Plattform, open source, DSGVO |

---

## Wichtigste Takeaways

```
1. "Nimm den Cloud-Dienst" stimmt — bis DSGVO oder Kosten dagegen sprechen.
   Dann: Hetzner + self-hosted Open Source.

2. Für LLMs in Deutschland: Azure OpenAI (EU-Region) oder Mistral AI
   sind der pragmatischste Weg zu Compliance.

3. Kein Kubernetes bevor du es wirklich brauchst.
   Railway / Fly.io / Render reichen sehr weit.

4. OpenTelemetry von Anfang an einbauen —
   dann kannst du das Monitoring-Backend jederzeit wechseln.

5. Vector DB? Fang mit pgvector an.
   Migriere zu Qdrant wenn pgvector zum Bottleneck wird.

6. Die Komplexität kommt nicht von KI allein —
   sie kommt davon, dass gute Software viele Probleme löst.
   Jede Schicht hat ihren Grund.
```

---

*Stand: 2026 — dieses Feld entwickelt sich schnell.
Tools die heute Standard sind, können in 12 Monaten überholt sein.*
