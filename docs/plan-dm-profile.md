# Plan: DM-Profil

Jeder DM hat genau ein Profil (Singleton) — persönliche Informationen, Avatar und
eine Übersicht über die eigene Spielleiter-Aktivität.

**Status: Implementiert** ✅

---

## Felder

| Feld | Typ | Beschreibung |
|------|-----|-------------|
| `id` | `String` | Immer `'dm_profile'` (Singleton) |
| `dmName` | `String` | Name oder Alias des DMs |
| `bio` | `String?` | Kurze Selbstbeschreibung |
| `avatarPath` | `String?` | Lokaler Pfad zum Profilbild |
| `favoriteSystem` | `String?` | z.B. „D&D 5e", „Pathfinder 2e" |
| `createdAt` | `DateTime` | Erstellt |
| `updatedAt` | `DateTime` | Zuletzt geändert |

### Berechnete Stats (nicht gespeichert)

| Stat | Quelle |
|------|--------|
| Kampagnen | `campaigns`-Tabelle |
| Sitzungen | `sessions`-Tabelle |
| Charaktere | `player_characters`-Tabelle |

---

## Neue Dateien

| Datei | Inhalt |
|-------|--------|
| `lib/models/dm_profile.dart` | Singleton-Modell + `DmProfile.empty()` |
| `lib/database/repositories/dm_profile_model_repository.dart` | `getOrCreate()`, `upsertProfile()` |
| `lib/services/dm_profile_service.dart` | get/update/avatar + `loadStats()` |
| `lib/viewmodels/dm_profile_viewmodel.dart` | ChangeNotifier, lädt Profil + Stats |
| `lib/screens/profile/dm_profile_screen.dart` | Ansicht + Inline-Bearbeitungsmodus |

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/database/migrations/database_migration.dart` | `_createDmProfileTable()` hinzugefügt |
| `lib/main.dart` | `DmProfileViewModel` + `DmProfileService` registriert |
| `lib/screens/navigation/home_screen.dart` | „DM-Profil"-Kachel aktiviert + Navigation verdrahtet |

---

## Datenbankschema

```sql
CREATE TABLE dm_profile (
  id TEXT PRIMARY KEY,           -- immer 'dm_profile'
  dm_name TEXT NOT NULL DEFAULT '',
  bio TEXT,
  avatar_path TEXT,
  favorite_system TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

Migration ist idempotent (Guard-Check via `sqlite_master`).

---

## Repository — Singleton-Pattern

```dart
// Liest das einzige Profil oder legt es beim ersten Aufruf an
Future<DmProfile> getOrCreate()

// INSERT OR REPLACE (ConflictAlgorithm.replace)
Future<DmProfile> upsertProfile(DmProfile profile)
```

---

## Screen — Inline-Edit-Modus

Der Screen hat zwei Zustände:
- **Ansicht** — schreibgeschützte Felder + Stats-Zeile, Edit-Icon in AppBar
- **Bearbeitung** — TextFormFields editierbar, „Speichern" / „Abbrechen" in AppBar

Avatar-Bild: klick auf Kamera-Icon → `FilePicker` für Bilder → `ImageStorageService.saveImageToSecureFolder()`.

---

## Firebase-Erweiterung (Zukunft)

Wenn Firebase Foundation implementiert ist, kann das DM-Profil optional mit
`app_user.dart` (Firebase Auth UID) verknüpft werden:
- `dmProfile.uid` → Auth UID
- Profil-Sync zwischen Geräten via Cloud Firestore
- Avatar-Upload zu Firebase Storage statt lokalem Pfad

---

## Verifikation

1. `flutter analyze` — null Warnungen
2. „DM-Profil"-Kachel im HomeScreen ist klickbar (lila Farbe, nicht mehr grau)
3. Profil-Screen öffnet sich, Stats werden korrekt angezeigt
4. Name bearbeiten → Speichern → Wert bleibt nach App-Neustart
5. Avatar setzen → Bild erscheint als Kreis
6. Avatar entfernen → Platzhalter-Icon wieder sichtbar
7. Frischer DB-Install: `dm_profile`-Tabelle wird angelegt, `getOrCreate()` erzeugt leeres Profil
