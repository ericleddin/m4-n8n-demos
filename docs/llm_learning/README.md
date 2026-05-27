# LLM Learning Documentation

Community-Beiträge mit ergänzender Konzept-Dokumentation rund um LLM-Entwicklung, Observability und KI-Infrastruktur. Die Dateien hier sind keine Code-Demos, sondern vertiefende Erklärungen — zur Orientierung, zum Nachschlagen oder als Ergänzung zum Live-Unterricht.

**Stand der Inhalte:** Mai 2026. Besonders Tool- und Provider-Bewertungen in diesem Bereich altern schnell — bitte mit gesunder Skepsis lesen und aktuelle Quellen gegebenenfalls prüfen.

## 📂 Inhalte

- **[best_practice_tech_stack_2026.md](dozent/m4-n8n-demos/docs/llm_learning/best_practice_tech_stack_2026.md)** — Die wichtigste Datei für den Einstieg: vollständiger Tech-Stack von Solo-Projekt bis Enterprise, mit Cloud-Diensten, EU/DSGVO-Bewertung und konkreten Kostenangaben pro Stufe.
- **[llm_app_techstack_overview.md](dozent/m4-n8n-demos/docs/llm_learning/llm_app_techstack_overview.md)** — Das **Warum** hinter den Stack-Entscheidungen: LiteLLM, pgvector vs. Qdrant, RAG-Pipeline, semantisches Caching, OTel, Fine-Tuning vs. RAG. Konzepte statt Tool-Listen.
- **[langfuse_vs_langsmith.md](dozent/m4-n8n-demos/docs/llm_learning/langfuse_vs_langsmith.md)** — Direktvergleich der beiden führenden LLM-Observability-Plattformen: Architektur, Kosten, Integration, Codebeispiele und Entscheidungshilfe.
- **[observability_monitoring_tools.md](dozent/m4-n8n-demos/docs/llm_learning/observability_monitoring_tools.md)** — Überblick über die drei Observability-Schichten (Logs, Metrics, Traces) und konkrete Tool-Empfehlungen von Netdata/Dozzle auf dem Homelab bis Datadog im Enterprise.
- **[ki-infrastruktur_agent_scaling_guide.md](dozent/m4-n8n-demos/docs/llm_learning/ki-infrastruktur_agent_scaling_guide.md)** — Strategische Perspektive auf KI-Infrastruktur und Agenten-Systeme: Vertrauensentscheidungen bei API-Quellen, Datensicherheit, Flexibilität und Skalierbarkeit.

## 🗺️ Empfohlene Lesereihenfolge

```
Neu im Thema?
└── 1. best_practice_tech_stack_2026.md      ← Orientierung verschaffen
    2. llm_app_techstack_overview.md          ← Bausteine verstehen
    3. langfuse_vs_langsmith.md               ← Observability konkret
    4. observability_monitoring_tools.md      ← Monitoring-Schichten
    5. ki-infrastruktur_agent_scaling_guide.md ← Strategische Tiefe
```

## 🤝 Beiträge willkommen

Ergänzungen und Korrekturen sind herzlich willkommen. Bitte halte dich an die bestehenden Konventionen:

- **Deutsch**, **du-Form**, konkret und ohne Füllwörter
- Tabellen und ASCII-Diagramme für Vergleiche bevorzugen
- Code-Beispiele gehören **nicht** hierher — die liegen unter `workflows/` bzw. in den jeweiligen Projekt-Repos (siehe [CLAUDE.md](../../CLAUDE.md))
