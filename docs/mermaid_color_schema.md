# Mermaid Color Schema – n8n Kompendium

Dieses Dokument definiert das einheitliche Farbmodell für alle Mermaid-Diagramme im n8n-Kompendium. Alle Farben sind für Dark-Mode-Darstellung optimiert: satte Füllfarben mit weißem Text (`color:#fff`).

---

## Farbpalette nach Kategorie

| Kategorie | Verwendung | `fill` | `stroke` | `color` |
| :--- | :--- | :--- | :--- | :--- |
| **Weiche / Entscheidung** | IF, Switch, Verzweigungsknoten | `#d4820a` | `#a06200` | `#fff` |
| **Warten / Timing** | Wait, Loop Over Items | `#c8860a` | `#a06800` | `#fff` |
| **Erfolg / True-Pfad** | True-Branch, Erfolgs-Pfad | `#1e8449` | `#155d34` | `#fff` |
| **Fehler / False-Pfad** | False-Branch, Error-Pfad, Stop and Error, Error Trigger | `#c0392b` | `#922b21` | `#fff` |
| **Fehler-Knoten (stark)** | Fehler-Sammelpunkt, `X`-Knoten | `#922b21` | `#7b241c` | `#fff` |
| **Sub-Workflow / Integration** | Execute Workflow, Trigger-Node | `#1771c4` | `#0f4f8c` | `#fff` |
| **Datenform / Shaping** | Edit Fields, Split Out, Aggregate | `#0e6b7a` | `#084f5a` | `#fff` |
| **Zusammenführung** | Merge | `#7b4dad` | `#5a3480` | `#fff` |
| **Filter** | Filter-Node | `#7d3c98` | `#5b2c6f` | `#fff` |
| **Verworfen / Inaktiv** | Verworfene Items, Trash | `#555555` | `#888888` | `#ccc` |
| **Branch 1 (neutral)** | Erster paralleler Zweig | `#c8860a` | `#a06800` | `#fff` |
| **Branch 2 (neutral)** | Zweiter paralleler Zweig | `#1771c4` | `#0f4f8c` | `#fff` |

---

## Style-Snippets zum Kopieren

```
%% Weiche / Entscheidung (IF, Switch)
style NODE fill:#d4820a,stroke:#a06200,color:#fff

%% Warten / Timing (Wait, Loop)
style NODE fill:#c8860a,stroke:#a06800,color:#fff

%% Erfolg / True-Pfad
style NODE fill:#1e8449,stroke:#155d34,color:#fff

%% Fehler / False-Pfad / Stop and Error / Error Trigger
style NODE fill:#c0392b,stroke:#922b21,color:#fff

%% Fehler-Knoten stark (Sammelpunkt)
style NODE fill:#922b21,stroke:#7b241c,color:#fff

%% Sub-Workflow / Integration
style NODE fill:#1771c4,stroke:#0f4f8c,color:#fff

%% Datenform / Shaping (Edit Fields, Split Out, Aggregate)
style NODE fill:#0e6b7a,stroke:#084f5a,color:#fff

%% Zusammenführung (Merge)
style NODE fill:#7b4dad,stroke:#5a3480,color:#fff

%% Filter
style NODE fill:#7d3c98,stroke:#5b2c6f,color:#fff

%% Verworfen / Inaktiv (gestrichelt)
style NODE fill:#555555,stroke:#888888,color:#ccc,stroke-dasharray: 5 5
```

---

## Farbvorschau

```mermaid
flowchart LR
    A["Weiche / IF"]:::decision
    B["Wait / Loop"]:::timing
    C["Erfolg"]:::success
    D["Fehler"]:::error
    E["Sub-Workflow"]:::subflow
    F["Datenform"]:::shaping
    G["Merge"]:::merge
    H["Filter"]:::filter
    I["Verworfen"]:::discarded

    A --> B --> C --> D --> E --> F --> G --> H --> I

    style A fill:#d4820a,stroke:#a06200,color:#fff
    style B fill:#c8860a,stroke:#a06800,color:#fff
    style C fill:#1e8449,stroke:#155d34,color:#fff
    style D fill:#c0392b,stroke:#922b21,color:#fff
    style E fill:#1771c4,stroke:#0f4f8c,color:#fff
    style F fill:#0e6b7a,stroke:#084f5a,color:#fff
    style G fill:#7b4dad,stroke:#5a3480,color:#fff
    style H fill:#7d3c98,stroke:#5b2c6f,color:#fff
    style I fill:#555555,stroke:#888888,color:#ccc,stroke-dasharray: 5 5
```

---

*Optimiert für Dark-Mode-Renderer (VS Code, GitHub, n8n-Docs). Für Light-Mode ggf. `fill`-Werte um 20–30 % aufhellen und `color:#fff` beibehalten.*
