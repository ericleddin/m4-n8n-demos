---
title: "Observability & Monitoring"
weight: 80
---

# Observability & Monitoring — Von klein/on-premise bis groß/Cloud

> Observability beantwortet die Frage: **"Was passiert gerade in meinem System?"**
> Monitoring beantwortet: **"Ist alles okay?"**
> Beide gehören zusammen.

---

## Die drei Säulen der Observability

```
        LOGS              METRICS            TRACES
   "Was ist passiert?"  "Wie läuft es?"   "Wo ist es langsam?"

   Zeitgestempelte       Zahlen über       Pfad einer Anfrage
   Ereignisse            Zeit (CPU, RPS,   durch verteilte
   (Errors, Infos)       Latenz, p99)      Services
        │                    │                  │
        └────────────────────┴──────────────────┘
                             │
                     Observability Platform
```

---

## Schichten moderner Observability

```
┌──────────────────────────────────────────────────────────────┐
│  LLM-Schicht (AI-spezifisch)                                 │
│  Langfuse · LangSmith · Helicone · Phoenix                   │
│  Prompts, Token-Kosten, Evals, Halluzinationen               │
├──────────────────────────────────────────────────────────────┤
│  Application-Schicht (APM / Error Tracking)                  │
│  Sentry · Datadog APM · Highlight.run · Rollbar              │
│  Exceptions, Stack Traces, User-Sessions, Deployments        │
├──────────────────────────────────────────────────────────────┤
│  Infrastruktur-Schicht (Metrics, Logs, Infra)                │
│  Prometheus + Grafana · Datadog · VictoriaMetrics · Netdata  │
│  CPU, RAM, Disk, Netzwerk, Container-Health, DB-Queries      │
└──────────────────────────────────────────────────────────────┘
```

---

## Stufe 1 — Klein & On-Premise (Einzelperson / Homelab / kleines Team)

### Einstieg: Was brauche ich wirklich?

Für einen Solo-Dev oder ein kleines Team reicht oft:

| Was | Tool | Aufwand |
|---|---|---|
| App-Fehler sehen | **Sentry** (Free Tier) | 5 Minuten (`pip install sentry-sdk`) |
| Server-Metriken | **Netdata** | 1 Befehl (curl-Installer) |
| Logs durchsuchen | **Dozzle** (Docker-Logs UI) | 1 Docker Container |
| LLM Tracing | **Langfuse** self-hosted | Docker Compose (bereits gemacht ✅) |

### Netdata — schnellster Start für Infra-Monitoring

```bash
curl https://my-netdata.io/kickstart.sh > /tmp/netdata-kickstart.sh
sh /tmp/netdata-kickstart.sh
```

- Automatisch: CPU, RAM, Disk, Netzwerk, Docker-Container, PostgreSQL, Redis, …
- Web-UI auf Port 19999
- Kein Prometheus, kein Grafana nötig für den Start
- Nachteil: kurzfristige Metriken, kein gutes Long-Term-Storage

### Dozzle — Docker-Logs im Browser

```yaml
# docker-compose.yml
services:
  dozzle:
    image: amir20/dozzle
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - 9999:8080
```

→ Alle Docker-Container-Logs auf einen Blick, Echtzeit, mit Suche.

---

## Stufe 2 — Mittlere Größe (Team / eigener Server / VPS)

### Der Klassiker: Prometheus + Grafana

```
App / Exporter          Prometheus              Grafana
─────────────     →    ──────────────    →    ──────────────
/metrics endpoint       Scraping &             Dashboards
(HTTP, Pull-Modell)     Speicherung            Alerting
                        (TSDB)                 (Visualisierung)
```

**Prometheus** scrapt in konfigurierten Intervallen Metriken-Endpoints ab:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'meine-app'
    static_configs:
      - targets: ['app:8080']   # App muss /metrics exponieren
```

**Exporters** für gängige Services:
- `node_exporter` → Linux System-Metriken
- `postgres_exporter` → PostgreSQL
- `redis_exporter` → Redis
- `cadvisor` → Docker Container
- viele weitere auf [exporterhub.io](https://exporterhub.io)

**Grafana** verbindet sich zu Prometheus und zeigt Dashboards:
- Tausende Community-Dashboards auf grafana.com/dashboards
- Dashboard für Node Exporter: ID `1860` (einfach importieren)

### Logs: Loki (Grafana's Log-Tool)

```
App / Docker Container
        │
    Promtail          ←  Log-Shipper (wie ein Tail -f)
        │
      Loki            ←  Log-Speicher (wie Prometheus, aber für Logs)
        │
    Grafana           ←  Logs + Metriken in einem UI (LogQL)
```

> **Vorteil:** Loki ist ressourcenschonend — es indexiert nur Labels, nicht den
> Log-Inhalt. Perfekt für On-Premise.

### Kompletter Stack mit Docker Compose

```yaml
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

  loki:
    image: grafana/loki

  promtail:
    image: grafana/promtail
    volumes:
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers
```

### Error Tracking: Sentry (self-hosted)

```bash
# Sentry hat ein eigenes docker-compose Setup
git clone https://github.com/getsentry/self-hosted.git
cd self-hosted
./install.sh
docker compose up -d
```

- Vollständiges Sentry auf deinem eigenen Server
- Empfohlen: mind. 4 GB RAM, 20 GB Disk

---

## Stufe 3 — Groß & Cloud (skalierte Produktion)

### Option A: Managed — Alles aus einer Hand

#### **Datadog** — Der Enterprise-Standard

```
Alles in einem:
├── APM (Tracing, Profiling)
├── Logs (strukturiert, mit ML-Anomalie-Erkennung)
├── Metrics (Infra, Custom)
├── Synthetics (Uptime Monitoring)
├── RUM (Real User Monitoring)
├── Security (SIEM, CSPM)
└── AI Observability (LLM-Tracing, Kosten)
```

- Agent auf jedem Server → sendet alles zu Datadog
- Sehr mächtig, sehr teuer (~$23/Host/Monat, Logs extra)
- De-facto-Standard in größeren Tech-Unternehmen

#### **Grafana Cloud** — Managed Prometheus/Loki/Tempo

- Selber Stack wie self-hosted, aber managed
- Generous Free Tier (10k Metrics, 50 GB Logs, 50 GB Traces)
- Gute Wahl wenn man Prometheus/Grafana kennt aber kein Ops-Team hat

#### **New Relic** — APM-Fokus

- Ähnlich Datadog, historisch stärker im APM-Bereich
- Free Tier mit 100 GB/Monat Daten

### Option B: Open Source, skaliert

#### **VictoriaMetrics** — Prometheus-kompatibler Ersatz

- Drop-in Replacement für Prometheus
- Deutlich ressourcenschonender, bessere Kompression
- Eignet sich für Multi-Tenant Setups

#### **OpenTelemetry (OTel)** — Das Protokoll der Zukunft

```
App mit OTel-SDK
      │
  OTel Collector   ←  sammelt Logs, Metrics, Traces
      │
      ├──→  Prometheus (Metrics)
      ├──→  Loki (Logs)
      ├──→  Tempo / Jaeger (Traces)
      ├──→  Langfuse (LLM Traces)
      └──→  Sentry / Datadog / ...
```

> **Wichtig:** OTel ist kein Tool, sondern ein **Standard** (CNCF).
> Einmal instrumentiert, kannst du das Backend jederzeit wechseln.

```python
# Python Beispiel mit OTel
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider

tracer = trace.get_tracer("meine-app")

with tracer.start_as_current_span("db-query") as span:
    span.set_attribute("db.statement", "SELECT ...")
    # ... Code ...
```

---

## Sentry im Kontext

Sentry hat seinen ganz eigenen Bereich: **Application Error Monitoring**

```
Was Sentry einzigartig macht:
├── Exception mit vollständigem Stack Trace
├── Kontext: welcher User, welcher Browser, welche Version
├── Release-Tracking: "Fehler trat erstmals in v2.3.1 auf"
├── Source Maps (JavaScript Minification auflösen)
├── Performance Tracing (Spans, DB-Queries, HTTP)
└── Alerts + Issue-Gruppierung per ML
```

Sentry ergänzt Prometheus/Grafana — es ersetzt sie nicht:
- Grafana sagt: **"Fehlerrate ist gestiegen"**
- Sentry sagt: **"Zeile 42 in user_service.py, NullPointerException, betrifft 143 User"**

---

## Entscheidungsbaum

```
Wie groß ist dein Setup?
│
├── Einzelperson / Homelab
│   └── Netdata + Dozzle + Sentry Free + Langfuse self-hosted
│
├── Kleines Team (2-10 Personen, 1-5 Server)
│   └── Prometheus + Grafana + Loki + Sentry self-hosted
│
├── Mittleres Team (eigene Infra, Kubernetes)
│   └── Prometheus + Grafana + Loki + Tempo + Sentry + OTel
│       oder: Grafana Cloud (managed, spart Ops-Aufwand)
│
└── Großes Team / Enterprise
    ├── Datadog (alles in einem, wenn Budget da)
    ├── Grafana Cloud + Sentry Cloud (günstiger)
    └── Self-managed OTel-Stack auf K8s (volle Kontrolle)
```

---

## Toolübersicht kompakt

| Tool | Kategorie | Hosting | Kosten | Stärke |
|---|---|---|---|---|
| **Prometheus** | Metrics | Self-hosted | Free | Standard, riesiges Ökosystem |
| **Grafana** | Visualisierung | Both | Free/Cloud | Dashboards, Alerting |
| **Loki** | Logs | Both | Free/Cloud | Günstig, Grafana-integriert |
| **Tempo** | Traces | Both | Free/Cloud | Grafana-Stack Tracing |
| **VictoriaMetrics** | Metrics | Self-hosted | Free | Ressourcenschonend, schnell |
| **Sentry** | Error Tracking | Both | Free Tier | Beste DX bei Exceptions |
| **Datadog** | All-in-one | Cloud | Teuer | Enterprise, vollständig |
| **New Relic** | APM/All-in-one | Cloud | Free Tier | APM-Fokus |
| **Netdata** | Infra Monitoring | Both | Free/Cloud | Schnellster Start |
| **Jaeger** | Tracing | Self-hosted | Free | Distributed Tracing, CNCF |
| **OpenTelemetry** | Standard/SDK | — | Free | Vendor-neutral Instrumentierung |
| **Langfuse** | LLM Observability | Both | Free/Paid | LLM Tracing, Evals |

---

## Empfohlener Lernpfad

1. **Sentry** einrichten (5 Minuten, Free Account) → Error Tracking verstehen
2. **Langfuse** self-hosted (bereits gemacht ✅) → LLM Tracing verstehen
3. **Prometheus + Grafana** mit Docker Compose → Metrics & Dashboards
4. **Loki + Promtail** dazu → Logs zentralisieren
5. **OpenTelemetry** in eine App integrieren → Vendor-Lock-in vermeiden

> Wer diese 5 Schritte versteht, kann jeden Produktions-Stack einschätzen
> und debuggen — egal ob on-premise oder Cloud.
