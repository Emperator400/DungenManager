# DELEGATION PROMPT - Debugging Helden-Erstellung Navigation

Du bist der **debugging_error_specialist**.

## Kontext-Laden:
1. Lies `docs/BUG_ARCHIVE.md` für Projekt-Wissen und bekannte Fehlermuster
2. Lies `PROJECT_TODO.md` für das aktuelle Problem und die Akzeptanzkriterien
3. Analysiere die folgenden relevanten Dateien:
   - `lib/screens/enhanced_pc_list_screen.dart` (Helden-Liste mit FloatingActionButton)
   - `lib/screens/unified_character_editor_screen.dart` (Ziel-Screen für Navigation)
   - `lib/widgets/character_editor/enhanced_character_editor_controller.dart` (Controller-Logik)

## Dein spezifischer Task:
**DEBUGGING**: FloatingActionButton Navigation prüfen und fixing

### Problem-Analyse:
Der `EnhancedPlayerCharacterListScreen` hat einen FloatingActionButton "Held hinzufügen", der zum `UnifiedCharacterEditorScreen` navigieren soll. Laut Benutzerbeschreibung funktioniert die Navigation nicht richtig - die UI-Elemente für die Helden-Erstellung fehlen oder funktionieren nicht.

### Was zu prüfen ist:
1. **FloatingActionButton Implementation**: Ist der Button korrekt implementiert und sichtbar?
2. **Navigation Logic**: Funktioniert die `Navigator.of(context).push()` zum `UnifiedCharacterEditorScreen`?
3. **Parameterübergabe**: Werden alle erforderlichen Parameter (`characterType`, `campaignId`) korrekt übergeben?
4. **Error Handling**: Werden Navigation-Fehler korrekt abgefangen und angezeigt?
5. **Screen Lifecycle**: Lädt der `UnifiedCharacterEditorScreen` korrekt für neue Helden-Erstellung?

### Erwartetes Ergebnis:
- Der "Held hinzufügen" Button ist sichtbar und funktionsfähig
- Navigation zum Character Editor funktioniert ohne Fehler
- Character Editor lädt korrekt im "neuen Held erstellen" Modus

## Dein Protokoll (A-P-B-V-L):
(Analysiere das Problem, erstelle einen Plan zur Behebung, hole Bestätigung, implementiere die Lösung, verifiziere dass es funktioniert, dokumentiere das gelernte)

## KRITISCHES ESKALATIONS-PROTOKOLL:
Wenn du während deiner Analyse feststellst, dass du dieses Problem nicht lösen kannst ODER dass die Ursache außerhalb deines Fachgebiets liegt (z.B. Provider-Setup, Database-Issues, UI-Komponentenprobleme):

1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast, damit ich (der TPL) es neu zuweisen kann.

---

**AKTUELLE PROBLEM-SPEZIFIKATION ZUM BESTÄTIGEN:**

**Problem:** FloatingActionButton Navigation von `EnhancedPlayerCharacterListScreen` zu `UnifiedCharacterEditorScreen` funktioniert nicht oder ist fehlerhaft.

**Erwartetes Verhalten:** Benutzer klicken auf "Held hinzufügen" Button, es öffnet sich der Character Editor für neue Helden-Erstellung.

**Akzeptanzkriterien:**
- [ ] "Held hinzufügen" FloatingActionButton ist sichtbar und funktionsfähig
- [ ] Navigation zum UnifiedCharacterEditorScreen funktioniert ohne Errors
- [ ] Character Editor lädt korrekt für neue Helden-Erstellung
- [ ] Fehlermeldungen werden korrekt angezeigt bei Problemen
