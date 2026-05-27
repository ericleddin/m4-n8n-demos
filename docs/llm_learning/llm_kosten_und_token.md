# LLM-Kosten & Token-Management

> LLM-APIs kosten Geld pro Token — und Kosten können schnell explodieren
> wenn man nicht aufpasst. Dieses Dokument erklärt wie Token-Preise
> funktionieren und wie du die Kosten unter Kontrolle behältst.

---

## Was ist ein Token?

Ein Token ist nicht gleich ein Wort — sondern ein Wort-Stück:

```
"Hallo"              = 1 Token
"Künstliche"         = 2 Tokens  (Künst + liche)
"Intelligenz"        = 2 Tokens  (Intelli + genz)
"LLM-Entwicklung"    = 4 Tokens

Faustregel:
  Englisch: ~1 Token = 0,75 Wörter
  Deutsch:  ~1 Token = 0,6 Wörter  (Deutsch ist tokenineffizienter)
```

→ Deutsche Prompts und Antworten kosten mehr als englische bei gleichem Inhalt.

---

## Wie Preise berechnet werden

LLM-APIs rechnen separat für Input und Output:

| Modell | Input (pro 1M Tokens) | Output (pro 1M Tokens) |
|---|---|---|
| GPT-4o | $2.50 | $10.00 |
| GPT-4o mini | $0.15 | $0.60 |
| Claude Sonnet 4.6 | $3.00 | $15.00 |
| Claude Haiku 4.5 | $0.80 | $4.00 |
| Mistral Large | $2.00 | $6.00 |
| Mistral 7B | $0.25 | $0.25 |
| Ollama (lokal) | $0.00 | $0.00 |

> **Wichtig:** Output-Tokens kosten 3–5× mehr als Input-Tokens.
> Kurze, präzise Antworten sind günstiger als lange.

---

## Was kostet ein typischer Call?

```
Beispiel: Kundenservice-Bot

System-Prompt:    ~200 Tokens
Gesprächshistorie: ~300 Tokens
User-Frage:        ~50 Tokens
─────────────────────────────
Input gesamt:     ~550 Tokens → bei GPT-4o: $0.0014

Antwort:          ~150 Tokens → bei GPT-4o: $0.0015

Pro Gespräch:     ~$0.003  (0,3 Cent)
1.000 Gespräche:  ~$3
100.000 Gespräche: ~$300/Monat
```

→ Bei GPT-4o mini wären es ~$15/Monat für 100.000 Gespräche.

---

## Die größten Kostenfallen

### 1. Gesprächshistorie unkontrolliert wachsen lassen

```
Gespräch 1: 500 Tokens Input
Gespräch 2: 500 + 500 = 1.000 Tokens Input  (Histroie mitgeschickt)
Gespräch 3: 1.000 + 500 = 1.500 Tokens Input
...
Gespräch 20: ~10.000 Tokens Input  ← 20× teurer als Gespräch 1

Fix: Nur die letzten N Nachrichten mitschicken (Rolling Window)
     oder Zusammenfassung statt vollständige Historie
```

### 2. Zu großes Modell für einfache Aufgaben

```
Klassifikation (POSITIV / NEGATIV):
  GPT-4o:      $2.50 / 1M Tokens  ← Overkill
  GPT-4o mini: $0.15 / 1M Tokens  ← reicht völlig
  → 16× günstiger bei gleichem Ergebnis
```

### 3. Unnötig langen System-Prompt

```
System-Prompt mit 2.000 Tokens × 10.000 Calls/Tag
= 20.000.000 Token/Tag nur für den System-Prompt

Fix: Prompt Caching (OpenAI und Anthropic bieten das an)
     Gecachte Tokens kosten ~10× weniger
```

### 4. Keine Antwortlänge begrenzen

```
Ohne Limit:  LLM schreibt manchmal 1.000 Tokens wenn 100 reichen
Mit Limit:   max_tokens=200 im API-Call setzen
```

---

## Kosten senken — Strategien

### Modell-Routing

Nicht jede Anfrage braucht das teuerste Modell:

```
Einfache Klassifikation   → GPT-4o mini / Mistral 7B
Zusammenfassungen         → Claude Haiku / GPT-4o mini
Komplexe Analyse          → GPT-4o / Claude Sonnet
Kreatives Schreiben       → Claude Opus / GPT-4o
Datenschutz-kritisch      → Ollama (lokal, kostenlos)
```

LiteLLM kann das automatisch routen basierend auf Regeln.

### Semantisches Caching

```
User A: "Was sind eure Öffnungszeiten?"  → LLM-Call, $0.001
User B: "Wann habt ihr auf?"             → Cache-Hit, $0.000  ← gleiche Bedeutung

Ersparnis: 40–70% bei wiederkehrenden ähnlichen Fragen
Tool: LiteLLM Proxy + Redis
```

### Prompt Caching

OpenAI und Anthropic cachen lange System-Prompts automatisch:

```
System-Prompt (1.000 Tokens) + User-Frage (50 Tokens)

Ohne Caching:  1.050 Tokens × $2.50/1M = $0.0026
Mit Caching:   50 Tokens normal + 1.000 Tokens gecacht (90% Rabatt)
               = $0.000125 + $0.00025 = $0.000375  ← 7× günstiger
```

→ Prompt Caching aktiviert sich automatisch bei langen, stabilen Prompts.

### Batch Processing

Wenn Antworten nicht sofort gebraucht werden:

```
OpenAI Batch API: 50% Rabatt
Nachteil: Antworten kommen erst nach Stunden
Gut für: Offline-Verarbeitung großer Dokumentmengen, nächtliche Reports
```

---

## Kosten tracken mit Langfuse

Langfuse trackt Kosten automatisch pro Trace:

```
Langfuse Dashboard zeigt:
├── Kosten pro Tag / Woche / Monat
├── Kosten pro Modell
├── Kosten pro User
├── Kosten pro Feature / Workflow
└── Durchschnittliche Token-Länge pro Call
```

So siehst du sofort: welches Feature kostet am meisten? Wo gibt es Ausreißer?

---

## Kosten-Kalkulation vor dem Launch

```
Formel:
  Calls/Monat × Ø Input-Tokens × Input-Preis
+ Calls/Monat × Ø Output-Tokens × Output-Preis
= Monatliche LLM-Kosten

Beispiel Chat-App:
  10.000 Gespräche/Monat
  × 800 Input-Tokens Ø × $2.50/1M     = $20
  + 10.000 × 200 Output-Tokens × $10/1M = $20
  = $40/Monat für LLM-Kosten

Puffer: ×2 für unerwartetes Wachstum = $80 Budget einplanen
```

---

## Modellwahl-Entscheidungsbaum

```
Aufgabe definieren
        │
        ▼
Brauche ich Reasoning / komplexe Analyse?
  JA  → GPT-4o oder Claude Sonnet
  NEIN → weiter
        │
        ▼
Datenschutz-kritisch (keine Daten in die Cloud)?
  JA  → Ollama + lokales Modell
  NEIN → weiter
        │
        ▼
EU-Compliance wichtig?
  JA  → Mistral AI oder Azure OpenAI (EU-Region)
  NEIN → weiter
        │
        ▼
Kosten minimieren?
  JA  → GPT-4o mini / Mistral 7B / Claude Haiku
  NEIN → GPT-4o / Claude Sonnet für beste Qualität
```
