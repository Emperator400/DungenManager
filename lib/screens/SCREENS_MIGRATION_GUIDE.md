# Screens-Ordner Reorganisation - Migrationsleitfaden

## Überblick

Dieser Leitfaden dokumentiert die durchgeführte Reorganisation des `lib/screens` Ordners und die noch ausstehenden Schritte.

## Was wurde erledigt

### 1. Neue Ordnerstruktur erstellt

Die folgende Ordnerstruktur wurde erstellt:

```
lib/screens/
├── audio/              # Audio-Screens
├── bestiary/          # Bestiarium-Screens
├── campaign/           # Kampagnen-Screens
├── characters/         # Charakter-Screens
├── debug/             # Debug-Screens
├── items/             # Gegenstands-Screens
├── lore/              # Lore/Wiki-Screens
├── navigation/        # Navigations-Screens
├── quests/            # Quest-Screens
└── session/           # Sitzungs-Screens
```

### 2. Dateien in neue Ordner verschoben

Alle 36 Dateien wurden in die entsprechenden Unterordner verschoben und umbenannt:

| Alter Pfad | Neuer Pfad |
|------------|-------------|
| `enhanced_active_session_screen.dart` | `session/active_session_screen.dart` |
| `enhanced_edit_session_screen.dart` | `session/edit_session_screen.dart` |
| `encounter_setup_screen.dart` | `session/encounter_setup_screen.dart` |
| `initiative_tracker_screen.dart` | `session/initiative_tracker_screen.dart` |
| `enhanced_pc_list_screen.dart` | `characters/pc_list_screen.dart` |
| `enhanced_edit_pc_screen.dart` | `characters/edit_pc_screen.dart` |
| `unified_character_editor_screen.dart` | `characters/character_editor_screen.dart` |
| `enhanced_unified_character_editor_screen.dart` | `characters/character_editor_screen_old.dart` |
| `select_character_for_scene_screen.dart` | `characters/select_character_screen.dart` |
| `enhanced_bestiary_screen.dart` | `bestiary/bestiary_screen.dart` |
| `enhanced_edit_creature_screen.dart` | `bestiary/edit_creature_screen.dart` |
| `enhanced_official_monsters_screen.dart` | `bestiary/official_monsters_screen.dart` |
| `enhanced_item_library_screen.dart` | `items/item_library_screen.dart` |
| `enhanced_edit_item_screen.dart` | `items/edit_item_screen.dart` |
| `add_item_from_library_screen.dart` | `items/add_item_screen.dart` |
| `enhanced_quest_library_screen.dart` | `quests/quest_library_screen.dart` |
| `enhanced_edit_quest_screen.dart` | `quests/edit_quest_screen.dart` |
| `edit_campaign_quest_screen.dart` | `quests/edit_campaign_quest_screen.dart` |
| `add_quest_from_library_screen.dart` | `quests/add_quest_screen.dart` |
| `link_quest_to_scene_screen.dart` | `quests/link_quest_screen.dart` |
| `enhanced_lore_keeper_screen.dart` | `lore/lore_keeper_screen.dart` |
| `enhanced_edit_wiki_entry_screen.dart` | `lore/edit_wiki_entry_screen.dart` |
| `link_entry_to_scene_screen.dart` | `lore/link_entry_screen.dart` |
| `link_wiki_entries_screen.dart` | `lore/link_wiki_entries_screen.dart` |
| `enhanced_sound_library_screen.dart` | `audio/sound_library_screen.dart` |
| `enhanced_edit_sound_screen.dart` | `audio/edit_sound_screen.dart` |
| `add_sound_to_scene_screen.dart` | `audio/add_sound_screen.dart` |
| `sound_library_screen.dart` | `audio/sound_library_screen_old.dart` |
| `enhanced_edit_scene_screen.dart` | `scenes/edit_scene_screen.dart` |
| `enhanced_main_navigation_screen.dart` | `navigation/main_navigation_screen.dart` |
| `all_screens_screen.dart` | `navigation/all_screens_screen.dart` |
| `screen_graph_visualization_screen.dart` | `debug/screen_graph_visualization_screen.dart` |
| `enhanced_edit_campaign_screen.dart` | `campaign/edit_campaign_screen.dart` |
| `enhanced_campaign_dashboard_screen.dart` | `campaign/campaign_dashboard_screen.dart` |
| `enhanced_session_list_for_campaign_screen.dart` | `campaign/session_list_for_campaign_screen.dart` |

### 3. Import-Pfade aktualisiert

Folgende Dateien wurden bereits aktualisiert:
- ✅ `lib/main.dart`
- ✅ `lib/screens/campaign/campaign_selection_screen.dart`

## Was noch zu tun ist

### 1. Import-Pfade in allen betroffenen Dateien aktualisieren

Die folgenden Dateien müssen aktualisiert werden (23 Dateien):

**Campaign-bezogene Dateien:**
- `lib/widgets/campaign_heroes_tab.dart`
- `lib/screens/campaign/campaign_dashboard_screen.dart`
- `lib/screens/campaign/session_list_for_campaign_screen.dart`

**Character-bezogene Dateien:**
- `lib/screens/characters/pc_list_screen.dart`
- `lib/screens/characters/edit_pc_screen.dart`
- `lib/screens/characters/character_editor_screen.dart`

**Session-bezogene Dateien:**
- `lib/screens/session/active_session_screen.dart`
- `lib/screens/session/edit_session_screen.dart`
- `lib/screens/session/encounter_setup_screen.dart`
- `lib/screens/session/initiative_tracker_screen.dart`

**Andere Dateien:**
- `lib/screens/navigation/all_screens_screen.dart`
- `lib/screens/navigation/main_navigation_screen.dart`
- `lib/screens/bestiary/bestiary_screen.dart`
- `lib/screens/bestiary/edit_creature_screen.dart`
- `lib/screens/bestiary/official_monsters_screen.dart`
- `lib/screens/items/item_library_screen.dart`
- `lib/screens/items/edit_item_screen.dart`
- `lib/screens/items/add_item_screen.dart`
- `lib/screens/quests/quest_library_screen.dart`
- `lib/screens/quests/edit_quest_screen.dart`
- `lib/screens/quests/edit_campaign_quest_screen.dart`
- `lib/screens/quests/add_quest_screen.dart`
- `lib/screens/quests/link_quest_screen.dart`
- `lib/screens/lore/lore_keeper_screen.dart`
- `lib/screens/lore/edit_wiki_entry_screen.dart`
- `lib/screens/lore/link_entry_screen.dart`
- `lib/screens/lore/link_wiki_entries_screen.dart`
- `lib/screens/audio/sound_library_screen.dart`
- `lib/screens/audio/edit_sound_screen.dart`
- `lib/screens/audio/add_sound_screen.dart`
- `lib/screens/scenes/edit_scene_screen.dart`
- `lib/screens/debug/screen_graph_visualization_screen.dart`

### 2. Klassennamen in verschobenen Dateien aktualisieren

Alle Klassen in den verschobenen Dateien müssen umbenannt werden, um das "enhanced_" Präfix zu entfernen:

Beispiel:
- `EnhancedEditCampaignScreen` → `EditCampaignScreen`
- `EnhancedMainNavigationScreen` → `MainNavigationScreen`
- usw.

### 3. Referenzen auf Klassennamen aktualisieren

Alle Dateien, die diese Klassen verwenden, müssen aktualisiert werden, um die neuen Klassennamen zu verwenden.

### 4. Alte Versionen löschen

Nach erfolgreicher Migration können die folgenden Dateien gelöscht werden:
- `lib/screens/characters/character_editor_screen_old.dart`
- `lib/screens/audio/sound_library_screen_old.dart`

## Automatische Migration

Führen Sie den folgenden PowerShell-Befehl aus, um alle Import-Pfade automatisch zu aktualisieren:

```powershell
cd lib
Get-ChildItem -Recurse -Filter *.dart | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Importe aktualisieren
    $content = $content -replace "import '../screens/enhanced_([a-z_]+)_screen.dart'", "import '../screens/`$1/`$1_screen.dart'"
    $content = $content -replace "import '../screens/([a-z_]+)_screen.dart'", "import '../screens/`$1/`$1_screen.dart'"
    $content = $content -replace "import '../screens/unified_character_editor_screen.dart'", "import '../screens/characters/character_editor_screen.dart'"
    
    # Klassennamen aktualisieren
    $content = $content -replace "class Enhanced([A-Z][a-zA-Z]+Screen", "class `$1Screen"
    $content = $content -replace "_Enhanced([A-Z][a-zA-Z]+ScreenState", "_`1ScreenState"
    $content = $content -replace "Enhanced([A-Z][a-zA-Z]+ScreenWithProvider", "`1ScreenWithProvider"
    
    Set-Content $_.FullName -Value $content -NoNewline
}
```

## Manuelle Schritte

Wenn die automatische Migration fehlschlägt, führen Sie folgende Schritte manuell durch:

### Schritt 1: Klassennamen in Screen-Dateien aktualisieren

Für jede verschobene Datei:
1. Öffnen Sie die Datei
2. Ändern Sie den Klassennamen (entfernen Sie "enhanced_")
3. Ändern Sie den State-Klassennamen (entfernen Sie "enhanced_")

Beispiel für `edit_campaign_screen.dart`:
```dart
// Vorher
class EnhancedEditCampaignScreen extends StatefulWidget {
  State<EnhancedEditCampaignScreen> createState() => _EnhancedEditCampaignScreenState();
}
class _EnhancedEditCampaignScreenState extends State<EnhancedEditCampaignScreen> {

// Nachher
class EditCampaignScreen extends StatefulWidget {
  State<EditCampaignScreen> createState() => _EditCampaignScreenState();
}
class _EditCampaignScreenState extends State<EditCampaignScreen> {
```

### Schritt 2: Importe aktualisieren

Für jede Datei, die Screens importiert:
1. Finden Sie alle Importe von `lib/screens`
2. Aktualisieren Sie die Pfade, um die neuen Unterordner zu verwenden

Beispiel:
```dart
// Vorher
import '../screens/enhanced_edit_campaign_screen.dart';
import '../screens/unified_character_editor_screen.dart';

// Nachher
import '../screens/campaign/edit_campaign_screen.dart';
import '../screens/characters/character_editor_screen.dart';
```

### Schritt 3: Klassenreferenzen aktualisieren

Aktualisieren Sie alle Referenzen auf die umbenannten Klassen:

Beispiel:
```dart
// Vorher
Navigator.push(context, MaterialPageRoute(
  builder: (context) => EnhancedEditCampaignScreen(campaign: campaign)
));

// Nachher
Navigator.push(context, MaterialPageRoute(
  builder: (context) => EditCampaignScreen(campaign: campaign)
));
```

## Testen

Nachdem alle Änderungen abgeschlossen sind:

1. Führen Sie `flutter pub get` aus
2. Führen Sie `flutter analyze` aus, um Syntaxfehler zu finden
3. Führen Sie `flutter test` aus, um Tests zu prüfen
4. Starten Sie die App und testen Sie die Navigation

## Vorteile der neuen Struktur

1. **Bessere Übersicht**: Dateien sind nach Funktion gruppiert
2. **Einfacheres Auffinden**: Screens sind schneller zu finden
3. **Skalierbarkeit**: Neue Screens können leicht in die richtige Kategorie einsortiert werden
4. **Sauberer Code**: Entfernt die冗den "enhanced_" Präfixe

## Rückgängigmachung

Wenn Sie die Migration rückgängig machen müssen:

```powershell
# Alle Dateien zurück in den screens-Ordner verschieben
cd lib/screens
Get-ChildItem -Directory | ForEach-Object {
    Get-ChildItem $_.FullName -Filter *.dart | ForEach-Object {
        Move-Item $_.FullName -Destination ".." -Force
    }
}

# Alte Ordner löschen
Get-ChildItem -Directory | Remove-Item -Recurse -Force
```

## Unterstützung

Bei Problemen oder Fragen wenden Sie sich an das Entwicklungsteam.