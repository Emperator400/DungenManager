# DungenManager Codebase Architektur-Bericht

Erstellt am: 4. November 2025  
Analyst: Codebase-Architekt-Analyst (Lesezugriff-only)

---

## 1. Domänen-Analyse (Haupt-Verzeichnisstruktur)

### Haupt-Verzeichnisse und deren Zweck

| Verzeichnis | Zweck | Beschreibung |
|-------------|-------|-------------|
| **`lib/`** | **Core Application** | Hauptanwendungscode mit vollständiger D&D Dungeon Manager Funktionalität |
| **`lib/models/`** | **Datenmodelle** | Immutable Datenklassen mit fromMap/toMap Patterns für SQLite-Datenbank |
| **`lib/screens/`** | **UI-Screens** | StatefulWidget-basierte Benutzeroberflächen für verschiedene Features |
| **`lib/widgets/`** | **Wiederverwendbare UI** | StatelessWidget Komponenten mit DnD-Theme-Konsistenz |
| **`lib/services/`** | **Business-Logik** | Singleton-Services ohne UI-Imports für Datenverarbeitung |
| **`lib/database/`** | **Datenbankschicht** | SQLite-Operationen über DatabaseHelper |
| **`lib/utils/`** | **Hilfsfunktionen** | Utility-Functions und Parser für verschiedene Aufgaben |
| **`lib/theme/`** | **Design-System** | D&D-spezifisches Theme mit Fantasy-Farben und Stilen |
| **`lib/constants/`** | **Konstanten** | Anwendungskonstanten für Attacks und andere Werte |
| **`lib/game_data/`** | **Spieldaten** | D&D 5e Datenimport und Demo-Daten |
| **`test/`** | **Unit-Tests** | Flutter-Tests für Modelle, Services und UI-Komponenten |
| **`integration_test/`** | **Integrationstests** | End-to-End Tests für komplexe Szenarien |
| **`examples/`** | **Beispiele** | MCP-Server Demo-Skripte und Nutzungshandbücher |
| **`bin/`** | **Executable Scripts** | MCP-Server Implementierung |
| **`.github/workflows/`** | **CI/CD** | Automatisierung für GitHub Actions |

### Spezifische Feature-Verzeichnisse

| Verzeichnis | Feature | Zweck |
|-------------|---------|-------|
| **`lib/widgets/character_editor/`** | Charakter-Editor | Komplexe Inventar-Management UI mit Hotbar-System |
| **`lib/widgets/quest_library/`** | Quest-Bibliothek | Quest-Management und Filter-Systeme |
| **`lib/widgets/character_list/`** | Charakter-Liste | Helden-Anzeige mit Avatar-System |
| **`lib/widgets/lore_keeper/`** | Wiki-System | Wissensdatenbank mit Cross-Referenzen |
| **`lib/widgets/sound/`** | Audio-System | Sound-Mixer und Scene-Flow für Atmosphäre |

---

## 2. Technologie-Stack & Architektur-Muster

### Kern-Abhängigkeiten (aus pubspec.yaml)

#### **Datenbank & Speicher**
- **`sqflite` + `sqflite_common_ffi`** - SQLite Datenbank für Desktop/Mobile
- **`path`** - Dateisystem-Pfade
- **`path_provider`** - Sichere Speicherorte

#### **UI & Framework**
- **`flutter`** - Basis Framework
- **`flutter_markdown`** - Markdown-Rendering für Wiki-Einträge
- **`font_awesome_flutter`** - Icon-Bibliothek
- **`flutter_svg`** - SVG-Unterstützung
- **`ultimate_flutter_icons`** - Zusätzliche Icons

#### **Audio & Medien**
- **`audioplayers`** - Audio-Wiedergabe für Sound-System
- **`file_picker`** - Dateiauswahl für MP3-Dateien

#### **Netzwerk & Daten**
- **`http: ^1.1.0`** - HTTP-Client für 5e.tools Datenimport
- **`uuid`** - UUID-Generierung für Datenbank-IDs

#### **Entwicklung & MCP**
- **`json_rpc_2: ^3.0.2`** - MCP-Server Implementierung

### Architektur-Muster im Code

#### **1. Service Layer Pattern**
```dart
// Strikte Trennung: UI → Service → Database
// Beispiel: CampaignService
class CampaignService {
  final DatabaseHelper _databaseHelper;
  
  // Nur Business-Logik, keine UI-Imports
  // Comprehensive CRUD-Operations
  // Validation im Service Layer
}
```

#### **2. Repository Pattern (DatabaseHelper)**
```dart
// Zentraler Datenbankzugriff
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  // Alle Datenbankoperationen zentralisiert
}
```

#### **3. Immutable Model Pattern**
```dart
// Alle Models mit final fields
class Campaign {
  final String id;
  final String title;
  // fromMap/toMap für Datenbank
  // copyWith für immutable Updates
}
```

#### **4. Widget Composition Pattern**
```dart
// Wiederverwendbare StatelessWidget
// DnDTheme-Konsistenz
// Konfigurierbare Parameters
```

### State-Management-Ansatz

**Kein explizites State-Management Framework** (kein Riverpod, Bloc, Provider):
- **setState()** für einfache UI-States
- **Service Layer** für Business-Logik
- **Models mit copyWith()** für State-Updates

---

## 3. Konventions- & Standard-Dateien

### Formelle Regel-Dateien

| Datei | Pfad | Zweck |
|-------|------|-------|
| **`CODE_STANDARDS.md`** | Root | **UMFASSENDE CODIERUNGSKONVENTIONEN** - Bindend für alle Entwickler |
| **`analysis_options.yaml`** | Root | **STRICT LINTING RULES** - 200+ aktivierte Regeln |
| **`REFACTORING_PLAN.md`** | Root | **PHASENWEISES REFACTORING** - Detaillierter Plan für Code-Qualität |
| **`README_MCP_SERVER.md`** | Root | **MCP-SERVER DOKUMENTATION** - Integration und Nutzung |
| **`MCP_SERVER_NUTZUNGSHANDBUCH.md`** | Root | **MCP-Server Handbuch** (Deutsch) |
| **`.github/workflows/ci_cd_pipeline.yml`** | GitHub | **AUTOMATISIERUNG** - CI/CD Pipeline |

### Spezifische README-Dateien

| Datei | Pfad | Zweck |
|-------|------|-------|
| **`README.md`** | Root | **Projekt-Übersicht** |
| **`README_SETTINGS_MCP.md`** | Root | **Settings MCP Integration** |
| **`lib/widgets/character_editor/README_INVENTORY_REDESIGN.md`** | Widgets | **Inventar-Redesign Dokumentation** |
| **`lib/widgets/character_list/README_HERO_REDESIGN.md`** | Widgets | **Hero-Redesign Dokumentation** |
| **`lib/quest_library/README_QUEST_INTEGRATION.md`** | Feature | **Quest-Integration Anleitung** |
| **`lib/quest_library/TODO_QUEST_REWARD_INTEGRATION.md`** | Feature | **Quest-Reward Integration TODO** |
| **`lib/lore_keeper/README_PHASE3_UPGRADE.md`** | Feature | **Wiki-System Upgrade Plan** |

### Konfigurationsdateien

| Datei | Pfad | Zweck |
|-------|------|-------|
| **`.vscode/settings.json`** | IDE | **VSCode Projekt-Einstellungen** |
| **`app_settings.json`** | Root | **Anwendungs-Konfiguration** |
| **`.gitignore`** | Root | **Git Ignore Regeln** |
| **`LICENSE`** | Root | **Lizenzinformationen** |

---

## 4. Kritische Architektur-Informationen

### Domain-spezifische Keywords für Rollen-Manifest

#### **Character Editor Domain**
- Keywords: `character`, `editor`, `inventory`, `hotbar`, `attack`, `ability`, `attribute`
- Dateien: `lib/widgets/character_editor/`, `lib/models/creature.dart`, `lib/models/player_character.dart`
- Services: `character_editor_service.dart`, `inventory_service.dart`

#### **Quest Library Domain**
- Keywords: `quest`, `library`, `reward`, `filter`, `search`
- Dateien: `lib/widgets/quest_library/`, `lib/models/quest.dart`
- Services: `quest_library_service.dart`, `quest_reward_service.dart`

#### **Campaign Management Domain**
- Keywords: `campaign`, `dashboard`, `session`, `dungeon master`
- Dateien: `lib/screens/campaign_*.dart`, `lib/models/campaign.dart`
- Services: `campaign_service.dart`

#### **Wiki/Lore Keeper Domain**
- Keywords: `wiki`, `lore`, `knowledge`, `search`, `cross-reference`
- Dateien: `lib/widgets/lore_keeper/`, `lib/models/wiki_entry.dart`
- Services: `wiki_*_service.dart`

#### **Sound System Domain**
- Keywords: `sound`, `audio`, `scene`, `mixer`, `atmosphere`
- Dateien: `lib/widgets/sound/`, `lib/models/sound.dart`
- Services: `sound_mixer_viewmodel.dart`

#### **Bestiary/Monsters Domain**
- Keywords: `monster`, `creature`, `bestiary`, `official`, `5e`
- Dateien: `lib/screens/bestiary_screen.dart`, `lib/models/official_monster.dart`
- Services: `monster_parser_service.dart`

### Technologische Patterns für Rollen-Anweisungen

#### **Datenbank-Pattern**
- **SQLite mit sqflite** - Alle Models müssen fromMap/toMap implementieren
- **DatabaseHelper Singleton** - Zentraler Datenbankzugriff
- **UUID für IDs** - Konsistente ID-Generierung

#### **UI-Pattern**
- **DnDTheme exclusiv** - Keine hardcodierten Farben erlaubt
- **StatelessWidget für Widgets** - Wiederverwendbarkeit
- **StatefulWidget für Screens** - State-Management mit setState()
- ** mounted checks vor setState** - Memory Leak Prevention

#### **Service-Pattern**
- **KEINE UI-IMPORTS** in Services (strikte Regel)
- **Dependency Injection** im Constructor
- **Future-based Methods** für async Operationen
- **Detaillierte Error Handling** mit try-catch

#### **Testing-Pattern**
- **flutter_test** für Unit-Tests
- **integration_test** für E2E-Tests
- **Test Coverage ≥80%** als Ziel

---

## 5. Qualitätssicherung & Standards

### Linting-Regeln (aus analysis_options.yaml)

#### **Critical Rules (Errors)**
- `invalid_assignment: error`
- `missing_return: error`
- `dead_code: error`
- `unused_import: error`
- `unused_local_variable: error`

#### **Naming Conventions**
- `file_names: true` - snake_case für Dateien
- `camel_case_types: true` - PascalCase für Klassen
- `prefer_single_quotes: true` - Single Quotes für Strings

#### **Code Quality**
- `avoid_dynamic_calls: true`
- `avoid_unnecessary_containers: true`
- `prefer_final_fields: true`
- `use_key_in_widget_constructors: true`

### Performance-Standards

#### **UI Performance**
- **ListView.builder** für große Listen
- **Image loadingBuilder** für Netzwerk-Images
- **const constructors** wo möglich

#### **Memory Management**
- **mounted checks** vor setState
- **Controller disposal** in dispose()
- **Stream/Subscription cancellation**

---

## 6. MCP-Server Integration

### Server-Komponenten
- **`bin/mcp_server.dart`** - Haupt-Server
- **`json_rpc_2`** - RPC-Kommunikation
- **`test_mcp_server.dart`** - Server-Testing
- **`examples/`** - Nutzungsbeispiele

### Integration-Pattern
- **External Tool Support** für VSCode
- **JSON-RPC Protokoll** für KI-Assistenz
- **Service Locator Pattern** für MCP-Integration

---

## 7. Empfehlungen für Rollen-Architektur

### Benötigte Rollen basierend auf Domänen

1. **`character_editor_specialist.md`** - Charakter-Editor & Inventar
2. **`quest_library_specialist.md`** - Quest-Management
3. **`campaign_manager_specialist.md`** - Kampagnen-Management
4. **`wiki_lore_keeper_specialist.md`** - Wissensdatenbank
5. **`sound_audio_specialist.md`** - Audio-System
6. **`bestiary_monster_specialist.md`** - Monster-Bestiary
7. **`database_architect_specialist.md`** - Datenbank & Models
8. **`ui_theme_specialist.md`** - DnDTheme & UI-Consistency
9. **`testing_quality_specialist.md`** - Tests & Code-Qualität
10. **`mcp_integration_specialist.md`** - MCP-Server & External Tools

### Kritische Kontext-Dateien für alle Rollen
- **`CODE_STANDARDS.md`** (MUST READ vor jeder Arbeit)
- **`analysis_options.yaml`** (Linting-Regeln beachten)
- **`REFACTORING_PLAN.md`** (aktueller Refactoring-Status)
- **Domain-spezifische README-Dateien**

---

## Zusammenfassung

Die DungenManager Codebase ist eine **ausgereifte Flutter-Anwendung** mit:

- **Klare Architektur** (Service → Database → UI)
- **Strenge Coding-Standards** (200+ Linting-Regeln)
- **Umfassende Dokumentation** (mehrere README-Dateien)
- **Modulare Feature-Struktur** (Character Editor, Quest Library, etc.)
- **Professionelle Qualitätssicherung** (Tests, CI/CD, MCP-Integration)

Die Codebase ist **hervorragend für rollenbasierte KI-Assistenz geeignet** aufgrund der klaren Domänen-Trennung und umfassenden Dokumentation.

---

*Dieser Bericht dient als Grundlage für die Erstellung spezialisierter KI-Rollen und Manifest-Dateien.*
