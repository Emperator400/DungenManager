# Delegation Prompt: Quest Library Screen Error Fix

**An:** Debugging Error Specialist  
**Von:** Technical Project Leader (TPL)  
**Datum:** 2025-11-10  
**Priorität:** 🔴 HOCH

---

Du bist der Debugging Error Specialist.

**Kontext-Laden:**
1. Lies `.vscode/docs/BUG_ARCHIVE.md` für bekannte Fehlermuster in Screens
2. Lies `CODE_STANDARDS.md` für Code-Quality-Standards
3. Lies `lib/widgets/quest_library/enhanced_quest_filter_chips_widget.dart` um die korrekte Widget-Klasse zu identifizieren

**Dein spezifischer Task:**
Behebe die kritischen Kompilierungsfehler im `lib/screens/enhanced_quest_library_screen.dart`:

**Fehler 1 - Undefined Method:**
```
The method 'QuestFilterChipsWidget' isn't defined for the type '_EnhancedQuestLibraryScreenState'.
Try correcting the name to the name of an existing method, or defining a method named 'QuestFilterChipsWidget'.
```

**Fehler 2 - Code-Quality:**
```
Unnecessary use of a block function body.
Try using an expression function body.dartprefer_expression_function_bodies
```

**Analyse-Anforderungen:**
1. Überprüfe, welches Widget tatsächlich verwendet werden soll (wahrscheinlich `EnhancedQuestFilterChipsWidget`)
2. Finde alle Vorkommnisse von `QuestFilterChipsWidget` und korrigiere sie
3. Optimiere不必要的 Block-Funktionen zu Expression Functions
4. Stelle sicher, dass alle Importe korrekt sind

**Dein Protokoll (A-P-B-V-L):**
- **Analyse:** Fehler identifizieren, Ursachen bestimmen, korrekten Widget-Namen finden
- **Plan:** Korrekturen mit präzisen Diffs vorbereiten
- **Bestätigung:** Änderungen klar präsentieren und zur Bestätigung geben
- **Verifikation:** Kompilierung erfolgreich prüfen, `flutter analyze` durchführen
- **Lernen:** Lösung in BUG_ARCHIVE.md dokumentieren

**KRITISCHES ESKALATIONS-PROTOKOLL:**
Wenn du feststellst, dass:
- Das Problem tieferliegt (z.B. komplette Widget-Architektur fehlerhaft)
- Mehrere betroffene Dateien existieren
- Die Ursache outside des Screens liegt (z.B. Import-Probleme)

Dann:
- **STOPPE.** Schreibe keinen Code.
- **Melde zurück:** `[ESKALATION]`
- **Beschreibe:** Das neue Problem mit klarer Problem-Spezifikation für Neuzuweisung.

**Erwartetes Ergebnis:**
- ✅ `EnhancedQuestLibraryScreen` kompiliert fehlerfrei
- ✅ Alle Widget-Referenzen korrekt aufgelöst
- ✅ Code-Quality-Regeln eingehalten
- ✅ Linter läuft ohne Fehler durch
- ✅ Bug-Archiv-Eintrag erstellt
