---
title: "Architektur"
weight: 1
---

Ergänzende Konzept-Dokumentation für den Aufbau einer eigenen LLM-fähigen Anwendung. Die Dokumente hier erklären kein einzelnes Werkzeug — sie zeigen, wie die Werkzeuge aus dem M4-Kurs (FastAPI, LiteLLM, Supabase, Langfuse, n8n) als System zusammenspielen.

**Zwei Sprachen, eine Architektur — und das reicht für fast alles.** Frontend in TypeScript, Backend in Python, klare Trennung dazwischen. Kein Microservices-Overhead, kein Cloud-native von Anfang an — erst ein System das läuft und dessen Teile man versteht.

**Ziel:** Du verstehst, wie eine Client/Server-Anwendung strukturiert ist, kannst einen eigenen Server aufbauen und weißt, wie du von einem lokalen Setup zu einer produktionsnahen Umgebung kommst.

**Voraussetzung:** Keine Programmiererfahrung nötig — ein grundlegendes Verständnis davon, was APIs und Datenbanken sind, hilft.

---

## 🟢 Grundlagen

*Kein Vorwissen nötig. Hier starten.*

- **[01 — Client & Server](01_client_server_grundlagen/)** — Das Grundprinzip: wer fragt, wer antwortet. Was ist ein Monolith und wann reicht er?
- **[02 — Tech-Stack im Überblick](02_tech_stack_uebersicht/)** — Alle Bausteine erklärt: FastAPI, LiteLLM, Supabase, Langfuse, n8n — Rolle, Zweck und Zusammenspiel.
- **[03 — Kommunikationsflüsse](03_kommunikationsfluss/)** — Wie reden die Komponenten miteinander? Sequenzdiagramme für API-Calls, LLM-Calls und n8n-Automatisierungen.
- **[04 — Server-Struktur](04_server_aufbau/)** — Wie organisiere ich meinen Code? package-by-layer vs. package-by-feature, Vergleich und Empfehlung für den Einstieg.
- **[05 — Von lokal bis Produktion](05_von_lokal_bis_produktion/)** — Die drei Stufen: lokal entwickeln, ersten Endpunkt bauen, produktionsnah deployen.

## 🟡 Aufbauend

*Empfohlen wenn du 01–05 durch hast und weiterbauen willst.*

- **[06 — Supabase Best Practices](06_supabase_best_practices/)** — Supabase verstehen, lokal entwickeln, Migrations-Workflow, Umgebungen synchronisieren.
- **[Appendix — Frontend-Optionen](appendix_frontend_optionen/)** — React, Vue3, Next.js, Nuxt.js: Kurzprofil und Entscheidungshilfe.
- **[Appendix — Walking Skeleton](appendix_walking_skeleton/)** — Warum du den Stromkreis zuerst schließt: von localStorage-POC über Walking Skeleton bis zum vollständigen System.
- **[Appendix — C4-Modell & Architekturdiagramme](appendix_c4_modell/)** — System Context, Container, Component, Code: Architektur verständlich visualisieren nach Simon Brown.

## 🔴 Fortgeschritten

*Für alle, die ihr System produktionsnah absichern wollen.*

- **[Appendix — LLM Integration Tests & Test Harness](appendix_llm_integration_tests/)** — Wie man KI-Verhalten systematisch testet: SSE-Streaming, Contract Validation, Behavior-Suiten, Modell-Benchmarks.

---

## Empfohlene Lesereihenfolge

### 🟢 Einsteiger-Pfad

```
1. 01_client_server_grundlagen   ← Was ist überhaupt ein Server?
2. 02_tech_stack_uebersicht      ← Welche Werkzeuge nutze ich?
3. 03_kommunikationsfluss        ← Wie reden die Teile miteinander?
4. 04_server_aufbau              ← Wie strukturiere ich meinen Code?
5. 05_von_lokal_bis_produktion   ← Wie komme ich vom Laptop in die Cloud?
```

### 🟡 Aufbau-Pfad

```
6. 06_supabase_best_practices    ← Datenbank sauber verwalten
7. appendix_frontend_optionen    ← Welches Frontend passt zu mir?
8. appendix_walking_skeleton     ← Wie fange ich ein neues Projekt richtig an?
9. appendix_c4_modell            ← Wie visualisiere ich meine Architektur?
```

### 🔴 Fortgeschrittenen-Pfad

```
10. appendix_llm_integration_tests ← KI-Verhalten systematisch testen
```

---

## Beiträge willkommen

Ergänzungen und Korrekturen sind herzlich willkommen. Bitte halte dich an die bestehenden Konventionen:

- **Deutsch**, **du-Form**, konkret und ohne Füllwörter
- Mermaid-Diagramme nach dem [Farbschema](/n8n_learning/mermaid_color_schema/)
- Neutral formulieren — keine Bezüge zu internen Projekten oder Personen
- Quellenangaben bei übernommenen Konzepten
