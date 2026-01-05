# Phase 6: Service Migration Plan

## Übersicht

Dieses Dokument beschreibt den Migrationsplan für Services von den alten Entity-basierten Repositories zu den neuen Model-basierten Repositories.

## Status

- **Datum:** 2026-01-02
- **Phase:** 6 - Aufräumarbeiten und Service Migration
- **Status:** @deprecated Annotationen hinzugefügt

## Architektur-Übersicht

### Alte Architektur (Deprecated)

```
Service -> EntityRepository -> Entity -> Model
```

Die alten Repositories:
- `campaign_repository.dart`
- `creature_repository.dart`
- `inventory_item_repository.dart`
- `item_repository.dart`
- `player_character_repository.dart`
- `quest_repository.dart`
- `session_repository.dart`
- `sound_repository.dart`
- `wiki_link_repository.dart`
- `wiki_repository.dart`

Alle sind jetzt mit `@deprecated` markiert.

### Neue Architektur (Target)

```
Service -> ModelRepository -> Model -> Entity -> Database
```

Die neuen Repositories:
- `campaign_model_repository.dart`
- `creature_model_repository.dart`
- `inventory_item_model_repository.dart`
- `item_model_repository.dart`
- `player_character_model_repository.dart`
- `quest_model_repository.dart`
- `session_model_repository.dart`
- `sound_model_repository.dart`
- `wiki_entry_model_repository.dart`
- `wiki_link_model_repository.dart`

## Migrations-Prioritäten

### Hohe Priorität (Kritische Services)

Diese Services werden häufig verwendet und sollten zuerst migriert werden:

1. **Campaign Service**
   - Alt: `CampaignRepository`
   - Neu: `CampaignModelRepository`
   - Dateien: `campaign_service.dart`, `campaign_service_locator.dart`
   - Auswirkung: Kampagnen-Management

2. **Character Editor Service**
   - Alt: `PlayerCharacterRepository`, `CreatureRepository`
   - Neu: `PlayerCharacterModelRepository`, `CreatureModelRepository`
   - Dateien: `character_editor_service.dart`
   - Auswirkung: Charakter-Erstellung und -Bearbeitung

3. **Quest Library Service**
   - Alt: `QuestRepository`
   - Neu: `QuestModelRepository`
   - Dateien: `quest_library_service.dart`, `quest_service_locator.dart`
   - Auswirkung: Quest-Management

### Mittlere Priorität

4. **Item Library Service**
   - Alt: `ItemRepository`, `InventoryItemRepository`
   - Neu: `ItemModelRepository`, `InventoryItemModelRepository`
   - Dateien: `inventory_service.dart`
   - Auswirkung: Item- und Inventar-Management

5. **Wiki Service**
   - Alt: `WikiRepository`, `WikiLinkRepository`
   - Neu: `WikiEntryModelRepository`, `WikiLinkModelRepository`
   - Dateien: `wiki_entry_service.dart`, `wiki_link_service.dart`, `wiki_service_locator.dart`
   - Auswirkung: Lore Keeper

6. **Session Service**
   - Alt: `SessionRepository`
   - Neu: `SessionModelRepository`
   - Dateien: `campaign_service.dart`
   - Auswirkung: Session-Management

### Niedrige Priorität

7. **Sound Service**
   - Alt: `SoundRepository`
   - Neu: `SoundModelRepository`
   - Dateien: Diverse Sound-Services
   - Auswirkung: Sound-Library

## Migrations-Schritte

### Schritt 1: Service-Analyse

Für jeden Service:

1. Alle Referenzen auf alte Repositories finden
   ```bash
   grep -r "CampaignRepository" lib/services/
   grep -r "PlayerCharacterRepository" lib/services/
   ```

2. Abhängigkeiten und Verwendungszweck dokumentieren
   - Welche Methoden werden verwendet?
   - Welche Entity-Operationen?
   - Gibt es spezielle Repository-Methoden?

### Schritt 2: Service-Refactoring

1. Import aktualisieren:
   ```dart
   // Alt
   import '../database/repositories/campaign_repository.dart';
   
   // Neu
   import '../database/repositories/campaign_model_repository.dart';
   ```

2. Repository-Instanziierung aktualisieren:
   ```dart
   // Alt
   final _repository = CampaignRepository(databaseConnection);
   
   // Neu
   final _repository = CampaignModelRepository(databaseConnection);
   ```

3. Methodenaufrufe anpassen:
   - Die neuen ModelRepositories akzeptieren Model-Objekte direkt
   - Entity-zu-Model-Konvertierungen sind nicht mehr nötig
   - Rückgabewerte sind bereits Model-Objekte

4. Typ-Anpassungen:
   ```dart
   // Alt
   Future<List<CampaignEntity>> getAllCampaigns() async {
     final entities = await _repository.findAll();
     return entities; // Entity-Objekte
   }
   
   // Neu
   Future<List<Campaign>> getAllCampaigns() async {
     return await _repository.findAll(); // Model-Objekte direkt
   }
   ```

### Schritt 3: Tests aktualisieren

1. Alle Service-Tests finden
2. Test-Imports aktualisieren
3. Test-Daten erstellen (Model-Objekte statt Entity-Objekte)
4. Erwartete Rückgabewerte anpassen (Model statt Entity)

### Schritt 4: ViewModels aktualisieren (falls nötig)

Wenn Services direkt in ViewModels verwendet werden:

1. ViewModels mit Service-Referenzen finden
2. Imports aktualisieren (falls Services importiert werden)
3. Typ-Annotationen anpassen

## Service-spezifische Migrations-Details

### CampaignService

**Datei:** `lib/services/campaign_service.dart`

**Änderungen:**
- `CampaignRepository` → `CampaignModelRepository`
- `SessionRepository` → `SessionModelRepository`

**Methoden-Auswirkung:**
- `getAllCampaigns()` - Keine Entity-zu-Model-Konvertierung mehr nötig
- `getCampaignById()` - Gibt direkt `Campaign` zurück
- `createCampaign()` - Nimmt `Campaign` statt `CampaignEntity`

### CharacterEditorService

**Datei:** `lib/services/character_editor_service.dart`

**Änderungen:**
- `PlayerCharacterRepository` → `PlayerCharacterModelRepository`
- `CreatureRepository` → `CreatureModelRepository`

**Methoden-Auswirkung:**
- Alle Methoden geben direkt Model-Objekte zurück
- Keine Entity-zu-Model-Konvertierung mehr nötig

### QuestLibraryService

**Datei:** `lib/services/quest_library_service.dart`

**Änderungen:**
- `QuestRepository` → `QuestModelRepository`

**Methoden-Auswirkung:**
- `getQuestsByCampaign()` - Gibt `List<Quest>` direkt zurück
- `createQuest()` - Nimmt `Quest` direkt

### InventoryService

**Datei:** `lib/services/inventory_service.dart`

**Änderungen:**
- `ItemRepository` → `ItemModelRepository`
- `InventoryItemRepository` → `InventoryItemModelRepository`

**Methoden-Auswirkung:**
- Alle Item-bezogenen Methoden geben Model-Objekte zurück

### WikiEntryService

**Datei:** `lib/services/wiki_entry_service.dart`

**Änderungen:**
- `WikiRepository` → `WikiEntryModelRepository`

**Methoden-Auswirkung:**
- `getEntriesByCampaign()` - Gibt `List<WikiEntry>` direkt zurück

### WikiLinkService

**Datei:** `lib/services/wiki_link_service.dart`

**Änderungen:**
- `WikiLinkRepository` → `WikiLinkModelRepository`

**Methoden-Auswirkung:**
- `getLinksForEntry()` - Gibt `List<WikiLink>` direkt zurück

## Rückfallebene

Wenn bei der Migration Probleme auftreten:

1. **Die alten Repositories sind noch vorhanden und funktionierfähig**
   - Sie sind nur `@deprecated`, nicht gelöscht
   - Services können temporär weiter alte Repositories verwenden

2. **Schrittweise Migration**
   - Nicht alle Services müssen gleichzeitig migriert werden
   - Beginne mit kritischen Services

3. **Feature-Flags (optional)**
   - Feature-Flags können alten und neuen Code parallel laufen lassen
   - schrittweises Rollout möglich

## Validierungs-Checkliste

Für jeden migrierten Service:

- [ ] Alle alten Repository-Imports entfernt
- [ ] Alle neuen Repository-Imports hinzugefügt
- [ ] Service-Tests grün
- [ ] ViewModels funktionieren korrekt
- [ ] UI funktioniert wie erwartet
- [ ] Keine Compiler-Warnungen für @deprecated

## Zeitplan

Empfohlene Reihenfolge:

1. Woche 1: Campaign Service, Character Editor Service
2. Woche 2: Quest Library Service, Item Library Service
3. Woche 3: Wiki Services, Session Service
4. Woche 4: Sound Service, finale Tests und Cleanup

## Nächste Schritte

1. **Beginne mit hoher Priorität**
   - Campaign Service zuerst migrieren
   - Tests verifizieren

2. **Dokumentiere Erfahrungen**
   - Welche Probleme aufgetreten?
   - Welche Anpassungen notwendig?
   - Aktualisiere dieses Dokument

3. **Kommunikation**
   - Informiere das Team über @deprecated Annotationen
   - Plane Meetings für Fragen

## Referenzen

- API_REFACTORING_PLAN.md - Gesamt-Refactoring-Plan
- REFACTORING_PROGRESS.md - Fortschritts-Tracking
- PHASE6_ANALYSIS.md - Detaillierte Analyse
- DATABASE_API_DOCUMENTATION.md - API-Dokumentation

## Notizen

- Die Migration sollte schrittweise erfolgen
- Jede Service-Migration sollte getestet werden
- Alte Repositories bleiben erhalten bis alle Services migriert sind
- Dokumentation sollte mit jedem Schritt aktualisiert werden
