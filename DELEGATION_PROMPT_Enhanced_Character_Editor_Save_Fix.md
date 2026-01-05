# DELEGATION PROMPT - Enhanced Character Editor Save Fix

**AUFTRAGGEBER:** Technischer Projektleiter (TPL)
**EMPFAENGER:** Character Editor Specialist
**PRIORITÄT:** KRITISCH
**DATUM:** 2025-11-29

---

Du bist der **Character Editor Specialist**.

## Kontext-Laden:
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen und bekannte Lösungen
2. Lies `PROJECT_TODO.md` für aktuellen Status und High-Level-Tasks
3. Analysiere die folgenden Dateien für Kontext:
   - `lib/widgets/character_editor/enhanced_character_editor_controller.dart`
   - `lib/viewmodels/character_editor_viewmodel.dart` 
   - `lib/services/character_editor_service.dart`

## Dein spezifischer Task:

**KRITISCHER BUG:** Der enhanced_character_editor_controller speichert keine vollständigen Player-Objekte in der Datenbank.

### Problem-Spezifikation:
- **Hauptproblem:** Beim Speichern von Character-Daten gehen Informationen verloren
- **Symptom:** Gespeicherte Characters werden dem Nutzer nicht richtig angezeigt
- **Datenfluss-Analyse:**
  - Controller → ViewModel: `viewModel.savePlayerCharacter()` wird korrekt aufgerufen
  - ViewModel → Service: `_characterService.updatePlayerCharacter()` wird korrekt aufgerufen  
  - Service → Database: `_dbHelper.updatePlayerCharacter(character)` wird korrekt aufgerufen
- **VERMUTETE URSACHE:** In der Konvertierung von `Map<String, dynamic>` zu `PlayerCharacter` im `CharacterEditorViewModel.savePlayerCharacter()` gehen Daten verloren

### Erwartetes Verhalten:
- Alle Formulardaten aus dem Controller sollen korrekt in der Datenbank gespeichert werden
- Angriffsliste, Inventar und alle Character-Attribute sollen persistent gespeichert werden
- Nach dem Speichern sollen die Daten korrekt aus der Datenbank geladen und angezeigt werden

### Akzeptanzkriterien:
- [ ] Player Characters werden vollständig mit allen Attributen gespeichert
- [ ] Creatures werden vollständig mit allen Attributen gespeichert  
- [ ] Attack-Liste wird korrekt übertragen und gespeichert
- [ ] Inventory-Daten werden korrekt übertragen und gespeichert (falls vorhanden)
- [ ] Nach dem Speichern sind alle Daten in der UI sichtbar
- [ ] Keine Daten gehen bei der Map → Objekt Konvertierung verloren
- [ ] Fehlerbehandlung funktioniert korrekt bei Speicherfehlern

## Dein Protokoll (A-P-B-V-L):

### A - Analyse:
1. **Datenfluss-Trace:** Analysiere den kompletten Datenfluss vom Controller zur Datenbank
2. **Fehlerlokalisierung:** Finde genau heraus, wo und welche Daten verloren gehen
3. **Map-Konvertierung:** Untersuche die `savePlayerCharacter()` Methode im ViewModel auf Datenverlust
4. **Model-Validierung:** Prüfe das `PlayerCharacter` Modell auf fehlende Felder

### P - Plan (mit Diffs + Verifikation):
1. **Datenfluss-Analyse:** Trace durch den gesamten Speicherprozess
2. **Problem-Identifikation:** Finde die exakte Stelle des Datenverlusts
3. **Lösungs-Design:** Entwickele einen Fix für die Datenkonvertierung
4. **Test-Strategie:** Plane Tests zur Verifikation des Fixes
5. **Implementierung:** Erstelle die notwendigen Code-Änderungen

### B - Bestätigung (User-Gate):
Stelle mir den folgenden Plan zur Bestätigung vor:
- Genaue Fehlerursache
- Geplanter Lösungsansatz
- Zu ändernde Dateien und Methoden
- Test-Methode zur Verifikation

### V - Verifikation:
1. **Unit-Tests:** Erstelle Tests für die Datenkonvertierung
2. **Integration-Tests:** Teste den gesamten Speicherprozess
3. **UI-Tests:** Verifiziere, dass gespeicherte Daten korrekt angezeigt werden
4. **Datenbank-Tests:** Prüfe, dass alle Felder korrekt in der DB landen

### L - Lernen (Bug-Archiv):
Dokumentiere die Lösung in `.vscode/docs/BUG_ARCHIVE.md` mit:
- Genaue Fehlerbeschreibung
- Ursachenanalyse
- Implementierte Lösung
- Lessons Learned für zukünftige Character-Editor Arbeiten

## KRITISCHES ESKALATIONS-PROTOKOLL:

Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache des Problems außerhalb deines Fachgebiets liegt (z.B. du bist Character Editor Specialist, aber das Problem ist ein Database-Service Problem):

1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

## Wichtige Hinweise:
- **Konsistenz:** Stelle sicher, dass PlayerCharacter und Creature Konsistent behandelt werden
- **Fehlerbehandlung:** Implementiere robuste Fehlerbehandlung für Speicheroperationen
- **Testing:** Teste sowohl Happy Path als auch Error Cases
- **Performance:** Achte auf Performance bei großen Datenmengen (Attack-Listen, Inventory)

## Erfolgskriterien:
- Der enhanced_character_editor_controller speichert vollständig funktionierende Player-Objekte
- Alle Character-Daten werden persistiert und korrekt angezeigt
- Der Character-Editor ist wieder voll funktionsfähig
- Die Lösung ist robust und zukunftssicher

---

**Zeitrahmen:** Da dies ein kritischer Bug ist, priorisiere diese Aufgabe und melde bei Blockaden sofort zurück.
