# UnifiedCharacterInventoryWidget Dokumentation

## Übersicht

Das `UnifiedCharacterInventoryWidget` ist eine integrierte UI-Komponente, die Ausrüstung und Inventar in einer einzigen übersichtlichen Oberfläche vereint. Es wurde entwickelt, um das Inventar-Management für Characters zu vereinfachen und zu verbessern.

## Features

- ✅ **Integrierte Ausrüstungs- und Inventar-Sektion**: Alles in einer Ansicht
- ✅ **Kompakte Ausrüstungs-Slots**: Übersichtliche 5x3 Grid-Ansicht aller Equipment-Slots
- ✅ **Grid/List Toggle**: Wechsel zwischen Raster- und Listenansicht für das Inventar
- ✅ **Filter nach Item-Typ**: Schnelles Filtern nach Waffen, Rüstung, Tränken, etc.
- ✅ **Item-Details Panel**: Slide-in Panel mit detaillierten Item-Informationen
- ✅ **Gold-Anzeige**: Integrierte Währungs-Anzeige (Gold, Silber, Kupfer)
- ✅ **Konsistentes DnD Design**: Folgt dem DnDTheme für visuelle Konsistenz
- ✅ **Responsive**: Passt sich an verschiedene Bildschirmgrößen an

## Installation

```dart
import 'package:flutter/material.dart';
import '../widgets/ui_components/inventory/unified_character_inventory_widget.dart';
```

## Grundlegende Verwendung

```dart
UnifiedCharacterInventoryWidget(
  inventoryItems: viewModel.inventory,
  equipmentMap: viewModel.equipmentMap,
  gold: viewModel.gold,
  onEquipItem: (slot, displayItem) => viewModel.equipItem(slot, displayItem),
  onUnequipItem: (slot) => viewModel.unequipItem(slot),
  onAddItem: () => _addItemFromLibrary(),
  onDeleteItem: (displayItem) => viewModel.removeInventoryItem(displayItem.inventoryItem.id),
)
```

## API-Referenz

### Erforderliche Parameter

| Parameter | Typ | Beschreibung |
|-----------|------|-------------|
| `inventoryItems` | `List<DisplayInventoryItem>` | Liste aller Inventar-Items |
| `equipmentMap` | `Map<EquipmentSlot, DisplayInventoryItem?>` | Map der ausgerüsteten Items pro Slot |
| `gold` | `int` | Goldmenge des Characters |

### Optionale Parameter

| Parameter | Typ | Default | Beschreibung |
|-----------|------|---------|-------------|
| `silver` | `int?` | `null` | Silbermenge (optional) |
| `copper` | `int?` | `null` | Kupfermenge (optional) |
| `onEquipItem` | `Function(EquipmentSlot, DisplayInventoryItem)?` | `null` | Callback zum Ausrüsten eines Items |
| `onUnequipItem` | `Function(EquipmentSlot)?` | `null` | Callback zum Ablegen eines Items |
| `onAddItem` | `VoidCallback?` | `null` | Callback zum Hinzufügen eines neuen Items |
| `onDeleteItem` | `Function(DisplayInventoryItem)?` | `null` | Callback zum Löschen eines Items |
| `onUpdateQuantity` | `Function(DisplayInventoryItem, int)?` | `null` | Callback zum Aktualisieren der Menge |
| `showGold` | `bool` | `true` | Gold-Sektion anzeigen |
| `allowQuantityEdit` | `bool` | `false` | Mengen-Bearbeitung erlauben |
| `allowDelete` | `bool` | `true` | Löschen erlauben |
| `isEditable` | `bool` | `true` | Editier-Modus aktivieren |

## Verwendung mit EditPCViewModel

```dart
Widget _buildInventoryTab() {
  return Consumer<EditPCViewModel>(
    builder: (context, viewModel, child) {
      if (!viewModel.isEdit) {
        return _buildEmptyState();
      }

      return UnifiedCharacterInventoryWidget(
        inventoryItems: viewModel.inventory,
        equipmentMap: viewModel.equipmentMap,
        gold: viewModel.gold,
        silver: viewModel.silver,
        copper: viewModel.copper,
        onEquipItem: (slot, displayItem) async {
          try {
            await viewModel.equipItem(slot, displayItem);
            if (mounted) {
              SnackBarHelper.showSuccess(context, '${displayItem.item.name} ausgerüstet');
            }
          } catch (e) {
            if (mounted) {
              SnackBarHelper.showError(context, e.toString());
            }
          }
        },
        onUnequipItem: (slot) async {
          try {
            await viewModel.unequipItem(slot);
            if (mounted) {
              SnackBarHelper.showSuccess(context, 'Item abgelegt');
            }
          } catch (e) {
            if (mounted) {
              SnackBarHelper.showError(context, e.toString());
            }
          }
        },
        onAddItem: _addItemFromLibrary,
        onDeleteItem: (displayItem) async {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted) return;
          try {
            await viewModel.removeInventoryItem(displayItem.inventoryItem.id);
            if (mounted) {
              SnackBarHelper.showSuccess(context, '${displayItem.item.name} gelöscht');
            }
          } catch (e) {
            if (mounted) {
              SnackBarHelper.showError(context, 'Fehler beim Löschen: $e');
            }
          }
        },
      );
    },
  );
}

Future<void> _addItemFromLibrary() async {
  if (_viewModel.pcToEdit == null) {
    SnackBarHelper.showError(
      context,
      'Bitte speichere den Charakter zuerst, bevor du Gegenstände hinzufügst.'
    );
    return;
  }

  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => AddItemFromLibraryScreen(
          characterId: _viewModel.pcToEdit!.id,
        ),
      ),
    );
    if (mounted && _viewModel.pcToEdit != null) {
      await _viewModel.initialize(widget.campaignId, _viewModel.pcToEdit);
    }
  } catch (e) {
    if (mounted) {
      SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }
}
```

## Erweiterte Verwendung

### Nur Lesemodus (Read-Only)

```dart
UnifiedCharacterInventoryWidget(
  inventoryItems: viewModel.inventory,
  equipmentMap: viewModel.equipmentMap,
  gold: viewModel.gold,
  isEditable: false,
  allowDelete: false,
)
```

### Ohne Gold-Anzeige

```dart
UnifiedCharacterInventoryWidget(
  inventoryItems: viewModel.inventory,
  equipmentMap: viewModel.equipmentMap,
  gold: viewModel.gold,
  showGold: false,
)
```

### Mit Silber und Kupfer

```dart
UnifiedCharacterInventoryWidget(
  inventoryItems: viewModel.inventory,
  equipmentMap: viewModel.equipmentMap,
  gold: viewModel.gold,
  silver: viewModel.silver,
  copper: viewModel.copper,
)
```

## Design-Principles

### Konsistentes Dungeon-Design

Das Widget folgt strikt dem DnDTheme für visuelle Konsistenz:

- **Hintergrundfarben**: `DnDTheme.slateGrey`, `DnDTheme.stoneGrey`, `DnDTheme.dungeonBlack`
- **Akzentfarben**: `DnDTheme.ancientGold`, `DnDTheme.arcaneBlue`, `DnDTheme.mysticalPurple`
- **Textfarben**: `Colors.white`, `Colors.white70`, `Colors.white60`
- **Border Radius**: `DnDTheme.radiusMedium`, `DnDTheme.radiusSmall`, `DnDTheme.radiusLarge`
- **Spacing**: Konsistente Verwendung von `DnDTheme.xs`, `DnDTheme.sm`, `DnDTheme.md`, `DnDTheme.lg`, `DnDTheme.xl`

### Layout-Struktur

```
UnifiedCharacterInventoryWidget
├── Gold-Sektion (optional)
│   └── Währungs-Chips (Gold, Silber, Kupfer)
├── Ausrüstungs-Sektion
│   ├── Header (Icon + Titel + Equip-Count)
│   └── Compact Equipment Grid (5 Spalten)
│       └── 11 Equipment Slots
├── Inventar-Sektion
│   ├── Header (Icon + Titel + Item-Count + Actions)
│   ├── Filter-Chips (Alle + Item-Types)
│   └── Grid/List View
│       ├── Grid View (4 Spalten)
│       └── List View (Scrollable)
└── Detail-Panel (Slide-in)
    ├── Header (Close Button + Titel)
    └── Content
        ├── Item Header (Icon + Name + Type)
        ├── Item Info (Gewicht, Menge)
        ├── Beschreibung
        └── Actions (Ausrüsten, Löschen)
```

## Equipment-Slots

Das Widget unterstützt alle 11 Equipment-Slots:

| Slot | Icon | Beschreibung |
|------|------|-------------|
| `helmet` | 🛡️ | Helm |
| `armor` | 🛡️ | Rüstung |
| `shield` | 🛡️ | Schild |
| `weaponPrimary` | ⚔️ | Hauptwaffe |
| `weaponSecondary` | ⚔️ | Nebenwaffe |
| `gloves` | 🧤 | Handschuhe |
| `boots` | 👢 | Stiefel |
| `ring1` | ⭕ | Ring 1 |
| `ring2` | ⭕ | Ring 2 |
| `amulet` | 🏆 | Amulett |
| `cloak` | 🧥 | Umhang |

## Item-Typ Filter

Das Widget unterstützt Filter für alle Item-Typen:

- Alle
- Waffe (Weapon)
- Rüstung (Armor)
- Schild (Shield)
- Trank (Potion)
- Magisches Item (MagicItem)
- Werkzeug (Tool)
- Material (Material)
- Ausrüstung (AdventuringGear)

## Migration Guide

### Von separaten Tabs migrieren

**Vorher (zwei separate Tabs):**

```dart
// Tab 1: Inventar
UnifiedInventoryWidget(
  displayItems: viewModel.inventory,
  onAddItem: _addItemFromLibrary,
  onDeleteItem: _handleDelete,
)

// Tab 2: Ausrüstung
EquipmentWidget(
  equipment: viewModel.equipmentMap,
  onEquipItem: _handleEquip,
  onUnequipItem: _handleUnequip,
)
```

**Nachher (ein integrierter Tab):**

```dart
// Einziger Tab: Inventar & Ausrüstung
UnifiedCharacterInventoryWidget(
  inventoryItems: viewModel.inventory,
  equipmentMap: viewModel.equipmentMap,
  gold: viewModel.gold,
  onEquipItem: _handleEquip,
  onUnequipItem: _handleUnequip,
  onAddItem: _addItemFromLibrary,
  onDeleteItem: _handleDelete,
)
```

## Best Practices

### 1. Callbacks asynchron behandeln

```dart
onEquipItem: (slot, displayItem) async {
  try {
    await viewModel.equipItem(slot, displayItem);
    if (mounted) {
      SnackBarHelper.showSuccess(context, 'Erfolgreich ausgerüstet');
    }
  } catch (e) {
    if (mounted) {
      SnackBarHelper.showError(context, e.toString());
    }
  }
}
```

### 2. Mounted-Check verwenden

Verwende immer `if (mounted)` Checks in async Callbacks, um Fehler zu vermeiden:

```dart
onDeleteItem: (displayItem) async {
  await viewModel.removeItem(displayItem.inventoryItem.id);
  if (mounted) { // WICHTIG!
    SnackBarHelper.showSuccess(context, 'Item gelöscht');
  }
}
```

### 3. User Feedback geben

Gib dem Nutzer Feedback für alle Aktionen:

```dart
onEquipItem: (slot, displayItem) async {
  await viewModel.equipItem(slot, displayItem);
  if (mounted) {
    SnackBarHelper.showSuccess(context, '${displayItem.item.name} ausgerüstet');
  }
}
```

### 4. Validierung vor dem Hinzufügen

```dart
void _addItemFromLibrary() {
  if (_viewModel.pcToEdit == null) {
    SnackBarHelper.showError(
      context,
      'Bitte speichere den Charakter zuerst.'
    );
    return;
  }
  // ... Navigate to library
}
```

## Performance-Tipps

1. **Consumer verwenden**: Nutze `Consumer<EditPCViewModel>` für effiziente Rebuilds
2. **ShrinkWrap**: Das Widget verwendet automatisch `shrinkWrap: true` für verschachtelte Listen
3. **NeverScrollableScrollPhysics**: Verschachtelte Listen verwenden diese Physics für bessere Performance
4. **Lazy Loading**: Grid und List bauen Items on-demand auf

## Testing

### Widget-Test Beispiel

```dart
testWidgets('UnifiedCharacterInventoryWidget displays items correctly', (tester) async {
  final displayItems = [
    DisplayInventoryItem(
      inventoryItem: InventoryItem(
        id: '1',
        characterId: 'char1',
        itemId: 'item1',
        name: 'Test Item',
        quantity: 1,
      ),
      item: Item(
        id: 'item1',
        name: 'Test Item',
        itemType: ItemType.Weapon,
        weight: 5.0,
      ),
    ),
  ];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: UnifiedCharacterInventoryWidget(
          inventoryItems: displayItems,
          equipmentMap: {},
          gold: 100,
          onAddItem: () {},
          onDeleteItem: (_) {},
        ),
      ),
    ),
  );

  expect(find.text('Test Item'), findsOneWidget);
  expect(find.text('100'), findsOneWidget);
});
```

## Troubleshooting

### Items werden nicht angezeigt

**Problem**: Inventar ist leer, aber `inventoryItems` enthält Items.

**Lösung**: Überprüfe, ob die Items bereits ausgerüstet sind. Das Widget zeigt nur nicht-ausgerüstete Items an.

```dart
final equippedIds = equipmentMap.values
    .where((item) => item != null)
    .map((item) => item!.inventoryItem.id)
    .toSet();

final unequippedItems = inventoryItems
    .where((item) => !equippedIds.contains(item.inventoryItem.id))
    .toList();
```

### Callback wird nicht aufgerufen

**Problem**: `onEquipItem` oder andere Callbacks werden nicht aufgerufen.

**Lösung**: Überprüfe, ob `isEditable` auf `true` gesetzt ist und die Callbacks nicht `null` sind.

```dart
UnifiedCharacterInventoryWidget(
  isEditable: true, // WICHTIG!
  onEquipItem: (slot, item) => // ...
)
```

## Future Enhancements

Geplante Features für zukünftige Versionen:

- [ ] Drag&Drop zwischen Inventar und Ausrüstung
- [ ] Mengen-Editor direkt im Inventar
- [ ] Stapel-Management für gleiche Items
- [ ] Item-Vergleich (Vergleiche zwei Items)
- [ ] Quick-Equip (Doppelklick zum sofortigen Ausrüsten)
- [ ] Favoriten-System für häufig genutzte Items
- [ ] Benutzerdefinierte Filter

## Support

Bei Problemen oder Fragen:

1. Überprüfe die [DnDTheme](../../../theme/dnd_theme.dart) Konstanten
2. Konsultiere die [ItemColorHelper](../../character_editor/item_color_helper.dart) für Item-Icons
3. Review die [Equipment](../../../models/equipment.dart) Modelle
4. Schau dir die [Beispiele](#grundlegende-verwendung) an

## Version History

- **v1.0.0** (2026-02-08): Initiale Veröffentlichung
  - Integrierte Ausrüstungs- und Inventar-Sektion
  - Grid/List Toggle
  - Filter nach Item-Typ
  - Item-Details Panel
  - Gold-Anzeige
  - Konsistentes DnD Design

---

**Letztes Update**: 08.02.2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
