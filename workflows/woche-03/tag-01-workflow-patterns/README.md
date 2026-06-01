# Tag 1: Workflow-Patterns

Fünf eigenständige Demos zu den Bausteinen robuster Workflows — Branching, Loop, Parallelität, Sub-Workflow — plus ein Vorher/Nachher-Refactoring vom Monolith zum modularen Aufbau. Woche 3 bewegt sich bewusst nicht entlang der Architektur-Achse, sondern steht im Zeichen von Engineering-Disziplin: gleiche Patterns, sauberer gebaut.

## 📍 Architektur-Spektrum

**Workflow** — alle Beispiele sind deterministische Kontrollfluss-Patterns. In Pattern 1 klassifiziert ein LLM eine E-Mail, entscheidet aber nicht über den Ablauf (kein Tool-Use), die Verzweigung macht der `switch`.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- Bedingte Verzweigung mit `switch` + immer einem **Default-Zweig** (Pattern 1)
- Iteration mit `splitInBatches` (Loop Over Items), Rate-Limiting via `wait`, Fehler im Loop mit Continue-On-Fail abfangen (Pattern 2)
- Mehrere unabhängige Branches mit `merge` als Synchronisationspunkt zusammenführen (Pattern 3)
- Logik in `executeWorkflow`-Sub-Workflows auslagern — wie eine Funktion (Pattern 4)
- JavaScript in `code`-Nodes für Datenerzeugung und Anreicherung
- Konzeptionell: **wann ein Sub-Workflow statt Inline-Logik** sinnvoll ist und wie man einen Monolith in vier Schritten refactored (Benennung → Branching → Auslagerung → Fehlerpfad)

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| OpenRouter | `OpenRouter Api` | https://openrouter.ai/keys |
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |
| Supabase | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |

Nur **Pattern 1** (OpenRouter) und **Pattern 3** (Resend + Supabase) brauchen Credentials. Pattern 2, Pattern 4, das Refactoring-Beispiel und der Sub-Workflow laufen ohne.

### Community Nodes

Keine — nur Core- und LangChain-Nodes (`Manual Trigger`, `Set`, `Switch`, `Loop Over Items`, `Wait`, `Merge`, `Code`, `HTTP Request`, `Supabase`, `Execute Workflow`, `Execute Workflow Trigger`, `No Operation` + `AI Agent` / `OpenRouter Chat Model`).

### Supabase: Tabelle anlegen (nur für Pattern 3)

Pattern 3 legt einen Kunden in der Tabelle `demo_kunden` an (Felder `name`, `email`). Falls du Supabase neu einrichtest, im **SQL Editor** ausführen:

```sql
create table demo_kunden (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  email text not null,
  erstellt_am timestamptz default now()
);
```

Demo-Daten brauchst du nicht — der Workflow füllt die Tabelle beim Ausführen selbst.

**API-URL** und **Service Role Key** findest du unter **Project Settings → API** — beides brauchst du für das `Supabase API` Credential in n8n.

**💡 Tipp: KI als Setup-Assistent nutzen**

Falls dir das Setup unklar ist, kannst du Claude (oder eine andere KI) fragen:

> Ich nutze Supabase zum ersten Mal und brauche eine Tabelle `demo_kunden` mit den Spalten `id` (UUID, Primary Key, default `gen_random_uuid()`), `name` (text, not null), `email` (text, not null), `erstellt_am` (timestamptz, default `now()`). Erkläre mir Schritt für Schritt:
> 1. Wie ich ein neues Supabase-Projekt anlege,
> 2. Wie ich die Tabelle via SQL Editor erstelle,
> 3. Wo ich die API-URL und den Service Role Key finde, um sie in n8n unter `Supabase API` zu hinterlegen.

So lernst du nebenbei, wie KI dich bei Setup-Aufgaben unterstützt — eine Kern-Kompetenz für M4.

## 📦 Enthaltene Workflows

Gleichrangige Beispiele zum selben Thema (kein Haupt-/Bonus-Verhältnis):

- **`workflow-pattern-1-branching.json`** — LLM klassifiziert eine E-Mail in ein Wort, der `switch` routet nach Kategorie (Beschwerde / Anfrage / Spam) plus Default-Zweig.
- **`workflow-pattern-2-loop.json`** — Loop Over Items mit Batch-Größe 1, `wait` für Rate-Limiting; Lead 3 wirft bewusst einen Fehler, Continue-On-Fail lässt den Loop trotzdem durchlaufen.
- **`workflow-pattern-3-parallele-ausfuehrung.json`** — ein Input, drei unabhängige Branches (Resend-Mail, Supabase-Insert, Mock-Benachrichtigung) → `merge` wartet auf alle drei. „Parallel" meint hier **Unabhängigkeit**, nicht OS-Parallelität.
- **`workflow-pattern-4-sub-workflow.json`** — ruft den Sub-Workflow wie eine Funktion auf und übergibt `kundeId`.
- **`workflow-refactoring-monolith-zu-modular.json`** — Vorher (linearer Monolith, generische Namen, doppelte Logik, kein Fehlerpfad) vs. Nachher (in vier Schritten refactored, mit Try/Catch über den Error-Output des Subs).
- **`subworkflow-kundendaten-anreichern.json`** — abhängiger Sub: wird von **Pattern 4 und vom Refactoring-Beispiel** aufgerufen, **nicht eigenständig nutzbar**.

## 🚀 Import & Setup

1. **Alle sechs JSON-Dateien importieren** über `Workflows → Add Workflow → Import from File`.
2. **Sub-Workflow einrichten** (`subworkflow-kundendaten-anreichern.json`):
   1. Importieren und speichern (kein „Active"-Toggle nötig — der gilt nur für Trigger-Workflows, hier wird der Sub über `Execute Workflow` aufgerufen).
   2. In Pattern 4 und im Refactoring-Beispiel den `Execute Workflow`-Node öffnen (Node `SUB - Kundendaten anreichern` bzw. `Kundendaten anreichern (Sub)`) und den Sub neu auswählen — die im JSON exportierte Sub-ID `n77KEUdHbxU3oAJg` zeigt sonst ins Leere (n8n-Eigenheit beim Import).
3. **OpenRouter-Credential** (`OpenRouter Api`) anlegen und im Node `OpenRouter Modell` von Pattern 1 auswählen.
4. **Pattern 3 verkabeln**: Resend-Credential (`HTTP Bearer Auth`) im Node `Willkommens-Mail (Resend)`, Supabase-Credential (`Supabase API`) im Node `Kunde in Supabase anlegen` auswählen; Tabelle `demo_kunden` anlegen (siehe oben).
5. **Notification-Empfänger eintragen**: im Node `Willkommens-Mail (Resend)` von Pattern 3 das `to`-Feld im JSON-Body von `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` auf deine eigene Adresse ändern.
6. **Test**: jede Demo einzeln über ihren `Manual Trigger` starten (`Execute workflow`).

## 📤 Erwartetes Verhalten

- **Pattern 1**: Die Beispiel-E-Mail wird vom LLM klassifiziert, der `switch` schickt sie je nach Kategorie auf einen eigenen Mock-Pfad; unbekannte Kategorien landen im Default „Manuell prüfen".
- **Pattern 2**: Fünf Leads werden einzeln durchlaufen, jeweils mit 1 s Pause. Lead 3 wirft einen Fehler, der abgefangen wird — der Loop läuft komplett durch, die Zusammenfassung zählt alle Durchläufe.
- **Pattern 3**: Aus einem Kundendatensatz starten drei unabhängige Aktionen; der `merge` wartet, bis Mail, Supabase-Insert und Mock-Benachrichtigung fertig sind.
- **Pattern 4**: Der Haupt-Workflow übergibt eine `kundeId` an den Sub und erhält angereicherte Daten (Firma, Umsatz, Region) zurück.
- **Refactoring**: Beide Stränge laufen ab demselben Trigger — der Monolith als Negativbeispiel, die modulare Variante mit Switch nach Typ und Fehler-Fallback aus dem Sub-Error-Output.

## 💡 Variationen & Übungsideen

- **Pattern 1**: eine vierte Kategorie (z.B. „Rechnung") ergänzen — neuer `switch`-Output plus Mock-Pfad.
- **Pattern 2**: Continue-On-Fail im Node `Lead anreichern` abschalten und beobachten, wie der Loop bei Lead 3 stoppt; den Fehler stattdessen sauber in einen **Error-Output** abfangen statt nur durchzuwinken (saubere Praxis).
- **Pattern 3**: den Mock `Sales-Team benachrichtigen` durch einen echten `Slack`-Node ersetzen.
- **Refactoring**: die hartcodierten `api.example.com`-URLs des Monolithen in echte **n8n-Credentials oder Variablen** ziehen (saubere Praxis, direkt im Vorher/Nachher erlebbar).

---

Tiefergehende Erklärung der Datenfluss-Patterns (Switch, Merge, Loop) in `docs/n8n_learning/n8n_datenfluss_kompendium.md`, zu den `code`-Nodes in `docs/n8n_learning/n8n_developer_guide.md`.
