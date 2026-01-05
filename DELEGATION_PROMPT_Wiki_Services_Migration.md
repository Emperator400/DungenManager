# 🎯 Wiki-Services Migration - Umfassender Refactoring-Prompt

## 📋 Übersicht

**Ziel:** Alle Wiki-bezogenen Services und betroffenen Screens/Widgets zur neuen ModelRepository-Architektur migrieren

**Umfang:** 12 Dateien (7 Services + 4 Screens + 1 Widget)

**Geschätzte Dauer:** 2-4 Stunden

---

## 🏗️ Hintergrund

Die meisten Services (86%) und ViewModels (100%) wurden bereits erfolgreich zur neuen `ModelRepository<T>` Architektur migriert. Die Wiki-Services sind die letzten verbleibenden Dateien mit Kompilierungsfehlern.

### Neue Architektur
- **Alles:** `ViewModel → Repository → Model → Database`
- **Keine Entity-Konvertierungen mehr nötig**
- **Modelle implementieren ihre eigene Serialisierung**

### Betroffene Dateien
```
lib/services/wiki_service_locator.dart           - DatabaseHelperLegacyBackup Fehler
lib/services/wiki_search_service.dart           - isSuccess/data auf Listen
lib/services/wiki_link_service.dart             - operation Parameter, ServiceResult
lib/services/wiki_auto_link_service.dart         - Viele Fehler
lib/services/wiki_template_service.dart         - Typ-Mismatch, CampaignTemplateService
lib/services/wiki_bulk_operations_service.dart   - isSuccess/data, operation Parameter
lib/services/wiki_export_import_service.dart     - Setter-Fehler
lib/screens/enhanced_edit_wiki_entry_screen.dart - DatabaseHelper Import
lib/widgets/sound_scenes_tab.dart              - DatabaseHelper Import
lib/screens/add_item_from_library_screen.dart    - DatabaseHelper Import
lib/screens/encounter_setup_screen.dart         - DatabaseHelper Import
lib/widgets/character_editor/character_inventory_handler.dart - DatabaseHelper
```

---

## 🎯 Migrations-Prinzipien

### 1. **ServiceResult Korrekt verwenden**
```dart
// FALSCH - isSuccess/data auf Listen oder Einzelobjekte aufrufen
var result = await wikiRepository.findAll();
if (result.isSuccess) {  // ❌ List<WikiEntry> hat keine isSuccess Methode
  var entries = result.data;  // ❌ List<WikiEntry> hat keine data Eigenschaft
}

// RICHTIG - Repository gibt direkt Listen zurück
List<WikiEntry> entries = await wikiRepository.findAll();  // ✅

// RICHTIG - ServiceResult nur bei Service-Methoden
ServiceResult<WikiEntry> result = await wikiService.getWikiEntry('id');
if (result.isSuccess) {  // ✅
  var entry = result.data;  // ✅
}
```

### 2. **ModelRepository statt Entity-Repository**
```dart
// ALT
final wikiRepository = WikiRepository();  // Altes Entity-Repository
WikiEntity entity = await wikiRepository.findById('id');
WikiEntry entry = WikiEntry.fromEntity(entity);

// NEU
final wikiRepository = WikiEntryModelRepository();  // Neues Model-Repository
WikiEntry entry = await wikiRepository.findById('id');  // Direktes Model
```

### 3. **Setter nicht verwenden (Unveränderliche Modelle)**
```dart
// FALSCH
entry.id = 'newId';  // ❌ Setter existieren nicht
entry.campaignId = 'newCampaign';  // ❌

// RICHTIG
final newEntry = entry.copyWith(
  id: 'newId',
  campaignId: 'newCampaign',
);  // ✅ copyWith Methode
```

### 4. **ServiceException Subklassen verwenden**
```dart
// FALSCH - ServiceException ist abstrakt
throw ServiceException('error message');  // ❌

// RICHTIG - Konkrete Subklassen
throw NotFoundException('WikiEntry', 'id');  // ✅
throw ValidationException('Invalid input');  // ✅
throw DatabaseException('Database error');  // ✅
```

---

## 📝 Datei-spezifische Migrations-Anweisungen

---

### 1️⃣ lib/services/wiki_service_locator.dart

**Hauptprobleme:**
- `DatabaseHelperLegacyBackup` wird verwendet (existiert nicht mehr)

**Lösung:**
```dart
// Alle Vorkommen von DatabaseHelperLegacyBackup durch die neuen ModelRepositories ersetzen

// ALT
final _databaseHelper = DatabaseHelperLegacyBackup();

// NEU
final _wikiRepository = WikiEntryModelRepository();
final _wikiLinkRepository = WikiLinkModelRepository();

// Alle Methoden aktualisieren:
Future<WikiEntryService> getWikiEntryService() async {
  // ALT:
  // return WikiEntryService(databaseHelper: _databaseHelper);
  
  // NEU:
  return WikiEntryService(
    wikiRepository: _wikiRepository,
  );
}

Future<WikiLinkService> getWikiLinkService() async {
  // ALT:
  // return WikiLinkService(databaseHelper: _databaseHelper);
  
  // NEU:
  return WikiLinkService(
    wikiRepository: _wikiRepository,
    wikiLinkRepository: _wikiLinkRepository,
  );
}
```

**Wichtige Änderungen:**
1. Alle `DatabaseHelperLegacyBackup` Referenzen entfernen
2. Die Services mit ModelRepositories initialisieren
3. Konstruktoren der Services prüfen und anpassen

---

### 2️⃣ lib/services/wiki_search_service.dart

**Hauptprobleme:**
- `isSuccess/data` auf `List<WikiEntry>` aufgerufen
- `isSuccess/data` auf `WikiEntry?` aufgerufen
- Rückgabetyp `Future<List<WikiSearchResult>>` aber `ServiceResult` wird zurückgegeben

**Lösung:**
```dart
// Beispiel für searchWikiEntries() Methode:

// ALT (Zeile ~37-43):
var entries = await wikiRepository.findAll();
if (entries.isSuccess) {  // ❌
  final data = entries.data;  // ❌
  // ...
}
return [];  // ❌ Falscher Rückgabetyp

// NEU:
List<WikiEntry> entries = await wikiRepository.findAll();  // ✅
List<WikiSearchResult> results = entries
    .map((entry) => WikiSearchResult(
          id: entry.id,
          title: entry.title,
          type: entry.type,
          campaignId: entry.campaignId,
        ))
    .toList();
return results;  // ✅ Richtiger Rückgabetyp

// Beispiel für findWikiEntry() Methode:

// ALT (Zeile ~384):
var entry = await wikiRepository.findById(id);
if (entry.isSuccess && entry.data != null) {  // ❌
  return entry.data!;  // ❌
}

// NEU:
WikiEntry? entry = await wikiRepository.findById(id);  // ✅
if (entry != null) {
  return entry;  // ✅
}
return null;
```

**Wichtige Änderungen:**
1. Alle Repository-Aufrufe geben Listen oder Einzelobjekte direkt zurück
2. Keine `isSuccess/data` Aufrufe auf Repository-Ergebnissen
3. Rückgabetypen mit Methodensignaturen abgleichen

---

### 3️⃣ lib/services/wiki_link_service.dart

**Hauptprobleme:**
- `operation` Parameter fehlt bei Repository-Methoden
- `isSuccess/data` auf Entity-Ergebnissen
- `void` Rückgabewerte werden falsch behandelt

**Lösung:**
```dart
// Beispiel für createWikiLink() Methode:

// ALT:
final link = await wikiLinkRepository.create(WikiLink(...));
if (link.isSuccess) {  // ❌
  return link.data;  // ❌
}
// void wird als Rückgabewert erwartet

// NEU:
WikiLink link = await wikiLinkRepository.create(WikiLink(...));  // ✅
return link;

// Beispiel für deleteWikiLink() Methode:

// ALT:
await wikiLinkRepository.delete(id);  // void
if (deleteResult.isSuccess) {  // ❌ void hat isSuccess nicht
  return;  // ❌
}

// NEU:
await wikiLinkRepository.delete(id);  // ✅ void Methode
return;  // ✅

// Beispiel für updateWikiLink() Methode:

// ALT (Zeile ~116):
final result = await wikiLinkRepository.update(
  id: id,
  entity: link,
  operation: 'update',  // ❌ operation Parameter existiert nicht
);

// NEU:
await wikiLinkRepository.update(link);  // ✅ Direkt das Model übergeben

// Beispiel für Methoden, die WikiEntry laden:

// ALT (Zeile ~58):
var entry = await wikiRepository.findById(sourceId);
if (entry.isSuccess && entry.data != null) {  // ❌
  sourceEntry = entry.data!;  // ❌
}

// NEU:
WikiEntry? entry = await wikiRepository.findById(sourceId);  // ✅
if (entry != null) {
  sourceEntry = entry;  // ✅
}
```

**Wichtige Änderungen:**
1. Alle `operation` Parameter aus Repository-Methoden entfernen
2. Repository-Methoden geben Modelle direkt zurück (nicht ServiceResult)
3. `delete()` und ähnliche Methoden geben `void` zurück

---

### 4️⃣ lib/services/wiki_auto_link_service.dart

**Hauptprobleme:**
- `PlayerCharacterRepository.getByCampaignId()` existiert nicht
- `CampaignRepository.getById()` existiert nicht
- `Campaign.name` existiert nicht (Campaign hat `title`)
- `Creature.campaignId` existiert nicht (Creature ist nicht direkt mit Campaign verknüpft)
- `ServiceException` wird direkt instanziiert (abstrakt)
- `WikiEntity`/`WikiEntry` Typ-Mismatch
- `isSuccess/data` auf Listen/Einzelobjekten

**Lösung:**
```dart
// Importe korrigieren:
import 'package:dungen_manager/database/repositories/player_character_repository.dart';
import 'package:dungen_manager/database/repositories/creature_repository.dart';
import 'package:dungen_manager/database/repositories/campaign_repository.dart';
import 'package:dungen_manager/database/repositories/wiki_entry_repository.dart';
import 'package:dungen_manager/database/repositories/wiki_link_repository.dart';

// Initialisierung der Repositories (ALT durch NEU ersetzen):
// ALT:
// final _playerCharacterRepository = PlayerCharacterRepository();
// final _creatureRepository = CreatureRepository();
// final _campaignRepository = CampaignRepository();
// final _wikiRepository = WikiRepository();

// NEU:
final _playerCharacterRepository = PlayerCharacterModelRepository();
final _creatureRepository = CreatureModelRepository();
final _campaignRepository = CampaignModelRepository();
final _wikiRepository = WikiEntryModelRepository();
final _wikiLinkRepository = WikiLinkModelRepository();

// Methode autoLinkCreatures():

// ALT (Zeile ~47):
var characters = await _playerCharacterRepository.getByCampaignId(campaignId);  // ❌

// NEU:
List<PlayerCharacter> characters = await _playerCharacterRepository.findByCampaign(campaignId);  // ✅

// Beispiel für Exception:

// ALT (Zeile ~194):
throw ServiceException('Auto-link failed: $e');  // ❌

// NEU:
throw DatabaseException('Auto-link failed: $e');  // ✅

// Beispiel für Campaign laden:

// ALT (Zeile ~83):
var campaign = await _campaignRepository.getById(campaignId);  // ❌
if (campaign.isSuccess) {  // ❌

// NEU:
Campaign? campaign = await _campaignRepository.findById(campaignId);  // ✅
if (campaign != null) {
  // campaign.title verwenden, nicht campaign.name
  var campaignName = campaign.title;  // ✅
}

// Beispiel für WikiEntry/Entity Mismatch:

// ALT (Zeile ~176):
var entityResult = await _wikiRepository.create(wikiEntry);  // wikiEntry ist WikiEntry
if (entityResult.isFailure) {  // ❌ WikiEntity hat isFailure nicht

// NEU:
WikiEntry createdEntry = await _wikiRepository.create(wikiEntry);  // ✅ WikiEntry zurück

// Beispiel für Creature Felder:

// ALT (Zeile ~211):
var creatureCampaignId = creature.campaignId;  // ❌ Feld existiert nicht

// NEU:
// Creature ist nicht direkt mit Campaign verknüpft
// Verknüpfung über Session oder andere Relationen
// Stattdessen die Campaign-ID aus der Session oder Kontext holen
```

**Wichtige Änderungen:**
1. Alle alten Repositories durch ModelRepositories ersetzen
2. Methodennamen an neue Repositories anpassen
3. `Campaign.title` statt `Campaign.name` verwenden
4. Creature-Beziehung zur Campaign über Session/Relationen
5. Konkrete Exception-Klassen verwenden

---

### 5️⃣ lib/services/wiki_template_service.dart

**Hauptprobleme:**
- `WikiEntity`/`WikiEntry` Typ-Mismatch
- `WikiLinkType` und `WikiLink` als Klasseneigenschaften aufgerufen
- `CampaignTemplateService` Methode existiert nicht
- `isSuccess/data` auf WikiEntity

**Lösung:**
```dart
// Repositories initialisieren:

// ALT:
// final _wikiRepository = WikiRepository();
// final _wikiLinkRepository = WikiLinkRepository();

// NEU:
final _wikiRepository = WikiEntryModelRepository();
final _wikiLinkRepository = WikiLinkModelRepository();

// Beispiel für createFromTemplate():

// ALT (Zeile ~66):
var result = await _wikiRepository.create(wikiEntry);
if (result.isFailure) {  // ❌
  throw result.error;  // ❌
}
final entity = result.data;  // ❌

// NEU:
try {
  WikiEntry createdEntry = await _wikiRepository.create(wikiEntry);  // ✅
  return createdEntry;
} catch (e) {
  throw DatabaseException('Failed to create wiki entry from template: $e');  // ✅
}

// Beispiel für WikiLink Typen:

// ALT (Zeile ~107):
return this.WikiLinkType.reference;  // ❌ Klassenmethode existiert nicht

// NEU:
import 'package:dungen_manager/models/wiki_link.dart';
return WikiLinkType.reference;  // ✅ Enum direkt

// Beispiel für CampaignTemplateService:

// ALT (Zeile ~1203-1226):
// Alle Vorkommen von CampaignTemplateService() entfernen

// NEU:
// Diese Methode existiert nicht mehr
// Stattdessen CampaignRepository verwenden oder Service direkt aufrufen

// Beispiel:
final campaignService = CampaignServiceLocator().getCampaignService();
var templates = await campaignService.getCampaignTemplates();  // Wenn Methode existiert

// Oder direkt mit Repository arbeiten:
var campaigns = await _campaignRepository.findAll();
// ...
```

**Wichtige Änderungen:**
1. Repository-Ergebnisse sind direkt Modelle
2. Enum-Typen direkt aus dem Model importieren
3. `CampaignTemplateService` Referenzen entfernen
4. ServiceResult nur bei Service-Methoden, nicht bei Repositories

---

### 6️⃣ lib/services/wiki_bulk_operations_service.dart

**Hauptprobleme:**
- `isSuccess/data` auf `WikiEntity`
- `operation` Parameter fehlt
- `deleteLinksByEntryId()` Methode existiert nicht
- `createdBy` Parameter existiert nicht

**Lösung:**
```dart
// Repositories initialisieren:

// ALT:
// final _wikiRepository = WikiRepository();
// final _wikiLinkRepository = WikiLinkRepository();

// NEU:
final _wikiRepository = WikiEntryModelRepository();
final _wikiLinkRepository = WikiLinkModelRepository();

// Beispiel für createWikiEntry():

// ALT (Zeile ~44):
var entity = await _wikiRepository.create(wikiEntry);
if (entity.isFailure) {  // ❌

// NEU:
try {
  WikiEntry createdEntry = await _wikiRepository.create(wikiEntry);  // ✅
  return createdEntry;
} catch (e) {
  throw DatabaseException('Failed to create wiki entry: $e');
}

// Beispiel für updateWikiEntry():

// ALT (Zeile ~270):
var result = await _wikiRepository.update(
  id: wikiEntry.id,
  entity: wikiEntity,
  operation: 'update',  // ❌
);

// NEU:
await _wikiRepository.update(wikiEntry);  // ✅ Direkt das Model

// Beispiel für deleteWikiEntry():

// ALT (Zeile ~315):
await _wikiLinkRepository.deleteLinksByEntryId(entryId);  // ❌ Methode existiert nicht

// NEU:
// Alle Links für diesen Eintrag finden und einzeln löschen
List<WikiLink> links = await _wikiLinkRepository.findBySourceEntry(entryId);
for (var link in links) {
  await _wikiLinkRepository.delete(link.id);
}
// Dann den Eintrag löschen
await _wikiRepository.delete(entryId);

// Beispiel für createWikiEntry() mit createdBy:

// ALT (Zeile ~270):
createdBy: 'system',  // ❌ Parameter existiert nicht

// NEU:
// createdBy Feld entfernen oder in metadata speichern
// WikiEntry Model hat kein createdBy Feld
// Stattdessen createdAt/updatedAt verwenden
```

**Wichtige Änderungen:**
1. Alle `operation` Parameter entfernen
2. Repository-Methoden geben Modelle direkt zurück
3. `deleteLinksByEntryId()` durch manuelles Löschen ersetzen
4. Nicht existierende Felder entfernen

---

### 7️⃣ lib/services/wiki_export_import_service.dart

**Hauptprobleme:**
- Setter-Fehler (`id`, `campaignId`, `sourceEntryId`, `targetEntryId`)
- `isSuccess/data` auf `WikiEntity`
- `ServiceResult<WikiImportResult>` wird zurückgegeben, aber `Future<WikiImportResult>` erwartet
- Typ-Mismatch WikiEntry/WikiEntity

**Lösung:**
```dart
// Repositories initialisieren:

// ALT:
// final _wikiRepository = WikiRepository();
// final _wikiLinkRepository = WikiLinkRepository();

// NEU:
final _wikiRepository = WikiEntryModelRepository();
final _wikiLinkRepository = WikiLinkModelRepository();

// Beispiel für importWikiEntries():

// ALT (Zeile ~167):
return importResult;  // ❌ ServiceResult<WikiImportResult> erwartet

// NEU:
return importResult.data;  // ✅ Nur die Daten zurückgeben

// Beispiel für WikiEntry Import:

// ALT (Zeile ~230):
entry.id = importedId;  // ❌ Setter existiert nicht
entry.campaignId = campaignId;  // ❌

// NEU:
final newEntry = entry.copyWith(
  id: importedId,
  campaignId: campaignId,
);  // ✅ copyWith Methode

// Beispiel für WikiEntry speichern:

// ALT (Zeile ~244-248):
var result = await _wikiRepository.create(wikiEntry);
if (result.isFailure) {  // ❌

// NEU:
try {
  WikiEntry createdEntry = await _wikiRepository.create(wikiEntry);  // ✅
  return createdEntry;
} catch (e) {
  throw DatabaseException('Failed to import wiki entry: $e');
}

// Beispiel für WikiLink Import:

// ALT (Zeile ~268-279):
link.id = linkId;  // ❌
link.sourceEntryId = sourceId;  // ❌
link.targetEntryId = targetId;  // ❌
link.campaignId = campaignId;  // ❌

// NEU:
final newLink = link.copyWith(
  id: linkId,
  sourceEntryId: sourceId,
  targetEntryId: targetId,
  campaignId: campaignId,
);  // ✅ copyWith Methode

// Beispiel für WikiLink speichern:

// ALT (Zeile ~288):
await _wikiLinkRepository.create(link);  // link ist WikiLink

// NEU:
// WikiLink Entity in WikiLink Entity umwandeln
WikiLinkEntity linkEntity = WikiLinkEntity.fromModel(link);
await _wikiLinkRepository.create(linkEntity);  // ❌

// NEU BESSER:
await _wikiLinkRepository.create(link);  // ✅ Direkt WikiLink
```

**Wichtige Änderungen:**
1. Alle Setter durch `copyWith()` ersetzen
2. Repository-Aufrufe geben Modelle direkt zurück
3. ServiceResult.data bei Rückgabe aus Services
4. Keine Entity-Konvertierung mehr nötig

---

### 8️⃣ lib/screens/enhanced_edit_wiki_entry_screen.dart

**Hauptprobleme:**
- Importiert `lib/database/database_helper.dart` (existiert nicht mehr)

**Lösung:**
```dart
// Import entfernen:

// ALT:
import 'package:dungen_manager/database/database_helper.dart';
final _dbHelper = DatabaseHelper();

// NEU:
// Import entfernen und _dbHelper Referenzen entfernen
// Alle Datenbankoperationen über ViewModel durchführen

// Beispiel für Datenbankoperation:

// ALT:
final result = await _dbHelper.getWikiEntry(entryId);

// NEU:
final entry = await viewModel.getWikiEntry(entryId);
```

**Wichtige Änderungen:**
1. DatabaseHelper Import entfernen
2. Alle Datenbankoperationen über ViewModel durchführen
3. ViewModel bereits migriert (siehe REFACTORING_PROGRESS.md)

---

### 9️⃣ lib/widgets/sound_scenes_tab.dart

**Hauptprobleme:**
- Importiert `lib/database/database_helper.dart` (existiert nicht mehr)

**Lösung:**
```dart
// Import entfernen:

// ALT:
import 'package:dungen_manager/database/database_helper.dart';
final DatabaseHelper _dbHelper = DatabaseHelper();

// NEU:
// Import entfernen und _dbHelper Referenzen entfernen
// Alle Datenbankoperationen über ViewModel oder Context durchführen

// Beispiel für Datenbankoperation:

// ALT:
final result = await _dbHelper.getScene(sceneId);

// NEU:
// Über Provider oder Context holen
final viewModel = context.watch<ViewModel>();
final scene = await viewModel.getScene(sceneId);
```

**Wichtige Änderungen:**
1. DatabaseHelper Import entfernen
2. Über Provider/Context auf ViewModels zugreifen
3. ViewModel bereits migriert

---

### 🔟 lib/screens/add_item_from_library_screen.dart

**Hauptprobleme:**
- Importiert `lib/database/database_helper.dart` (existiert nicht mehr)

**Lösung:**
```dart
// Import entfernen:

// ALT:
import 'package:dungen_manager/database/database_helper.dart';
final DatabaseHelper _dbHelper = DatabaseHelper();

// NEU:
// Import entfernen und _dbHelper Referenzen entfernen
// Alle Datenbankoperationen über ViewModel durchführen

// Beispiel für Datenbankoperation:

// ALT:
final result = await _dbHelper.addItemToInventory(characterId, itemId);

// NEU:
final viewModel = context.read<ItemLibraryViewModel>();
await viewModel.addItemToInventory(characterId, itemId);
```

**Wichtige Änderungen:**
1. DatabaseHelper Import entfernen
2. Über Provider auf ViewModels zugreifen
3. ViewModel bereits migriert

---

### 1️⃣1️⃣ lib/screens/encounter_setup_screen.dart

**Hauptprobleme:**
- Importiert `lib/database/database_helper.dart` (existiert nicht mehr)

**Lösung:**
```dart
// Import entfernen:

// ALT:
import 'package:dungen_manager/database/database_helper.dart';
final DatabaseHelper _dbHelper = DatabaseHelper();

// NEU:
// Import entfernen und _dbHelper Referenzen entfernen
// Alle Datenbankoperationen über ViewModel durchführen

// Beispiel für Datenbankoperation:

// ALT:
final result = await _dbHelper.getCreature(creatureId);

// NEU:
final viewModel = context.read<BestiaryViewModel>();
final creature = await viewModel.getCreature(creatureId);
```

**Wichtige Änderungen:**
1. DatabaseHelper Import entfernen
2. Über Provider auf ViewModels zugreifen
3. ViewModel bereits migriert

---

### 1️⃣2️⃣ lib/widgets/character_editor/character_inventory_handler.dart

**Hauptprobleme:**
- Importiert `lib/database/database_helper.dart` (existiert nicht mehr)
- Verwendet `_dbHelper` Eigenschaft

**Lösung:**
```dart
// Import entfernen:

// ALT:
import 'package:dungen_manager/database/database_helper.dart';
final DatabaseHelper _dbHelper = DatabaseHelper();

// NEU:
// Import entfernen und _dbHelper Referenzen entfernen
// Alle Datenbankoperationen über ViewModel oder Service durchführen

// Repositories initialisieren:

// NEU:
final _inventoryItemRepository = InventoryItemModelRepository();

// Beispiel für Datenbankoperation:

// ALT (Zeile ~62):
var result = await _dbHelper.getInventoryItems(characterId);

// NEU:
List<InventoryItem> items = await _inventoryItemRepository.findByCharacter(characterId);  // ✅

// ALT (Zeile ~84):
var result = await _dbHelper.addInventoryItem(item);

// NEU:
InventoryItem createdItem = await _inventoryItemRepository.create(item);  // ✅

// ALT (Zeile ~158):
await _dbHelper.updateInventoryItem(item);

// NEU:
await _inventoryItemRepository.update(item);  // ✅

// ALT (Zeile ~173):
await _dbHelper.deleteInventoryItem(itemId);

// NEU:
await _inventoryItemRepository.delete(itemId);  // ✅
```

**Wichtige Änderungen:**
1. DatabaseHelper Import und Eigenschaften entfernen
2. InventoryItemModelRepository verwenden
3. Repository-Methoden geben Modelle direkt zurück

---

## 🧪 Test-Strategie

### Nach jeder Datei:
1. `flutter analyze` ausführen
2. Auf Kompilierungsfehler prüfen
3. Falls Fehler: Fix anwenden und erneut testen

### Nach allen Dateien:
1. `flutter test` ausführen
2. `flutter test integration_test/app_comprehensive_test.dart` ausführen
3. Auf verbleibende Fehler prüfen

---

## 📊 Checkliste

- [ ] wiki_service_locator.dart migriert
- [ ] wiki_search_service.dart migriert
- [ ] wiki_link_service.dart migriert
- [ ] wiki_auto_link_service.dart migriert
- [ ] wiki_template_service.dart migriert
- [ ] wiki_bulk_operations_service.dart migriert
- [ ] wiki_export_import_service.dart migriert
- [ ] enhanced_edit_wiki_entry_screen.dart korrigiert
- [ ] sound_scenes_tab.dart korrigiert
- [ ] add_item_from_library_screen.dart korrigiert
- [ ] encounter_setup_screen.dart korrigiert
- [ ] character_inventory_handler.dart korrigiert
- [ ] flutter analyze ohne Fehler
- [ ] flutter test erfolgreich
- [ ] Integrationstest erfolgreich

---

## 🎯 Erfolgskriterien

1. ✅ **Keine Kompilierungsfehler** - `flutter analyze` zeigt 0 Fehler
2. ✅ **Alle Tests erfolgreich** - `flutter test` grün
3. ✅ **Integrationstest erfolgreich** - `app_comprehensive_test.dart` bestanden
4. ✅ **Konsistente Architektur** - Alle Wiki-Services nutzen ModelRepositories
5. ✅ **Keine veralteten Importe** - Alle DatabaseHelper Referenzen entfernt

---

## 📚 Referenz-Dokumentation

- **REFACTORING_PROGRESS.md** - Aktueller Status der Migration
- **PHASE6_SERVICE_MIGRATION_PLAN.md** - Service-Migrationsplan
- **API_REFACTORING_PLAN.md** - Detaillierter Refactoring-Plan
- **DATABASE_API_DOCUMENTATION.md** - Datenbank-API

---

*Letztes Update: 02.01.2026*
*Status: Warten auf Durchführung*
*Nächster Schritt: Alle Wiki-Services und betroffenen Screens/Widgets gemäß diesem Prompt migrieren*
