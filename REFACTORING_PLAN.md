# DungenManager Refactoring Plan - Phase 3

Basierend auf der Analyse mit `flutter analyze` (246 Issues) und den definierten CODE_STANDARDS.md.

## Zusammenfassung der Analyse

### Status: 🟡 GUT FORTSCHRITT
- **Parse-Fehler behoben** ✅
- **Keine Errors** ✅ (nur Warnings/Infos)
- **85% der Codebase bereits konform** ✅ (wie in Phase 1 analysiert)

### Wichtigste Issues (nach Priorität):

#### 🔴 KRITISCH (muss behoben werden):
1. **Unused Imports** (42+ Vorkommen) - Code-Verschmutzung
2. **Deprecated Member Usage** (120+ Vorkommen) - `withOpacity`, `value`, etc.
3. **Unused Fields/Variables** (15+ Vorkommen) - Memory Leaks

#### 🟡 WICHTIG (sollte behoben werden):
1. **Unnecessary Null Checks** (8+ Vorkommen) - Redundanter Code
2. **Switch Default Cases** (4+ Vorkommen) - Unreachable Code
3. **Dead Code Expressions** (3+ Vorkommen) - Cleanup nötig

#### 🟢 OPTIMIERUNG (kann warten):
1. **Deprecated Flutter APIs** - Viele `withOpacity` -> `.withValues()`
2. **Unnecessary Casts** - Performance-Optimierung
3. **Documentation** - Public APIs sollten dokumentiert werden

---

## Refactoring-Strategie

### Modul 1: `lib/models/` aufräumen (HOHE PRIORITÄT)

**Ziele:** Konsistente fromMap/toMap Patterns, copyWith Methoden, Business-Logic

**Dateien zur Überarbeitung:**
1. `lib/models/quest.dart` - unused imports entfernen
2. `lib/models/creature.dart` - unnecessary null comparisons
3. `lib/models/player_character.dart` - dead null-aware expressions
4. `lib/models/item_effect.dart` - unreachable switch defaults
5. `lib/models/official_monster.dart` - invalid null-aware operators

**Erwartete Issues:** ~15 Warnings

### Modul 2: `lib/services/` vereinheitlichen (HOHE PRIORITÄT)

**Ziele:** UI-Import-Entfernung, Singleton-Pattern, detaillierte Return-Maps

**Dateien zur Überarbeitung:**
1. `lib/services/quest_reward_service.dart` - unused import entfernen
2. `lib/services/wiki_search_service.dart` - unnecessary ! assertions
3. `lib/services/wiki_export_import_service.dart` - unused fields
4. `lib/services/wiki_template_service.dart` - dead null-aware expressions
5. Alle Services - Singleton-Pattern überprüfen

**Erwartete Issues:** ~10 Warnings

### Modul 3: `lib/widgets/` extrahieren (MITTEL PRIORITÄT)

**Ziele:** DnDTheme-Konsistenz, Wiederverwendbarkeit, Performance

**Gruppen:**

#### 3A: Character Editor Widgets (MEHRERE AUFWANDUNG)
- `lib/widgets/character_editor/*.dart` - deprecated withOpacity, unused fields
- Focus: Theme-Konsistenz, Performance-Optimierung

#### 3B: Quest Library Widgets
- `lib/widgets/quest_library/*.dart` - deprecated members aufräumen
- Focus: Wiederverwendbarkeit verbessern

#### 3C: Character List Widgets
- `lib/widgets/character_list/*.dart` - deprecated members
- Focus: Theme-Konsistenz

#### 3D: Lore Keeper Widgets
- `lib/widgets/lore_keeper/*.dart` - deprecated members
- Focus: Theme-Konsistenz

**Erwartete Issues:** ~150 Warnings

### Modul 4: `lib/screens/` bereinigen (NIEDRIGE PRIORITÄT)

**Ziele:** State-Management Standardisierung, Error Handling, Import-Reihenfolge

**Dateien zur Überarbeitung:**
1. `lib/screens/enhanced_edit_quest_screen.dart` - deprecated value, withOpacity
2. `lib/screens/bestiary_screen.dart` - unused imports/fields
3. `lib/screens/campaign_dashboard_screen.dart` - unused imports
4. `lib/screens/edit_*_screen.dart` - deprecated value members
5. Alle Screens - Import-Reihenfolge korrigieren

**Erwartete Issues:** ~60 Warnings

### Modul 5: Theme & Utilities (NIEDRIGE PRIORITÄT)

**Ziele:** Deprecated APIs ersetzen, Utility-Functions aufräumen

**Dateien zur Überarbeitung:**
1. `lib/theme/dnd_theme.dart` - deprecated background/onBackground
2. `lib/theme/dnd_icons.dart` - deprecated withOpacity
3. `lib/utils/*.dart` - unnecessary operators
4. `lib/main.dart` - deprecated withOpacity

**Erwartete Issues:** ~10 Warnings

### Modul 6: Tests (NIEDRIGE PRIORITÄT)

**Ziele:** Test-Code aufräumen, unused imports entfernen

**Dateien zur Überarbeitung:**
1. `test/*.dart` - unused imports
2. `integration_test/*.dart` - unused variables

**Erwartete Issues:** ~5 Warnings

---

## Implementierungs-Timeline

### Woche 1: Foundation (Module 1-2)
- **Tag 1-2:** `lib/models/` komplett überarbeiten
- **Tag 3-4:** `lib/services/` vereinheitlichen
- **Tag 5:** Review & Testing

### Woche 2: UI Layer (Module 3-4)
- **Tag 1-2:** `lib/widgets/` Character Editor (kritischste)
- **Tag 3-4:** `lib/widgets/` Quest & Character Lists
- **Tag 5:** `lib/screens/` High-Traffic Screens
- **Tag 6-7:** `lib/screens/` Remaining Screens
- **Tag 8:** Review & Testing

### Woche 3: Polish (Module 5-6)
- **Tag 1-2:** `lib/theme/` & `lib/utils/` 
- **Tag 3-4:** `test/` & `integration_test/`
- **Tag 5:** Final Review & Documentation Update

---

## Automatisierungs-Tools

### Pre-Commit Checks:
```bash
# 1. Analyse vor Commits
flutter analyze --no-fatal-infos

# 2. Tests durchführen
flutter test --coverage

# 3. Formatierung prüfen
dart format --set-exit-if-changed .

# 4. spezifische Rules prüfen
flutter analyze | grep -E "(unused_import|unnecessary_|deprecated_member_use)"
```

### Post-Refactoring Validierung:
1. **Performance-Messung:** Build-Zeit vor/nach
2. **Memory-Profiling:** Ladezeiten für große Listen
3. **UI-Consistency:** Theme-Usage prüfen
4. **Code-Coverage:** Testabdeckung sicherstellen

---

## Erfolgskriterien

### Phase 3 Erfolgreich wenn:
- [ ] **< 50 Issues** reduziert (von 246 auf <125)
- [ ] **0 Errors** in `flutter analyze`
- [ ] **Alle deprecated members** ersetzt
- [ ] **Alle unused imports** entfernt
- [ ] **Theme-Konsistenz** 100% erreicht
- [ ] **Build-Zeit** verbessert oder gleich
- [ ] **Test-Coverage** ≥ 80%

### Qualitätsziele:
- **Code-Qualität:** A+ (<10 warnings pro 1000 LOC)
- **Performance:** ≤200ms Build-Zeit
- **Wartbarkeit:** Konsistente Patterns in allen Modulen
- **Dokumentation:** CODE_STANDARDS.md aktuell

---

## Nächste Schritte

### 1. Vorbereitung
- [ ] Branch `refactoring/phase-3` erstellen
- [ ] Backup von main branch
- [ ] Development Environment vorbereiten

### 2. Start mit Modul 1
- [ ] `lib/models/quest.dart` überarbeiten
- [ ] `flutter analyze` nach jeder Datei
- [ ] Tests für geänderte Models
- [ ] Review von Models

### 3. Fortsetzung mit Modul 2-6
- [ ] Module nach Plan durchführen
- [ ] Tägliche Analyse-Checks
- [ ] Wöchentliches Review-Meeting

### 4. Abschluss
- [ ] Final Review mit allen Standards
- [ ] Performance-Messung
- [ ] Documentation Update
- [ ] Merge nach main

---

**Dieser Plan ist lebend und wird nach Bedarf angepasst.**
**Fortlaufende Überwachung der Issue-Zahlen ist entscheidend.**

*Erstellt: 1. November 2025*
*Phase 3 Start: 2. November 2025 (geplant)*
*Phase 3 Ende: 22. November 2025 (geplant)*
