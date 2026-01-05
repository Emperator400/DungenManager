# DELEGATION PROMPT - Inventory Database Column Fix

**AUFTRAGGEBER:** Technischer Projektleiter (TPL)
**EMPFAENGER:** Database Error Specialist
**PRIORITÄT:** KRITISCH
**DATUM:** 2025-11-29

---

Du bist der **Database Error Specialist**.

## Kontext-Laden:
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen und bekannte Lösungen
2. Lies `PROJECT_TODO.md` für aktuellen Status und High-Level-Tasks
3. Analysiere die folgenden Dateien für Kontext:
   - `lib/services/inventory_service.dart`
   - `lib/models/inventory_item.dart`
   - `lib/database/database_helper.dart`

## Dein spezifischer Task:

**KRITISCHER BUG:** SQL-Abfrage für Inventar schlägt fehl wegen inkonsistenter Spaltennamen

### Problem-Spezifikation:
- **Hauptproblem:** Die SQL-Abfrage verwendet sowohl `owner_id` als auch `ownerId`, aber nur `owner_id` existiert in der Datenbank
- **Fehlermeldung:** `SqfliteFfiException(sqlite_error: 1): no such column: ownerId`
- **Betroffene SQL:** `SELECT * FROM inventory_items WHERE owner_id = ? OR ownerId = ? ORDER BY isEquipped DESC, itemId ASC`
- **Ursache:** Inkonsistente Namenskonvention zwischen Datenbank-Schema und SQL-Abfragen
- **Auswirkung:** Betrifft alle Inventar-Operationen (laden, speichern, anzeigen)

### Fehler-Analyse:
Die `loadInventory` Methode in `lib/services/inventory_service.dart` Zeile 42-45 verwendet:
```dart
where: 'owner_id = ? OR ownerId = ?',
whereArgs: [ownerId, ownerId],
```

Aber die Datenbank hat nur die Spalte `owner_id`, nicht `ownerId`.

### Erwartetes Verhalten:
- Alle Inventar-Operationen funktionieren fehlerfrei
- Konsistente Spaltennamen in allen SQL-Abfragen
- Keine Datenverlust oder Inkonsistenzen
- Inventar wird korrekt geladen und angezeigt

### Akzeptanzkriterien:
- [ ] SQL-Abfrage verwendet nur existierende Spaltennamen (`owner_id`)
- [ ] Alle Inventar-Operationen laden Daten korrekt
- [ ] Keine SQL-Fehler mehr beim Inventar-Zugriff
- [ ] Konsistente Namenskonvention im gesamten Code
- [ ] Bestehende Funktionalität bleibt erhalten
- [ ] Datenbank-Migration (falls nötig) funktioniert korrekt

## Dein Protokoll (A-P-B-V-L):

### A - Analyse:
1. **SQL-Analyse:** Untersuche alle SQL-Abfragen auf inkonsistente Spaltennamen
2. **Schema-Prüfung:** Überprüfe das tatsächliche Datenbank-Schema
3. **Code-Review:** Finde alle Vorkommen von `ownerId` vs `owner_id`
4. **Impact-Analyse:** Identifiziere alle betroffenen Methoden und Services

### P - Plan (mit Diffs + Verifikation):
1. **SQL-Korrektur:** Fixe die `loadInventory` Methode um nur `owner_id` zu verwenden
2. **Konsistenz-Prüfung:** Stelle sicher dass alle anderen Abfragen konsistent sind
3. **Test-Strategie:** Plane Tests für alle Inventar-Operationen
4. **Implementierung:** Führe die notwendigen Code-Änderungen durch
5. **Validierung:** Überprüfe dass keine Regressionen entstehen

### B - Bestätigung (User-Gate):
Stelle mir den folgenden Plan zur Bestätigung vor:
- Genaue SQL-Korrektur
- Betroffene Methoden und Dateien
- Test-Methode zur Verifikation
- Risiken und Mitigierungsstrategien

### V - Verifikation:
1. **SQL-Tests:** Teste die korrigierten Abfragen direkt
2. **Integration-Tests:** Überprüfe Inventar-Ladevorgänge in der App
3. **Regression-Tests:** Stelle sicher dass bestehende Funktionalität funktioniert
4. **Datenbank-Tests:** Verifiziere Datenintegrität nach den Änderungen

### L - Lernen (Bug-Archiv):
Dokumentiere die Lösung in `.vscode/docs/BUG_ARCHIVE.md` mit:
- Genaue Fehlerbeschreibung
- Ursachenanalyse (inkonsistente Namenskonvention)
- Implementierte Lösung
- Lessons Learned für zukünftige Datenbank-Operationen

## KRITISCHES ESKALATIONS-PROTOKOLL:

Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt (z.B. du bist Database Error Specialist, aber das Problem ist ein Service-Design Problem):

1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

## Wichtige Hinweise:
- **Konsistenz:** Stelle sicher dass alle SQL-Abfragen die gleichen Spaltennamen verwenden
- **Backward Compatibility:** Achte darauf dass bestehende Daten nicht verloren gehen
- **Performance:** Die Korrektur sollte die Performance nicht negativ beeinflussen
- **Testing:** Teste sowohl leere als auch gefüllte Inventare

## Erfolgskriterien:
- Die SQL-Abfrage `loadInventory` funktioniert ohne Fehler
- Alle Inventar-Operationen sind wieder voll funktionsfähig
- Keine Inkonsistenzen in Spaltennamen mehr vorhanden
- Die Lösung ist robust und zukunftssicher

---

**Zeitrahmen:** Da dies ein kritischer Bug ist, der die Inventar-Funktionalität blockiert, priorisiere diese Aufgabe und melde bei Blockaden sofort zurück.
