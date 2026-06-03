---
title: "Übersicht LLM Learning"
weight: 1
---

# LLM Learning Documentation

Community-Beiträge mit ergänzender Konzept-Dokumentation rund um LLM-Entwicklung, Observability und KI-Infrastruktur. Die Dateien hier sind keine Code-Demos, sondern vertiefende Erklärungen — zur Orientierung, zum Nachschlagen oder als Ergänzung zum Live-Unterricht.

**Stand der Inhalte:** Mai 2026. Besonders Tool- und Provider-Bewertungen in diesem Bereich altern schnell — bitte mit gesunder Skepsis lesen und aktuelle Quellen gegebenenfalls prüfen.

## 📂 Inhalte

### Grundlagen
- **[glossar.md](glossar.md)** — Alle Fachbegriffe kurz erklärt: Token, Embedding, RAG, Vector DB, Inference, Prompt und mehr. Beim ersten Lesen überfliegen, danach zum Nachschlagen.
- **[llm_prompt_engineering.md](llm_prompt_engineering.md)** — Wie man LLMs richtig anspricht: System-Prompt, Few-Shot, Chain-of-Thought, Sicherheit, Versionierung. Der praktischste Einstieg.
- **[rag_konzept_und_praxis.md](rag_konzept_und_praxis.md)** — RAG von Grund auf erklärt: Indexierung, Retrieval, Chunking, Embedding-Wahl, häufige Fehler und Qualitätsmessung.
- **[llm_kosten_und_token.md](llm_kosten_und_token.md)** — Wie Token-Preise funktionieren, was typische Calls kosten, die größten Kostenfallen und wie man sie vermeidet.
- **[lokale_llms_ollama.md](lokale_llms_ollama.md)** — LLMs lokal betreiben mit Ollama: Hardware, Setup, Modellwahl, Integration mit n8n und Langfuse.

### Sicherheit & Datenschutz
- **[rag_dsgvo_pseudonymisierung.md](rag_dsgvo_pseudonymisierung.md)** — Architektur-Blueprint für DSGVO-konformes RAG: wie PII per NER erkannt, durch semantische Platzhalter maskiert und über eine lokale Mapping-Datenbank de-pseudonymisiert wird — ohne die Vektorsuche zu zerstören.

### Agenten-Architektur
- **[agenten_architektur_patterns.md](agenten_architektur_patterns.md)** — Wann Agent statt Workflow, Tool-Design-Prinzipien, Memory-Patterns (Buffer/Summary/Vector), Multi-Agent-Patterns (Supervisor, Pipeline, Handoff), Failure-Modes und Produktions-Checkliste.

### Stack & Infrastruktur
- **[best_practice_tech_stack_2026.md](best_practice_tech_stack_2026.md)** — Vollständiger Tech-Stack von Solo-Projekt bis Enterprise, mit TS/Python-Vergleich, Cloud-Diensten und EU/DSGVO-Bewertung.
- **[llm_app_techstack_overview.md](llm_app_techstack_overview.md)** — Das **Warum** hinter den Stack-Entscheidungen: LiteLLM, pgvector vs. Qdrant, semantisches Caching, OTel, Fine-Tuning vs. RAG.
- **[ki-infrastruktur_agent_scaling_guide.md](ki-infrastruktur_agent_scaling_guide.md)** — Strategische Perspektive auf KI-Infrastruktur und Agenten-Systeme: API-Quellen, Frameworks, Observability.

### Observability
- **[langfuse_vs_langsmith.md](langfuse_vs_langsmith.md)** — Direktvergleich der beiden führenden LLM-Observability-Plattformen mit Architektur, Kosten und Entscheidungshilfe.
- **[observability_monitoring_tools.md](observability_monitoring_tools.md)** — Die drei Observability-Schichten (Logs, Metrics, Traces) und Tool-Empfehlungen von Homelab bis Enterprise.

## 🗺️ Empfohlene Lesereihenfolge

```
Neu im Thema?
└── 1. glossar.md                        ← Begriffe klären
    2. llm_prompt_engineering.md         ← Ersten LLM-Call verstehen
    3. rag_konzept_und_praxis.md         ← Eigene Daten einbinden
    4. llm_kosten_und_token.md           ← Kosten im Griff
    5. best_practice_tech_stack_2026.md  ← Gesamtbild
    6. llm_app_techstack_overview.md     ← Konzepte vertiefen
    7. langfuse_vs_langsmith.md          ← Observability konkret
    8. observability_monitoring_tools.md ← Monitoring-Schichten
    9. lokale_llms_ollama.md                  ← Lokal & datenschutzkonform
   10. rag_dsgvo_pseudonymisierung.md         ← PII schützen in RAG-Systemen
   11. agenten_architektur_patterns.md          ← Agenten bauen & absichern
   12. ki-infrastruktur_agent_scaling_guide.md ← Strategische Tiefe
```

## 🤝 Beiträge willkommen

Ergänzungen und Korrekturen sind herzlich willkommen. Bitte halte dich an die bestehenden Konventionen:

- **Deutsch**, **du-Form**, konkret und ohne Füllwörter
- Tabellen und ASCII-Diagramme für Vergleiche bevorzugen
- Code-Beispiele gehören **nicht** hierher — die liegen unter `workflows/` bzw. in den jeweiligen Projekt-Repos (siehe [CLAUDE.md](../../CLAUDE.md))
