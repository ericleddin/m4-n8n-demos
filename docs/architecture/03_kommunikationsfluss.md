---
title: "03 — Kommunikationsflüsse"
weight: 30
---

# Kommunikationsflüsse

Dieses Kapitel zeigt, wie die Bausteine des Stacks miteinander kommunizieren — von einfachen API-Calls bis zu komplexen Automatisierungsabläufen. Im zweiten Teil: die sechs Architektur-Patterns für LLM-Anwendungen nach Anthropic.

---

## 1. Der einfachste Fall: Client → API → Datenbank

Ein Client fragt Daten an, der Server liest aus der Datenbank und antwortet.

```mermaid
sequenceDiagram
    participant C as 🌐 Client
    participant S as ⚙️ FastAPI
    participant DB as 🗄️ Supabase

    C->>S: GET /items
    S->>DB: SELECT * FROM items
    DB-->>S: Datensätze
    S-->>C: JSON-Array
```

Das ist das Grundmuster. Alle anderen Flows bauen darauf auf.

---

## 2. Mit LLM — API → LiteLLM → Modell

Wenn eine Anfrage KI-Verarbeitung braucht, wird LiteLLM eingebunden. Langfuse zeichnet den Vorgang im Hintergrund auf.

```mermaid
sequenceDiagram
    participant C as 🌐 Client
    participant S as ⚙️ FastAPI
    participant L as 🤖 LiteLLM
    participant M as 💬 LLM-Modell
    participant LF as 📊 Langfuse

    C->>S: POST /chat { message }
    S->>L: Chat-Anfrage (System-Prompt + Nachricht)
    L->>M: Anfrage weiterleiten
    M-->>L: Token-Stream
    L-->>S: Token-Stream
    S-->>C: SSE-Stream (Server-Sent Events)
    S-)LF: Trace (async, non-blocking)
```

**SSE (Server-Sent Events)** ist ein Protokoll für Echtzeit-Streams vom Server zum Client. Der Nutzer sieht die Antwort Wort für Wort, anstatt auf das komplette Ergebnis zu warten.

Der Trace zu Langfuse wird **asynchron** verschickt — er blockiert nicht den Antwort-Stream.

---

## 3. n8n als Automation-Actor

Aus Sicht des Servers ist n8n ein normaler Client — er schickt HTTP-Anfragen wie jeder andere. Der Server braucht nichts Besonderes zu wissen.

```mermaid
sequenceDiagram
    participant Trigger as ⏰ n8n Trigger\n(Zeitplan / Webhook)
    participant N8N as 🔁 n8n Workflow
    participant S as ⚙️ FastAPI
    participant DB as 🗄️ Supabase

    Trigger->>N8N: Ausführen
    N8N->>S: POST /report/generate
    S->>DB: Daten aggregieren
    DB-->>S: Ergebnis
    S-->>N8N: JSON-Report
    N8N->>N8N: Weiterverarbeiten\n(E-Mail senden, Slack-Nachricht, ...)
```

Mehr zu n8n-Workflows: [n8n Learning](../n8n_learning/)

---

## 4. Anthropic: Sechs Patterns für LLM-Anwendungen

> *"The most important thing is to match the architecture to the actual requirements of your task — not to use the most sophisticated pattern you can think of."*
>
> — Quelle: [Anthropic Engineering — Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)

Bevor du einen komplexen Agenten baust, lohnt es sich zu verstehen welche Muster es gibt und wann welches passt.

### Workflows vs. Agents

| | Workflow | Agent |
|---|---|---|
| **Steuerung** | Code bestimmt den Ablauf | Das LLM entscheidet selbst |
| **Vorhersagbarkeit** | Hoch | Niedriger |
| **Flexibilität** | Begrenzt | Hoch |
| **Einsatz** | Aufgaben mit klarem Ablauf | Offene, unstrukturierte Probleme |

Für die meisten Anwendungen im M4-Kurs sind **Workflows** die richtige Wahl — strukturierter, testbarer, weniger überraschend.

---

### Pattern 1 — Augmented LLM

Das LLM wird mit zusätzlichem Kontext angereichert: Retrieval (eigene Daten), Tools (externe Funktionen) und Memory (Gesprächshistorie).

```mermaid
flowchart LR
    Input["📥 Anfrage"]
    LLM["💬 LLM"]
    Output["📤 Antwort"]

    Retrieval["🔍 Retrieval\n(eigene Daten)"]
    Tools["🔧 Tools\n(Funktionsaufrufe)"]
    Memory["🧠 Memory\n(Gesprächshistorie)"]

    Input --> LLM
    Retrieval --> LLM
    Tools <--> LLM
    Memory --> LLM
    LLM --> Output

    style Input fill:#1771c4,stroke:#0f4f8c,color:#fff
    style LLM fill:#7b4dad,stroke:#5a3480,color:#fff
    style Output fill:#1771c4,stroke:#0f4f8c,color:#fff
    style Retrieval fill:#0e6b7a,stroke:#084f5a,color:#fff
    style Tools fill:#1e8449,stroke:#155d34,color:#fff
    style Memory fill:#d4820a,stroke:#a06200,color:#fff
```

**Im Stack:** FastAPI reichert die Anfrage an (Retrieval aus Supabase, Gesprächshistorie aus der DB) bevor LiteLLM aufgerufen wird.

**Wann:** Fast immer — das ist die Basis für alle anderen Patterns.

---

### Pattern 2 — Prompt Chaining

Eine Aufgabe wird in Einzelschritte zerlegt. Jeder Schritt ist ein eigener LLM-Call, das Ergebnis fließt in den nächsten. Zwischen Schritten können Prüfungen ("Gates") eingebaut werden.

```mermaid
flowchart LR
    Input["📥 Anfrage"]
    LLM1["💬 Schritt 1\nExtrahieren"]
    Gate["🔀 Gate\n(Prüfung)"]
    LLM2["💬 Schritt 2\nVerarbeiten"]
    LLM3["💬 Schritt 3\nFormatieren"]
    Output["📤 Ergebnis"]

    Input --> LLM1 --> Gate --> LLM2 --> LLM3 --> Output

    style Input fill:#1771c4,stroke:#0f4f8c,color:#fff
    style LLM1 fill:#7b4dad,stroke:#5a3480,color:#fff
    style Gate fill:#d4820a,stroke:#a06200,color:#fff
    style LLM2 fill:#7b4dad,stroke:#5a3480,color:#fff
    style LLM3 fill:#7b4dad,stroke:#5a3480,color:#fff
    style Output fill:#1771c4,stroke:#0f4f8c,color:#fff
```

**Im Stack:** Mehrere aufeinanderfolgende LiteLLM-Calls in einem FastAPI-Endpunkt, oder als n8n-Workflow mit mehreren LLM-Nodes.

**Wann:** Aufgabe lässt sich in feste Teilschritte zerlegen (z.B. "Daten extrahieren → zusammenfassen → in Zielsprache übersetzen").

---

### Pattern 3 — Routing

Die Anfrage wird zunächst klassifiziert, dann an den passenden Folge-Prozess weitergeleitet.

```mermaid
flowchart LR
    Input["📥 Anfrage"]
    Router["🔀 Classifier\n(LLM oder Regel)"]
    PathA["💬 Pfad A\n(Einfache Anfrage)"]
    PathB["💬 Pfad B\n(Komplexe Anfrage)"]
    PathC["💬 Pfad C\n(Eskalation)"]
    Output["📤 Antwort"]

    Input --> Router
    Router -->|"Typ A"| PathA --> Output
    Router -->|"Typ B"| PathB --> Output
    Router -->|"Typ C"| PathC --> Output

    style Input fill:#1771c4,stroke:#0f4f8c,color:#fff
    style Router fill:#d4820a,stroke:#a06200,color:#fff
    style PathA fill:#7b4dad,stroke:#5a3480,color:#fff
    style PathB fill:#7b4dad,stroke:#5a3480,color:#fff
    style PathC fill:#7b4dad,stroke:#5a3480,color:#fff
    style Output fill:#1771c4,stroke:#0f4f8c,color:#fff
```

**Im Stack:** FastAPI-Endpunkt klassifiziert die Anfrage (einfacher LLM-Call oder Regelwerk), dann Weiterleitung. In n8n: IF/Switch-Node nach einem Classifier-LLM-Call.

**Wann:** Anfragen fallen klar in unterschiedliche Kategorien, die verschieden behandelt werden müssen.

---

### Pattern 4 — Parallelisierung

Mehrere LLM-Calls laufen gleichzeitig. Zwei Varianten:

**Sectioning** — unabhängige Teilaufgaben parallel bearbeiten:

```mermaid
flowchart LR
    Input["📥 Dokument"]
    Split["📋 Aufteilen"]
    LLM1["💬 Abschnitt 1"]
    LLM2["💬 Abschnitt 2"]
    LLM3["💬 Abschnitt 3"]
    Merge["🔗 Zusammenführen"]
    Output["📤 Gesamt-Ergebnis"]

    Input --> Split
    Split --> LLM1 & LLM2 & LLM3
    LLM1 & LLM2 & LLM3 --> Merge --> Output

    style Input fill:#1771c4,stroke:#0f4f8c,color:#fff
    style Split fill:#1e8449,stroke:#155d34,color:#fff
    style LLM1 fill:#7b4dad,stroke:#5a3480,color:#fff
    style LLM2 fill:#7b4dad,stroke:#5a3480,color:#fff
    style LLM3 fill:#7b4dad,stroke:#5a3480,color:#fff
    style Merge fill:#7b4dad,stroke:#5a3480,color:#fff
    style Output fill:#1771c4,stroke:#0f4f8c,color:#fff
```

**Voting** — dieselbe Frage mehrfach stellen und abstimmen (für höhere Zuverlässigkeit):

```mermaid
flowchart LR
    Input["📥 Anfrage"]
    LLM1["💬 Versuch 1"]
    LLM2["💬 Versuch 2"]
    LLM3["💬 Versuch 3"]
    Vote["🗳️ Mehrheitsentscheid"]
    Output["📤 Antwort"]

    Input --> LLM1 & LLM2 & LLM3
    LLM1 & LLM2 & LLM3 --> Vote --> Output

    style Input fill:#1771c4,stroke:#0f4f8c,color:#fff
    style LLM1 fill:#7b4dad,stroke:#5a3480,color:#fff
    style LLM2 fill:#7b4dad,stroke:#5a3480,color:#fff
    style LLM3 fill:#7b4dad,stroke:#5a3480,color:#fff
    style Vote fill:#d4820a,stroke:#a06200,color:#fff
    style Output fill:#1771c4,stroke:#0f4f8c,color:#fff
```

**Im Stack:** Sectioning via `asyncio.gather()` in FastAPI. Voting selten nötig, aber mit n8n gut abzubilden.

**Wann:** Sectioning bei großen Dokumenten oder unabhängigen Teilaufgaben. Voting wenn Zuverlässigkeit kritisch ist.

---

### Pattern 5 — Orchestrator-Workers

Ein zentrales LLM (Orchestrator) plant die Aufgabe, delegiert Teilaufgaben dynamisch an Worker-LLMs und fasst die Ergebnisse zusammen.

```mermaid
flowchart TD
    Input["📥 Aufgabe"]
    Orch["💬 Orchestrator\n(plant + delegiert)"]
    W1["💬 Worker A"]
    W2["💬 Worker B"]
    W3["💬 Worker C"]
    Synth["💬 Synthese"]
    Output["📤 Ergebnis"]

    Input --> Orch
    Orch -->|"Teilaufgabe 1"| W1
    Orch -->|"Teilaufgabe 2"| W2
    Orch -->|"Teilaufgabe 3"| W3
    W1 & W2 & W3 --> Synth --> Output

    style Input fill:#1771c4,stroke:#0f4f8c,color:#fff
    style Orch fill:#d4820a,stroke:#a06200,color:#fff
    style W1 fill:#7b4dad,stroke:#5a3480,color:#fff
    style W2 fill:#7b4dad,stroke:#5a3480,color:#fff
    style W3 fill:#7b4dad,stroke:#5a3480,color:#fff
    style Synth fill:#7b4dad,stroke:#5a3480,color:#fff
    style Output fill:#1771c4,stroke:#0f4f8c,color:#fff
```

Der Unterschied zu Parallelisierung: die Teilaufgaben werden **dynamisch** bestimmt — der Orchestrator entscheidet erst zur Laufzeit, was getan werden muss.

**Im Stack:** FastAPI-Endpunkt mit mehreren LiteLLM-Calls in einer gesteuerten Schleife.

**Wann:** Komplexe Aufgaben deren Teilschritte nicht im Voraus feststehen (z.B. Code-Analyse über mehrere Dateien).

---

### Pattern 6 — Evaluator-Optimizer

Ein LLM generiert eine Antwort, ein zweites bewertet sie — in einer Schleife, bis die Qualität ausreicht.

```mermaid
flowchart LR
    Input["📥 Aufgabe"]
    Gen["💬 Generator"]
    Eval["💬 Evaluator"]
    Output["📤 Endergebnis"]

    Input --> Gen
    Gen -->|"Entwurf"| Eval
    Eval -->|"Feedback\n(nicht gut genug)"| Gen
    Eval -->|"Akzeptiert"| Output

    style Input fill:#1771c4,stroke:#0f4f8c,color:#fff
    style Gen fill:#7b4dad,stroke:#5a3480,color:#fff
    style Eval fill:#d4820a,stroke:#a06200,color:#fff
    style Output fill:#1771c4,stroke:#0f4f8c,color:#fff
```

**Im Stack:** Zwei LiteLLM-Calls in einer FastAPI-Funktion — einer generiert, einer bewertet. Schleife mit definiertem Abbruchkriterium (max. Iterationen oder Qualitätsschwelle).

**Wann:** Es gibt klare Qualitätskriterien, und iterative Verbesserung bringt messbaren Mehrwert (z.B. Code-Generierung mit automatischer Test-Prüfung).

---

## 5. Welches Pattern passt wann?

| Pattern | Verwende es wenn... |
|---|---|
| Augmented LLM | immer — das ist die Basis |
| Prompt Chaining | die Aufgabe klar in Schritte zerfällt |
| Routing | Anfragen in verschiedene Kategorien fallen |
| Parallelisierung | unabhängige Teilaufgaben gleichzeitig bearbeitbar sind |
| Orchestrator-Workers | die Aufgabe dynamisch zerlegt werden muss |
| Evaluator-Optimizer | Qualität messbar und iterativ verbesserbar ist |

> **Empfehlung für den Einstieg:** Fang mit Augmented LLM an. Füge Prompt Chaining hinzu, wenn ein einzelner Call nicht ausreicht. Nur wenn das nicht mehr genug ist, wechsle zu komplexeren Patterns.

Quelle: [Anthropic Engineering — Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
