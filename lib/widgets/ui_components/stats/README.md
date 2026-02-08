# UI Components - Stats

Dieses Verzeichnis enthält wiederverwendbare Widgets für D&D 5e Statistiken und Werte.

## Available Components

### 1. AttributesGridWidget
Wiederverwendbares Widget für D&D 5e Attribute (STR, DEX, CON, INT, WIS, CHA).

#### Usage:
```dart
AttributesGridWidget(
  attributes: {
    'strength': viewModel.strength,
    'dexterity': viewModel.dexterity,
    'constitution': viewModel.constitution,
    'intelligence': viewModel.intelligence,
    'wisdom': viewModel.wisdom,
    'charisma': viewModel.charisma,
  },
  onAttributeChanged: (attribute, value) {
    switch (attribute) {
      case 'strength':
        viewModel.updateStrength(value);
        break;
      case 'dexterity':
        viewModel.updateDexterity(value);
        break;
      // ... andere Attribute
    }
  },
  isEditable: true,
  showModifiers: true,
)
```

#### Features:
- ✅ Anzeige aller 6 D&D Attribute in einem Grid
- ✅ Editierbare oder read-only Modi
- ✅ Automatische Berechnung von Attributsmodifikatoren
- ✅ Visuell ansprechende Karten mit Icons
- ✅ Optionaler Modifikator-Badge (+3, -1, etc.)

### 2. CombatStatsWidget
Wiederverwendbares Widget für D&D 5e Kampfwerte (HP, RK, SG, Bewegungsrate).

#### Usage:
```dart
CombatStatsWidget(
  maxHp: viewModel.maxHp,
  currentHp: viewModel.currentHp,
  armorClass: viewModel.armorClass,
  challengeRating: viewModel.challengeRating,
  speed: viewModel.speed,
  onMaxHpChanged: (value) => viewModel.updateMaxHp(value),
  onCurrentHpChanged: (value) => viewModel.updateCurrentHp(value),
  onArmorClassChanged: (value) => viewModel.updateArmorClass(value),
  onChallengeRatingChanged: (value) => viewModel.updateChallengeRating(value),
  onSpeedChanged: (value) => viewModel.updateSpeed(value),
  isEditable: true,
)
```

#### Features:
- ✅ Lebenspunkte (Max & Aktuell)
- ✅ Rüstungsklasse (AC)
- ✅ Herausforderungsgrad (CR)
- ✅ Bewegungsrate
- ✅ Editierbare oder read-only Modi
- ✅ Konsistentes Design mit Icons

## Design Principles

### 1. **Consistency**
Alle Widgets verwenden das gleiche Design-System:
- `DnDTheme.mysticalPurple` als Primärfarbe
- `Colors.grey.shade800` als Hintergrund
- Abgerundete Ecken (BorderRadius.circular(8-12))
- Konsistente Icons für jeden Stat-Typ

### 2. **Flexibility**
Alle Widgets sind parameterisiert und unterstützen:
- Editierbare vs. read-only Modi
- Callback-Funktionen für Änderungen
- Optional Anzeigen von Zusatzinformationen (z.B. Modifikatoren)

### 3. **User Experience**
- Klare visuelle Hierarchie
- Intuitive Icons
- Responsive Layouts
- Feedback bei Interaktionen

## Integration mit anderen Screens

### Example: Creature Editor
```dart
Column(
  children: [
    // Kampfwerte Section
    SectionCardWidget(
      title: 'Kampfwerte',
      icon: Icons.security,
      child: CombatStatsWidget(
        maxHp: viewModel.maxHp,
        currentHp: viewModel.currentHp,
        armorClass: viewModel.armorClass,
        challengeRating: viewModel.challengeRating,
        speed: viewModel.speed,
        onMaxHpChanged: viewModel.updateMaxHp,
        // ... andere Callbacks
      ),
    ),
    
    // Attribute Section
    SectionCardWidget(
      title: 'Attribute',
      icon: Icons.fitness_center,
      child: AttributesGridWidget(
        attributes: {
          'strength': viewModel.strength,
          'dexterity': viewModel.dexterity,
          // ...
        },
        onAttributeChanged: (attr, value) {
          // Handle Änderung
        },
      ),
    ),
  ],
)
```

### Example: Player Character Editor
```dart
// Read-only Ansicht für Spieler
AttributesGridWidget(
  attributes: {
    'strength': character.strength,
    'dexterity': character.dexterity,
    // ...
  },
  isEditable: false,
  showModifiers: true,
)

// Editierbare Ansicht für DM
CombatStatsWidget(
  maxHp: character.maxHp,
  currentHp: character.currentHp,
  isEditable: true,
)
```

## Future Enhancements

- [ ] Unterstützung für Profizienz-Bonus
- [ ] Anzeige von Saving Throws
- [ ] Integration mit Roll-System
- [ ] Animierte Wert-Änderungen
- [ ] Tooltip für detaillierte Informationen

## Related Components

- [`SectionCardWidget`](../cards/section_card_widget.dart) - Wrapper für Sektionen
- [`FormFieldWidget`](../forms/form_field_widget.dart) - Konsistente Formular-Felder
- [`AbilityScoreWidget`](./ability_score_widget.dart) - Legacy Attributs-Widget
