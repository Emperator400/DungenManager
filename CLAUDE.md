# CLAUDE.md — DungenManager

D&D 5e session-management app. Flutter · SQLite · Provider (MVVM). Target platforms: Windows, iOS, Android.

---

## Architecture

```
UI (Screens + Widgets)
        ↓
ViewModels (ChangeNotifier + Provider)
        ↓
Services (Business Logic)
        ↓
Repositories (ModelRepository<T>)
        ↓
Database (SQLite via sqflite — DatabaseConnection singleton)
```

---

## Key Patterns

### Repository Layer — `ModelRepository<T>`

Base class: `lib/database/repositories/model_repository.dart`

- `create(T model) → Future<T>` — always returns non-null
- `update(T model) → Future<T>` — always returns non-null
- `findById(String id) → Future<T?>` — nullable (not found = null)
- `findAll() → Future<List<T>>`

**Never** add null guards after `create()` or `update()` — they always return non-null.

Two repository variants exist per entity:
- `*_repository.dart` — legacy, Entity-based
- `*_model_repository.dart` — preferred, works directly with domain models

**Always prefer `*_model_repository.dart`** for new code.

Accessing `.id` on generic `T` inside `ModelRepository<T>` requires a dynamic cast — the static type system cannot resolve properties on unconstrained generics:
```dart
// Correct — required pattern for generic T access
final modelId = (model as dynamic).id;
final copy = (model as dynamic).copyWith(id: newId) as T;

// Wrong — compile error: 'id' can't be unconditionally accessed
final modelId = model.id;
```

### Service Layer — `ServiceResult<T>` + `performServiceOperation`

Some services (campaign, character editor, quest library, creature data) use a `ServiceResult<T>` wrapper:

```dart
// Pattern used in ~8 service files
Future<ServiceResult<T>> someOperation() async {
  return performServiceOperation(() async {
    // ... logic ...
    return result;
  });
}
```

Check `.isSuccess` and access `.data` on the result. Not all services use this pattern — direct exceptions and nullable returns also exist (known inconsistency, not worth unifying now).

### ViewModel Layer

- Extend `ChangeNotifier`
- Call `notifyListeners()` after state changes
- Call `dispose()` to release resources
- Use `mounted` check after any `await` before calling `setState` or `context`

### State Management in UI

```dart
// In main.dart — service locator + MultiProvider setup
Provider<SomeViewModel>(create: (_) => SomeViewModel(...))

// In widgets — consume
context.read<SomeViewModel>().doSomething();
context.watch<SomeViewModel>().someField;
Consumer<SomeViewModel>(builder: (context, vm, _) => ...)
```

---

## File Organization

```
lib/
├── main.dart                    # App entry, MultiProvider setup, kIsProductionMode flag
├── constants/                   # D&D combat values (global constants)
├── database/
│   ├── core/                    # DatabaseConnection (singleton), BaseEntity
│   ├── entities/                # SQLite entity classes (15 tables)
│   ├── migrations/              # database_migration.dart, refactoring_migration_v2.dart
│   ├── legacy/                  # Unused backup — do not modify
│   └── repositories/            # 16 repository classes (all *_model_repository.dart except creature_repository.dart)
├── models/                      # 36 pure Dart domain models, no Flutter dependencies
├── services/                    # 40 service classes (business logic)
├── viewmodels/                  # 23 ChangeNotifier ViewModels
├── screens/                     # 38 feature screens
├── widgets/
│   ├── character_editor/        # 23 widgets — largest widget module
│   ├── ui_components/           # 38 reusable components (cards, chips, states, stats...)
│   └── ...                      # feature-specific widget folders
├── theme/                       # DnDTheme, DnDIcons
├── utils/                       # 9 helpers (formatters, parsers)
└── game_data/                   # D&D 5e SRD data, demo data, importers
```

---

## Coding Conventions

### Naming Conventions

| Ebene | Stil | Beispiel |
|-------|------|---------|
| Dateien | `snake_case.dart` | `quest_library_screen.dart` |
| Klassen | `PascalCase` | `QuestLibraryScreen` |
| Variablen & Methoden | `camelCase` | `loadQuestData()` |
| Private Members | `_camelCase` | `_isLoading`, `_loadData()` |
| Konstanten | `camelCase` (Dart-üblich) | `kIsProductionMode` |

### Import Order

```dart
// 1. Dart core
import 'dart:async';

// 2. External packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 3. Own project (absolute paths from lib/)
import '../../models/item.dart';
import '../../services/item_service.dart';
```

### Null Safety

- Do NOT add null guards after `create()` / `update()` — they return non-null `T`
- Do NOT use `!` on non-nullable fields — check the model definition first
- Dart flow analysis narrows through `if (x != null)` and `if (isEquipped)` (bool variable set from null check), but NOT through `?.field == false` conditions
- When the analyzer warns "'!' will have no effect" inside a `?.field == false` block, verify with the compiler before removing — it may be a false positive

### Colors / Opacity

Always use `.withValues(alpha: x)` — never `.withOpacity(x)` (deprecated).

### Logging

Always use `debugPrint()` — never `print()`.

### Switch Statements on Enums

If all enum values are covered as cases, omit `default:` — it becomes unreachable dead code.

### Theme — No Hardcoded Colors

**Never** use `Colors.grey[800]`, `Colors.amber`, etc. Always use `DnDTheme.*`:

```dart
// Correct
Container(color: DnDTheme.stoneGrey)
Text('...', style: TextStyle(color: DnDTheme.ancientGold))

// Wrong
Container(color: Colors.grey[800])  // hardcoded!
```

Key `DnDTheme` colors:

| Name | Usage |
|------|-------|
| `DnDTheme.stoneGrey` | Backgrounds, AppBars |
| `DnDTheme.mysticalPurple` | Accents, buttons |
| `DnDTheme.ancientGold` | Highlights, rewards |
| `DnDTheme.successGreen` | Success feedback |
| `DnDTheme.errorRed` | Error feedback |

### Widget Guidelines

- Prefer `StatelessWidget` for reusable components — only use `StatefulWidget` when local state is truly needed
- Use callback parameters (`VoidCallback? onTap`, `void Function(T)? onChanged`) for parent communication — never navigate or call services directly from reusable widgets
- Use `ListView.builder` for lists with more than a few items — never `Column(children: items.map(...).toList())`

### Async in UI

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    final data = await _service.getData();
    if (mounted) setState(() => _data = data);
  } catch (e) {
    if (mounted) _showError('Fehler: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

## Adding a New Feature

1. **Model** — add to `lib/models/`, pure Dart, implement `toDatabaseMap()` / `fromDatabaseMap()` / `copyWith()`
2. **Migration** — add table creation to `database_migration.dart` or a new migration
3. **Repository** — create `lib/database/repositories/my_feature_model_repository.dart` extending `ModelRepository<MyModel>`
4. **Service** — create `lib/services/my_feature_service.dart`, inject repository via constructor
5. **ViewModel** — create `lib/viewmodels/my_feature_viewmodel.dart` extending `ChangeNotifier`, inject service
6. **Register** in `lib/main.dart` MultiProvider list
7. **Screen/Widget** — consume ViewModel via `Provider`/`Consumer`

---

## Static Analysis

**Target: zero warnings in `lib/`** (run `flutter analyze`).

Exception: `inference_failure_*` warnings (~210 remaining) — cosmetic, low priority, no action needed.

Categories already resolved (as of April 2026):
- `.withOpacity()` → `.withValues(alpha:)` — 401 locations fixed
- `print()` → `debugPrint()` — 696 locations fixed
- Unused fields, dead null-safety operators, unreachable code — all fixed

---

## Routing / Production Flag

```dart
// lib/main.dart
const bool kIsProductionMode = true;
```

When `true`, routes to the normal production UI. When `false`, routes to a debug/test screen. Do not change this unless intentionally switching modes.

---

## Large Files (Read in Sections)

These files exceed 1500 lines — use `offset` and `limit` parameters when reading:

| File | Lines | Notes |
|------|-------|-------|
| `lib/screens/scenes/edit_scene_screen.dart` | ~2152 | Scene editor |
| `lib/screens/session/active_session_screen.dart` | ~2026 | Active session UI |
| `lib/viewmodels/edit_creature_viewmodel.dart` | ~1800 | Creature editor state |
| `lib/widgets/character_editor/enhanced_inventory_tab_widget.dart` | ~1500+ | Inventory UI |

---

## Known Stale Areas

- `lib/database/legacy/` — unused backup file, do not modify
- `lib/screens/debug/` — developer tools, not production code
- TODOs in `lib/viewmodels/campaign_viewmodel.dart` — low priority cleanup items
- `lib/services/quest_lore_integration_service.dart` — service body is mostly commented out, a stub awaiting implementation

---

## Database Tables

| Table | Purpose |
|-------|---------|
| `campaigns` | Campaigns |
| `creatures` | Monsters + NPCs |
| `player_characters` | Player characters |
| `quests` | Quest library |
| `sessions` | Sessions per campaign |
| `scenes` | Scene templates |
| `sounds` | Sound files |
| `items` | Item library |
| `inventory_items` | Inventory entries (relation) |
| `encounters` | Encounter definitions |
| `encounter_participants` | Encounter participants |
| `wiki_entries` | Wiki articles |
| `wiki_links` | Wiki cross-references |
| `session_character_tracking` | HP/status per session |
| `session_quest_progress` | Quest progress per session |
