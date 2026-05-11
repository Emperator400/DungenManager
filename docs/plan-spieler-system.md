# Plan: Globales Spieler-System

## Context
Aktuell hat `PlayerCharacter` nur ein freies Textfeld `playerName` — es gibt keine eigenständige „Spieler"-Entität. Der DM kann keine Spieler (echte Personen wie „Clemens") verwalten, denen Charaktere zugeordnet sind. Dieses Feature fügt ein globales `Player`-Modell hinzu, das kampagnenübergreifend existiert und Charaktere per FK referenziert.

---

## Neue Dateien (in dieser Reihenfolge erstellen)

| Datei | Inhalt |
|-------|--------|
| `lib/models/player.dart` | Player-Modell |
| `lib/database/repositories/player_model_repository.dart` | Repository |
| `lib/services/player_service.dart` | Service + `PlayerWithCharacters` |
| `lib/viewmodels/player_viewmodel.dart` | ViewModel |
| `lib/screens/players/player_list_screen.dart` | Spieler-Übersicht |
| `lib/screens/players/edit_player_screen.dart` | Anlegen / Bearbeiten |
| `lib/screens/players/player_detail_screen.dart` | Detail + Charakterliste |

## Zu ändernde Dateien

| Datei | Änderung |
|-------|----------|
| `lib/models/player_character.dart` | Feld `playerId` (nullable) hinzufügen |
| `lib/database/migrations/database_migration.dart` | `players`-Tabelle + `player_id`-Spalte |
| `lib/viewmodels/edit_pc_viewmodel.dart` | `_playerId`-State + `updatePlayerId()` |
| `lib/screens/characters/edit_pc_screen.dart` | Player-Picker im Stammdaten-Tab |
| `lib/main.dart` | `PlayerModelRepository` + `PlayerViewModel` registrieren |
| `lib/screens/navigation/home_screen.dart` | „Spieler"-Eintrag in `_bereiche` |

---

## Schritt 1 — `lib/models/player.dart`

```dart
class Player {
  final String id;
  final String name;
  final String color;       // Hex, z.B. '#7C3AED'
  final String? avatarPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String get tableName => 'players';

  factory Player.create({required String name, String color = '#6B6B66',
      String? avatarPath, String? notes})
  Map<String, dynamic> toDatabaseMap()
  factory Player.fromDatabaseMap(Map<String, dynamic> map)  // ModelParsingHelper
  Player copyWith({...})
}
```

---

## Schritt 2 — Migration (`database_migration.dart`)

Zwei neue private Methoden, am Ende von `runMigrations()` aufgerufen (nach `_addVerlaufsKarteImagePathColumn`):

**`_createPlayersTable(db)`** — idempotent via `sqlite_master`-Check:
```sql
CREATE TABLE players (
  id TEXT PRIMARY KEY, name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#6B6B66',
  avatar_path TEXT, notes TEXT,
  created_at TEXT NOT NULL, updated_at TEXT NOT NULL
);
CREATE INDEX idx_players_name ON players(name);
```

**`_addPlayerIdToPlayerCharacters(db)`** — idempotent via `PRAGMA table_info`:
```sql
ALTER TABLE player_characters ADD COLUMN player_id TEXT;
CREATE INDEX idx_player_characters_player_id ON player_characters(player_id);
```

---

## Schritt 3 — `PlayerCharacter`-Modell erweitern

- Neues Feld: `final String? playerId;`
- `toDatabaseMap()`: `'player_id': playerId`
- `fromDatabaseMap()`: `playerId: ModelParsingHelper.safeStringOrNull(map, 'player_id', null)`
- `copyWith()`: `String? playerId` Parameter
- `playerName` bleibt unverändert (Rückwärtskompatibilität)

---

## Schritt 4 — Repository

`PlayerModelRepository extends ModelRepository<Player>` — überschreibt `tableName`, `toDatabaseMap`, `fromDatabaseMap`. Zusätzliche Methoden:
- `findByName(String query)` — LIKE-Suche
- `findByExactName(String name)`

---

## Schritt 5 — Service (`player_service.dart`)

Muster: `CampaignService` / `performServiceOperation` + `ServiceResult<T>`.

```dart
class PlayerWithCharacters {
  final Player player;
  final List<PlayerCharacter> characters;
}
```

Methoden:
- `getAllPlayers()`, `getPlayerById(id)`, `createPlayer()`, `updatePlayer()`, `deletePlayer(id)`
- `assignCharacterToPlayer(characterId, playerId)` → setzt auch `playerName = player.name`
- `unassignCharacterFromPlayer(characterId)`
- `getCharactersForPlayer(playerId)`
- `getPlayersWithCharacters()`

`deletePlayer` → erst alle Charaktere mit `playerId = null` updaten, dann löschen.

---

## Schritt 6 — ViewModel (`player_viewmodel.dart`)

`ChangeNotifier` mit State: `_players`, `_playersWithCharacters`, `_isLoading`, `_error`.  
Methoden analog zum Service. `clearError()` vorhanden.

---

## Schritt 7 — `main.dart`

```dart
Provider<PlayerModelRepository>(create: (_) => PlayerModelRepository(dbConnection)),
ChangeNotifierProvider(create: (_) => PlayerViewModel(
  playerService: PlayerService(
    playerRepository: PlayerModelRepository(dbConnection),
    characterRepository: PlayerCharacterModelRepository(dbConnection),
  ),
)),
```

---

## Schritt 8 — UI

### `player_list_screen.dart`
- `ListView` mit Player-Karten (farbiger Dot, Name, Charakteranzahl-Badge, Notizen-Preview)
- FAB → `EditPlayerScreen`
- Tap → `PlayerDetailScreen`

### `edit_player_screen.dart`
- Felder: Name (Pflicht), Farbe (Farbwahl aus `DnDTheme`-Farben als Swatches), Avatar (optional, `ImageStorageService`), Notizen (mehrzeilig)

### `player_detail_screen.dart`
- Header mit Spielerfarbe + Avatar
- Charakterliste, nach Kampagne gruppiert

### `edit_pc_screen.dart` — Player-Picker
Im Stammdaten-Tab nach dem `playerName`-Feld: `DropdownButton<Player?>` mit „Kein Spieler"-Option.  
Beim Auswählen: `vm.updatePlayerId(player?.id)` + `vm.updatePlayerName(player?.name ?? '')`.

### `home_screen.dart`
Neuer Eintrag in `_bereiche`:
```dart
id: 'spieler', label: 'Spieler', icon: Icons.group,
color: Color(0xFF065F46), beschreibung: 'Spieler & Charaktere'
```

---

## App-Theme in der UI

Das Projekt hat **zwei Theme-Systeme**:
- `context.appColors` (`AppColorsExtension`) — primär, theme-aware (light/dark), für alle allgemeinen Farben
- `DnDTheme.*` — D&D-spezifische Farben (Klassen-Farben, Seltenheiten, Fantasy-Akzente)

**Pflicht in allen neuen Screens:**
```dart
// Oben im build()-Methode
final C = context.appColors;

// Dann:
color: C.bg          // Hintergründe
color: C.accent      // Akzente / Buttons
color: C.text        // Texte
color: C.bgPanel     // Karten / Panels
color: C.border      // Rahmen
```

Für den **Farbwähler** im `EditPlayerScreen` werden `DnDTheme.classColors`-Werte als Swatches angeboten (D&D-Klassen-Farben als Vorschläge).

Die `_bereiche`-Kachel in `home_screen.dart` verwendet keinen hardcodierten `Color(0xFF...)` sondern `C.accent` oder einen `DnDTheme`-Farbwert.

---

## Schritt 9 — Import/Export (`player_export_import_service.dart`)

Neuer Service nach dem Muster von `lib/services/wiki_export_import_service.dart`.  
Bereits verfügbare Pakete: `file_picker ^8.0.0`, `path_provider ^2.1.4`.

### Export-Format (`.player.json`)
Selbstständige, portable JSON-Datei die alles enthält was nötig ist:

```json
{
  "format": "dungenmanager_player",
  "version": "1.0",
  "exportedAt": "2026-05-11T...",
  "player": { ...Player-Felder... },
  "characters": [
    { ...PlayerCharacter-Felder..., "campaignName": "..." }
  ]
}
```

`campaignName` wird denormalisiert mitgespeichert (zur Anzeige beim Import, da die Kampagne auf dem Zielgerät nicht existieren muss).

### Neue Datei: `lib/services/player_export_import_service.dart`

```dart
class PlayerExportImportService {
  // Export
  Future<ServiceResult<String>> exportPlayer(String playerId) async { ... }
  // → erzeugt .player.json im app-spezifischen Verzeichnis (path_provider)
  // → gibt Dateipfad zurück, UI kann Share-Dialog öffnen

  // Import
  Future<PlayerImportResult> importPlayerFromFile() async { ... }
  // → file_picker öffnet .json-Auswahl
  // → validiert format + version
  // → legt Player an (neue ID)
  // → legt Charaktere an (neue IDs, campaign_id = null wenn Kampagne unbekannt)

  // Backup alle Spieler
  Future<ServiceResult<String>> exportAllPlayers() async { ... }
}

class PlayerImportResult {
  final bool success;
  final Player? player;
  final int charactersImported;
  final int charactersSkipped;
  final String? error;
}
```

### UI-Integration

Im `PlayerDetailScreen` und `PlayerListScreen` je ein Export-Button (Icon: `Icons.upload_file`).  
Im `PlayerListScreen` ein Import-Button (Icon: `Icons.download`).  
Beim Import wird ein Bestätigungs-Dialog mit Vorschau (Name, Anzahl Charaktere) angezeigt.

---

## Konventionen (CLAUDE.md)

- **UI-Farben**: `context.appColors` (`final C = context.appColors`) — keine `Colors.grey[x]`, keine hardcodierten `Color(0xFF...)`
- **D&D-Farben**: `DnDTheme.*` nur für D&D-spezifische Elemente (Klassen, Seltenheiten)
- `.withValues(alpha:)` statt `.withOpacity()`
- `debugPrint()` statt `print()`
- `(model as dynamic).id` in generischen Repository-Methoden
- Migrations-Methoden immer idempotent (Guard-Check vor DDL)

---

## Verifikation

1. `flutter analyze` — null Warnungen (außer `inference_failure_*`)
2. App starten → HomeScreen zeigt „Spieler"-Kachel (korrekte Theme-Farben, light & dark)
3. Spieler anlegen (Name, Farbe, Notizen) → erscheint in Liste
4. Charakter bearbeiten → Player-Picker wählbar → `player_id` in DB gesetzt
5. Player-Detail → Charakter erscheint unter der richtigen Kampagne
6. Spieler löschen → Charakter hat `player_id = null`, `playerName` bleibt erhalten
7. Frischer DB-Install (Migration von 0): beide neuen Tabellen/Spalten korrekt angelegt
8. Export: Spieler → `.player.json` wird erzeugt, Datei ist valides JSON mit allen Charakteren
9. Import: `.player.json` einlesen → Spieler + Charaktere erscheinen in der App (neue IDs)
