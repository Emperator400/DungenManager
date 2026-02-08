# Inventory UI Components

Wiederverwendbare Inventar-Widgets für D&D 5e Character Management.

## Inhaltsverzeichnis

- [InventoryListWidget](#inventorylistwidget)
- [Verwendung](#verwendung)
- [Beispiele](#beispiele)
- [Design-Principles](#design-principles)

---

## InventoryListWidget

Ein einfaches, wiederverwendbares Widget für Inventar-Listen im Dungeon-Stil.

### Features

- ✅ **Inventar-Liste**: Zeigt alle Items übersichtlich als Card-Liste an
- ✅ **Dungeon-Stil**: Konsistentes Design mit DnDTheme
- ✅ **Editierbar**: Optionale Bearbeiten- und Löschen-Funktionen
- ✅ **Empty State**: Automatische Anzeige bei leeren Inventaren
- ✅ **Durability**: Anzeige von Haltbarkeitsbalken (falls vorhanden)
- ✅ **Quantity**: Anzeige der Item-Menge (bei quantity > 1)
- ✅ **Item-Icons**: Typspezifische Icons mit Farbkodierung

### Design

**Konsistente Dungeon-Farben:**
- Karten-Hintergrund: `DnDTheme.slateGrey`
- Icon-Hintergrund: `DnDTheme.arcaneBlue`
- Quantity-Badge: `DnDTheme.ancientGold`
- Delete-Button: `DnDTheme.errorRed`
- Edit-Button: `DnDTheme.arcaneBlue`

**Typography:**
- Titel: `DnDTheme.bodyText1` (fett, weiß)
- Beschreibung: `DnDTheme.bodyText2` (grau)
- Dialog-Titel: `DnDTheme.headline2` (ancientGold)

**Shapes:**
- Card-Radius: `DnDTheme.radiusMedium`
- Badge-Radius: `DnDTheme.radiusSmall`

---

## Verwendung

### Grundlegende Implementierung

```dart
import 'package:flutter/material.dart';
import '../../widgets/ui_components/inventory/inventory_list_widget.dart';

class MyInventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InventoryListWidget(
      items: viewModel.displayInventory,
      onItemTap: (displayItem) {
        // Handle Item-Tap
        print('Item tapped: ${displayItem.item.name}');
      },
      onItemEdit: (displayItem) {
        // Handle Item-Bearbeitung
        _showEditDialog(displayItem);
      },
      onItemDelete: (displayItem) {
        // Handle Item-Löschung
        viewModel.removeItem(displayItem);
      },
      isEditable: true,
    );
  }
}
```

### Read-Only Modus

```dart
InventoryListWidget(
  items: viewModel.displayInventory,
  onItemTap: (displayItem) {
    // Nur Taps erlaubt, kein Editieren
  },
  isEditable: false,
)
```

### Custom Empty State

```dart
InventoryListWidget(
  items: [],
  emptyTitle: 'Noch kein Loot!',
  emptySubtitle: 'Kehre siegreich aus dem Dungeon zurück',
  showEmptyState: true,
)
```

---

## Beispiele

### EnhancedEditCreatureScreen Integration

```dart
SectionCardWidget(
  title: 'Inventar',
  icon: Icons.inventory_2,
  child: InventoryListWidget(
    items: viewModel.displayInventory,
    onItemTap: (displayItem) {
      // Zeige Item-Details
    },
    onItemDelete: (displayItem) async {
      await viewModel.removeInventoryItem(displayItem.inventoryItem.id);
    },
    isEditable: viewModel.isEditable,
  ),
)
```

### EnhancedEditPcScreen Integration (geplant)

```dart
SectionCardWidget(
  title: 'Inventar',
  icon: Icons.inventory_2,
  child: InventoryListWidget(
    items: viewModel.displayInventory,
    onItemTap: (displayItem) {
      // Navigiere zu Item-Details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedEditItemScreen(
            displayItem: displayItem,
          ),
        ),
      );
    },
    onItemEdit: (displayItem) {
      // Öffne Item-Editor
    },
    onItemDelete: (displayItem) {
      // Lösche Item
    },
    isEditable: true,
  ),
)
```

---

## Design-Principles

### 1. Konsistentes Design

Alle Inventar-Components folgen dem Dungeon-Design-System:

- **Farbschema**: SlateGrey, StoneGrey, AncientGold, ArcaneBlue
- **Typography**: DnDTheme.bodyText1, DnDTheme.bodyText2, DnDTheme.headline2
- **Shapes**: DnDTheme.radiusMedium, DnDTheme.radiusSmall
- **Spacing**: Konsistente Abstände (xs, sm, md, lg, xl)

### 2. Wiederverwendbarkeit

Das Widget ist:
- **Unabhängig**: Keine direkten Datenbank-Zugriffe
- **Testbar**: Pure Widget mit klaren Interfaces
- **Erweiterbar**: Easy zu kustomisieren

### 3. UX-Best Practices

- **Schnelle Aktionen**: Direkte Edit/Delete Buttons
- **Feedback**: Konfirmationsdialog vor Löschen
- **Empty States**: Hilfreiche Hinweise bei leeren Listen
- **Durability**: Visuelle Indikatoren für Haltbarkeit

---

## Advanced Usage

### Custom Quantity Handling

```dart
InventoryListWidget(
  items: items,
  onItemTap: (displayItem) {
    if (displayItem.inventoryItem.quantity > 1) {
      _showQuantityDialog(displayItem);
    } else {
      _showItemDetails(displayItem);
    }
  },
)
```

### Durability Warning

Das Widget zeigt automatisch einen Durability-Balken an, wenn:

```dart
item.hasDurability == true &&
displayItem.currentDurability != null
```

Die Farben werden automatisch basierend auf dem Haltbarkeits-Status berechnet:
- > 75%: Grün
- 50-75%: Gelb
- 25-50%: Orange
- < 25%: Rot

---

## Unterschied zu EnhancedInventoryGridWidget

| Feature | InventoryListWidget | EnhancedInventoryGridWidget |
|---------|-------------------|---------------------------|
| **Komplexität** | Einfach | Komplex |
| **Layout** | Liste | Grid + Slots |
| **Drag&Drop** | Nein | Ja |
| **Ausrüstung** | Nein | Ja (Slots) |
| **Anwendung** | Kreaturen, NPC | Player Characters |
| **Stil** | Dungeon-konsistent | Character-Editor spezifisch |

### Wann welches Widget verwenden?

**InventoryListWidget verwenden für:**
- Kreaturen-Monster
- NPCs
- Einfache Inventar-Ansichten
- Lesemodus

**EnhancedInventoryGridWidget verwenden für:**
- Player Characters
- Volle Ausrüstungs-Management
- Drag&Drop benötigt
- Komplexe Inventar-Systeme

---

## Migration Guide

### Vom alten Inventar-Widget migrieren

**Vorher:**
```dart
// Altes, nicht wiederverwendbares Widget
_buildInventorySection() {
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return Card(
        color: Colors.grey.shade800,
        child: ListTile(
          title: Text(item.name),
          // ...
        ),
      );
    },
  );
}
```

**Nachher:**
```dart
// Neues, wiederverwendbares Widget
InventoryListWidget(
  items: displayItems,
  onItemTap: (displayItem) => // Handle Tap
  onItemDelete: (displayItem) => // Handle Delete
  isEditable: true,
)
```

---

## Performance Tips

1. **ShrinkWrap**: Nutze `shrinkWrap: true` für flexible Layouts
2. **Physics**: `NeverScrollableScrollPhysics` für verschachtelte Listen
3. **Lazy Loading**: Widget baut Liste on-demand auf
4. **Rebuilds**: Nur bei Datenänderungen rebuilden

---

## Testing

### Widget-Test Beispiel

```dart
testWidgets('InventoryListWidget shows items correctly', (tester) async {
  final items = [
    DisplayInventoryItem(
      inventoryItem: InventoryItem(...),
      item: Item(name: 'Test Item', ...),
    ),
  ];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: InventoryListWidget(
          items: items,
          onItemTap: (_) {},
        ),
      ),
    ),
  );

  expect(find.text('Test Item'), findsOneWidget);
});
```

---

## Future Enhancements

Geplante Features für zukünftige Versionen:

- [ ] Filter nach Item-Typ
- [ ] Sortier-Optionen
- [ ] Batch-Operationen
- [ ] Drag&Drop Support
- [ ] Animationen für Item-Add/Remove
- [ ] Custom Item-Cards
- [ ] Grid-Layout Option

---

## Contributing

Beim Hinzufügen neuer Inventar-Components:

1. ✅ Konsistentes Dungeon-Design nutzen
2. ✅ DnDTheme für alle Farben/Styles
3. ✅ Dokumentation im Markdown-Format
4. ✅ Unit-Tests schreiben
5. ✅ Widget-Tests schreiben

---

## Support

Bei Problemen oder Fragen:

1. Checke die [DnDTheme](../../../theme/dnd_theme.dart) Konstanten
2. Schau dir die [Beispiele](#beispiele) an
3. Konsultiere die [ItemColorHelper](../../character_editor/item_color_helper.dart)
4. Review die [Design-Principles](#design-principles)

---

**Letztes Update**: 17.01.2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
