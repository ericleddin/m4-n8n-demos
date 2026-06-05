---
title: "LLM Learning"
weight: 2
---

Community-Beiträge mit ergänzender Konzept-Dokumentation rund um LLM-Entwicklung, Observability und KI-Infrastruktur. Die Dateien hier sind keine Code-Demos, sondern vertiefende Erklärungen — zur Orientierung, zum Nachschlagen oder als Ergänzung zum Live-Unterricht.

**Stand der Inhalte:** Mai 2026. Besonders Tool- und Provider-Bewertungen in diesem Bereich altern schnell — bitte mit gesunder Skepsis lesen und aktuelle Quellen gegebenenfalls prüfen.

## Grundlagen

- **[Glossar](glossar/)** — Alle Fachbegriffe kurz erklärt: Token, Embedding, RAG, Vector DB, Inference, Prompt und mehr.
- **[Prompt Engineering](llm_prompt_engineering/)** — Wie man LLMs richtig anspricht: System-Prompt, Few-Shot, Chain-of-Thought, Sicherheit, Versionierung.
- **[RAG: Konzept & Praxis](rag_konzept_und_praxis/)** — RAG von Grund auf erklärt: Indexierung, Retrieval, Chunking, Embedding-Wahl, häufige Fehler und Qualitätsmessung.
- **[Kosten & Token](llm_kosten_und_token/)** — Wie Token-Preise funktionieren, was typische Calls kosten und wie man die größten Kostenfallen vermeidet.
- **[Lokale LLMs mit Ollama](lokale_llms_ollama/)** — LLMs lokal betreiben: Hardware, Setup, Modellwahl, Integration mit n8n und Langfuse.

## Sicherheit & Datenschutz

- **[RAG & DSGVO](rag_dsgvo_pseudonymisierung/)** — Architektur-Blueprint für DSGVO-konformes RAG mit PII-Erkennung und Pseudonymisierung.

## Agenten-Architektur

- **[Agenten-Patterns](agenten_architektur_patterns/)** — Wann Agent statt Workflow, Tool-Design, Memory-Patterns, Multi-Agent-Patterns, Failure-Modes und Produktions-Checkliste.

## Stack & Infrastruktur

- **[Best Practice Tech Stack 2026](best_practice_tech_stack_2026/)** — Vollständiger Tech-Stack von Solo-Projekt bis Enterprise.
- **[LLM App Tech Stack](llm_app_techstack_overview/)** — Das Warum hinter den Stack-Entscheidungen: LiteLLM, pgvector, semantisches Caching, OTel.
- **[KI-Infrastruktur & Scaling](ki-infrastruktur_agent_scaling_guide/)** — Strategische Perspektive auf KI-Infrastruktur und Agenten-Systeme.

## Observability

- **[Langfuse vs. Langsmith](langfuse_vs_langsmith/)** — Direktvergleich der beiden führenden LLM-Observability-Plattformen.
- **[Observability Tools](observability_monitoring_tools/)** — Die drei Observability-Schichten (Logs, Metrics, Traces) und Tool-Empfehlungen.

## Empfohlene Lesereihenfolge

```
Neu im Thema?
└── 1. Glossar
    2. Prompt Engineering
    3. RAG: Konzept & Praxis
    4. Kosten & Token
    5. Best Practice Tech Stack 2026
    6. LLM App Tech Stack
    7. Langfuse vs. Langsmith
    8. Observability Tools
    9. Lokale LLMs mit Ollama
   10. RAG & DSGVO
   11. Agenten-Patterns
   12. KI-Infrastruktur & Scaling
```

## Beiträge willkommen

Ergänzungen und Korrekturen sind herzlich willkommen. Bitte halte dich an die bestehenden Konventionen:

- **Deutsch**, **du-Form**, konkret und ohne Füllwörter
- Tabellen und ASCII-Diagramme für Vergleiche bevorzugen
- Code-Beispiele gehören **nicht** hierher — die liegen unter `workflows/`
