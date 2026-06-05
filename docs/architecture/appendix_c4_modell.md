---
title: "Appendix — C4-Modell & Architekturdiagramme"
weight: 85
---

# C4-Modell & Architekturdiagramme

> 🟡 **Aufbauend** — empfohlen nach [01–05](README.md)

Sobald ein System wächst, stellt sich die Frage: Wie erkläre ich anderen (oder mir selbst in sechs Monaten) wie das System aufgebaut ist? Das C4-Modell gibt dafür einen klaren, stufenweisen Rahmen.

---

## Was ist das C4-Modell?

Das **C4-Modell** wurde von **Simon Brown** entwickelt und ist ein leicht erlernbares System zur Visualisierung von Softwarearchitektur. Der Name steht für die vier Abstraktionsebenen:

- **C**ontext
- **C**ontainer
- **C**omponent
- **C**ode

Die Grundidee: Je nach Gesprächspartner und Fragestellung brauchst du eine andere Detailtiefe. Ein Manager braucht den Kontext (Vogelperspektive), ein Entwickler braucht die Komponentensicht. Das C4-Modell gibt für jede Ebene ein eigenes Diagramm.

> *"A set of hierarchical abstractions — software systems, containers, components, and code."*
> — Simon Brown, c4model.com

---

## Die vier Ebenen

### Ebene 1 — System Context

Die höchste Abstraktionsebene. Zeigt das System als Black Box im Umfeld der Nutzer und externen Systeme. Keine technischen Details — nur: Wer benutzt das System, und mit welchen anderen Systemen spricht es?

**Frage:** *Welchen Platz nimmt unser System in der Welt ein?*

```mermaid
flowchart TB
    User["👤 Nutzer\n(Web-Browser)"]
    System["🖥️ KI-Assistent\n[Software System]"]
    LLMProvider["☁️ LLM-Anbieter\n[Externes System]"]
    Email["📧 E-Mail-Dienst\n[Externes System]"]

    User -- "Anfragen stellen\nErgebnisse lesen" --> System
    System -- "KI-Calls" --> LLMProvider
    System -- "Benachrichtigungen" --> Email

    style User fill:#1771c4,stroke:#0f4f8c,color:#fff
    style System fill:#1e8449,stroke:#155d34,color:#fff
    style LLMProvider fill:#555555,stroke:#888888,color:#ccc
    style Email fill:#555555,stroke:#888888,color:#ccc
```

**Zielgruppe:** Alle — technisch und nicht-technisch. Dieses Diagramm sollte jeder im Team verstehen.

---

### Ebene 2 — Container

Zoomt in das System hinein und zeigt die deployierbaren Einheiten: Server, Datenbanken, Frontend-Applikationen, Worker-Prozesse. Nicht "Docker-Container" im Sinne von Docker — sondern jede eigenständig deploybare Einheit.

**Frage:** *Aus welchen laufenden Teilen besteht das System?*

```mermaid
flowchart TB
    User["👤 Nutzer"]
    N8N["🔁 n8n\n[Automation Container]"]

    subgraph System["🖥️ KI-Assistent [Software System]"]
        FE["🌐 Frontend\n[Web App / React]\nPort 3000"]
        API["⚙️ API-Server\n[FastAPI / Python]\nPort 8090"]
        LiteLLM["🤖 LLM-Proxy\n[LiteLLM]\nPort 4000"]
        DB["🗄️ Datenbank\n[Supabase / PostgreSQL]\nPort 54321"]
        Observability["📊 Tracing\n[Langfuse]\nPort 3000"]
    end

    LLMProvider["☁️ LLM-Anbieter\n[Externes System]"]

    User -- "HTTPS" --> FE
    N8N -- "HTTP/REST" --> API
    FE -- "HTTP/REST\nSSE" --> API
    API -- "OpenAI-API" --> LiteLLM
    LiteLLM -- "HTTPS" --> LLMProvider
    API -- "SQL" --> DB
    API -. "Traces" .-> Observability

    style User fill:#1771c4,stroke:#0f4f8c,color:#fff
    style N8N fill:#b5451b,stroke:#8a3315,color:#fff
    style FE fill:#1771c4,stroke:#0f4f8c,color:#fff
    style API fill:#1e8449,stroke:#155d34,color:#fff
    style LiteLLM fill:#7b4dad,stroke:#5a3480,color:#fff
    style DB fill:#0e6b7a,stroke:#084f5a,color:#fff
    style Observability fill:#d4820a,stroke:#a06200,color:#fff
    style LLMProvider fill:#555555,stroke:#888888,color:#ccc
```

**Zielgruppe:** Entwickler, Architekten, DevOps. Dieses Diagramm beantwortet "Was muss ich deployen?"

---

### Ebene 3 — Component

Zoomt in einen einzelnen Container und zeigt seine internen Bausteine — Module, Klassen, Services — und wie sie miteinander interagieren.

**Frage:** *Wie ist dieser Container intern aufgebaut?*

```mermaid
flowchart TB
    FE["🌐 Frontend"]
    DB["🗄️ Datenbank"]
    LiteLLM["🤖 LiteLLM"]

    subgraph API["⚙️ API-Server [Container]"]
        Router["Routes\n(HTTP-Endpunkte)"]
        ChatService["Chat Service\n(LLM-Orchestrierung)"]
        ItemService["Item Service\n(Business-Logik)"]
        Coordinator["Coordinator\n(Intent-Klassifikation)"]
        ItemRepo["Item Repository\n(DB-Zugriff)"]
    end

    FE -- "POST /chat" --> Router
    FE -- "GET /items" --> Router
    Router --> ChatService
    Router --> ItemService
    ChatService --> Coordinator
    ChatService --> LiteLLM
    ItemService --> ItemRepo
    ItemRepo --> DB

    style FE fill:#1771c4,stroke:#0f4f8c,color:#fff
    style DB fill:#0e6b7a,stroke:#084f5a,color:#fff
    style LiteLLM fill:#7b4dad,stroke:#5a3480,color:#fff
    style Router fill:#1e8449,stroke:#155d34,color:#fff
    style ChatService fill:#1e8449,stroke:#155d34,color:#fff
    style ItemService fill:#1e8449,stroke:#155d34,color:#fff
    style Coordinator fill:#d4820a,stroke:#a06200,color:#fff
    style ItemRepo fill:#0e6b7a,stroke:#084f5a,color:#fff
```

**Zielgruppe:** Entwickler. Dieses Diagramm passt zur Ordnerstruktur im Code (package-by-layer oder package-by-feature).

---

### Ebene 4 — Code

Die unterste Ebene — zeigt die Implementierung einzelner Komponenten: Klassen, Interfaces, Methoden. In der Praxis selten manuell gezeichnet, weil IDEs und Tools das automatisch generieren können.

**Frage:** *Wie ist diese Komponente im Code umgesetzt?*

```mermaid
classDiagram
    class ItemService {
        +create(title, description) Item
        +list(filter) list~Item~
        +update(id, data) Item
    }
    class ItemRepository {
        <<interface>>
        +insert(item) Item
        +find_all() list~Item~
        +find_by_id(id) Item
        +update(id, data) Item
    }
    class SupabaseItemRepository {
        -client: SupabaseClient
        +insert(item) Item
        +find_all() list~Item~
        +find_by_id(id) Item
        +update(id, data) Item
    }

    ItemService --> ItemRepository
    SupabaseItemRepository ..|> ItemRepository
```

**Zielgruppe:** Entwickler die an dieser Komponente arbeiten. Für kleinere Teams oft übersprungen — der Code selbst ist das Diagramm.

---

## Wann welche Ebene?

| Ebene | Zeigt | Für wen | Wann zeichnen |
|---|---|---|---|
| **Context** | System im Gesamtbild | Alle | Immer — am Anfang des Projekts |
| **Container** | Deploybare Einheiten | Entwickler, DevOps | Sobald mehrere Services existieren |
| **Component** | Interne Struktur eines Containers | Entwickler | Wenn ein Container komplex genug wird |
| **Code** | Klassen & Interfaces | Entwickler | Selten — nur für kritische Komponenten |

> **Empfehlung:** Fang mit Context und Container an. Component nur für komplexe Services. Code fast nie — der Code selbst ist besser.

---

## Ergänzende Diagrammtypen

Neben den vier Hauptebenen definiert C4 drei weitere Diagrammtypen für spezielle Fragen:

### System Landscape
Zeigt mehrere Systeme und ihre Beziehungen — sinnvoll wenn dein KI-Assistent Teil einer größeren Systemlandschaft ist (z.B. neben einem CRM, einem ERP, einer Datenplattform).

### Dynamic Diagram
Zeigt den **Ablauf** einer spezifischen Funktion quer durch die Container — ähnlich einem Sequenzdiagramm, aber im C4-Stil. Gut für: "Was passiert genau wenn ein Nutzer eine Anfrage stellt?"

```mermaid
sequenceDiagram
    participant U as 👤 Nutzer
    participant FE as 🌐 Frontend
    participant API as ⚙️ API-Server
    participant LLM as 🤖 LiteLLM
    participant DB as 🗄️ Datenbank

    U->>FE: Nachricht eingeben
    FE->>API: POST /chat
    API->>DB: Kontext laden
    DB-->>API: Letzte Einträge
    API->>LLM: Anfrage + Kontext
    LLM-->>API: Antwort-Stream
    API-->>FE: SSE-Stream
    FE-->>U: Antwort anzeigen
```

### Deployment Diagram
Zeigt wie Container auf Infrastruktur verteilt sind — welcher Container läuft auf welchem Server, in welcher Cloud, in welchem Docker-Netzwerk.

---

## Werkzeuge

Das C4-Modell ist **notations- und toolunabhängig**. Du kannst es mit jedem Diagramm-Werkzeug umsetzen:

| Werkzeug | Typ | Besonderheit |
|---|---|---|
| [Structurizr](https://structurizr.com) | Web-Tool | Von Simon Brown, C4-nativ |
| [draw.io / diagrams.net](https://diagrams.net) | Web-Tool | C4-Shape-Bibliothek verfügbar |
| Mermaid | Code (Text) | In Markdown einbettbar — wie in diesen Docs |
| PlantUML | Code (Text) | C4-Erweiterung verfügbar |
| Excalidraw | Skizze | Für schnelle Entwürfe |

Für diese Dokumentationsreihe wird **Mermaid** verwendet — kein separates Tool nötig, direkt im Markdown.

---

## Quellen & Weiterführendes

### Offizielle Dokumentation

**c4model.com** — die primäre Quelle. Alle Ebenen, Notation, FAQ, interaktive Beispiele und Werkzeug-Empfehlungen.
→ [https://c4model.com](https://c4model.com)

Interaktives Beispiel (vollständige C4-Diagramme für ein reales System):
→ [https://c4model.com/example](https://c4model.com/example)

### Video

**"Visualising software architecture with the C4 model"**
Simon Brown — Agile on the Beach 2019. Der beste Einstieg: Simon Brown erklärt das Modell selbst, mit konkreten Beispielen und dem Vergleich zu anderen Ansätzen. ~45 Minuten.
→ [https://www.youtube.com/watch?v=x2-rSnhpw0g](https://www.youtube.com/watch?v=x2-rSnhpw0g)

### Buch

**"The C4 model for visualising software architecture"** — Simon Brown (O'Reilly).
Kompaktes Referenzwerk, auch als kostenloser Leanpub-Download verfügbar über c4model.com.

### Autor

**Simon Brown** — Softwarearchitekt, Autor, Trainer. Entwickler des C4-Modells.
→ [https://simonbrown.je](https://simonbrown.je)
