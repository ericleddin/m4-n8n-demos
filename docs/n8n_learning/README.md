# n8n Learning Documentation

Community-Beiträge mit ergänzender Konzept-Dokumentation zum M4-Curriculum. Die Dateien hier sind keine Workflow-Demos, sondern vertiefende Erklärungen — zur Vorbereitung, zum Nachschlagen oder als Ergänzung zum Live-Unterricht.

**Stand der Inhalte:** Mai 2026. Vor allem die Tool- und Framework-Bewertungen in `ai_agent_ecosystem_overview.md` altern schnell — bitte mit gesunder Skepsis lesen und gegebenenfalls aktuelle Quellen prüfen.

## 📂 Inhalte

- **[n8n_datenfluss_kompendium.md](n8n_datenfluss_kompendium.md)** — n8n-Kern-Referenz: Datenmodell, Kontroll-Nodes, Fehler-Handling. Die wichtigste Datei, wenn du n8n vertieft verstehen willst.
- **[llm_agent_tools_intro.md](llm_agent_tools_intro.md)** — Konzeptuelle Einführung in LLMs, Agents und Tools. Architektur-Muster und Anti-Patterns, anbieterunabhängig.
- **[n8n_llm_integration.md](n8n_llm_integration.md)** — Die Brücke zwischen n8n und LLM-Infrastruktur: die vier Patterns (einfacher Call, RAG, Agent, Pipeline), Langfuse-Anbindung, Ollama in n8n und typische Workflow-Beispiele.
- **[n8n_developer_guide.md](n8n_developer_guide.md)** — Vertiefung für Studierende mit Dev-Background: Code-Node, AI-Nodes, Custom Community Nodes und Anbindung externer Services.
- **[ai_agent_ecosystem_overview.md](ai_agent_ecosystem_overview.md)** — Senior-Level-Überblick über das AI-Tool-Ökosystem (Provider-SDKs, Frameworks, Vector Stores, etc.). Die Bewertungen reflektieren den Stand Mai 2026 und altern schnell.
- **[mermaid_color_schema.md](mermaid_color_schema.md)** — Internes Farbschema für Mermaid-Diagramme in den Doku-Files.

## 🤝 Beiträge willkommen

Ergänzungen und Korrekturen zur Doku sind herzlich willkommen. Bitte halte dich an die bestehenden Konventionen:

- **Deutsch**, **du-Form**, konkret und ohne Füllwörter
- Mermaid-Diagramme nach dem [Farbschema](mermaid_color_schema.md)
- Workflow-Demos gehören **nicht** hierher — die liegen unter `workflows/` (siehe [CLAUDE.md](../../CLAUDE.md))
