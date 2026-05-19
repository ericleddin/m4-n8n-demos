# M4 – KI Experte: n8n Workflow Demos

Sammlung der n8n-Workflows, die wir im **Modul 4 – KI Experte: Automatisierte Workflows & Agenten** am Syntax Institut live demonstrieren.

Die Workflows decken das **Architektur-Spektrum** von einfachem Prompting bis hin zu Multi-Agent-Systemen ab und sind nach Kurswochen organisiert.

## 📁 Struktur

```
workflows/
├── woche-01/
│   ├── tag-01-prompt-basics/
│   │   ├── workflow.json
│   │   └── README.md
│   └── ...
├── woche-02/
└── ...
```

Jeder Workflow liegt in einem eigenen Ordner mit einer README, die erklärt:

- Was der Workflow demonstriert
- Welche Credentials/API-Keys benötigt werden
- Wo im Architektur-Spektrum er sich einordnet

## 🚀 Workflow importieren

1. Öffne deine n8n-Instanz (lokal oder über die Syntax-Cloud)
2. Klick auf **Workflows → Add Workflow → Import from File**
3. Wähle die `workflow.json` aus dem gewünschten Ordner
4. Folge der jeweiligen README, um die benötigten Credentials anzulegen

## 🔑 Credentials

In den Workflows findest du Platzhalter im Format `<<REPLACE_WITH_XYZ_KEY>>`. Diese ersetzt du entweder:

- direkt im jeweiligen Node-Feld, **oder**
- (empfohlen) indem du in n8n eigene **Credentials** anlegst und sie im Node referenzierst

Aus Sicherheitsgründen werden in diesem Repository **niemals echte API-Keys** geteilt.

## 📚 Kurs-Kontext

Dieses Repository begleitet das **Modul 4** der KI-Zertifizierung am Syntax Institut. Der vollständige Lehrplan und weiterführende Materialien werden über Moodle bereitgestellt.

## 📝 Lizenz

MIT – siehe `LICENSE`.
