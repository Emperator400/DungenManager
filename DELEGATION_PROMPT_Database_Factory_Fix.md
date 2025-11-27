Du bist der `Database Architect Specialist`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `lib/main.dart` für die aktuelle Initialisierungsreihenfolge.
3. Lies `lib/services/wiki_service_locator.dart` für den Service Locator.
4. Lies `lib/database/database_helper.dart` für die Datenbank-Implementierung.

**Dein spezifischer Task:**
Korrigiere die Database Factory Initialisierungsreihenfolge in `lib/main.dart`. Das Problem ist, dass `_initializeServices()` vor der `databaseFactory` Initialisierung aufgerufen wird, was zu `WikiServiceLocator Initialisierung fehlgeschlagen: Bad state: databaseFactory not initialized` führt.

**Konkrete Anforderungen:**
1. Verschiebe `sqfliteFfiInit()` und `databaseFactory = databaseFactoryFfi;` VOR den Aufruf von `_initializeServices()`
2. Stelle sicher dass die Reihenfolge für alle Plattformen (Windows, Linux, macOS) korrekt ist
3. Behalte die Audio-Initialisierung an der richtigen Position

**Dein Protokoll (A-P-B-V-L):**
(Analysiere den aktuellen Code, erstelle einen Plan mit den genauen Änderungen, lass dir den Plan bestätigen, implementiere die Änderungen, verifiziere die Funktion)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du (Sub-Agent) während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt (z.B. Platform-spezifische Initialisierung):
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

**Erwartetes Ergebnis:**
- Die `databaseFactory` ist korrekt initialisiert bevor der WikiServiceLocator versucht auf die Datenbank zuzugreifen
- Die App startet ohne Database-Factory-Fehler
- Alle Services können erfolgreich initialisiert werden
