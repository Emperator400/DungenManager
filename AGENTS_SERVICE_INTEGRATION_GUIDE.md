# Agents Service Integration Guide

**Datum:** 11. November 2025  
**Spezialist:** Debugging Error Specialist  
**Zweck:** Anleitung für Agenten zur Nutzung der standardisierten Services

---

## **🎯 Überblick**

Die Services wurden erfolgreich gemäß dem `character_editor_service` Muster standardisiert. Diese Anleitung zeigt allen Agenten, wie sie die neuen Service-Interfaces korrekt verwenden können.

---

## **📋 Service-Kategorien und Nutzung**

### **🟢 Kategorie A: Gold-Standard Services**

Diese Services bieten die fortschrittlichsten Features mit Dependency Injection und standardisiertem Error-Handling.

#### **campaign_service.dart**
```dart
// Richtige Initialisierung mit Dependency Injection
final campaignService = CampaignService(
  dbHelper: customDatabaseHelper, // Optional
  questService: customQuestService, // Optional
);

// Verwendung mit ServiceResult Pattern
final result = await campaignService.getCampaignsByStatus('active');
if (result.isSuccess) {
  final campaigns = result.data!;
} else {
  print('Fehler: ${result.errors.first}');
}
```

#### **quest_library_service.dart**
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

#### **inventory_service.dart** (NEU standardisiert)
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

---

### **🟡 Kategorie B: Static Helper Services**

Diese Services bieten statische Helper-Funktionen für Datenverarbeitung und Serialisierung.

#### **quest_data_service.dart** (Standardisiert)
```dart
// Statische Methoden - keine Instanz nötig
final questType = QuestDataService.parseQuestType(questTypeString);
final difficulty = QuestDataService.parseDifficulty(difficultyString);
final rewards = QuestDataService.parseRewards(rewardsData);

// Serialisierung für Datenbank
final serializedRewards = QuestDataService.serializeRewards(rewardsList);
```

#### **player_character_service.dart** (Standardisiert)
```dart
// Statische Serialisierungsfunktionen
final serializedSkills = PlayerCharacterService.serializeSkills(skillsList);
final skills = PlayerCharacterService.deserializeSkills(skillsString);

// Validierung
final isValid = PlayerCharacterService.isValidPlayerCharacter(character);

// Formatierung
final formatted = PlayerCharacterService.formatPlayerCharacter(character);
```

---

### **🔴 Kategorie C: Noch zu standardisieren**

Diese Services benötigen noch die volle Standardisierung.

#### **quest_lore_integration_service.dart**
```dart
// Aktuell noch altes Pattern (TODO: Standardisierung)
final service = QuestLoreIntegrationService();
final result = await service.linkQuestToLore(questId, loreEntryId);
```

#### **quest_reward_service.dart**
```dart
// Aktuell noch altes Pattern (TODO: Standardisierung)
final service = QuestRewardService();
final rewards = await service.getQuestRewards(questId);
```

---

## **🔧 ViewModel Integration Patterns**

### **Standard Dependency Injection Pattern**
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

---

## **🚀 Best Practices für Agenten**

### **1. Immer Dependency Injection verwenden**
```dart
// ❌ Schlecht (Hard-coded Dependencies)
final service = MyService(DatabaseHelper.instance);

// ✅ Gut (Dependency Injection)
final service = MyService(
  dbHelper: customDatabaseHelper,
  otherDependency: customOtherService,
);
```

### **2. ServiceResult Pattern nutzen**
```dart
// ❌ Schlecht (Manuelles Error-Handling)
try {
  final data = await service.getData();
  return data;
} catch (e) {
  return null;
}

// ✅ Gut (ServiceResult Pattern)
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

### **3. Spezifische Exceptions behandeln**
```dart
try {
  final result = await service.operation();
} on ValidationException catch (e) {
  // Handle Validierungsfehler
  print('Validation failed: ${e.validationErrors}');
} on DatabaseException catch (e) {
  // Handle Datenbankfehler
  print('Database error: ${e.message}');
} on BusinessException catch (e) {
  // Handle Business-Logic Fehler
  print('Business rule violated: ${e.message}');
}
```

---

## **🔄 Migration Guide für bestehende Agenten**

### **Schritt 1: Service-Instanziierung anpassen**
```dart
// Vorher
final inventoryService = InventoryService();

// Nachher
final inventoryService = InventoryService(
  dbHelper: customDatabaseHelper, // Optional
  uuidService: customUuidService, // Optional
);
```

### **Schritt 2: Error-Handling modernisieren**
```dart
// Vorher
try {
  final inventory = await inventoryService.loadInventory(id);
} catch (e) {
  print('Error: $e');
}

// Nachher
final inventory = await inventoryService.loadInventory(id);
// Error-Handling wird bereits im Service gemacht
```

### **Schritt 3: Static Helpers korrekt verwenden**
```dart
// Vorher (falls instanziiert)
final questDataService = QuestDataService();
final type = questDataService.parseQuestType(data);

// Nachher (statisch)
final type = QuestDataService.parseQuestType(data);
```

---

## **📊 Testing mit standardisierten Services**

### **Unit Tests mit Mock-Dependencies**
```dart
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockUuidService extends Mock implements UuidService {}

test('InventoryService loads inventory correctly', () async {
  final mockDb = MockDatabaseHelper();
  final mockUuid = MockUuidService();
  
  final service = InventoryService(
    dbHelper: mockDb,
    uuidService: mockUuid,
  );
  
  // Test-Logik
});
```

### **Integration Tests**
```dart
test('Full inventory workflow', () async {
  final service = InventoryService();
  
  // Teste mit echten Dependencies
  final inventory = await service.loadInventory(testCharacterId);
  expect(inventory, isNotNull);
});
```

---

## **⚠️ Wichtige Hinweise**

### **Breaking Changes vermieden**
- Die externe API der Services bleibt `Future<T>` kompatibel
- ViewModels müssen nicht sofort umgestellt werden
- Graduelle Migration ist möglich

### **Hybrid Pattern**
- Services verwenden intern `performServiceOperation<T>()`
- Externe API bleibt für Kompatibilität
- Zukünftige Migration zu `ServiceResult<T>` geplant

### **Performance**
- Dependency Injection hat keine Performance-Nachteile
- Standardisiertes Error-Handling ist effizient
- Static Helpers sind optimal für Datenverarbeitung

---

## **🎯 Nächste Schritte für Agenten**

1. **Dokumentation lesen:** SERVICES_STANDARDIZATION_REPORT.md
2. **Eigenen Code prüfen:** Verwendet ihr die neuen Patterns?
3. **Tests anpassen:** Mock-Dependencies für Unit Tests
4. **Migration planen:** Alte Code schrittweise modernisieren
5. **Feedback geben:** Issues oder Verbesserungen melden

---

## **📞 Support**

Bei Fragen zur Service-Integration:
1. **Dokumentation prüfen:** SERVICES_STANDARDIZATION_REPORT.md
2. **Beispiele ansehen:** character_editor_viewmodel.dart
3. **Pattern Guide konsultieren:** AGENTS_SERVICE_INTEGRATION_GUIDE.md
4. **Issue erstellen:** Bei spezifischen Problemen

---

**Guide erstellt von:** Debugging Error Specialist  
**Zuletzt aktualisiert:** 11. November 2025  
**Version:** 1.0
