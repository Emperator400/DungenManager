# DELEGATION PLAN - TPL Task-Management System

**Generiert:** 2025-11-08  
**Status:** Implementation Phase  
**Ziel:** Vollständige Task-Delegation für 42 Kompilierungsfehler

---

## 🎯 PHASE 1: Sofortige Delegation (Kritische Blocker)

### Task 1.1: DND Data Importer Fehler (Backend-Agent)
**Status:** Bereit zur Delegation  
**Agent:** Backend-Agent  
**Priorität:** Höchste

```markdown
Du bist der `Backend-Agent`.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für Projekt-Wissen.
2. Lies `.vscode/PROJECT_TODO.md` für den aktuellen Projekt-Plan.
3. Lies `lib/game_data/dnd_data_importer.dart` für die fehlerhafte Datei.
4. Lies `lib/database/database_helper.dart` für DatabaseHelper-Methoden.
5. Lies `lib/models/official_monster.dart` für das OfficialMonster-Modell.

**Dein spezifischer Task:**
Behebe die 5 kritischen Fehler im DND Data Importer:

**Fehlerliste:**
1. `lib/game_data/dnd_data_importer.dart(79,45)`: Map<String,dynamic> zu OfficialMonster Konvertierung
2. `lib/game_data/dnd_data_importer.dart(485,43)`: Map<String,dynamic> zu OfficialMonster Konvertierung  
3. `lib/game_data/dnd_data_importer.dart(637,22)`: `getLatestVersion()` Methode fehlt in DatabaseHelper
4. `lib/game_data/dnd_data_importer.dart(646-651,32)`: `clearOfficialData()` erwartet keine Parameter
5. `lib/game_data/dnd_data_importer.dart(748,65)`: `getAllOfficialMonsters(limit:)` Parameter nicht unterstützt

**Anforderungen:**
1. Implementiere fehlende DatabaseHelper-Methoden
2. Korrigiere Typ-Konvertierungen zu OfficialMonster
3. Stelle sicher dass alle Datenbank-Aufrufe korrekte Parameter haben
4. Teste die Funktionalität mit `flutter analyze`

**Dein Protokoll (A-P-B-V-L):**
(Analyse, Plan mit Diffs + Verifikation, Bestätigung, Verifikation, Lernen)

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du während deiner Analyse feststellst, dass du diesen Task nicht lösen kannst ODER dass die Ursache außerhalb deines Fachgebiets liegt:
1. **STOPPE.** Schreibe *keinen* Code.
2. **Melde zurück:** `[ESKALATION]`
3. **Beschreibe:** Formuliere eine neue "Problem-Spezifikation" für das Problem, das du gefunden hast.

**Erfolgskriterien:**
- Alle 5 Fehler behoben
- `flutter analyze` zeigt 0 Errors für dnd_data_importer.dart
- Datenbank-Methoden korrekt implementiert
- OfficialMonster-Konvertierungen funktionieren
```

---

## 📋 VERBLIEBENDE TASKS ZUR DELEGATION

### Phase 1 Weiter Tasks:

#### Task 1.2: Model Tests Fehler (Backend-Agent) - 7 Fehler
- [ ] `test/unit_models_test.dart`: int zu String Konvertierungen (version-Felder)
- [ ] `test/unit_models_test.dart`: String zu int Konvertierungen (id-Felder)
- [ ] `test/widget_comprehensive_test.dart`: version int zu String

#### Task 1.3: Character Editor Core (Frontend-Agent) - 6 Fehler
- [ ] `lib/widgets/character_editor/inventory_demo_widget.dart`: inventory Parameter entfernen
- [ ] `lib/widgets/character_editor/character_editor_controller.dart`: List<Object> zu List<DisplayInventoryItem>
- [ ] `lib/widgets/character_editor/character_editor_controller.dart`: getDisplayInventoryForOwner() Methode implementieren
- [ ] `lib/widgets/character_editor/character_editor_controller.dart`: String? zu String Parameter anpassen
- [ ] `lib/screens/edit_campaign_screen.dart`: createdAt Parameter zu Campaign hinzufügen

### Phase 2: UI-WIDGETS (Frontend-Agent) - 16 Fehler
#### Task 2.1: Campaign Widgets - 3 Fehler
#### Task 2.2: Enhanced Inventory Tab Widget - 11 Fehler  
#### Task 2.3: Quest Library - 2 Fehler

### Phase 3: Code-Qualität (Generalist-Agent) - 5 Fehler
#### Task 3.1: Wiki Components - 3 Fehler
#### Task 3.2: Cleanup - 2 Fehler

---

## 🔄 DELEGATIONS-PROZESS

1. **Task-Vorbereitung:** Prompt generieren und prüfen
2. **Agenten-Auswahl:** Richtigen Spezialisten wählen
3. **Delegation:** Prompt an Agenten übergeben
4. **Feedback-Verarbeitung:** Ergebnisse analysieren und PROJECT_TODO.md aktualisieren
5. **Nächster Task:** Fortfahren mit nächstem Prioritäts-Task

---

## 📊 STATUS-VERFOLGUNG

| Phase | Tasks | Agent | Status | Fehler |
|-------|-------|-------|--------|--------|
| 1.1 | DND Data Importer | Backend | Ready | 5 |
| 1.2 | Model Tests | Backend | Pending | 7 |
| 1.3 | Character Editor | Frontend | Pending | 6 |
| 2.1 | Campaign Widgets | Frontend | Pending | 3 |
| 2.2 | Enhanced Inventory | Frontend | Pending | 11 |
| 2.3 | Quest Library | Frontend | Pending | 2 |
| 3.1 | Wiki Components | Generalist | Pending | 3 |
| 3.2 | Cleanup | Generalist | Pending | 2 |

**Gesamt:** 42 Fehler über 8 Tasks

---

## 🎯 NÄCHSTE SCHRITTE

1. **Sofort:** Task 1.1 an Backend-Agent delegieren
2. **Parallel:** Delegation-Prompts für Tasks 1.2 und 1.3 vorbereiten
3. **Systematisch:** Vollständige Delegation-Kette etablieren

---
**TPL Status:** Ready for Delegation Phase
**Nächste Aktion:** Task 1.1 Delegation an Backend-Agent
