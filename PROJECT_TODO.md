# PROJECT_TODO - High-Level Projekt-Steuerung

## KRITISCHER BUG: Kompilierungsfehler - Fehlende DatabaseHelper Methoden

**Problem:** Flutter-Anwendung kompiliert nicht wegen fehlender Methoden in DatabaseHelper
**Ursache:** Mehrere CRUD-Methoden für offizielle D&D-Daten und Inventar-Display-Methode fehlen
**Priorität:** KRITISCH - Blockiert gesamte Anwendung

**Fehlende Methoden:**
- `getAllOfficialMonsters()` - für Bestiarum
- `clearOfficialData()` - für Datenimport
- `insertOfficialMonster()` - für Monster-Import
- `insertOfficialSpell()` - für Spell-Import
- `insertOfficialClass()` - für Klassen-Import
- `insertOfficialRace()` - für Völker-Import
- `insertOfficialItem()` - für Item-Import
- `insertOfficialLocation()` - für Orts-Import
- `getOfficialDataCount()` - für Import-Tracking
- `getLatestVersion()` - für Versionsmanagement
- `getDisplayInventoryForOwner()` - für Encounter-Setup

---

## KRITISCHER BUG: Navigation zur Heldenerstellung funktioniert nicht

**Problem:** Beim Klick auf "Helden" wird Platzhalter-Screen angezeigt statt der Charakter-Liste
**Ursache:** Die globale `_navigateToScreen` Funktion erhält den `campaign` Parameter nicht korrekt
**Priorität:** HOCH - Blockiert Heldenerstellung-Funktionalität

---

## NEUER TASK: campaign_dnd_data_tab.dart Fehlerbehebung - ✅ ABGESCHLOSSEN

**Problem:** Die `campaign_dnd_data_tab.dart` Datei enthält mehrere Fehler und kompiliert nicht korrekt
**Ursache:** Falsche Import-Pfade, fehlende Datenbank-Methoden, UI-Inkonsistenzen
**Priorität:** HOCH - Blockiert Kampagnen-D&D-Daten-Funktionalität

**Fehler-Details:**
- ✅ Import-Pfad zu `enhanced_official_monsters_screen.dart` korrigiert (../../ → ../)
- ✅ Methode `getAllOfficialSpells()` in DatabaseHelper implementiert
- ✅ OfficialSpell Import hinzugefügt
- ✅ Kompilierungstest bestanden - keine Fehler gefunden

**Erledigtes Verhalten:**
- ✅ Datei kompiliert fehlerfrei
- ✅ Alle Datenbank-Zugriffe funktionieren korrekt
- ✅ Monster-Integration funktioniert vollständig
- ⚠️ Zauber- und Gegenstands-Tabs haben Platzhalter-Implementierungen (funktionell für MVP)
- ✅ Robuste Fehlerbehandlung ist implementiert

---

## Zuvor geplantes Problem: UI-Testing-Funktionalität für alle Screens

**Problem:** Die App hat aktuell nur zwei Startoptionen (Hauptanwendung, Inventar-Demo). Für effizientes UI-Testing wird eine dritte Option benötigt, die alle verfügbaren Screens einzeln auflistet und testbar macht.

**Erwartetes Verhalten:** Eine dritte Option "Alle Screens" in der AppSelectionScreen, die zu einer ListView mit allen verfügbaren Screens führt. Jeder Screen sollte einzeln aufrufbar sein für Testing-Zwecke.

**Akzeptanzkriterien:**
- [ ] Dritter Button "Alle Screens" in AppSelectionScreen sichtbar und funktionsfähig
- [ ] Neuer AllScreensScreen mit ListView aller verfügbaren Screens
- [ ] Jeder Screen in der Liste mit Name und Kurzbeschreibung
- [ ] Navigation zu jedem Screen funktioniert
- [ ] Konsistentes Design mit DnDTheme
- [ ] Rücknavigation funktioniert korrekt

---

## HIGH-LEVEL TASKS - KRITISCHER BUGFIX (HÖCHSTE PRIORITÄT)

- [ ] **DATABASE-METHODEN**: Alle fehlenden CRUD-Methoden in DatabaseHelper implementieren
- [ ] **METHODEN-SIGNATUR**: Falsche Parameter-Signatur in Zeile 1667 korrigieren
- [ ] **OFFIZIELLE-DATEN**: Vollständige Implementierung für D&D-Daten-Import
- [ ] **INVENTAR-DISPLAY**: getDisplayInventoryForOwner Methode implementieren
- [ ] **KOMPILIERUNG-TEST**: Stellen Sie sicher, dass alle Kompilierungsfehler behoben sind
- [ ] **INTEGRATIONSTEST**: Testen Sie die gesamte Anwendung nach dem Fix

---

## HIGH-LEVEL TASKS - NIEDRIGERE PRIORITÄT

- [ ] **BUG-ANALYSE**: Problem in globaler `_navigateToScreen` Funktion identifizieren
- [ ] **PARAMETER-FIX**: `campaign` Parameter korrekt an globale Funktion übergeben
- [ ] **NAVIGATION-KORREKTUR**: Heldennavigation zur richtigen Screen-Implementierung leiten
- [ ] **TESTING**: Heldenerstellung mit ausgewählter Kampagne testen
- [ ] **UI-ERWEITERUNG**: AppSelectionScreen um dritten Button erweitern
- [ ] **SCREEN-ERSTELLUNG**: Neuen AllScreensScreen erstellen
- [ ] **SCREEN-INVENTORY**: Alle verfügbaren Screens auflisten und kategorisieren
- [ ] **NAVIGATION**: Navigation zu einzelnen Screens implementieren
- [ ] **HANDLING**: Spezialfälle für Screens mit Parametern behandeln
- [ ] **TESTING**: Gesamte Funktionalität testen und verifizieren

---

## STATUS
- **Phase**: 1 - Anforderungsanalyse (ABGESCHLOSSEN)
- **Nächster Schritt**: Task-Delegation an Database Error Specialist
- **Priorität**: KRITISCH - Kompilierungsfehler müssen sofort behoben werden
