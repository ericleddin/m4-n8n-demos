---
title: "DSGVO-konformes RAG"
weight: 100
---

# Architektur-Blueprint: DSGVO-konformes RAG mittels Pseudonymisierung (Maskierung)

Dieses Dokument beschreibt den technischen Ansatz, wie personenbezogene Daten (PII) vor der Verarbeitung durch Online-Embedding-Modelle und Vektordatenbanken geschützt werden, ohne die semantische Mustersuche zu zerstören.

---

## 1. Der Kontext (Das Problem & die Philosophie)

* **Das Dilemma:** Vektordatenbanken speichern Text-Chunks dauerhaft. Online-Embedding-APIs verarbeiten diese Texte im Internet. Die DSGVO (Art. 17 - Recht auf Vergessenwerden, Art. 28 - Auftragsverarbeitung) verbietet die ungeschützte, permanente Speicherung personenbezogener Daten (PII) in Drittsystemen ohne immensen Löschaufwand.
* **Die Fehlannahme:** Echte *Verschlüsselung* (AES etc.) von Chunks zerstört die mathematische Struktur des Textes. Verschlüsselter Text hat keine Semantik mehr – die Vektorsuche wird unbrauchbar.
* **Die Philosophie:** Der **thematische Kontext** (die "Aura" des Textes) bleibt im Klartext lesbar, damit das Modell die Bedeutung versteht. Nur die **identifizierenden Details** werden durch strukturierte, sprechende Platzhalter (Pseudonyme) ersetzt.

---

## 2. Techniken & Methodiken

### A. Named Entity Recognition (NER) & Sanitizing
Vor dem Zerschneiden in Chunks (Chunking) scannt eine spezialisierte Pipeline den Text nach PII.
* **Tool-Beispiele:** *Microsoft Presidio*, *SpaCy* (mit Custom Modellen) oder lokale Open-Source-Modelle.
* **Methodik:** Erkennung von Entitäten wie `PER` (Personen), `LOC` (Orte), `ORG` (Organisationen), E-Mails, IBANs und Telefonnummern.

### B. Semantische Maskierung (Tokenisierung)
Erkannte Daten werden nicht gelöscht oder geschwärzt (`XXXX`), sondern durch **semantische Platzhalter** ersetzt.
* *Beispiel:* `Max Mustermann` -> `[PERSON_1]`
* *Vorteil:* Das LLM behält das grammatikalische und logische Verständnis (es weiß, dass `[PERSON_1]` ein Mensch ist).

### C. Bidirektionales ID-Mapping (Die "Vault")
Die Zuordnung zwischen echtem Wert und Platzhalter wird in einer sicheren, lokalen und relationalen Datenbank (z. B. PostgreSQL/Redis) außerhalb des KI-Systems gespeichert.

---

## 3. Der Datenfluss (Wie man damit umgeht)

### Phase A: Daten-Ingestion (Befüllen der Vektordatenbank)

1. **Rohdaten-Eingang:** Dokumente liegen im Klartext in der Applikation vor.
2. **Sanitizing (Lokale App):**
   * `Max Mustermann kauft ein Auto in Berlin.`
   * Der Sanitizer erkennt die Entitäten.
3. **Mapping-Generierung:** Die App speichert intern:
   * `[PERSON_1]` = `Max Mustermann`
   * `[STADT_1]` = `Berlin`
4. **Chunking & Embedding:** Der maskierte Text (`[PERSON_1] kauft ein Auto in [STADT_1].`) wird in Chunks geschnitten und an die Embedding-API (z. B. OpenAI, Cohere) geschickt.
5. **Speicherung:** Die Vektordatenbank erhält den mathematischen Vektor und den *maskierten* Text-Chunk.

### Phase B: Query & Retrieval (Die Abfrage)

1. **Nutzer-Frage:** Der Nutzer fragt: *"Wo hat Max Mustermann ein Auto gekauft?"*
2. **Query-Maskierung:** Die lokale App maskiert die Frage vorab mithilfe der internen Mapping-Tabelle: *"Wo hat [PERSON_1] ein Auto gekauft?"*
3. **Vektorsuche:** Die maskierte Frage wird vervektort. Die Vektordatenbank findet den passenden Chunk anhand des semantischen Musters ("Autokauf").
4. **LLM-Verarbeitung:** Das LLM erhält die maskierte Frage und den maskierten Kontext. Es generiert die Antwort: *"[PERSON_1] hat ein Auto in [STADT_1] gekauft."*
5. **De-Pseudonymisierung (Lokale App):** Bevor der Text an den Nutzer ausgespielt wird, fängt die App die Antwort ab, schaut in die Mapping-Tabelle und ersetzt die Platzhalter mit den Klarnamen.
6. **Ausgabe:** *"Max Mustermann hat ein Auto in Berlin gekauft."*

---

## 4. Sicherheits- und Architektur-Vorgaben

* **Besitz des Secrets:** Die Mapping-Tabelle (das Secret) darf **niemals** die eigene, geschützte Enterprise-Infrastruktur verlassen. Weder die Embedding-API noch die Vektordatenbank haben Zugriff darauf.
* **Konsistenz:** Innerhalb eines logischen Kontexts/Dokuments muss die ID-Vergabe konsistent sein (`Max Mustermann` ist im gesamten Chatverlauf oder Dokument immer `[PERSON_1]`).
* **Datenschutz-Konformität:** Da in der Cloud nur Daten wie *"Person_1 hat bei Firma_A ein Produkt_X gemietet"* liegen, ist kein direkter Personenbezug gegeben. Ein "Recht auf Vergessenwerden" wird durch das einfache Löschen der Zeile in der *lokalen* Mapping-Datenbank systemübergreifend durchgesetzt.
