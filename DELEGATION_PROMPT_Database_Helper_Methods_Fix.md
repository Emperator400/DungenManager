# DELEGATION PROMPT - Database Helper Methods Fix

**Ziel**: Implementierung fehlender CRUD-Methoden in DatabaseHelper für offizielle D&D-Daten

---

## **AUFRUF AN SUB-AGENT**

"Du bist der **Database Architect Specialist**.

**Kontext-Laden:**
1. Lies `docs/BUG_ARCHIVE.md` für Projekt-Wissen
2. Lies `lib/database/database_helper.dart` für aktuellen Datenbank-Status
3. Lies `PROJECT_TODO.md` für Liste der fehlenden Methoden

**Dein spezifischer Task:**
Implementiere alle fehlenden CRUD-Methoden in DatabaseHelper für offizielle D&D-Daten, die derzeit die Kompilierung der gesamten Anwendung blockieren.

**Dein Protokoll (A-P-B-V-L):**
(Analyse → Plan → Bestätigung → Verifikation → Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du feststellst, dass du diese Methoden nicht implementieren kannst ODER das Problem außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Neue Problem-Spezifikation für mich (TPL)

---

## **PROBLEM-SPEZIFIKATION**

### **Hauptproblem**
Die Flutter-Anwendung kompiliert nicht wegen 11 fehlender Methoden in `lib/database/database_helper.dart`, die für offizielle D&D-Daten und Inventar-Display benötigt werden.

### **Fehlende Methoden (kritisch):**

**Offizielle D&D-Daten Methoden:**
1. `getAllOfficialMonsters()` - für Bestiarum-Funktionalität
2. `clearOfficialData()` - für Datenimport/Cleanup
3. `insertOfficialMonster()` - für Monster-Import
4. `insertOfficialSpell()` - für Spell-Import
5. `insertOfficialClass()` - für Klassen-Import
6. `insertOfficialRace()` - für Völker-Import
7. `insertOfficialItem()` - für Item-Import
8. `insertOfficialLocation()` - für Orts-Import
9. `getOfficialDataCount()` - für Import-Tracking
10. `getLatestVersion()` - für Versionsmanagement

**Inventar-Display Methode:**
11. `getDisplayInventoryForOwner()` - für Encounter-Setup

### **Kompatibilitäts-Problem:**
Bestehende Methoden verwenden möglicherweise veraltete Model-Klassen oder falsche Parameter-Signaturen (z.B. Zeile 1667).

### **Impact:**
- **KRITISCH**: Blockiert gesamte Anwendungskompilierung
- Betrifft: Bestiarum, Spell-Library, Item-Library, Official Data Import, Encounter Setup

---

## **ERWARTETE ERGEBNISSE**

### **Funktionale Anforderungen:**
1. **Alle 11 Methoden implementiert** mit korrekten Signaturen
2. **Datenbank-Kompatibilität** mit bestehendem Schema
3. **Fehlerbehandlung** für alle Datenbank-Operationen
4. **Performance-optimierte Queries** mit Indizes wo nötig
5. **Type-Safety** mit richtigen Rückgabetypen

### **Technische Anforderungen:**
1. **SQLite-konforme Syntax** für alle Queries
2. **Parameter-Binding** für SQL-Injection-Schutz
3. **Async/Await Pattern** für alle Methoden
4. **Fehlerlogging** mit aussagekräftigen Meldungen
5. **Dokumentation** für jede neue Methode

### **Qualitätsanforderungen:**
1. **Consistent Naming** mit bestehenden Methoden
2. **Proper Error Handling** mit spezifischen Exceptions
3. **Unit-Test-Ready** Code-Struktur
4. **Performance Considerations** bei großen Datenmengen
5. **Future-Proof Design** für zukünftige Erweiterungen

---

## **ANNAHMEN & ABHÄNGIGKEITEN**

### **Existierende Strukturen:**
- DatabaseHelper verwendet Singleton-Pattern
- Bestehende `official_monsters` Tabelle existiert
- Model-Klassen: `OfficialMonster`, `OfficialSpell`, etc. sind vorhanden
- Standard-Datenbank-Helper Methoden sind implementiert

### **Datenbank-Schema Annahmen:**
- Tabellen für offizielle Daten folgen Namenskonvention `official_*`
- Primary Keys sind `id` (String/UUID)
- Standard-Felder: `createdAt`, `updatedAt`, `version`
- Foreign Keys folgen Konvention `*_id`

### **Code-Standards:**
- Dart 3.0+ Compatibility
- Flutter/Dart Best Practices
- Exception Handling mit spezifischen Exception-Typen
- Logging mit ausreichend Kontext

---

## **VERIFIZIERUNGSKRITERIEN**

### **Kompilierungs-Test:**
- [ ] Anwendung kompiliert ohne Fehler
- [ ] Alle Import-Pfade funktionieren
- [ ] Keine veralteten Methoden-Aufrufe
- [ ] Type-Checker meldet keine Fehler

### **Funktionaler Test:**
- [ ] `getAllOfficialMonsters()` gibt korrekte Liste zurück
- [ ] `clearOfficialData()` löscht alle offiziellen Daten
- [ ] `insert*()` Methoden speichern Daten korrekt
- [ ] `getOfficialDataCount()` gibt korrekten Zähler zurück
- [ ] `getLatestVersion()` liefert Versionsinformation
- [ ] `getDisplayInventoryForOwner()` formatiert Inventar korrekt

### **Performance-Test:**
- [ ] Methoden führen in angemessener Zeit aus
- [ ] Memory-Usage ist akzeptabel
- [ ] Database-Connections werden korrekt verwaltet

### **Code-Qualität-Test:**
- [ ] Code folgt Projekt-Standards
- [ ] Dokumentation ist vollständig und nützlich
- [ ] Fehlerbehandlung ist robust
- [ ] Methoden sind testbar

---

## **RISIKO-ANALYSE**

### **Hohe Risiken:**
1. **Schema-Inkonsistenzen** - Tabellenstruktur anders als erwartet
2. **Model-Kompatibilität** - Model-Klassen passen nicht zu Tabellen
3. **Performance-Issues** - Große Datenmengen blockieren UI
4. **Migration-Konflikte** - Bestehende Daten könnten verloren gehen

### **Mittlere Risiken:**
1. **Parameter-Signatur** - Rückgabetypen falsch
2. **Fehlerhandling** - Exceptions nicht abgefangen
3. **Dependencies** - Weitere fehlende Abhängigkeiten

### **Risikominderung:**
1. **Schema-Analyse** vor Implementierung
2. ** schrittweise Implementierung** mit Tests
3. **Backup-Strategie** für bestehende Daten
4. **Performance-Testing** während Entwicklung

---

## **FALLBACK-STRATEGIE**

### **Wenn Schema-Inkonsistenzen:**
1. Schema-Migration implementieren
2. Kompatibilitätsschicht erstellen
3. Daten-Konverter entwickeln

### **Wenn Model-Inkompatibilität:**
1. Adapter-Pattern implementieren
2. Model-Klassen anpassen
3. Data-Transfer-Objects verwenden

### **Wenn Performance-Probleme:**
1. Queries optimieren
2. Indizes hinzufügen
3. Pagination implementieren
4. Caching-Strategie entwickeln

---

## **SUCCESS METRICS**

### **Quantitative Metriken:**
- 11/11 Methoden erfolgreich implementiert
- 0 Kompilierungsfehler
- < 100ms Durchschnitt für einfache Queries
- < 500ms für komplexe Queries

### **Qualitative Metriken:**
- Code ist lesbar und wartbar
- Fehlermeldungen sind aussagekräftig
- Dokumentation ist vollständig
- Integration funktioniert nahtlos

### **Business Impact:**
- Anwendung kompiliert und startet
- Official Data Import funktioniert
- Bestiarum ist voll funktionsfähig
- Encounter Setup funktioniert

---

**WICHTIG**: Implementiere mit Fokus auf Stabilität und Performance. Diese Methoden sind kritisch für die gesamte Anwendungsfunktionalität!"
