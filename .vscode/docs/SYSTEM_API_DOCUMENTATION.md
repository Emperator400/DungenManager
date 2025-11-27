# 🚀 DungenManager System API Documentation

**Version:** 1.0  
**Datum:** 8. November 2025  
**Zweck:** Zentrale API-Referenz für alle Agenten und Spezialisten  
**Status:** Verbindliche Referenz gemäß AI_CONSTITUTION Artikel 3

---

## 📋 Inhaltsverzeichnis

1. [System Architecture Overview](#1-system-architecture-overview)
2. [Service Layer APIs](#2-service-layer-apis)
3. [Domain Integration Points](#3-domain-integration-points)
4. [ViewModel Integration Patterns](#4-viewmodel-integration-patterns)
5. [Testing Guidelines](#5-testing-guidelines)
6. [Error Handling & Escalation](#6-error-handling--escalation)
7. [Quick Reference Cards](#7-quick-reference-cards)
8. [Migration Guides](#8-migration-guides)

---

## 1. System Architecture Overview

### 🏗️ Layer-Struktur

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Screens/Widgets)              │
│  ├── Screens (StatefulWidget)                              │
│  ├── Widgets (StatelessWidget)                             │
│  └── ViewModels (ChangeNotifier)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ (Service Calls)
┌─────────────────────────────────────────────────────────────┐
│                  Service Layer (Business Logic)           │
│  ├── Gold-Standard Services (DI + Error Handling)        │
│  ├── Static Helper Services (Pure Functions)             │
│  └── Legacy Services (To be standardized)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼ (Database Operations)
┌─────────────────────────────────────────────────────────────┐
│                Database Layer (SQLite Operations)          │
│  ├── DatabaseHelper (CRUD Operations)                     │
│  ├── Migrations (Schema Evolution)                        │
│  └── Query Builder (Complex Queries)                      │
└─────────────────────────────────────────────────────────────┘
```

### 🔄 Datenfluss-Muster (STRICT EINZUHALTEN)

```
UI Layer (Screen/Widget) 
    -> ruft -> 
Service Layer (Business Logic) 
    -> ruft -> 
Database Layer (DatabaseHelper) 
    -> interagiert mit -> 
Datenbank (SQLite)
```

### 📊 Verantwortlichkeiten

| Layer | Verantwortlich für | NICHT verantwortlich für |
|-------|-------------------|--------------------------|
| **UI** | User Interface, State Management, Navigation | Business Logic, Datenbankzugriffe |
| **Service** | Business Logic, Validierung, Daten-Transformation | UI-Code, Direkte Datenbankzugriffe |
| **Database** | CRUD Operationen, Schema Management | Business Rules, UI Updates |

---

## 2. Service Layer APIs

### 🟢 Kategorie A: Gold-Standard Services

Diese Services bieten fortschrittliche Features mit Dependency Injection und standardisiertem Error-Handling.

#### **CampaignService**
```dart
// Dependency Injection Pattern
final campaignService = CampaignService(
  dbHelper: customDatabaseHelper, // Optional
  questService: customQuestService, // Optional
);

// ServiceResult Pattern
final result = await campaignService.getCampaignsByStatus('active');
if (result.isSuccess) {
  final campaigns = result.data!;
} else {
  print('Fehler: ${result.errors.first}');
}
```

**API-Methoden:**
- `Future<ServiceResult<List<Campaign>>> getCampaignsByStatus(String status)`
- `Future<ServiceResult<Campaign>> getCampaignById(String id)`
- `Future<ServiceResult<void>> createCampaign(Campaign campaign)`
- `Future<ServiceResult<void>> updateCampaign(Campaign campaign)`
- `Future<ServiceResult<void>> deleteCampaign(String id)`

**Dependencies:**
- `DatabaseHelper` (optional, default: `DatabaseHelper.instance`)
- `QuestLibraryService` (optional, für Quest-Integration)

---

#### **QuestLibraryService**
```dart
// Mit Dependency Injection
final questService = QuestLibraryService(
  dbHelper: customDatabaseHelper,
  questDataService: customQuestDataService,
);

// Standardisierte API-Aufrufe
final result = await questService.getAllQuests();
if (result.isSuccess) {
  final quests = result.data!;
  // Verarbeite Quests
}
```

**API-Methoden:**
- `Future<ServiceResult<List<Quest>>> getAllQuests()`
- `Future<ServiceResult<Quest>> getQuestById(String id)`
- `Future<ServiceResult<List<Quest>>> getQuestsByDifficulty(String difficulty)`
- `Future<ServiceResult<void>> createQuest(Quest quest)`
- `Future<ServiceResult<void>> updateQuest(Quest quest)`

**Dependencies:**
- `DatabaseHelper` (optional)
- `QuestDataService` (optional)

---

#### **InventoryService** (NEU standardisiert)
```dart
// Dependency Injection mit Default-Werten
final inventoryService = InventoryService(
  dbHelper: customDatabaseHelper, // Optional
  uuidService: customUuidService, // Optional
);

// Interne Verwendung von performServiceOperation<T>()
final inventory = await inventoryService.loadInventory(characterId);
// Automatisches Error-Handling mit spezifischen Exceptions
```

**API-Methoden:**
- `Future<List<InventoryItem>> loadInventory(String characterId)`
- `Future<void> addItem(String characterId, InventoryItem item)`
- `Future<void> removeItem(String characterId, String itemId)`
- `Future<void> updateItem(String characterId, InventoryItem item)`

**Dependencies:**
- `DatabaseHelper` (optional)
- `UuidService` (optional)

---

### 🟡 Kategorie B: Static Helper Services

Diese Services bieten statische Helper-Funktionen für Datenverarbeitung und Serialisierung.

#### **QuestDataService**
```dart
// Statische Methoden - keine Instanz nötig
final questType = QuestDataService.parseQuestType(questTypeString);
final difficulty = QuestDataService.parseDifficulty(difficultyString);
final rewards = QuestDataService.parseRewards(rewardsData);

// Serialisierung für Datenbank
final serializedRewards = QuestDataService.serializeRewards(rewardsList);
```

**Static API-Methoden:**
- `static QuestType parseQuestType(String typeString)`
- `static QuestDifficulty parseDifficulty(String difficultyString)`
- `static List<QuestReward> parseRewards(Map<String, dynamic> data)`
- `static String serializeRewards(List<QuestReward> rewards)`
- `static Map<String, dynamic> serializeQuest(Quest quest)`

---

#### **PlayerCharacterService**
```dart
// Statische Serialisierungsfunktionen
final serializedSkills = PlayerCharacterService.serializeSkills(skillsList);
final skills = PlayerCharacterService.deserializeSkills(skillsString);

// Validierung
final isValid = PlayerCharacterService.isValidPlayerCharacter(character);

// Formatierung
final formatted = PlayerCharacterService.formatPlayerCharacter(character);
```

**Static API-Methoden:**
- `static String serializeSkills(Map<String, int> skills)`
- `static Map<String, int> deserializeSkills(String skillsString)`
- `static bool isValidPlayerCharacter(PlayerCharacter character)`
- `static String formatPlayerCharacter(PlayerCharacter character)`

---

### 🔴 Kategorie C: Noch zu standardisieren

Diese Services benötigen noch die volle Standardisierung.

#### **QuestLoreIntegrationService**
```dart
// Aktuell noch altes Pattern (TODO: Standardisierung)
final service = QuestLoreIntegrationService();
final result = await service.linkQuestToLore(questId, loreEntryId);
```

**Legacy API-Methoden:**
- `Future<bool> linkQuestToLore(String questId, String loreEntryId)`
- `Future<bool> unlinkQuestFromLore(String questId, String loreEntryId)`
- `Future<List<WikiEntry>> getLoreForQuest(String questId)`

---

#### **QuestRewardService**
```dart
// Aktuell noch altes Pattern (TODO: Standardisierung)
final service = QuestRewardService();
final rewards = await service.getQuestRewards(questId);
```

**Legacy API-Methods:**
- `Future<List<QuestReward>> getQuestRewards(String questId)`
- `Future<void> addRewardToQuest(String questId, QuestReward reward)`
- `Future<void> removeRewardFromQuest(String questId, String rewardId)`

---

## 3. Domain Integration Points

### 🎮 Character Editor System

**Haupt-Services:**
- `CharacterEditorService` (Gold-Standard)
- `InventoryService` (Gold-Standard)
- `PlayerCharacterService` (Static Helper)

**Integration-Pattern:**
```dart
class CharacterEditorViewModel extends ChangeNotifier {
  final CharacterEditorService _characterService;
  final InventoryService _inventoryService;

  CharacterEditorViewModel({
    CharacterEditorService? characterService,
    InventoryService? inventoryService,
  }) : _characterService = characterService ?? CharacterEditorService(),
       _inventoryService = inventoryService ?? InventoryService();

  Future<void> loadCharacter(String characterId) async {
    final character = await _characterService.getCharacterById(characterId);
    final inventory = await _inventoryService.loadInventory(characterId);
    
    // Update UI
    notifyListeners();
  }
}
```

**Widgets:**
- `CharacterEditorWidget` → `CharacterEditorViewModel`
- `InventoryTabWidget` → `InventoryService`
- `AttributesTabWidget` → `PlayerCharacterService`

---

### 📜 Quest Library System

**Haupt-Services:**
- `QuestLibraryService` (Gold-Standard)
- `QuestDataService` (Static Helper)
- `QuestRewardService` (Legacy - TODO Standardisierung)

**Integration-Pattern:**
```dart
class QuestLibraryViewModel extends ChangeNotifier {
  final QuestLibraryService _questService;
  final QuestDataService _dataService = QuestDataService(); // Static

  QuestLibraryViewModel({
    QuestLibraryService? questService,
  }) : _questService = questService ?? QuestLibraryService();

  Future<void> loadQuests() async {
    final result = await _questService.getAllQuests();
    if (result.isSuccess) {
      _quests = result.data!;
      // Process with static helpers
      for (final quest in _quests) {
        final formatted = _dataService.serializeQuest(quest);
        // Use formatted data
      }
      notifyListeners();
    }
  }
}
```

---

### 📚 Wiki/Lore System

**Haupt-Services:**
- `WikiEntryService` (Gold-Standard)
- `WikiLinkService` (Gold-Standard)
- `WikiSearchService` (Gold-Standard)
- `WikiTemplateService` (Legacy - TODO Standardisierung)

**Integration-Pattern:**
```dart
class LoreKeeperViewModel extends ChangeNotifier {
  final WikiEntryService _entryService;
  final WikiLinkService _linkService;
  final WikiSearchService _searchService;

  LoreKeeperViewModel({
    WikiEntryService? entryService,
    WikiLinkService? linkService,
    WikiSearchService? searchService,
  }) : _entryService = entryService ?? WikiEntryService(),
       _linkService = linkService ?? WikiLinkService(),
       _searchService = searchService ?? WikiSearchService();

  Future<void> searchEntries(String query) async {
    final result = await _searchService.searchEntries(query);
    if (result.isSuccess) {
      _searchResults = result.data!;
      notifyListeners();
    }
  }
}
```

---

### 🎵 Audio/Sound System

**Haupt-Services:**
- `SoundLibraryService` (Gold-Standard)
- `SceneSoundService` (Legacy - TODO Standardisierung)

**Integration-Pattern:**
```dart
class SoundMixerViewModel extends ChangeNotifier {
  final SoundLibraryService _soundService;

  SoundMixerViewModel({
    SoundLibraryService? soundService,
  }) : _soundService = soundService ?? SoundLibraryService();

  Future<void> loadSoundLibrary() async {
    final result = await _soundService.getAllSounds();
    if (result.isSuccess) {
      _sounds = result.data!;
      notifyListeners();
    }
  }
}
```

---

### 🏰 Campaign Management System

**Haupt-Services:**
- `CampaignService` (Gold-Standard)
- `SessionService` (Legacy - TODO Standardisierung)

**Integration-Pattern:**
```dart
class CampaignManagerViewModel extends ChangeNotifier {
  final CampaignService _campaignService;

  CampaignManagerViewModel({
    CampaignService? campaignService,
  }) : _campaignService = campaignService ?? CampaignService();

  Future<void> loadActiveCampaigns() async {
    final result = await _campaignService.getCampaignsByStatus('active');
    if (result.isSuccess) {
      _activeCampaigns = result.data!;
      notifyListeners();
    }
  }
}
```

---

## 4. ViewModel Integration Patterns

### 🔧 Standard Dependency Injection Pattern

```dart
class ExampleViewModel extends ChangeNotifier {
  final InventoryService _inventoryService;
  final QuestLibraryService _questService;

  // Constructor mit optionalen Dependencies
  ExampleViewModel({
    InventoryService? inventoryService,
    QuestLibraryService? questService,
  }) : _inventoryService = inventoryService ?? InventoryService(),
       _questService = questService ?? QuestLibraryService();

  // Methode mit Error-Handling
  Future<void> loadCharacterInventory(String characterId) async {
    try {
      final inventory = await _inventoryService.loadInventory(characterId);
      // Verarbeite Inventar
      notifyListeners();
    } catch (e) {
      // Error wird bereits vom Service behandelt
      print('Error in ViewModel: $e');
    }
  }
}
```

### 🎯 ServiceLocator Pattern (für komplexe Dependencies)

```dart
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final CampaignService campaignService;
  late final QuestLibraryService questService;
  late final InventoryService inventoryService;

  void initialize({
    DatabaseHelper? dbHelper,
    UuidService? uuidService,
  }) {
    campaignService = CampaignService(dbHelper: dbHelper);
    questService = QuestLibraryService(dbHelper: dbHelper);
    inventoryService = InventoryService(
      dbHelper: dbHelper,
      uuidService: uuidService,
    );
  }
}

// Verwendung in ViewModels
class CampaignViewModel extends ChangeNotifier {
  final CampaignService _campaignService = ServiceLocator().campaignService;
  
  // ...
}
```

---

## 5. Testing Guidelines

### 🧪 Unit Tests mit Mock-Dependencies

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dungenmanager/services/inventory_service.dart';
import 'package:dungenmanager/models/inventory_item.dart';

// Generate mocks
@GenerateMocks([DatabaseHelper, UuidService])
import 'inventory_service_test.mocks.dart';

void main() {
  group('InventoryService Tests', () {
    late InventoryService service;
    late MockDatabaseHelper mockDb;
    late MockUuidService mockUuid;

    setUp(() {
      mockDb = MockDatabaseHelper();
      mockUuid = MockUuidService();
      service = InventoryService(
        dbHelper: mockDb,
        uuidService: mockUuid,
      );
    });

    test('loadInventory returns items correctly', () async {
      // Arrange
      final characterId = 'test-character';
      final expectedItems = [
        InventoryItem(id: '1', name: 'Sword', quantity: 1),
        InventoryItem(id: '2', name: 'Potion', quantity: 5),
      ];
      
      when(mockDb.getInventoryItems(characterId))
          .thenAnswer((_) async => expectedItems);

      // Act
      final result = await service.loadInventory(characterId);

      // Assert
      expect(result, equals(expectedItems));
      verify(mockDb.getInventoryItems(characterId)).called(1);
    });
  });
}
```

### 🔄 Integration Tests

```dart
void main() {
  group('Full Integration Tests', () {
    late DatabaseHelper dbHelper;
    late CampaignService campaignService;
    late QuestLibraryService questService;

    setUpAll(() async {
      // Use in-memory database for testing
      dbHelper = DatabaseHelper.instance;
      await dbHelper.initializeDatabase(inMemory: true);
      
      campaignService = CampaignService(dbHelper: dbHelper);
      questService = QuestLibraryService(dbHelper: dbHelper);
    });

    test('Complete campaign-quest workflow', () async {
      // Create campaign
      final campaign = Campaign(
        id: 'test-campaign',
        title: 'Test Campaign',
        description: 'Integration Test Campaign',
      );
      
      final createResult = await campaignService.createCampaign(campaign);
      expect(createResult.isSuccess, true);

      // Add quest to campaign
      final quest = Quest(
        id: 'test-quest',
        title: 'Test Quest',
        description: 'Integration Test Quest',
        campaignId: 'test-campaign',
      );
      
      final questResult = await questService.createQuest(quest);
      expect(questResult.isSuccess, true);

      // Verify data integrity
      final campaignResult = await campaignService.getCampaignById('test-campaign');
      expect(campaignResult.isSuccess, true);
      expect(campaignResult.data!.title, equals('Test Campaign'));
    });
  });
}
```

---

## 6. Error Handling & Escalation

### 🚨 Exception-Hierarchie

```dart
// Base Exception
abstract class DungenManagerException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  
  const DungenManagerException(this.message, {this.code, this.originalError});
}

// Specific Exception Types
class ValidationException extends DungenManagerException {
  final List<String> validationErrors;
  
  const ValidationException(
    super.message, {
    this.validationErrors = const [],
    super.code,
    super.originalError,
  });
}

class DatabaseException extends DungenManagerException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class BusinessException extends DungenManagerException {
  const BusinessException(
    super.message, {
    super.code,
    super.originalError,
  });
}

class ServiceUnavailableException extends DungenManagerException {
  const ServiceUnavailableException(
    super.message, {
    super.code,
    super.originalError,
  });
}
```

### 🔄 ServiceResult Pattern

```dart
class ServiceResult<T> {
  final T? data;
  final List<String> errors;
  final List<String> warnings;
  final bool isSuccess;

  const ServiceResult._({
    this.data,
    this.errors = const [],
    this.warnings = const [],
    required this.isSuccess,
  });

  factory ServiceResult.success(T data, {List<String> warnings = const []}) {
    return ServiceResult._(
      data: data,
      warnings: warnings,
      isSuccess: true,
    );
  }

  factory ServiceResult.failure(List<String> errors, {List<String> warnings = const []}) {
    return ServiceResult._(
      errors: errors,
      warnings: warnings,
      isSuccess: false,
    );
  }
}
```

### 📋 Error Handling Best Practices

```dart
// In Services
Future<ServiceResult<Campaign>> getCampaignById(String id) async {
  try {
    // Validation
    if (id.isEmpty) {
      return ServiceResult.failure(['Campaign ID cannot be empty']);
    }

    // Database operation
    final campaign = await _dbHelper.getCampaignById(id);
    if (campaign == null) {
      return ServiceResult.failure(['Campaign not found: $id']);
    }

    return ServiceResult.success(campaign);
  } on DatabaseException catch (e) {
    return ServiceResult.failure(['Database error: ${e.message}']);
  } catch (e) {
    return ServiceResult.failure(['Unexpected error: $e']);
  }
}

// In ViewModels
Future<void> loadCampaign(String id) async {
  setState(() => _isLoading = true);
  
  try {
    final result = await _campaignService.getCampaignById(id);
    
    if (result.isSuccess) {
      _campaign = result.data;
      _showSuccessSnackBar('Campaign loaded successfully');
    } else {
      _showErrorSnackBar('Failed to load campaign: ${result.errors.first}');
    }
  } catch (e) {
    _showErrorSnackBar('Unexpected error: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

---

## 7. Quick Reference Cards

### 🎯 Character Editor Specialist

| Benötigte Services | Initialisierung | Key Methods |
|-------------------|----------------|------------|
| `CharacterEditorService` | `CharacterEditorService()` | `getCharacterById()`, `saveCharacter()` |
| `InventoryService` | `InventoryService()` | `loadInventory()`, `addItem()` |
| `PlayerCharacterService` | Static | `serializeSkills()`, `deserializeSkills()` |

**Quick Start:**
```dart
final characterService = CharacterEditorService();
final inventoryService = InventoryService();

final character = await characterService.getCharacterById(characterId);
final inventory = await inventoryService.loadInventory(characterId);
```

---

### 📜 Quest Library Specialist

| Benötigte Services | Initialisierung | Key Methods |
|-------------------|----------------|------------|
| `QuestLibraryService` | `QuestLibraryService()` | `getAllQuests()`, `getQuestById()` |
| `QuestDataService` | Static | `parseQuestType()`, `serializeQuest()` |
| `QuestRewardService` | `QuestRewardService()` | `getQuestRewards()`, `addReward()` |

**Quick Start:**
```dart
final questService = QuestLibraryService();
final result = await questService.getAllQuests();
if (result.isSuccess) {
  final quests = result.data!;
}
```

---

### 📚 Wiki/Lore Keeper Specialist

| Benötigte Services | Initialisierung | Key Methods |
|-------------------|----------------|------------|
| `WikiEntryService` | `WikiEntryService()` | `getAllEntries()`, `getEntryById()` |
| `WikiLinkService` | `WikiLinkService()` | `getLinksForEntry()`, `createLink()` |
| `WikiSearchService` | `WikiSearchService()` | `searchEntries()`, `searchByTag()` |

**Quick Start:**
```dart
final wikiService = WikiEntryService();
final searchService = WikiSearchService();

final entries = await wikiService.getAllEntries();
final searchResults = await searchService.searchEntries(query);
```

---

### 🎵 Sound/Audio Specialist

| Benötigte Services | Initialisierung | Key Methods |
|-------------------|----------------|------------|
| `SoundLibraryService` | `SoundLibraryService()` | `getAllSounds()`, `getSoundById()` |
| `SceneSoundService` | `SceneSoundService()` | `getSoundsForScene()`, `addSoundToScene()` |

**Quick Start:**
```dart
final soundService = SoundLibraryService();
final result = await soundService.getAllSounds();
if (result.isSuccess) {
  final sounds = result.data!;
}
```

---

### 🏰 Campaign Manager Specialist

| Benötigte Services | Initialisierung | Key Methods |
|-------------------|----------------|------------|
| `CampaignService` | `CampaignService()` | `getCampaignsByStatus()`, `createCampaign()` |
| `SessionService` | `SessionService()` | `getSessionsForCampaign()`, `createSession()` |

**Quick Start:**
```dart
final campaignService = CampaignService();
final result = await campaignService.getCampaignsByStatus('active');
if (result.isSuccess) {
  final activeCampaigns = result.data!;
}
```

---

## 8. Migration Guides

### 🔄 Migration von Legacy Services

#### Schritt 1: Service-Instanziierung anpassen
```dart
// Vorher (Legacy)
final service = LegacyService();

// Nachher (Gold-Standard)
final service = ModernService(
  dbHelper: customDatabaseHelper, // Optional
  otherDependency: customOtherService, // Optional
);
```

#### Schritt 2: Error-Handling modernisieren
```dart
// Vorher (Legacy)
try {
  final data = await service.getData();
  return data;
} catch (e) {
  return null;
}

// Nachher (ServiceResult)
final result = await service.getData();
if (result.isSuccess) {
  return result.data;
} else {
  // Detaillierte Fehlerinformationen
  print('Errors: ${result.errors}');
  print('Warnings: ${result.warnings}');
  return null;
}
```

#### Schritt 3: Static Helpers korrekt verwenden
```dart
// Vorher (falls instanziiert)
final helper = HelperService();
final data = helper.parseSomething(input);

// Nachher (statisch)
final data = HelperService.parseSomething(input);
```

---

### 🚀 Performance-Optimierung

#### Dependency Injection Caching
```dart
class ServiceCache {
  static final Map<Type, dynamic> _cache = {};
  
  static T getService<T>() {
    return _cache.putIfAbsent(T, () => _createService<T>());
  }
  
  static T _createService<T>() {
    switch (T) {
      case CampaignService:
        return CampaignService() as T;
      case QuestLibraryService:
        return QuestLibraryService() as T;
      default:
        throw Exception('Service not registered: $T');
    }
  }
}

// Verwendung
final campaignService = ServiceCache.getService<CampaignService>();
```

#### Batch Operations
```dart
// Statt einzelner Aufrufe
for (final quest in quests) {
  await questService.updateQuest(quest);
}

// Batch Operation verwenden
await questService.updateQuestsBatch(quests);
```

---

## 📞 Support & Troubleshooting

### 🔍 Debugging Checklist

1. **Service Initialization:**
   - [ ] Dependencies korrekt injiziert?
   - [ ] Optional Dependencies mit Defaults versehen?
   - [ ] Static Methods korrekt aufgerufen?

2. **Error Handling:**
   - [ ] ServiceResult Pattern verwendet?
   - [ ] Spezifische Exceptions behandelt?
   - [ ] Error Messages an UI weitergegeben?

3. **Performance:**
   - [ ] Batch Operations wo möglich?
   - [ ] Service Caching implementiert?
   - [ ] Unnötige Datenbankaufrufe vermieden?

### 📚 Weitere Dokumentation

- **AI_CONSTITUTION.md** - Verbindliche Regeln und Protokolle
- **CODE_STANDARDS.md** - Architektonische Muster und Konventionen
- **AGENTEN_ACCESS_GUIDE.md** - Delegationssystem und Agenten-Routing
- **AGENTS_SERVICE_INTEGRATION_GUIDE.md** - Detaillierte Service-Integration

### 🚨 Eskalations-Protokoll

Bei Problemen mit System-Integration:

1. **Erster Versuch:** `debugging_error_specialist`
2. **Performance-Probleme:** `performance_error_specialist`
3. **Datenbank-Probleme:** `database_error_specialist`
4. **Kritische Systemprobleme:** `TPL_specialist`

---

**Diese Dokumentation ist verbindlich für alle Agenten und Spezialisten.**  
**Bei Abweichungen oder Fragen wende dich an den TPL_specialist.**

*Zuletzt aktualisiert: 8. November 2025*  
*Nächste Review: 8. Dezember 2025*
