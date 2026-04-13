# DungenManager — Projektübersicht

> D&D 5e Session-Management App für Windows/iOS/Android  
> Flutter · SQLite · Provider (MVVM)  
> Stand: April 2026 · Version 1.0 (in Entwicklung)

---

## Inhaltsverzeichnis

1. [Architektur](#architektur)
2. [Verzeichnisstruktur](#verzeichnisstruktur)
3. [Feature-Module](#feature-module)
4. [Datenbank](#datenbank)
5. [State Management](#state-management)
6. [Bekannte Probleme](#bekannte-probleme)
7. [Datei-Statistiken](#datei-statistiken)

---

## Architektur

```
UI (Screens + Widgets)
        ↓
ViewModels (ChangeNotifier + Provider)
        ↓
Services (Business Logic)
        ↓
Repositories (Model-Repositories)
        ↓
Database (SQLite via sqflite)
```

**Schichten:**
- **Models** — reine Dart-Klassen, keine Flutter-Abhängigkeiten
- **Repositories** — Datenbankzugriff, zwei Varianten: `*_repository.dart` (Entity-basiert) und `*_model_repository.dart` (Model-basiert, bevorzugt)
- **Services** — Business-Logik, domänenspezifisch, unabhängig von Flutter-UI
- **ViewModels** — `ChangeNotifier`, verbindet Services mit der UI
- **Screens** — Feature-Screens, nutzen ViewModels via `Provider`/`Consumer`
- **Widgets** — Wiederverwendbare UI-Komponenten

---

## Verzeichnisstruktur

```
lib/
├── main.dart                          # App-Einstieg, MultiProvider-Setup
├── constants/                         # Globale Konstanten (D&D Kampfwerte)
├── database/
│   ├── core/                          # DatabaseConnection (Singleton), Basis-Entity
│   ├── entities/                      # 15 SQLite-Entitäten
│   ├── legacy/                        # database_helper_legacy_backup.dart (UNBENUTZT)
│   ├── migrations/                    # database_migration.dart, refactoring_migration_v2.dart
│   └── repositories/                  # 25 Repository-Klassen
├── game_data/                         # D&D-Spielregeln, Demo-Daten, Importer
├── models/                            # 36 Domain-Modelle
├── screens/
│   ├── audio/                         # Soundbibliothek (sound_library_screen_old.dart UNBENUTZT)
│   ├── bestiary/                      # Kreaturenverwaltung
│   ├── campaign/                      # Kampagnenverwaltung
│   ├── characters/                    # Charakterverwaltung (character_editor_screen_old.dart UNBENUTZT)
│   ├── debug/                         # Entwickler-Tools (wigets_test_grund.dart — Tippfehler im Namen)
│   ├── items/                         # Gegenstände/Inventar
│   ├── lore/                          # Wiki/Lore-System
│   ├── navigation/                    # Haupt-Navigation
│   ├── quests/                        # Quest-System
│   ├── scenes/                        # Szenen-Editor
│   └── session/                       # Aktive Session, Encounter-Tracker
├── services/                          # 39 Service-Klassen + exceptions/
├── theme/                             # DnDTheme, DnDIcons
├── utils/                             # 9 Hilfsfunktionen (Formatter, Parser)
├── viewmodels/                        # 23 ViewModel-Klassen
└── widgets/
    ├── active_session/                # Session-Laufzeit-UI
    ├── audio/                         # Sound-Mixer-Widgets
    ├── bestiary/                      # Bestiary-Cards, Filter, FAB
    │   └── edit_creature/             # 11 Widgets für Kreaturen-Editor
    ├── campaign/                      # Kampagnen-Tabs und Cards
    ├── character_editor/              # 23 Widgets (größtes Widget-Modul)
    ├── character_list/                # Heldenübersicht
    ├── lore_keeper/                   # Wiki-Widgets
    ├── quest_library/                 # Quest-Filter, Cards, Suche
    ├── scene/                         # Szenen-Flow-Widget
    ├── sound/                         # Sound-Mixer
    └── ui_components/                 # 38 wiederverwendbare Komponenten
        ├── base/                      # UnifiedCardBase + Header/Content/Actions
        ├── cards/                     # 9 unified Cards (Campaign, Creature, Hero, ...)
        ├── chips/                     # UnifiedInfoChip
        ├── feedback/                  # ConfirmationDialog, SnackbarHelper
        ├── filter/                    # UnifiedFilterChip, FilterSectionBase
        ├── forms/                     # FormFieldWidget
        ├── inventory/                 # 6 Inventar-Widgets
        ├── lists/                     # PaginatedListView, ItemCountHeader
        ├── search/                    # UnifiedSearchBar
        ├── states/                    # EmptyState, ErrorState, LoadingState
        └── stats/                     # AbilityScore, AttributesGrid, CombatStats
```

---

## Feature-Module

### Kampagne
- Übersicht aller Kampagnen (`CampaignSelectionScreen`)
- Tabs: Übersicht, Helden, Quests, Sessions, Wiki-Daten
- Quest-Bibliothek mit Kampagnen-Modus (Quest direkt zur Kampagne hinzufügen)

### Bestiary (Kreaturenverwaltung)
- Monster + NPCs in einer Liste (`BestiaryScreen`)
- Editor mit 11 Sektionen: BasicInfo, Typ, CombatStats, Abilities, Inventar, Währung, ...
- Offizieller Monster-Importer (D&D 5e SRD-Daten)
- Kategorisierung: `CreatureCategory` Enum (14 Typen: Humanoid=NPC, Rest=Monster)

### Quest-System
- Quest-Bibliothek (`QuestLibraryScreen`) — normaler Modus + Kampagnen-Modus
- Quest-Editor (`EditQuestScreen`) mit Belohnungen und Lore-Integration
- Kampagnen-Quest-Status (`EditCampaignQuestScreen`)
- Status: `active`, `onHold`, `completed`, `failed`, `abandoned`

### Aktive Session
- 4-Quadranten-Layout: Szenenfluss, Atmosphäre, Quests, Live-Notizen
- Encounter-Tracker mit Initiative und HP-Verwaltung
- Zeit-Tracker, Sound-Atmosphäre

### Charaktere (PCs)
- Vollständiger D&D 5e Charakterbogen
- Inventar mit Ausrüstungsslots
- Angriffe, Fähigkeiten, Zauberslots

### Sound-System
- Multi-Stream-Audio (`MultiStreamSoundService`)
- Szenen-basierte Soundsets
- Sound-Mixer mit Lautstärkeregelung

### Wiki / Lore-Keeper
- Hierarchisches Wiki-System
- Cross-Referenzen zwischen Einträgen
- Auto-Link-Service

---

## Datenbank

**Technologie:** SQLite via `sqflite` (Singleton: `DatabaseConnection`)

**Tabellen:**
| Tabelle | Beschreibung |
|---------|-------------|
| `campaigns` | Kampagnen |
| `creatures` | Monster + NPCs |
| `player_characters` | Spielercharaktere |
| `quests` | Quest-Bibliothek |
| `sessions` | Sessions pro Kampagne |
| `scenes` | Szenen-Templates |
| `sounds` | Sound-Dateien |
| `items` | Gegenstände-Bibliothek |
| `inventory_items` | Inventar-Einträge (Relation) |
| `encounters` | Encounter-Definitionen |
| `encounter_participants` | Teilnehmer eines Encounters |
| `wiki_entries` | Wiki-Artikel |
| `wiki_links` | Wiki-Querverweise |
| `session_character_tracking` | HP/Status einer Session |
| `session_quest_progress` | Quest-Fortschritt einer Session |

**Migrationen:** `database_migration.dart` + `refactoring_migration_v2.dart`

---

## State Management

**Pattern:** MVVM mit `Provider` + `ChangeNotifier`

**Wichtige ViewModels:**
| ViewModel | Zuständig für |
|-----------|---------------|
| `ActiveSessionViewModel` | Laufende Session (HP, Initiative, Quests, Zeit) |
| `BestiaryViewModel` | Kreaturenliste, Filter, Suche |
| `CampaignViewModel` | Kampagnen-Übersicht |
| `EditCreatureViewModel` | Kreaturen-Editor |
| `QuestLibraryViewModel` | Quest-Bibliothek + Kampagnen-Modus |
| `EncounterTrackerViewModel` | Kampf-Tracker |
| `SoundMixerViewModel` | Audio-Steuerung |

**Service Locators:** `ServiceLocator`, `CampaignServiceLocator`, `QuestServiceLocator`, `WikiServiceLocator`

---

## Bekannte Probleme

### Offene Bugs
| # | Datei | Problem | Status |
|---|-------|---------|--------|
| — | — | — | — |

> Keine bekannten offenen Bugs. ✅

### Tote Dateien
> Alle bereinigt. ✅

### Code-Qualität
| Problem | Umfang | Status |
|---------|--------|--------|
| `.withOpacity()` statt `.withValues(alpha:)` | 401 Stellen, 63 Dateien | ✅ Behoben (12.04.2026) |
| `print()` statt `debugPrint()` | 696 Stellen, 51 Dateien | ✅ Behoben (12.04.2026) |
| Dateiname-Tippfehler: `wigets_test_grund.dart` | 1 Datei (`lib/screens/debug/`) | ❌ Offen |

---

## Datei-Statistiken

| Bereich | Anzahl Dateien |
|---------|---------------|
| Models | 36 |
| Database (Entities + Repos) | 44 |
| Services | 40 |
| ViewModels | 23 |
| Screens | 38 |
| Widgets | 119 |
| Utils + Theme + Constants | 12 |
| Game Data | 5 |
| **Gesamt** | **323** |
