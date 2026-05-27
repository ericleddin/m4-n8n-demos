# RAG — Konzept und Praxis

> RAG (Retrieval Augmented Generation) ist die wichtigste Technik um LLMs
> mit eigenen Daten arbeiten zu lassen — ohne teures Fine-Tuning.
> Dieses Dokument erklärt was es ist, wie es funktioniert und wo es scheitert.

---

## Das Problem das RAG löst

Ein LLM wie GPT-4o weiß viel — aber nicht über deine Daten:

```
Ohne RAG:
User: "Was steht in unserem Handbuch zu Urlaubsanträgen?"
LLM:  "Ich kenne euer Handbuch nicht." ❌
      oder: erfindet eine plausibel klingende Antwort (Halluzination) ❌

Mit RAG:
User: "Was steht in unserem Handbuch zu Urlaubsanträgen?"
→ System sucht relevante Stellen im Handbuch
→ Schickt sie als Kontext an das LLM
LLM:  "Laut eurem Handbuch (Seite 12) müssen Urlaubsanträge..." ✅
```

---

## Die zwei Phasen

### Phase 1 — Indexierung (einmalig)

```
Deine Dokumente (PDF, Word, Webseiten, ...)
        │
        ▼
Text extrahieren & in Chunks aufteilen
        │
        ▼
Embedding-Modell: jeden Chunk → Vektor (Liste von Zahlen)
        │
        ▼
Vector DB: Vektoren + Original-Text speichern
```

Das passiert einmal (oder wenn sich Dokumente ändern) — nicht bei jeder Anfrage.

### Phase 2 — Retrieval & Generation (bei jeder Anfrage)

```
User-Frage: "Wie beantrage ich Urlaub?"
        │
        ▼
Frage → Embedding-Modell → Vektor der Frage
        │
        ▼
Vector DB: semantisch ähnliche Chunks finden
(nicht Wort-Suche, sondern Bedeutungs-Suche)
        │
        ▼
Top-3 bis Top-5 relevante Chunks auswählen
        │
        ▼
Prompt aufbauen:
  [System-Prompt]
  [Kontext: relevante Chunks]
  [User-Frage]
        │
        ▼
LLM generiert Antwort auf Basis des Kontexts
        │
        ▼
Antwort → User
(optional: Quellenangabe welche Chunks genutzt wurden)
```

---

## Chunking — die unterschätzte Stellschraube

Wie du deine Dokumente aufteilst hat massiven Einfluss auf die Qualität.

### Chunk-Größe

| Chunk-Größe | Problem |
|---|---|
| Zu groß (>2000 Token) | Zu viel irrelevanter Text im Kontext, LLM verliert den Fokus |
| Zu klein (<100 Token) | Kein Zusammenhang, Satz ohne Kontext ist sinnlos |
| **500–1000 Token** | **Praxis-Empfehlung für die meisten Fälle** |

### Overlap (Überlappung)

```
Chunk 1: "...Urlaubsanträge müssen 4 Wochen im Voraus..."
Chunk 2:                    "...4 Wochen im Voraus eingereicht werden. Die Genehmigung..."
                 ↑
           ~10-20% Überlappung verhindert dass wichtige Infos
           genau an einer Chunk-Grenze abgeschnitten werden
```

### Chunking-Strategien

| Strategie | Wann |
|---|---|
| **Fixed Size** | Einfachster Start, für homogene Dokumente |
| **Nach Absätzen / Überschriften** | Wenn Dokument gut strukturiert ist (Handbücher, Wikis) |
| **Semantisch** | Chunks nach Thema statt nach Länge — besser aber aufwendiger |
| **Hierarchisch** | Große Chunks für Kontext + kleine für Präzision — komplex aber effektiv |

---

## Embedding-Modell wählen

Das Embedding-Modell bestimmt wie gut "Bedeutungsähnlichkeit" erkannt wird.

| Modell | Anbieter | Stärke | Kosten |
|---|---|---|---|
| `text-embedding-3-small` | OpenAI | Gute Qualität, günstig | ~$0.02 / 1M Tokens |
| `text-embedding-3-large` | OpenAI | Beste OpenAI-Qualität | ~$0.13 / 1M Tokens |
| `nomic-embed-text` | Ollama (lokal) | Kostenlos, privat | Hardware |
| `multilingual-e5-large` | Hugging Face | Mehrsprachig, gut für Deutsch | lokal |

> **Wichtig:** Das Embedding-Modell beim Indexieren und beim Suchen muss das **gleiche** sein.
> Du kannst nicht mit OpenAI indexieren und mit Ollama suchen.

---

## Retrieval-Strategien

Nicht immer reicht "die 3 ähnlichsten Chunks":

### Naive Retrieval (Einstieg)
Top-K ähnlichste Chunks → direkt in den Prompt.
Einfach, funktioniert gut für homogene Dokumente.

### Hybrid Search
Kombination aus semantischer Suche (Embeddings) + klassischer Keyword-Suche.
```
Embedding-Suche:  findet "Urlaubsantrag" wenn User "Freizeit beantragen" fragt
Keyword-Suche:    findet exakte Begriffe wie Produktnummern, IDs, Namen
Hybrid:           beide kombiniert → deutlich weniger Misses
```
→ Weaviate und Qdrant unterstützen Hybrid Search nativ.

### Re-Ranking
Nach dem Retrieval nochmals sortieren — mit einem spezialisierten Re-Ranking-Modell.
Aufwendiger aber bessere Präzision bei komplexen Fragen.

### Parent-Child Retrieval
Kleine Chunks für präzises Retrieval → aber größere "Eltern-Chunks" in den Prompt.
Vorteil: Feinkörnige Suche + ausreichend Kontext in der Antwort.

---

## Wo RAG scheitert — häufige Fehler

```
Problem                          Ursache                        Fix
───────────────────────────────────────────────────────────────────────
Antwort ignoriert den Kontext    Chunks zu groß, LLM verliert  Kleinere Chunks
                                 sich im Text

Falsche Chunks werden gefunden   Embedding-Modell passt nicht   Anderen Embedder
                                 zur Sprache (Deutsch!)          ausprobieren

"Ich weiß es nicht" obwohl       Threshold zu hoch gesetzt,    Similarity-Threshold
 Antwort im Dokument steht       relevante Chunks gefiltert     anpassen

LLM erfindet trotz RAG           Prompt sagt nicht klar:        System-Prompt: "Antworte
                                 "Nur aus dem Kontext!"          NUR auf Basis des Kontexts"

Antwort nicht auf dem neuesten   Indexierung ist veraltet       Indexierung automatisieren
Stand                                                            bei Dokumentänderungen
```

---

## RAG vs. Fine-Tuning — wann was?

| | **RAG** | **Fine-Tuning** |
|---|---|---|
| Daten ändern sich regelmäßig | ✅ | ❌ Neutraining nötig |
| Antworten sollen belegbar sein | ✅ Quellen nachvollziehbar | ❌ |
| Schnell umsetzbar | ✅ Tage | ❌ Wochen + GPU |
| Konsistenter Schreibstil | ⚠️ schwierig | ✅ |
| Sehr hohe Anfragemenge | ⚠️ Retrieval-Latenz | ✅ schneller |
| **Empfehlung** | **Standard-Fall** | **Optimierungsfall** |

> Fine-Tuning löst andere Probleme als RAG.
> Fast immer ist RAG die richtige erste Wahl.

---

## Minimaler RAG-Stack

```
Klein (Einstieg):
├── pgvector          Vector DB als Postgres-Extension — kein extra Service
├── OpenAI Embeddings text-embedding-3-small
└── Direkter API-Call Embeddings erstellen + pgvector abfragen + OpenAI aufrufen
                      Kein Framework — du siehst genau was passiert
                      (n8n als Alternative wenn kein Code gewünscht)

Mittel (Produktion):
├── Qdrant            Dedizierte Vector DB, DSGVO 🇩🇪
├── Eigenes Embedding nomic-embed-text (lokal) für Datenschutz
├── LiteLLM           Gateway für LLM-Calls + semantisches Caching
└── Langfuse          Tracing: welche Chunks wurden genutzt? War die Antwort gut?

Groß (Scale):
├── Weaviate Cluster  Hybrid Search (semantisch + Keyword), GraphQL
├── Re-Ranking        Cohere Rerank oder lokales Modell
├── LlamaIndex        Wenn RAG-Pipelines komplex werden (Parent-Child, HyDE, ...)
└── Eval-Pipeline     Langfuse Evals: Faithfulness, Relevance, Answer Quality
```

> **Warum kein LangChain für den Einstieg?**
> LangChain abstrahiert jeden Schritt — praktisch zum Lernen, problematisch zum Debuggen.
> Wenn etwas falsch läuft (falscher Chunk, schlechte Antwort), siehst du nicht wo.
> Direkter API-Call macht den RAG-Flow transparent: du verstehst was passiert.
> LlamaIndex lohnt sich erst wenn die Pipelines wirklich komplex werden.

---

## RAG-Qualität messen

Langfuse ermöglicht es, jeden RAG-Call zu tracen:
- Welche Chunks wurden abgerufen?
- Wie ähnlich waren sie zur Frage (Score)?
- Hat das LLM den Kontext genutzt?
- War die Antwort korrekt? (manuell oder LLM-as-Judge)

```
Wichtige RAG-Metriken:
├── Faithfulness:    Hält sich die Antwort an den Kontext? (keine Halluzinationen)
├── Relevance:       Waren die abgerufenen Chunks wirklich relevant?
├── Answer Quality:  Beantwortet die Antwort die Frage vollständig?
└── Latency:         Wie lange dauert Retrieval + Generation?
```
