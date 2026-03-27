# Chips UI Components

Diese Komponenten bieten einheitliche Chip-Widgets für das gesamte Projekt.

## UnifiedInfoChip

Der `UnifiedInfoChip` ist ein vielseitiger Chip, der verschiedene Chip-Typen durch Factory-Konstruktoren unterstützt.

### Grundlegende Verwendung

```dart
// Standard Chip
UnifiedInfoChip(
  label: 'HP',
  value: '45/50',
  icon: Icons.favorite,
  backgroundColor: Colors.red.withOpacity(0.15),
  textColor: Colors.red,
)

// Mit Tap-Callback
UnifiedInfoChip(
  label: 'AC',
  value: '18',
  icon: Icons.shield,
  onTap: () => print('AC tapped'),
)
```

### Factory-Konstruktoren

#### Kampf-Statistiken
```dart
UnifiedInfoChip.combat(
  label: 'AC',
  value: '18',
  icon: Icons.shield,
  color: Colors.blue,
)
```

#### Attribute
```dart
// Vollständiges Attribut
UnifiedInfoChip.attribute(
  name: 'STR',
  value: 16,
  modifier: 3,
)

// Kompakte Version
UnifiedInfoChip.attributeCompact(
  name: 'DEX',
  value: 14,
)
```

#### Währung
```dart
UnifiedInfoChip.currency(
  label: 'Gold',
  amount: 125.0,
  icon: Icons.monetization_on,
)
```

#### Gesinnung
```dart
UnifiedInfoChip.alignment(
  alignment: 'Lawful Good',
)
```

#### Status
```dart
UnifiedInfoChip.status(
  status: 'Aktiv',
  icon: Icons.check_circle,
)
```

#### Tags
```dart
UnifiedInfoChip.tag(
  tag: 'Feuer',
  icon: Icons.local_fire_department,
  color: Colors.orange,
)
```

#### Typ-spezifische Chips
```dart
UnifiedInfoChip.type(
  type: 'Humanoid',
  icon: Icons.person,
  color: Colors.blue,
)
```

#### Level/CR
```dart
UnifiedInfoChip.level(
  label: 'Lvl',
  level: 5,
  icon: Icons.star,
)
```

#### Zahlen/Count
```dart
UnifiedInfoChip.count(
  label: 'Anzahl',
  count: 42,
  icon: Icons.format_list_numbered,
)
```

## UnifiedChipRow

Eine Zeile von Chips mit automatischem Wrapping.

```dart
UnifiedChipRow(
  spacing: 8,
  runSpacing: 8,
  alignment: WrapAlignment.start,
  chips: [
    UnifiedInfoChip.tag(tag: 'Tag 1'),
    UnifiedInfoChip.tag(tag: 'Tag 2'),
    UnifiedInfoChip.tag(tag: 'Tag 3'),
  ],
)
```

## UnifiedChipSection

Eine Sektion mit Titel und Chips.

```dart
UnifiedChipSection(
  title: 'Eigenschaften',
  titleIcon: Icons.label,
  titleColor: DnDTheme.ancientGold,
  chips: [
    UnifiedInfoChip.tag(tag: 'Feuerresistenz'),
    UnifiedInfoChip.tag(tag: 'Dunkelsicht'),
  ],
)
```

## UnifiedStatsRow

Eine kompakte Statistik-Zeile (z.B. HP, AC, INIT, SPEED).

```dart
UnifiedStatsRow(
  spacing: 8,
  stats: [
    UnifiedStatItem.hp(45, 50),
    UnifiedStatItem.ac(18),
    UnifiedStatItem.initiative(3),
    UnifiedStatItem.speed(30),
  ],
)
```

### UnifiedStatItem Factories

- `UnifiedStatItem.hp(int current, int max)` - Trefferpunkte
- `UnifiedStatItem.ac(int value)` - Rüstungsklasse
- `UnifiedStatItem.initiative(int bonus)` - Initiative
- `UnifiedStatItem.speed(int value)` - Bewegungsrate
- `UnifiedStatItem.cr(String cr)` - Challenge Rating
- `UnifiedStatItem.level(int level)` - Level

## Farbschema

Die Chips verwenden automatisch qualitätsbasierte Farben für Attribute:

| Wert | Farbe |
|------|-------|
| 18+ | Grün (Accent) |
| 16-17 | Grün |
| 14-15 | Hellgrün |
| 12-13 | Blau |
| 10-11 | Hellblau |
| 8-9 | Orange |
| 6-7 | Dunkelorange |
| <6 | Rot |

## Integration mit UnifiedCardBase

Die Chip-Komponenten sind für die Verwendung mit `UnifiedCardBase` optimiert:

```dart
class MyCard extends UnifiedCardBase {
  @override
  Widget buildCardContent(BuildContext context) {
    return Column(
      children: [
        CardHeaderWidget(
          additionalInfo: [
            UnifiedInfoChip.tag(tag: 'Neu'),
          ],
        ),
        UnifiedStatsRow(stats: [
          UnifiedStatItem.hp(100, 100),
          UnifiedStatItem.ac(15),
        ]),
      ],
    );
  }
}