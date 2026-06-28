# Tag 3: Voltbox MCP-Server (ein Server, mehrere Agenten)

Alle Voltbox-Tools hängen an **einem** MCP-Server (`mcpTrigger`) und werden über das Model Context Protocol bereitgestellt. Zwei eigenständige Chat-Agenten verbinden sich per MCP-Client mit diesem Server — aber jeder sieht nur die Tools, die zu seiner Rolle passen. Didaktischer Fokus: Tool-Infrastruktur einmal zentral bauen und über echte, pro Anwendung gescopte Zugriffsgrenzen mehrfach nutzen — statt jede API in jedem Agenten neu zu verdrahten.

## 📍 Architektur-Spektrum

**Multi-Agent** — zwei autonome Agenten (Kundenservice extern, Support-Team intern) arbeiten unabhängig auf einer geteilten Tool-Schicht. Der Hauptworkflow selbst (`workflow.json`) ist kein Agent, sondern der **MCP-Server**: die gemeinsame Tool-Infrastruktur. Erst zusammen mit den beiden Client-Agenten entsteht das Multi-Agent-Bild — mehrere Agenten, eine Tool-Quelle, getrennte Berechtigungen.

```
Prompt → Custom GPT → Workflow → Agent → Multi-Agent
                                              ▲
```

## 🎯 Was du lernst

- Eigene Tools als MCP-Server bereitstellen: ein `mcpTrigger` (Pfad `voltbox-tools`) bündelt RAG, Bestellstatus, Ticket, Eskalation und Storno hinter einer einzigen MCP-Endpoint-URL
- Agenten als MCP-Client anbinden: `mcpClientTool` verbindet sich mit `<host>/mcp/voltbox-tools` und zieht die Server-Tools, ohne sie einzeln neu zu konfigurieren
- Tool-Scoping pro Anwendung: über `include: selected` sieht der Kundenservice-Agent nur `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen`; der Support-Team-Agent nur `bestellstatus_abfragen`, `bestellung_stornieren`, `Eskalation_an_Mensch` — dieselbe Server-Basis, zwei echte Berechtigungsgrenzen
- Credentials leben am Server: Supabase, Embeddings und Resend sind nur im Server-Workflow konfiguriert; die Client-Agenten brauchen ausschließlich ihr eigenes Chat-Modell — kein Tool-Credential pro Agent
- Konzeptionell: warum eine Zugriffsgrenze am Tool-Layer (Server-Scope) robuster ist als eine reine Prompt-Anweisung („du darfst X nicht") — der Kundenservice-Agent *kann* nicht stornieren, weil ihm das Tool fehlt, nicht weil der Prompt es verbietet

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Wo im Setup | Key holen unter |
|---------|---------------------|-------------|------------------|
| OpenRouter/OpenAI (Chat `gpt-4o-mini`) | `OpenAI` | beide Client-Agenten | https://openrouter.ai/keys bzw. https://platform.openai.com/api-keys |
| OpenAI (Embeddings `text-embedding-3-small`) | `OpenAI` | nur Server (RAG-Tool) | https://platform.openai.com/api-keys |
| Supabase (pgvector + `orders`/`tickets`) | `Supabase API` | nur Server | https://supabase.com/dashboard → Project Settings → API |
| Resend (Eskalations-Mail) | `Resend API` | nur Server | https://resend.com/api-keys |

Bemerkenswert: Die Tool-Credentials (Supabase, Embeddings, Resend) liegen **ausschließlich im Server-Workflow**. Die beiden Client-Agenten brauchen nur ihr Chat-Modell — ein Kernvorteil des MCP-Musters.

### Community Nodes

- **`n8n-nodes-resend`** (Resend) — liefert den `resendTool`-Node für `Eskalation_an_Mensch` im **Server** (`Settings → Community Nodes → Install`, Paketname `n8n-nodes-resend`).

`mcpTrigger` und `mcpClientTool` sind mitgelieferte LangChain-Nodes (ab n8n 1.88+) — keine Community-Installation nötig. Alle übrigen Nodes sind Core-Nodes.

### Geteilte Daten (aus Woche 6, Tag 3)

Kein eigener `data/`-Ordner — gleicher Supabase-Store und gleiche Wissensquelle wie der Support-Agent aus Woche 6:

- **Schema**: `documents` + `match_documents`, `orders` (`VB-10001`–`VB-10007`), `tickets` aus `../../woche-06/tag-03-support-agent/data/supabase_setup.sql`
- **Wissensquelle**: die 5 PDFs aus `../../woche-06/tag-03-support-agent/data/`, geladen über `../../woche-06/tag-03-support-agent-rag-optimiert/workflow-ingestion.json`

## 📦 Workflow-Varianten

- **`workflow.json`** — der **MCP-Server** (Hauptworkflow): `mcpTrigger` (Pfad `voltbox-tools`) mit allen fünf Tools — read (`search_knowledge_base` via Supabase Vector Store, `bestellstatus_abfragen`) und write (`Ticket_erstellen`, `Eskalation_an_Mensch`, `bestellung_stornieren`). Steht auf dem Spektrum bei **Workflow** (Tool-Provider, kein Agent).
- **`client-voltbox-kundenservice.json`** — **Client-Agent für Endkunden** (extern): Chat-Trigger → Agent + `memoryBufferWindow` + `mcpClientTool` mit Scope `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen`. Kann **nicht** stornieren/eskalieren. Position: **Agent**.
- **`client-support-team-assistent.json`** — **Client-Agent für Support-Mitarbeiter** (intern): Chat-Trigger → Agent + `memoryBufferWindow` + `mcpClientTool` mit Scope `bestellstatus_abfragen`, `bestellung_stornieren`, `Eskalation_an_Mensch`. Hat **kein** RAG und **kein** Ticket-Tool. Führt die Storno-Bestätigung selbst (eigenes Memory). Position: **Agent**.

## 🚀 Import & Setup

1. **Schema & Wissensbasis sicherstellen**: Falls Woche 6 / Tag 3 noch nicht eingerichtet ist, `../../woche-06/tag-03-support-agent/data/supabase_setup.sql` ausführen und die PDFs über die Ingestion-Pipeline in `documents` laden.
2. **Server importieren**: `workflow.json` einlesen.
3. **Server-Credentials zuweisen**: `Supabase API` → `search_knowledge_base`, `bestellstatus_abfragen`, `Ticket_erstellen`, `bestellung_stornieren`; `OpenAI` → `Embeddings OpenAI`; `Resend API` → `Eskalation_an_Mensch`. Im `Eskalation_an_Mensch`-Node `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` durch deine Empfänger-Adresse ersetzen.
4. **Server aktivieren**: Der `mcpTrigger` stellt seine produktive URL `<host>/mcp/voltbox-tools` erst bereit, wenn der Workflow **aktiv** ist (Toggle oben rechts). Die URL im `mcpTrigger`-Node kopieren.
5. **Clients importieren**: `client-voltbox-kundenservice.json` und `client-support-team-assistent.json` einlesen.
6. **Endpoint-URL setzen** (wichtig): In beiden Clients im `mcpClientTool`-Node `<<REPLACE_WITH_YOUR_N8N_HOST>>` in der `endpointUrl` durch den Host deiner n8n-Instanz ersetzen, sodass `<host>/mcp/voltbox-tools` herauskommt — exakt der Server-Pfad aus Schritt 4.
7. **Client-Credentials zuweisen**: `OpenAI`/OpenRouter → die `lmChatOpenAi`-Node in **beiden** Clients. Sonst nichts — die Tools laufen über den Server.
8. **Test**: In beiden Clients den Chat öffnen und dieselbe Frage stellen, z.B. „Storniere VB-10002": der **Support-Team-Assistent** fragt nach Bestätigung und storniert nach „Ja"; der **Kundenservice** hat kein Storno-Tool und verweist stattdessen auf ein Ticket bzw. support@voltbox.de.

## 📤 Erwartetes Verhalten

- **Kundenservice-Agent (extern)**: beantwortet Wissensfragen über `search_knowledge_base` (RAG), Statusfragen über `bestellstatus_abfragen` und legt bei ungelösten Anliegen ein Ticket an. Storno- oder Eskalationswünsche kann er nicht ausführen — ihm fehlen die Tools, er verweist auf ein Ticket oder support@voltbox.de.
- **Support-Team-Assistent (intern)**: fragt Status ab, storniert (zweistufig mit eigener Bestätigung im `memoryBufferWindow`) und schickt Eskalations-Mails. Wissens-/Produktfragen beantwortet er bewusst **nicht** aus eigenem Wissen — ihm fehlt das RAG-Tool, und der Prompt weist ihn an, dafür auf den Kundenservice-Agent zu verweisen statt zu raten.
- **Dieselbe Frage, zwei Ergebnisse**: „Storniere VB-10002" → extern ❌ (kein Tool, Ticket/Verweis), intern ✅ (mit Bestätigung). „Wie ist die Garantie?" → extern ✅ (RAG), intern ❌ (kein RAG). Die Grenze des einen ist die Stärke des anderen — und sie hängt am Server-Scope, nicht am Prompt.

## 💡 Variationen & Übungsideen

- Im `mcpClientTool` des Kundenservice-Agents `bestellung_stornieren` zum Scope hinzufügen und beobachten, dass er nun storniert — macht greifbar, dass die Zugriffsgrenze am Client-Scope hängt, nicht am System-Prompt
- Einen dritten Client-Agenten bauen (z.B. „Logistik-Assistent" mit nur `bestellstatus_abfragen`) — derselbe Server, ein weiterer Scope, null zusätzliche Tool-Credentials
- `include: all` statt `selected` setzen und sehen, dass dann beide Agenten alle fünf Tools sehen — der Kontrast macht den Scoping-Mechanismus deutlich
- Ein neues Tool nur am Server ergänzen (z.B. `retoure_anlegen`) und prüfen, wie es ohne Client-Änderung sofort für jeden Agenten verfügbar wird, der es in seinen Scope nimmt
- **Saubere Praxis**: Den `mcpTrigger` mit Authentifizierung absichern (Bearer-Token), damit nicht jeder mit der URL die Tools — inklusive Storno und Mail-Versand — aufrufen kann; in den Clients das Token als Credential hinterlegen statt der offenen URL

---

Tiefergehende Erklärung zum Model Context Protocol in `docs/n8n_learning/ai_agent_ecosystem_overview.md` (Abschnitt 12); zu Agenten und Tool-Use allgemein `docs/n8n_learning/llm_agent_tools_intro.md`. Die Tools, die hier als MCP-Server bereitstehen, stammen aus dem Single-Agent in `../../woche-06/tag-03-support-agent/`.
