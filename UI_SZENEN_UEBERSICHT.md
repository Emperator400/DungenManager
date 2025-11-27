# DungenManager - UI-Szenen Übersicht

Diese Dokumentation bietet eine umfassende Übersicht aller UI-Szenen des DungenManager-Projekts, um gezielte Anpassungen zu ermöglichen.

## 🏗️ Grundlegende Architektur

### Haupt-Navigation
**Datei:** `lib/screens/enhanced_main_navigation_screen.dart`

Die zentrale Navigation erfolgt über ein 2x5 Grid mit folgenden Hauptbereichen:

1. **Kampagnen** - Campaign Management
2. **Quests** - Adventure Library  
3. **Wiki** - Lore Keeper
4. **Charaktere** - Character Editor
5. **Gruppe** - Party Management
6. **Items** - Equipment Library
7. **Bestiarium** - Monster Collection
8. **Sessions** - Active Games
9. **Sounds** - Audio Library
10. **Offizielle Monster** - 5e Tools Database

---

## 📋 Detaillierte Szenen-Beschreibung

### 🎯 KAMPAGNEN-MANAGEMENT

#### 1. Enhanced Campaign Dashboard Screen
**Datei:** `lib/screens/enhanced_campaign_dashboard_screen.dart`
- **Zweck:** Zentrale Verwaltung aller Kampagnen
- **Hauptfunktionen:**
  - Kampagnenliste mit Filter-Chips
  - Kampagnen-Karten mit Status-Indikatoren
  - Quick-Actions (Start, Edit, Delete)
  - Kampagnen-Statistiken
- **Navigation:** Von Hauptnavigation → Kampagnen

#### 2. Enhanced Edit Campaign Screen  
**Datei:** `lib/screens/enhanced_edit_campaign_screen.dart`
- **Zweck:** Erstellen und Bearbeiten von Kampagnen
- **Hauptfunktionen:**
  - Grundlegende Kampagnen-Informationen
  - D&D 5e spezifische Einstellungen
  - Session-Verwaltung
  - Hero-Management
  - Quest-Integration
  - Wiki-Verknüpfungen
- **Tabs:** Overview, Heroes, Sessions, D&D Data, Quests

#### 3. Campaign Selection Screen
**Datei:** `lib/screens/campaign_selection_screen.dart`
- **Zweck:** Auswahl einer aktiven Kampagne
- **Hauptfunktionen:**
  - Kampagnen-Auswahl für den Start
  - Quick-Access zu letzten Kampagnen

---

### 📜 QUEST-MANAGEMENT

#### 4. Enhanced Quest Library Screen
**Datei:** `lib/screens/enhanced_quest_library_screen.dart`
- **Zweck:** Zentrale Quest-Bibliothek
- **Hauptfunktionen:**
  - Quest-Suche und Filterung
  - Quest-Karten mit Belohnungen
  - Lore-Integration
  - Status-Management
- **Komponenten:** Filter-Chips, Search-Delegate, Enhanced Quest Cards

#### 5. Enhanced Edit Quest Screen
**Datei:** `lib/screens/enhanced_edit_quest_screen.dart`
- **Zweck:** Erstellen und Bearbeiten von Quests
- **Hauptfunktionen:**
  - Quest-Details und Beschreibung
  - Belohnungs-System
  - Lore-Verknüpfungen
  - Status-Tracking

#### 6. Add Quest From Library Screen
**Datei:** `lib/screens/add_quest_from_library_screen.dart`
- **Zweck:** Hinzufügen von Quests aus der Bibliothek zu Kampagnen

#### 7. Link Quest to Scene Screen
**Datei:** `lib/screens/link_quest_to_scene_screen.dart`
- **Zweck:** Verknüpfung von Quests mit Spiel-Szenen

#### 8. Edit Campaign Quest Screen
**Datei:** `lib/screens/edit_campaign_quest_screen.dart`
- **Zweck:** Bearbeiten von kampagnenspezifischen Quests

---

### 📚 WIKI/LORE MANAGEMENT

#### 9. Enhanced Lore Keeper Screen
**Datei:** `lib/screens/enhanced_lore_keeper_screen.dart`
- **Zweck:** Zentrale Wissensdatenbank
- **Hauptfunktionen:**
  - Wiki-Einträge verwalten
  - Cross-Reference System
  - Suche und Filterung
  - Hierarchische Organisation
- **Komponenten:** Enhanced Wiki Entry Cards, Filter-Chips, Search-Delegate

#### 10. Enhanced Edit Wiki Entry Screen
**Datei:** `lib/screens/enhanced_edit_wiki_entry_screen.dart`
- **Zweck:** Erstellen und Bearbeiten von Wiki-Einträgen
- **Hauptfunktionen:**
  - Rich-Text-Editor
  - Link-Management
  - Kategorien und Tags
  - Markdown-Parser Integration

#### 11. Link Wiki Entries Screen
**Datei:** `lib/screens/link_wiki_entries_screen.dart`
- **Zweck:** Verknüpfung von Wiki-Einträgen untereinander

---

### 🧑‍🤝‍🧑 CHARACTER MANAGEMENT

#### 12. Enhanced Unified Character Editor Screen
**Datei:** `lib/screens/enhanced_unified_character_editor_screen.dart`
- **Zweck:** Unified Editor für alle Charaktertypen
- **Hauptfunktionen:**
  - Player Characters, Creatures, NPCs
  - Tab-basierte Oberfläche
  - Inventory-Management
  - Attack-System
  - Abilities und Skills
- **Tabs:** Basic Info, Attributes, Abilities, Attacks, Inventory

#### 13. Enhanced Edit PC Screen
**Datei:** `lib/screens/enhanced_edit_pc_screen.dart`
- **Zweck:** Spezialisierter Editor für Player Characters

#### 14. Enhanced Edit Creature Screen
**Datei:** `lib/screens/enhanced_edit_creature_screen.dart`
- **Zweck:** Spezialisierter Editor für Monster/Creatures

#### 15. Enhanced PC List Screen
**Datei:** `lib/screens/enhanced_pc_list_screen.dart`
- **Zweck:** Verwaltung aller Player Characters

#### 16. Encounter Setup Screen
**Datei:** `lib/screens/encounter_setup_screen.dart`
- **Zweck:** Aufbau von Kampfszenarien

#### 17. Initiative Tracker Screen
**Datei:** `lib/screens/initiative_tracker_screen.dart`
- **Zweck:** Kampf-Initiative-Verwaltung

---

### ⚔️ BESTIARY & MONSTER MANAGEMENT

#### 18. Enhanced Bestiary Screen
**Datei:** `lib/screens/enhanced_bestiary_screen.dart`
- **Zweck:** Eigene Monster-Sammlung
- **Hauptfunktionen:**
  - Monster-Liste mit Filterung
  - Stat-Blocks
  - Import/Export
  - Custom Monsters

#### 19. Enhanced Official Monsters Screen
**Datei:** `lib/screens/enhanced_official_monsters_screen.dart`
- **Zweck:** Zugriff auf offizielle 5e Tools Datenbank
- **Hauptfunktionen:**
  - Integration mit 5e.tools
  - Import offizieller Monster
  - Suchfunktionen

---

### 🎒 ITEM MANAGEMENT

#### 20. Enhanced Item Library Screen
**Datei:** `lib/screens/enhanced_item_library_screen.dart`
- **Zweck:** Zentrale Item-Bibliothek
- **Hauptfunktionen:**
  - Item-Kategorien
  - Magic Items
  - Equipment-Verwaltung
  - Stat-Tracker

#### 21. Enhanced Edit Item Screen
**Datei:** `lib/screens/enhanced_edit_item_screen.dart`
- **Zweck:** Erstellen und Bearbeiten von Items
- **Hauptfunktionen:**
  - Item-Stats und Effekte
  - Equipment-Slots
  - Rarität und Werte

#### 22. Add Item From Library Screen
**Datei:** `lib/screens/add_item_from_library_screen.dart`
- **Zweck:** Items zur Charakter-Ausrüstung hinzufügen

---

### 🎵 AUDIO MANAGEMENT

#### 23. Enhanced Sound Library Screen
**Datei:** `lib/screens/enhanced_sound_library_screen.dart`
- **Zweck:** Audio-Bibliothek für Atmosphäre
- **Hauptfunktionen:**
  - Sound-Kategorien
  - Mixer-Funktionen
  - Scene-Verknüpfungen
  - Playlist-Management

#### 24. Enhanced Edit Sound Screen
**Datei:** `lib/screens/enhanced_edit_sound_screen.dart`
- **Zweck:** Bearbeiten von Sound-Einträgen

#### 25. Add Sound to Scene Screen
**Datei:** `lib/screens/add_sound_to_scene_screen.dart`
- **Zweck:** Sounds zu Szenen hinzufügen

---

### 🎮 SESSION MANAGEMENT

#### 26. Enhanced Active Session Screen
**Datei:** `lib/screens/enhanced_active_session_screen.dart`
- **Zweck:** Aktive Spiel-Sitzungen leiten
- **Hauptfunktionen:**
  - Scene-Flow
  - Character-Tracker
  - Initiative-System
  - Notes und Logs

#### 27. Enhanced Edit Session Screen
**Datei:** `lib/screens/enhanced_edit_session_screen.dart`
- **Zweck:** Session-Planung und Vorbereitung

#### 28. Enhanced Session List for Campaign Screen
**Datei:** `lib/screens/enhanced_session_list_for_campaign_screen.dart`
- **Zweck:** Sessions pro Kampagne verwalten

#### 29. Enhanced Edit Scene Screen
**Datei:** `lib/screens/enhanced_edit_scene_screen.dart`
- **Zweck:** Szenen erstellen und bearbeiten

---

## 🎨 DESIGN-SYSTEM

### Theme-Integration
Alle Szenen verwenden das `DnDTheme` mit:
- **Farben:** Dungeon Black, Mystical Purple, Ancient Gold, Emerald Green, Deep Red, Arcane Blue
- **Komponenten:** Enhanced Cards, Filter-Chips, Navigation Items
- **Dekoration:** Dungeon Wall Patterns, Gradient Effects

### Gemeinsame Komponenten
- **Enhanced Cards:** Standardisierte Karten mit Hover-Effekten
- **Filter-Chips:** Spotify-Style Filterung
- **Search-Delegate:** Konsistente Suchfunktion
- **Hotbar:** Quick-Access Toolbar

---

## 🔄 NAVIGATIONS-FLUSS

### Haupt-Flow
```
Main Navigation → [Bereich] → Liste → Detail → Edit
```

### Beispiel-Flows
1. **Kampagne erstellen:** Main → Kampagnen → Dashboard → Edit Campaign
2. **Quest hinzufügen:** Main → Quests → Library → Select → Link to Campaign
3. **Charakter erstellen:** Main → Charaktere → Editor → Save → Add to Campaign

### Platzhalter-Screens
Einige Bereiche verwenden `_PlaceholderScreen`:
- Charaktere (in Entwicklung)
- Gruppe (in Entwicklung)  
- Sessions (in Entwicklung)

---

## 📊 DATEN-MODELLE

### Zentrale Models
- `Campaign` - Kampagnen-Daten
- `Quest` - Quest-Informationen
- `WikiEntry` - Lore-Einträge
- `PlayerCharacter` - Spieler-Charaktere
- `Creature` - Monster/NPCs
- `Item` - Gegenstände
- `Sound` - Audio-Dateien
- `Session` - Spiel-Sitzungen

---

## 🛠️ TECHNISCHE ARCHITEKTUR

### Provider-Pattern
Jede Scene hat ein entsprechendes ViewModel:
- `CampaignViewModel`
- `QuestLibraryViewModel`
- `WikiViewModel`
- `CharacterEditorViewModel`
- etc.

### Service-Layer
Alle Szenen nutzen standardisierte Services:
- `CampaignService`
- `QuestService`
- `WikiService`
- etc.

---

## 📝 ANPASSUNGSHINWEISE

### Farben anpassen
In `lib/theme/dnd_theme.dart` die Farbwerte ändern.

### Navigation erweitern
In `enhanced_main_navigation_screen.dart` neue `NavigationItem` Einträge hinzufügen.

### Neue Screens erstellen
1. Screen im `lib/screens/` Ordner erstellen
2. ViewModel in `lib/viewmodels/` erstellen
3. Zur Navigation hinzufügen
4. Provider registrieren

### Komponenten wiederverwenden
Die Enhanced Components in `lib/widgets/` können für neue Screens wiederverwendet werden.

---

*Letzte Aktualisierung: November 2025*
