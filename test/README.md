# DungenManager Test-System Dokumentation

## Ziele und Aufgaben (Abgeschlossen)

✅ **Ziel 1: Analyse der bestehenden Teststruktur**
- 18 alte Testdateien analysiert und dokumentiert
- Probleme identifiziert: Inkonsistente Benennung, fehlende Struktur, doppelte Dateien

✅ **Ziel 2: Backup der alten Tests**
- Alle alten Testdateien in `test/legacy_tests/` verschoben
- Keine Daten verloren

✅ **Ziel 3: Neue Verzeichnisstruktur erstellen**
- Klare Trennung nach Testtypen: `unit/`, `integration/`, `widget/`
- Organisierte Struktur innerhalb jeder Kategorie

✅ **Ziel 4: Test-Helper-Module implementieren**
- `test/test_helpers/test_setup.dart` - Globales Setup und Teardown
- `test/test_helpers/mock_data_factory.dart` - Zentrale Mock-Daten-Generierung

✅ **Ziel 5: Mock-Daten-Factory erstellen**
- Factories für alle Hauptmodelle: Campaign, Character, Quest, Session, Sound, InventoryItem
- Einheitliche API für Mock-Daten-Erstellung

✅ **Ziel 6: README.md mit vollständiger Dokumentation schreiben**
- Diese Datei enthält die vollständige Architektur-Dokumentation
- KI-freundliches Format für automatische Testgenerierung

✅ **Ziel 7: Beispieltests für jede Kategorie erstellen**
- Unit Tests, Integration Tests und Widget Tests als Vorlagen
- Konkrete Beispiele für jede Testkategorie

✅ **Ziel 8: Alte Testdateien entfernen**
- Alte Dateien in `legacy_tests/` archiviert
- Platz für neue, strukturierte Tests geschaffen

---

## Architektur-Dokumentation

### Verzeichnisstruktur

```
test/
├── README.md                           # Diese Datei - Hauptdokumentation
├── test_helpers/                       # Wiederverwendbare Hilfsfunktionen
│   ├── test_setup.dart                # Globales Setup (Datenbank, etc.)
│   └── mock_data_factory.dart         # Mock-Daten-Generierung
├── unit/                              # Unit Tests
│   ├── models/                        # Model-Tests
│   ├── services/                      # Service-Tests
│   └── viewmodels/                    # ViewModel-Tests
├── integration/                       # Integration Tests
│   ├── database/                      # Datenbank-Integrationstests
│   ├── services/                      # Service-Integrationstests
│   └── workflows/                    # Workflow-Tests
├── widget/                            # Widget Tests
│   ├── screens/                       # Screen-Widget-Tests
│   └── widgets/                      # Komponenten-Widget-Tests
└── legacy_tests/                      # Archiv der alten Tests (Backup)
```

### Test-Kategorien

#### 1. Unit Tests
**Zweck**: Testen einzelne Klassen oder Funktionen isoliert ohne externe Abhängigkeiten.

**Verwendung**: Testen von Model-Logik, Hilfsfunktionen, reine Dart-Funktionen.

**Merkmale**:
- Keine Datenbankzugriffe
- Keine Netzwerkanfragen
- Schnelle Ausführung
- 100% isoliert

**Beispiel**: Testen von `Campaign.isValid`, Berechnungen, Validierungslogik.

#### 2. Integration Tests
**Zweck**: Testen die Zusammenarbeit mehrerer Komponenten.

**Verwendung**: Testen von Datenbank-Operationen, Service-Integration, komplexe Workflows.

**Merkmale**:
- Datenbankzugriffe möglich
- Service-Layer Integration
- Mittlere Ausführungszeit
- Testen echte Interaktionen

**Beispiel**: Testen des Campaign-ViewModels mit echter Datenbank, Workflow: Campaign erstellen → Character hinzufügen → Quest erstellen.

#### 3. Widget Tests
**Zweck**: Testen von Flutter UI-Widgets und Screens.

**Verwendung**: Testen von Widget-Rendering, User-Interaktionen, State-Updates.

**Merkmale**:
- Flutter Test Framework
- Widget-Rendering testen
- User-Interaktionen simulieren
- Visuelle Validierung

**Beispiel**: Testen des CampaignSelectionScreen, Button-Clicks, Formular-Eingaben.

---

## Test-Konventionen und Best Practices

### Dateibenennung

- **Format**: `[feature]_[component]_test.dart`
- **Beispiele**:
  - `campaign_model_test.dart` (Unit Test)
  - `campaign_viewmodel_integration_test.dart` (Integration Test)
  - `campaign_selection_screen_test.dart` (Widget Test)

### Teststruktur

Jede Testdatei folgt diesem Muster:

```dart
// 1. Externe Packages
import 'package:flutter_test/flutter_test.dart';

// 2. Eigene Projekte (absolute Pfade)
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/viewmodels/campaign_viewmodel.dart';

// 3. Test Helpers
import 'test_helpers/test_setup.dart';
import 'test_helpers/mock_data_factory.dart';

void main() {
  group('Feature Name', () {
    setUp(() async {
      // Setup Code - wird vor JEDEM Test ausgeführt
      await setUpTestDatabase();
      // Additional setup
    });
    
    tearDown(() {
      // Cleanup Code - wird nach JEDEM Test ausgeführt
      // Teardown logic
    });
    
    group('Sub-Feature 1', () {
      test('should do something specific', () async {
        // Arrange - Vorbereitung
        final campaign = MockDataFactory.campaign.create();
        
        // Act - Ausführung
        final result = campaign.isValid;
        
        // Assert - Überprüfung
        expect(result, true);
      });
      
      test('should handle edge case', () async {
        // Test code
      });
    });
    
    group('Sub-Feature 2', () {
      test('should do another thing', () async {
        // Test code
      });
    });
  });
}
```

### AAA Pattern (Arrange-Act-Assert)

Jeder Test sollte im AAA-Muster geschrieben werden:

1. **Arrange**: Vorbereitung der Testdaten und -umgebung
2. **Act**: Ausführung der zu testenden Funktionalität
3. **Assert**: Überprüfung der Ergebnisse

```dart
test('should validate campaign with empty title', () async {
  // Arrange
  final campaign = MockDataFactory.campaign.create(title: '');
  
  // Act
  final isValid = campaign.isValid;
  
  // Assert
  expect(isValid, false);
  expect(campaign.hasValidTitle, false);
});
```

### Testbenennung

- Verwende beschreibende Namen im Format: `should [erwartetes Verhalten] when [Bedingung]`
- Beispiele:
  - ✅ `should return true when campaign has valid data`
  - ✅ `should throw exception when title is empty`
  - ❌ `testCampaignValidation` (zu vage)
  - ❌ `test1`, `test2` (nicht beschreibend)

### Setup und Teardown

**Setup (setUp)**:
- Initialisiere die Testdatenbank: `await setUpTestDatabase()`
- Erstelle Mock-Daten mit Factories
- Setze Services zurück falls nötig

**Teardown (tearDown)**:
- Schließe Verbindungen
- Lösche temporäre Daten
- Setze globale Zustände zurück

---

## Test-Helper Referenz

### test_setup.dart

```dart
// Initialisiert die SQLite FFI Datenbank für Tests
await initializeTestDatabase();

// Standard Test Setup
await setUpTestDatabase();

// Standard Test Teardown
await tearDownTestDatabase();

// Prüft ob Datenbank initialisiert ist
bool isInitialized = isDatabaseInitialized;

// Setzt Initialisierungsstatus zurück
resetDatabaseInitializationStatus();
```

### mock_data_factory.dart

#### Campaign Factory
```dart
// Import als Alias vermeidet Konflikte
import 'package:dungen_manager/test_helpers/mock_data_factory.dart' as mock;

// Standard Mock Campaign
final campaign = mock.MockCampaignFactory.create();

// Mit benutzerdefinierten Werten
final customCampaign = mock.MockCampaignFactory.create(
  title: 'Custom Campaign',
  status: CampaignStatus.active,
);

// Liste von Campaigns erstellen
final campaigns = mock.MockCampaignFactory.createList(5);

// Vordefinierte Szenarien
final activeCampaign = mock.MockCampaignFactory.createActive();
final completedCampaign = mock.MockCampaignFactory.createCompleted();
```

#### Character Factory
```dart
import 'package:dungen_manager/test_helpers/mock_data_factory.dart' as mock;

// Standard Mock Character
final character = mock.MockCharacterFactory.create();

// Mit benutzerdefinierten Werten
final customCharacter = mock.MockCharacterFactory.create(
  name: 'Hero',
  level: 5,
  strength: 18,
);

// Liste von Characters erstellen
final characters = mock.MockCharacterFactory.createList(3);

// High-Level Character
final highLevelChar = mock.MockCharacterFactory.createHighLevel();
```

#### Quest Factory
```dart
import 'package:dungen_manager/test_helpers/mock_data_factory.dart' as mock;

// Standard Mock Quest
final quest = mock.MockQuestFactory.create();

// Mit benutzerdefinierten Werten
final customQuest = mock.MockQuestFactory.create(
  title: 'Save Village',
  status: QuestStatus.completed,
);

// Liste von Quests erstellen
final quests = mock.MockQuestFactory.createList(5);
```

#### Session Factory
```dart
import 'package:dungen_manager/test_helpers/mock_data_factory.dart' as mock;

// Standard Mock Session
final session = mock.MockSessionFactory.create();

// Mit benutzerdefinierten Werten
final customSession = mock.MockSessionFactory.create(
  title: 'Session 1',
  inGameTimeInMinutes: 600,
);
```

#### Sound Factory
```dart
import 'package:dungen_manager/test_helpers/mock_data_factory.dart' as mock;

// Standard Mock Sound
final sound = mock.MockSoundFactory.create();

// Mit benutzerdefinierten Werten
final customSound = mock.MockSoundFactory.create(
  name: 'Battle Music',
  soundType: SoundType.Effekt,
);
```

#### InventoryItem Factory
```dart
import 'package:dungen_manager/test_helpers/mock_data_factory.dart' as mock;

// Standard Mock InventoryItem
final item = mock.MockInventoryItemFactory.create();

// Mit benutzerdefinierten Werten
final customItem = mock.MockInventoryItemFactory.create(
  name: 'Sword',
  characterId: 'char-123',
  quantity: 2,
);
```

---

## Beispieltests

### Unit Test Beispiel

**Datei**: `test/unit/models/campaign_model_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/test_helpers/mock_data_factory.dart';

void main() {
  group('Campaign Model Tests', () {
    group('Creation', () {
      test('should create valid campaign with factory', () {
        // Arrange
        final campaign = MockDataFactory.campaign.create(
          title: 'Test Campaign',
          description: 'Test Description',
        );
        
        // Act & Assert
        expect(campaign.title, 'Test Campaign');
        expect(campaign.description, 'Test Description');
        expect(campaign.id, isNotNull);
        expect(campaign.status, CampaignStatus.planning);
      });
      
      test('should be invalid with empty title', () {
        // Arrange
        final campaign = MockDataFactory.campaign.create(title: '');
        
        // Act & Assert
        expect(campaign.hasValidTitle, false);
        expect(campaign.isValid, false);
      });
    });
    
    group('Status Management', () {
      test('should change status correctly', () {
        // Arrange
        final campaign = MockDataFactory.campaign.create();
        
        // Act
        final updated = campaign.copyWith(status: CampaignStatus.active);
        
        // Assert
        expect(updated.status, CampaignStatus.active);
      });
    });
  });
}
```

### Integration Test Beispiel

**Datei**: `test/integration/services/campaign_service_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/services/campaign_service.dart';
import 'package:dungen_manager/test_helpers/test_setup.dart';
import 'package:dungen_manager/test_helpers/mock_data_factory.dart';

void main() {
  group('Campaign Service Integration Tests', () {
    late CampaignService service;
    
    setUp(() async {
      await setUpTestDatabase();
      service = CampaignService();
    });
    
    tearDown(() async {
      await tearDownTestDatabase();
    });
    
    group('Create Campaign', () {
      test('should save campaign to database', () async {
        // Arrange
        final campaign = MockDataFactory.campaign.create(
          title: 'New Campaign',
        );
        
        // Act
        await service.createCampaign(campaign);
        final retrieved = await service.getCampaign(campaign.id);
        
        // Assert
        expect(retrieved, isNotNull);
        expect(retrieved?.title, 'New Campaign');
      });
      
      test('should throw error with duplicate title', () async {
        // Arrange
        final campaign = MockDataFactory.campaign.create(
          title: 'Duplicate Campaign',
        );
        await service.createCampaign(campaign);
        
        // Act & Assert
        expect(
          () => service.createCampaign(campaign),
          throwsA(isA<DatabaseException>()),
        );
      });
    });
  });
}
```

### Widget Test Beispiel

**Datei**: `test/widget/screens/campaign_selection_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dungen_manager/screens/campaign_selection_screen.dart';
import 'package:dungen_manager/viewmodels/campaign_viewmodel.dart';
import 'package:dungen_manager/test_helpers/test_setup.dart';
import 'package:dungen_manager/test_helpers/mock_data_factory.dart';

void main() {
  group('CampaignSelectionScreen Widget Tests', () {
    setUp(() async {
      await setUpTestDatabase();
    });
    
    testWidgets('should display campaign list', (tester) async {
      // Arrange
      final mockCampaigns = MockDataFactory.campaign.createList(3);
      final viewModel = CampaignViewModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: CampaignSelectionScreen(),
          ),
        ),
      );
      
      // Act
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Campaign Selection'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
    });
    
    testWidgets('should show empty state when no campaigns', (tester) async {
      // Arrange
      final viewModel = CampaignViewModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: CampaignSelectionScreen(),
          ),
        ),
      );
      
      // Act
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('No campaigns yet'), findsOneWidget);
    });
  });
}
```

---

## Anleitung für Coding-KI

Wenn du neue Tests generieren sollst, befolge diese Schritte:

1. **Bestimme die Testkategorie**:
   - Unit Test → `test/unit/`
   - Integration Test → `test/integration/`
   - Widget Test → `test/widget/`

2. **Verwende die korrekte Dateistruktur**:
   - Importiere immer Test-Helper: `import 'test_helpers/test_setup.dart';` und `import 'test_helpers/mock_data_factory.dart';`
   - Verwende MockDataFactory für Testdaten

3. **Befolge das AAA-Muster**:
   - Arrange: Testdaten mit Factories erstellen
   - Act: Funktion ausführen
   - Assert: Ergebnisse mit `expect()` überprüfen

4. **Nutze Gruppen für Organisation**:
   - Oberste Gruppe: Feature-Name
   - Untergeordnete Gruppen: Sub-Features
   - Tests: Einzeln beschrieben

5. **Füge Setup/Teardown hinzu** wenn nötig:
   - Integration Tests immer mit `await setUpTestDatabase()`
   - Widget Tests mit Provider-Setup

6. **Schreibe beschreibende Testnamen**:
   - Format: `should [erwartetes Verhalten] when [Bedingung]`

---

## Häufige Test-Szenarien

### Validierung testen
```dart
test('should validate required fields', () async {
  final model = MockDataFactory.campaign.create(title: '');
  expect(model.isValid, false);
});
```

### Liste filtern testen
```dart
test('should filter campaigns by search query', () async {
  final campaigns = MockDataFactory.campaign.createList(5);
  final filtered = campaigns.where((c) => c.title.contains('Test')).toList();
  expect(filtered, isNotEmpty);
});
```

### State-Änderung testen
```dart
test('should update state when action is performed', () async {
  final viewModel = CampaignViewModel();
  await viewModel.loadCampaigns();
  expect(viewModel.isLoading, false);
});
```

### Fehlerbehandlung testen
```dart
test('should handle null values gracefully', () async {
  expect(() => Service().process(null), throwsA(isA<ArgumentError>()));
});
```

---

## Ausführen von Tests

### Alle Tests ausführen
```bash
flutter test
```

### Spezifische Testdatei
```bash
flutter test test/unit/models/campaign_model_test.dart
```

### Tests mit Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Integration Tests
```bash
flutter test integration_test/
```

---

## Wartung und Best Practices

1. **Regelmäßig aktualisieren**: Wenn Models sich ändern, Factories anpassen
2. **Testdaten isolieren**: Keine Abhängigkeiten zwischen Tests
3. **Schnell bleiben**: Unit Tests sollten < 100ms dauern
4. **Aussagekräftig**: Tests sollten wie Dokumentation funktionieren
5. **Refaktorierbar**: Änderungen sollten nur wenige Tests beeinflussen

---

## Weiterführende Ressourcen

- [Flutter Testing Documentation](https://docs.flutter.dev/cookbook/testing)
- [Flutter Test Package](https://pub.dev/packages/flutter_test)
- [Mockito Package](https://pub.dev/packages/mockito) für komplexe Mocks

---

**Letzte Aktualisierung**: 14.02.2026
**Version**: 1.0.0
**Status**: ✅ Alle Ziele erreicht