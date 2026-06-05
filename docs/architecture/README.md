---
title: "Übersicht Architektur"
weight: 1
---

# Architektur-Dokumentation

Ergänzende Konzept-Dokumentation für den Aufbau einer eigenen LLM-fähigen Anwendung. Die Dokumente hier erklären kein einzelnes Werkzeug — sie zeigen, wie die Werkzeuge aus dem M4-Kurs (FastAPI, LiteLLM, Supabase, Langfuse, n8n) als System zusammenspielen.

**Ziel:** Du verstehst, wie eine Client/Server-Anwendung strukturiert ist, kannst einen eigenen Server aufbauen und weißt, wie du von einem lokalen Setup zu einer produktionsnahen Umgebung kommst.

**Voraussetzung:** Keine Programmiererfahrung nötig — ein grundlegendes Verständnis davon, was APIs und Datenbanken sind, hilft.

---

## 📂 Inhalte

### 🟢 Grundlagen
*Kein Vorwissen nötig. Hier starten.*

- **[01 — Client & Server](01_client_server_grundlagen.md)** — Das Grundprinzip: wer fragt, wer antwortet. Was ist ein Monolith und wann reicht er?
- **[02 — Tech-Stack im Überblick](02_tech_stack_uebersicht.md)** — Alle Bausteine erklärt: FastAPI, LiteLLM, Supabase, Langfuse, n8n — Rolle, Zweck und Zusammenspiel.
- **[03 — Kommunikationsflüsse](03_kommunikationsfluss.md)** — Wie reden die Komponenten miteinander? Sequenzdiagramme für API-Calls, LLM-Calls und n8n-Automatisierungen. Plus: die sechs Agent-Patterns nach Anthropic.
- **[04 — Server-Struktur](04_server_aufbau.md)** — Wie organisiere ich meinen Code? package-by-layer vs. package-by-feature, Vergleich und Empfehlung für den Einstieg.
- **[05 — Von lokal bis Produktion](05_von_lokal_bis_produktion.md)** — Die drei Stufen: lokal entwickeln, ersten Endpunkt bauen, produktionsnah deployen.

### 🟡 Aufbauend
*Empfohlen wenn du 01–05 durch hast und weiterbauen willst.*

- **[06 — Supabase Best Practices](06_supabase_best_practices.md)** — Supabase verstehen, lokal entwickeln, Migrations-Workflow, Umgebungen synchronisieren.
- **[Appendix — Frontend-Optionen](appendix_frontend_optionen.md)** — React, Vue3, Next.js, Nuxt.js: Kurzprofil und Entscheidungshilfe.
- **[Appendix — Walking Skeleton](appendix_walking_skeleton.md)** — Warum du den Stromkreis zuerst schließt: von localStorage-POC über Walking Skeleton bis zum vollständigen System.

### 🔴 Fortgeschritten
*Für alle, die ihr System produktionsnah absichern wollen.*

- **[Appendix — LLM Integration Tests & Test Harness](appendix_llm_integration_tests.md)** — Wie man KI-Verhalten systematisch testet: SSE-Streaming, Contract Validation, Behavior-Suiten, Modell-Benchmarks.

---

## 🗺️ Empfohlene Lesereihenfolge

### 🟢 Einsteiger-Pfad
*Du willst verstehen wie das System funktioniert und deine erste App bauen.*

```
1. 01_client_server_grundlagen.md     ← Was ist überhaupt ein Server?
2. 02_tech_stack_uebersicht.md        ← Welche Werkzeuge nutze ich?
3. 03_kommunikationsfluss.md          ← Wie reden die Teile miteinander?
4. 04_server_aufbau.md               ← Wie strukturiere ich meinen Code?
5. 05_von_lokal_bis_produktion.md    ← Wie komme ich vom Laptop in die Cloud?
```

### 🟡 Aufbau-Pfad
*Du hast eine erste App gebaut und willst sie sauber weiterentwickeln.*

```
6. 06_supabase_best_practices.md     ← Datenbank sauber verwalten
7. appendix_frontend_optionen.md     ← Welches Frontend passt zu mir?
8. appendix_walking_skeleton.md      ← Wie fange ich ein neues Projekt richtig an?
```

### 🔴 Fortgeschrittenen-Pfad
*Du willst dein System produktionsnah absichern und Modelle vergleichen.*

```
9. appendix_llm_integration_tests.md ← KI-Verhalten systematisch testen
```

---

## 🤝 Beiträge willkommen

Ergänzungen und Korrekturen sind herzlich willkommen. Bitte halte dich an die bestehenden Konventionen:

- **Deutsch**, **du-Form**, konkret und ohne Füllwörter
- Mermaid-Diagramme nach dem [Farbschema](../mermaid_color_schema.md)
- Neutral formulieren — keine Bezüge zu internen Projekten oder Personen
- Quellenangaben bei übernommenen Konzepten
