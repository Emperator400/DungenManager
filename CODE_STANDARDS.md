# DungenManager Code Standards

Dieses Dokument definiert die architektonischen Muster und Kodierungsstandards für den DungenManager. Alle Entwickler müssen sich strikt an diese Regeln halten.

## Inhaltsverzeichnis

1. [Projektarchitektur](#projektarchitektur)
2. [Datenfluss-Muster](#datenfluss-muster)
3. [File-Naming Konventionen](#file-naming-konventionen)
4. [Import-Reihenfolge](#import-reihenfolge)
5. [Service-Pattern](#service-pattern)
6. [UI-Pattern](#ui-pattern)
7. [Model-Pattern](#model-pattern)
8. [Widget-Pattern](#widget-pattern)
9. [Theme-Pattern](#theme-pattern)
10. [Error Handling](#error-handling)
11. [Performance-Best Practices](#performance-best-practices)

---

## Projektarchitektur

### Ordnerstruktur

```
lib/
├── models/              # Datenmodelle (immutable, fromMap/toMap)
├── screens/             # UI-Screens und Pages (StatefulWidget)
├── widgets/            # Wiederverwendbare UI-Komponenten (StatelessWidget)
├── services/           # Business-Logik (Singleton, keine UI-Imports)
├── database/           # Datenbank-Operationen (DatabaseHelper)
├── utils/              # Hilfsfunktionen und Utilities
├── theme/              # D&D Theme und Styling
└── main.dart           # App-Einstiegspunkt
```

### Core-Prinzipien

- **Trennung von Concerns:** UI vs Business-Logik vs Daten
- **Wiederverwendbarkeit:** Erstelle wiederverwendbare Widgets
- **Konsistenz:** Folge etablierten Patterns
- **Testbarkeit:** Schreibe testbaren Code

---

## Datenfluss-Muster

**STRICT EINZUHALTEN:**

```
UI Layer (Screen/Widget) 
    -> ruft -> 
Service Layer (Business Logic) 
    -> ruft -> 
Database Layer (DatabaseHelper) 
    -> interagiert mit -> 
Datenbank (SQLite)
```

### Beispiele

**✅ Korrekt:**
```dart
// Screen ruft Service
final result = await questService.getQuestById(questId);

// Service ruft DatabaseHelper
final quest = await dbHelper.getQuestById(questId);
```

**❌ Falsch:**
```dart
// Direkter Datenbankzugriff im UI
final quest = await dbHelper.getQuestById(questId); // VERBOTEN!
```

---

## File-Naming Konventionen

### Files (snake_case)

```
lib/screens/character_detail_screen.dart
lib/widgets/dnd_button_widget.dart
lib/services/quest_service.dart
lib/models/character.dart
```

### Klassen (PascalCase)

```dart
class CharacterDetailScreen extends StatefulWidget { }
class DndButtonWidget extends StatelessWidget { }
class QuestService { }
class Character { }
```

### Variablen & Methods (camelCase)

```dart
final String questTitle = 'Der verlorene Amulett';
final List<Quest> availableQuests = [];
void _loadQuestData() async { }
bool _isValidQuest() { }
```

### Private Members (camelCase mit _ Prefix)

```dart
String _privateVariable = '';
void _privateMethod() { }
class _PrivateClass { }
```

---

## Import-Reihenfolge

**STRICT EINZUHALTEN:**

1. **Dart Core** (dart:*)
2. **Externe Packages** (package:flutter/material.dart, etc.)
3. **Eigene Projekte** (absolute Pfade von lib/)

### Beispiel

```dart
// 1. Dart Core
import 'dart:async';
import 'dart:convert';

// 2. Externe Packages
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

// 3. Eigene Projekte (absolute Pfade)
import '../models/quest.dart';
import '../services/quest_service.dart';
import '../theme/dnd_theme.dart';
import '../widgets/quest_library/quest_card_widget.dart';
```

---

## Service-Pattern

**KEINE UI-IMPORTS IN SERVICES!**

### Struktur

```dart
class XxxService {
  // Singleton Pattern
  static final XxxService _instance = XxxService._internal();
  factory XxxService() => _instance;
  XxxService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Nur Business-Logik Methoden
  Future<List<Quest>> getAllQuests() async {
    try {
      final result = await _dbHelper.getAllQuests();
      return result;
    } catch (e) {
      throw Exception('Fehler beim Laden der Quests: $e');
    }
  }

  // Detaillierte Return-Maps
  Future<Map<String, dynamic>> distributeRewards(String questId) async {
    // Business Logic hier...
    return {
      'success': true,
      'distributedRewards': [...],
      'errors': [...],
    };
  }
}
```

### Service-Regeln

- ✅ **Nur Business-Logik**
- ✅ **Keine UI-Imports** (Material, Flutter Widgets, etc.)
- ✅ **Future-based Methods**
- ✅ **Detaillierte Error Handling**
- ✅ **Detaillierte Return-Maps**
- ❌ **Kein Scaffold, SnackBar, etc.**

---

## UI-Pattern

### Screen-Struktur

```dart
class XxxScreen extends StatefulWidget {
  // Konfigurations-Parameter
  final String questId;
  const XxxScreen({super.key, required this.questId});

  @override
  State<XxxScreen> createState() => _XxxScreenState();
}

class _XxxScreenState extends State<XxxScreen> {
  // 1. State-Variablen
  bool _isLoading = false;
  List<Quest> _quests = [];
  
  // 2. Controller
  late TextEditingController _titleController;
  
  // 3. Dependencies
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // 4. Async Methods mit try-catch
  Future<void> _initializeData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final quests = await _dbHelper.getAllQuests();
      if (mounted) {
        setState(() => _quests = quests);
      }
    } catch (e) {
      _showErrorSnackBar('Fehler: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 5. UI-Helper Methods
  Widget _buildQuestCard(Quest quest) {
    return QuestCardWidget(
      quest: quest,
      onTap: () => _onQuestTapped(quest),
    );
  }

  // 6. SnackBar Methods
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DnDTheme.errorRed,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DnDTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.mysticalPurple),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quest Übersicht'),
        backgroundColor: DnDTheme.stoneGrey,
      ),
      body: ListView.builder(
        itemCount: _quests.length,
        itemBuilder: (context, index) => _buildQuestCard(_quests[index]),
      ),
    );
  }
}
```

### UI-Regeln

- ✅ **_isLoading State** für Ladeindikatoren
- ✅ **mounted Checks** vor setState/Navigation
- ✅ **try-catch Blocks** für async Operationen
- ✅ **Standardisierte SnackBar Methods**
- ✅ **Controller Disposal** in dispose()
- ❌ **Keine direkten Datenbankzugriffe**
- ❌ **Keine hardcodierten Farben**

---

## Model-Pattern

### Struktur

```dart
class Quest {
  // 1. Final Fields
  final String id;
  final String title;
  final String description;
  final List<QuestReward> rewards;
  final DateTime createdAt;

  // 2. Konstruktor mit Defaults
  const Quest({
    required this.id,
    required this.title,
    required this.description,
    this.rewards = const [],
    required this.createdAt,
  });

  // 3. fromMap/toMap für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rewards': rewards.map((r) => r.toMap()).toList(),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      rewards: (map['rewards'] as List)
          .map((r) => QuestReward.fromMap(r))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  // 4. copyWith für Immutable Updates
  Quest copyWith({
    String? id,
    String? title,
    String? description,
    List<QuestReward>? rewards,
    DateTime? createdAt,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      rewards: rewards ?? this.rewards,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 5. Business-Logic Methods
  Quest addReward(QuestReward reward) {
    if (rewards.any((r) => r.id == reward.id)) return this;
    
    return copyWith(
      rewards: [...rewards, reward],
    );
  }

  // 6. Helper Properties
  bool get hasRewards => rewards.isNotEmpty;
  bool get isEmpty => title.isEmpty;

  // 7. Display-Properties
  String get displayTitle => title.isEmpty ? 'Unbenannte Quest' : title;
}
```

### Model-Regeln

- ✅ **Immutable mit final fields**
- ✅ **fromMap/toMap Methoden**
- ✅ **copyWith Methode**
- ✅ **Business-Logic Methods** (addXxx, removeXxx)
- ✅ **Helper Properties** (hasXxx, isEmpty)
- ✅ **Extension Methods für Enums**

---

## Widget-Pattern

### Struktur

```dart
class QuestCardWidget extends StatelessWidget {
  // 1. Konfigurierbare Parameter
  final Quest quest;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool isSelected;
  final Widget? customTrailing;

  const QuestCardWidget({
    super.key,
    required this.quest,
    this.onTap,
    this.onEdit,
    this.isSelected = false,
    this.customTrailing,
  });

  // 2. UI-Helper Methods
  Color _getDifficultyColor() {
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return Colors.green;
      case QuestDifficulty.medium:
        return Colors.yellow;
      // ...
    }
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DnDTheme.ancientGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DnDTheme.ancientGold),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: DnDTheme.ancientGold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget-Struktur hier...
            ],
          ),
        ),
      ),
    );
  }
}
```

### Widget-Regeln

- ✅ **StatelessWidget für wiederverwendbare Widgets**
- ✅ **Konfigurierbare Constructor-Parameter**
- ✅ **Callbacks für Parent-Communication**
- ✅ **Private UI-Helper Methods**
- ✅ **Exklusive DnDTheme Nutzung**
- ❌ **Kein direkter State in wiederverwendbaren Widgets**

---

## Theme-Pattern

**VERBOT VON HARDCODIERTEN FARBEN!**

### Exklusive DnDTheme Nutzung

```dart
// ✅ Korrekt
Container(
  color: DnDTheme.stoneGrey,
  child: Text(
    'Quest',
    style: TextStyle(
      color: DnDTheme.ancientGold,
      fontSize: 16,
    ),
  ),
)

// ❌ FALSCH
Container(
  color: Colors.grey[800], // HARDCODIERT!
  child: Text(
    'Quest',
    style: TextStyle(
      color: Colors.amber, // HARDCODIERT!
      fontSize: 16,
    ),
  ),
)
```

### Verfügbare Theme-Farben

```dart
// Aus DnDTheme
DnDTheme.stoneGrey        // Hintergründe, AppBars
DnDTheme.mysticalPurple   // Akzente, Buttons
DnDTheme.ancientGold      // Highlights, Rewards
DnDTheme.successGreen     // Erfolg, Validierung
DnDTheme.errorRed         // Fehler, Warnungen
```

---

## Error Handling

### Async Operations

```dart
Future<void> _loadData() async {
  try {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getData();
    setState(() => _data = data);
  } catch (e) {
    _showErrorSnackBar('Fehler beim Laden: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

### Validation

```dart
String? _validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Bitte einen Titel eingeben';
  }
  if (value.trim().length < 3) {
    return 'Titel muss mindestens 3 Zeichen haben';
  }
  return null;
}
```

---

## Performance-Best Practices

### ListView

```dart
// ✅ Korrekt für große Listen
ListView.builder(
  itemCount: quests.length,
  itemBuilder: (context, index) => QuestCardWidget(quest: quests[index]),
)

// ❌ Falsch für große Listen
Column(
  children: quests.map((quest) => QuestCardWidget(quest: quest)).toList(),
)
```

### Image Handling

```dart
// ✅ Korrekt
Image.network(
  imageUrl,
  width: 100,
  height: 100,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)
```

### State Management

```dart
// ✅ Einfache States
setState(() {
  _isSelected = !_isSelected;
});

// ✅ Komplexe States mit Zustandsklassen
class QuestScreenState {
  final bool isLoading;
  final List<Quest> quests;
  final String? error;
  
  const QuestScreenState({
    required this.isLoading,
    required this.quests,
    this.error,
  });
}
```

---

## Refactoring-Prioritäten

### Phase 3: Geleitetes Refactoring

1. **lib/models/** aufräumen
   - Konsistente fromMap/toMap Patterns
   - copyWith Methoden implementieren
   - Business-Logic Methods hinzufügen

2. **lib/services/** vereinheitlichen
   - UI-Import-Entfernung
   - Singleton-Pattern implementieren
   - Detaillierte Return-Maps erstellen

3. **lib/widgets/** extrahieren
   - DnDTheme-Konsistenz sicherstellen
   - Wiederverwendbarkeit verbessern
   - Konfigurierbare Parameter hinzufügen

4. **lib/screens/** bereinigen
   - State-Management Standardisierung
   - Error Handling vereinheitlichen
   - Import-Reihenfolge korrigieren

---

## Qualitätssicherung

### Vor jeder Code-Übermittlung

1. `flutter analyze` ausführen (keine errors/warnings)
2. `flutter test` ausführen (alle Tests grün)
3. CODE_STANDARDS.md geprüft
4. Review durch zweiten Entwickler

### Checklist für neue Dateien

- [ ] File-Naming Convention (snake_case)
- [ ] Import-Reihenfolge korrekt
- [ ] Keine hardcodierten Farben
- [ ] Proper Error Handling
- [ ] Documentation bei komplexer Logik
- [ ] Performance-Best Practices beachtet

---

**Diese Standards sind bindend für alle DungenManager Entwickler!**

Bei Fragen oder Unklarheiten kontaktiere den Lead-Entwickler.
