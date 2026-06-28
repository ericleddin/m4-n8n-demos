# Tag 4: Produkt-Radar (Compounding-Kette)

Drei Agenten in fester Reihe — Sammler → Analyst → Reporter — veredeln Produkt-Feedback Stufe um Stufe: aus Rohdaten werden Cluster, aus Clustern ein priorisierter Feature-Brief, der per Mail rausgeht. Didaktischer Fokus: die einfachste Form der Agenten-Kooperation ist die deterministische Verkettung (Prompt-Chaining) — kein Router, keine Delegation wie in Tag 1/2, sondern eine Pipeline, in der jede Stufe den Output der vorigen weiterverarbeitet.

## 📍 Architektur-Spektrum

**Multi-Agent** — drei `agent`-Nodes arbeiten zusammen, aber in fester Reihenschaltung (`main → main → main`) statt über einen Orchestrator. Jede Stufe veredelt den Output der vorigen; nur Stufe 1 hat ein Tool, Stufe 2+3 sind reines Reasoning. Die einfachste Kooperationsform — bewusster Kontrast zum autonomen Routing aus Tag 1/2.

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                                              ▲
```

## 🎯 Was du lernst

- Agenten verketten (Compounding/Prompt-Chaining): drei `agent`-Nodes in Reihe, jede Stufe liest `{{ $json.output }}` der vorigen — Rohdaten → Cluster → Brief, ohne dass ein Agent über den Ablauf entscheidet
- Den Unterschied zwischen Kette und Orchestrierung: hier gibt es keinen Router und keine Delegation wie in `../tag-01-multi-agent-orchestrator-sub-workflows/` — der Fluss ist deterministisch verdrahtet (`scheduleTrigger → Sammler → Analyst → Reporter → Mail)
- Rollen-Spezialisierung über System-Prompts: jeder Agent hat eine enge Aufgabe (sammeln/nicht bewerten, clustern, priorisieren) und ein eigenes `lmChatOpenAi`-Modell
- Tool nur, wo nötig: allein der Sammler trägt ein `supabaseTool` (`product_feedback`, `getAll`); der deterministische Mail-Versand am Ketten-Ende ist ein fixer `resend`-Node (kein Agenten-Tool) — der Report geht immer raus, keine LLM-Entscheidung
- Geplante Ausführung: `scheduleTrigger` (wöchentlich Mo 08:00) macht aus der Kette einen wiederkehrenden Report; deterministisches Markdown→HTML (`markdown`-Node) formatiert den Brief für die Mail
- Konzeptionell: wann eine Kette ausreicht und ein Orchestrator Overkill wäre — feste, lineare Veredelungs-Schritte brauchen keine autonome Routing-Entscheidung

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter/OpenAI (Chat `gpt-4o-mini`, 3×) | `OpenAI` | https://openrouter.ai/keys bzw. https://platform.openai.com/api-keys |
| Supabase (`product_feedback`) | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| Resend (Report-Mail) | `Resend API` | https://resend.com/api-keys |

Die drei Agenten nutzen je ein eigenes `lmChatOpenAi`-Credential (im Export OpenRouter; ein echtes OpenAI-Credential tut es ebenso). Embeddings braucht diese Demo nicht — kein RAG.

### Community Nodes

- **`n8n-nodes-resend`** (Resend) — liefert den `resend`-Node für `Report senden` (`Settings → Community Nodes → Install`, Paketname `n8n-nodes-resend`).

Alle übrigen Nodes sind Core- bzw. mitgelieferte LangChain-Nodes (`scheduleTrigger`, `markdown`, `agent`, `lmChatOpenAi`, `supabaseTool`).

## 🌐 Companion-Files

- **`data/supabase_setup.sql`** — legt die Tabelle `product_feedback` an (`source` mit Check-Constraint `rezension`/`feature_request`/`umfrage`/`support`/`social`, `product`, `feedback`, `rating` 1–5 nullable) und füllt sie mit 20 zeitlosen Demo-Einträgen. Die Seeds bilden bewusst Cluster (Akku-Laufzeit, App/Bluetooth, Lüfter, Gewicht, Feature-Requests, Positives), damit die Analyst-Stufe Muster findet und der Reporter Funktionierendes als „beibehalten" erkennt.

Diese Tabelle ist eigenständig — sie gehört **nicht** zum geteilten Voltbox-Setup aus Woche 6 (`documents`/`orders`/`tickets`) und steht hier in einem eigenen `data/`-Ordner.

## 🚀 Import & Setup

1. **Tabelle anlegen & befüllen**: `data/supabase_setup.sql` im Supabase-SQL-Editor ausführen — legt `product_feedback` an und füllt die 20 Demo-Einträge ein.
2. **Workflow importieren**: `workflow.json` über `Workflows → Add Workflow → Import from File` einlesen.
3. **Credentials zuweisen** (nach dem Import sind die Nodes ohne Credential):
   - `OpenAI`/OpenRouter → die drei `lmChatOpenAi`-Nodes `Model (Sammler)`, `Model (Analyst)`, `Model (Reporter)`
   - `Supabase API` → `product_feedback_lesen`
   - `Resend API` → `Report senden`
4. **Platzhalter ersetzen**: Im `Report senden`-Node `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` durch deine Empfänger-Adresse ersetzen. Der Absender steht auf `onboarding@resend.dev` (Resend-Testdomain) — für echten Versand auf eine in Resend verifizierte Domain umstellen.
5. **Test**: Oben auf `Execute Workflow` klicken (der `scheduleTrigger` läuft sonst erst Mo 08:00). Die Kette durchläuft alle drei Stufen und verschickt den Brief.

## 📤 Erwartetes Verhalten

- **Sammler** ruft `product_feedback_lesen` (`getAll`, Limit 20) auf und trägt das Roh-Feedback strukturiert zusammen (Produkt, Quelle, Rating, Text) — ohne zu bewerten.
- **Analyst** liest den Sammler-Output (`{{ $json.output }}`), clustert nach Pain Points / Themen mit Häufigkeit, betroffenen Produkten und Sentiment — bei den Demo-Daten ergeben sich u.a. „Akku-Laufzeit", „App/Bluetooth", „Lüfter zu laut" sowie Feature-Wünsche und Positives.
- **Reporter** liest die Cluster-Analyse und schreibt einen priorisierten Feature-Brief (größter Schmerz zuerst), nimmt Positives als „beibehalten / nicht anfassen" auf.
- **Brief formatieren** wandelt das Reporter-Markdown deterministisch in HTML (`markdownToHtml`), **Report senden** verschickt es per Resend. Der Versand ist fix am Ketten-Ende — er hängt nicht an einer LLM-Entscheidung, deshalb bleibt der Reporter bewusst tool-los.

## 💡 Variationen & Übungsideen

- Eine vierte Stufe anhängen (z.B. „Lektor", der den Brief auf eine Management-Zusammenfassung kürzt) — zeigt, wie eine Kette linear wächst, ganz ohne Orchestrator
- Den Sammler von `getAll` auf einen Filter umstellen (z.B. nur `source = 'support'` oder nur negatives `rating`) und beobachten, wie sich die Cluster der nachgelagerten Stufen verschieben
- Dieselbe Aufgabe einmal als Kette (dieses Demo) und einmal mit einem Orchestrator (Tag 1/2) bauen und vergleichen: wann lohnt der Router, wann ist die feste Reihe einfacher und robuster?
- Das `scheduleTrigger`-Intervall anpassen (z.B. täglich) oder den Report zusätzlich in eine Tabelle schreiben, sodass sich die Briefe über die Zeit zu einer Historie **compounden**
- **Saubere Praxis**: Den Mail-Versand erst nach einer Mindest-Datenmenge auslösen — vor den Sammler ein `if` setzen, das bei leerer oder zu kleiner `product_feedback`-Rückgabe abbricht, damit kein inhaltsleerer Report rausgeht; und den Absender von der Resend-Testdomain auf eine verifizierte Domain umstellen

---

Tiefergehende Erklärung zu Agenten und Tool-Use in `docs/n8n_learning/llm_agent_tools_intro.md`; zur Einordnung von Multi-Agent-Mustern (Kette vs. Orchestrierung) `docs/n8n_learning/ai_agent_ecosystem_overview.md` (Abschnitt 5). Das orchestrierte Gegenstück mit Router: `../tag-01-multi-agent-orchestrator-sub-workflows/`.
