# Tag 1: Daten senden

Eine Kontakt-Pipeline mit zwei Eingangs-Triggern (n8n-Formular und Webhook), die eingehende Daten in Supabase ablegt und eine Benachrichtigungs-E-Mail via Resend verschickt. Didaktischer Fokus: wie unterschiedliche Trigger denselben Verarbeitungspfad speisen und wie ein eigenes HTML-Frontend per Webhook andockt.

## 📍 Architektur-Spektrum

**Workflow** — mehrere deterministische Schritte (Trigger → Normalisierung → Datenbank → E-Mail), keine LLM-gesteuerte Entscheidung.

```
Prompt → Custom GPT → [Workflow] → Agent → Multi-Agent
                          ▲
```

## 🎯 Was du lernst

- **Trigger-Vielfalt**: `formTrigger` (eingebautes n8n-Formular) und `webhook` (externer Aufruf) als gleichwertige Einstiegspunkte in dieselbe Pipeline
- Formular- und JSON-Body-Daten mit dem `set`-Node auf ein einheitliches Schema normalisieren
- Datenbank-Inserts via `supabase`-Node ausführen
- HTTP-Requests gegen die Resend-API mit Bearer-Auth absetzen
- **Upsert-Pattern** (Bonus): `supabase` getAll + `if` als Weiche zwischen Update und Insert
- Konzeptionell: warum es sinnvoll ist, **Webhook und Formular auf derselben Logik konvergieren** zu lassen, statt sie zu duplizieren

## 🧰 Voraussetzungen

### Benötigte Credentials

| Service | n8n Credential-Typ | Key holen unter |
|---------|---------------------|------------------|
| Supabase | `Supabase API` | https://supabase.com/dashboard → Project Settings → API |
| Resend | `HTTP Bearer Auth` | https://resend.com/api-keys |

In Supabase muss eine Tabelle `contacts` mit den Spalten `name`, `email`, `nachricht` (alle `text`) existieren. Für den Bonus zusätzlich eine Primärschlüssel-Spalte `id`.

### Community Nodes

Keine — nur Core-Nodes (`Form Trigger`, `Webhook`, `Set`, `Supabase`, `HTTP Request`, `If`).

## 📦 Workflow-Varianten

- **`workflow.json`** — Hauptversion: zwei Trigger (`formTrigger` und `webhook`) konvergieren auf einem gemeinsamen Insert-Pfad.
- **`workflow-bonus.json`** — Upsert-Variante: prüft per E-Mail-Lookup, ob der Kontakt bereits existiert, und verzweigt via `if` zwischen Update und Insert. Nur Form-Trigger, kein Webhook.

## 🌐 Companion-Files

- **`frontend/kontakt.html`** — eigenständige HTML-Seite mit Formular, die per `fetch` JSON an den Webhook der Hauptversion sendet. Komplett ohne Build-Tools, direkt im Browser oder von einem Static-Host nutzbar.

## 🚀 Import & Setup

1. **Workflows importieren**: `workflow.json` und `workflow-bonus.json` über `Workflows → Add Workflow → Import from File` einlesen
2. **Supabase-Credential** anlegen und in allen `Supabase`-Nodes auswählen
3. **Resend-Credential** anlegen (`HTTP Bearer Auth` mit deinem Resend-API-Key) und in allen `HTTP Request`-Nodes auswählen
4. **Notification-Empfänger eintragen**: in jedem `HTTP Request`-Node (Email: Neuer Kontakt, Email: Kontakt aktualisieren) das `to`-Feld im JSON-Body von `<<REPLACE_WITH_YOUR_NOTIFICATION_EMAIL>>` auf deine eigene E-Mail-Adresse ändern
5. **Workflow aktivieren** (Toggle oben rechts), damit der Webhook-Pfad live ist
6. **Frontend verkabeln**: `frontend/kontakt.html` in einem Editor öffnen und `<<REPLACE_WITH_YOUR_N8N_HOST>>` durch die Base-URL deiner n8n-Instanz ersetzen (z.B. `https://n8n.example.com`). Die Datei dann lokal im Browser öffnen oder auf einem Static-Host bereitstellen.
7. **Test**:
   - **Form-Trigger**: in n8n auf das `Kontaktformular` klicken → `Open form` → ausfüllen → senden
   - **Webhook**: `frontend/kontakt.html` im Browser öffnen → Formular ausfüllen → Absenden

## 📤 Erwartetes Verhalten

- Beim Absenden des **n8n-Formulars** läuft die Kette `Kontaktformular → Set Fields → Neuer Kontakt (Supabase) → Email: Neuer Kontakt (Resend)`.
- Beim Absenden des **HTML-Frontends** geht der Request an `POST /webhook/kontakt`, durchläuft `Webhook → Webhook: Felder normalisieren` und mündet im selben Supabase-Insert wie der Form-Pfad.
- In Supabase erscheint eine neue Zeile in `contacts`; im Postfach deiner Notification-Adresse landet eine Resend-E-Mail mit Name/E-Mail/Nachricht.
- Beim **Bonus-Workflow** entscheidet die `If`-Weiche anhand der E-Mail: bekannte Adresse → Update + "Kontakt Aktualisiert"-Mail, neue Adresse → Insert + "Neuer Kontakt"-Mail.

## 💡 Variationen & Übungsideen

- **Webhook-Authentifizierung** ergänzen (saubere Praxis): am `Webhook`-Node `Header Auth` oder einen Shared Secret in einem Header aktivieren und den Wert im Frontend mitschicken — schützt den öffentlichen Endpunkt vor Spam.
- Den HTML-Frontend um ein verstecktes Honeypot-Feld erweitern und bei gefülltem Honeypot im Workflow per `if` aussortieren.
- Den Bonus-Pfad auf den Webhook erweitern, sodass auch externe Aufrufer vom Upsert-Verhalten profitieren.
- Die Resend-`to`-Adresse aus einer n8n-Variable oder Credential statt aus dem JSON-Body ziehen, damit pro Umgebung (Dev/Prod) unterschiedliche Empfänger genutzt werden können.
