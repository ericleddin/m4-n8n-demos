# KI-Infrastruktur & Agenten-Systeme — Strategische Übersicht

> Kernaspekte für den professionellen Einsatz von LLMs und KI-Agenten:
> Datensicherheit, Flexibilität und Skalierbarkeit im Überblick.

---

## 1. Das Fundament: Die Vertrauensentscheidung

Die Wahl der API-Quelle bestimmt, wie sicher deine Daten sind und wie flexibel du Modelle tauschen kannst.

| Kriterium | **OpenRouter** (Flexibilität) | **AWS Bedrock** (Sicherheit) |
|---|---|---|
| **Kurz** | Marktplatz mit Zugriff auf 300+ Modelle | Enterprise-KI-Festung in der Amazon-Cloud |
| **Fokus** | Aggregator für maximale Auswahl | Sicherheit, Compliance, Skalierbarkeit |
| **Datenschutz** | Abhängig von Sub-Providern (ZDR möglich) | SOC 2, HIPAA-konform; kein Training auf Daten |
| **Ideal für** | Prototyping, schnelle Tests, KMU | Konzerne und regulierte Branchen |
| **Link** | [openrouter.ai](https://openrouter.ai/) | [aws.amazon.com/bedrock](https://aws.amazon.com/bedrock/) |

---

## 2. Das Gehirn: Agenten-Frameworks

Agenten-Frameworks steuern die Logik — sie entscheiden, wann die KI eine Datenbank abfragt, eine E-Mail schreibt oder einen anderen Agenten aufruft.

### Cloud-native (integrierte Lösungen)

| Tool | Was es macht | Link |
|---|---|---|
| **AWS Agents for Bedrock** | Verbindet Modelle direkt mit AWS-Datenquellen und -Funktionen | [aws.amazon.com/bedrock/agents](https://aws.amazon.com/bedrock/agents/) |
| **Microsoft Copilot Studio** | KI-Assistenten in Teams, Office 365 und Dynamics — meist ohne Code | [copilotstudio.microsoft.com](https://www.microsoft.com/en-us/microsoft-copilot/microsoft-copilot-studio) |
| **Google Vertex AI Agent Builder** | Agenten auf Basis von Google-Suche und BigQuery-Daten | [cloud.google.com/vertex-ai](https://cloud.google.com/vertex-ai) |

### Code-first (für Entwickler-Teams)

| Tool | Was es macht | Link |
|---|---|---|
| **LangGraph** | KI-Abläufe als präzises Flussdiagramm — verhindert Endlosschleifen bei Agenten | [langchain.com/langgraph](https://www.langchain.com/langgraph) |
| **CrewAI** | Mehrere Agenten wie eine virtuelle Abteilung zusammenarbeiten lassen | [crewai.com](https://www.crewai.com/) |
| **Microsoft AutoGen (AG2)** | Agenten chatten miteinander um komplexe Probleme gemeinsam zu lösen | [microsoft.github.io/autogen](https://microsoft.github.io/autogen/) |

### No-Code / Enterprise-Plattformen

| Tool | Was es macht | Link |
|---|---|---|
| **Dust.tt** | Internes Wissen aus Slack, Notion und Drive sicher bündeln — Mitarbeiter können die KI zu Firmen-Interna befragen | [dust.tt](https://dust.tt/) |
| **Vellum AI** | Management-Konsole: verschiedene Prompts und Modelle wissenschaftlich vergleichen und überwachen | [vellum.ai](https://www.vellum.ai/) |

---

## 3. Die Kontrolle: Observability & Monitoring

Ohne Überwachung sind Agenten eine Black Box. Diese Tools machen sichtbar, was die KI denkt und kostet.

| Tool | Fokus | Link |
|---|---|---|
| **Langfuse** | Metriken über Kosten, Geschwindigkeit und Antwortqualität in Echtzeit — self-hostbar | [langfuse.com](https://langfuse.com/) |
| **LangSmith** | Debugging: jeden einzelnen Denkschritt eines Agenten visualisieren | [smith.langchain.com](https://smith.langchain.com/) |

→ Ausführlicher Vergleich: [langfuse_vs_langsmith.md](dozent/m4-n8n-demos/docs/llm_learning/langfuse_vs_langsmith.md)

---

## Zusammenfassung & Empfehlung

```
Maximale Sicherheit    → AWS Bedrock als API-Quelle
Komplexe Agenten-Logik → LangGraph oder CrewAI
Überwachung            → Langfuse (self-hosted) oder LangSmith
```

**Nächste Frage:** Welcher Anwendungsfall steht im Vordergrund —
interne Wissensabfrage (wie Dust) oder Automatisierung komplexer Prozesse (wie LangGraph)?
