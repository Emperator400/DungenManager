# UI-Components für Helden-Erstellung - Optimierungsdokumentation

## Übersicht

Dieses Dokument beschreibt die neuen wiederverwendbaren UI-Components, die für die Optimierung der Helden-Erstellungs-UI erstellt wurden. Diese Components basieren auf der neuen UI-Architektur und können in verschiedenen Screens verwendet werden.

## Neue Components

### 1. Formular-Components (`forms/form_field_widget.dart`)

Wiederverwendbare Formular-Elemente mit konsistentem Styling.

#### FormFieldWidget

Standard-Textfeld für Formulareingaben.

```dart
FormFieldWidget(
  label: 'Name des Charakters',
  value: viewModel.name,
  onChanged: (value) => viewModel.updateName(value),
  validator: viewModel.validateName,
  icon: Icons.person,
)
```

**Parameter:**
- `label` - Bezeichnung des Feldes
- `value` - Aktueller Wert
- `onChanged` - Callback bei Änderung
- `validator` - Validierungsfunktion (optional)
- `icon` - Icon (optional)
- `keyboardType` - Tastaturtyp (optional)
- `inputFormatters` - Eingabeformatierer (optional)
- `maxLines` - Maximale Zeilen (Standard: 1)
- `enabled` - Aktiviert/Deaktiviert (Standard: true)
- `maxLength` - Maximale Länge (optional)

**Beispiel für Zahlenfeld:**
```dart
FormFieldWidget(
  label: 'Stufe',
  value: viewModel.level.toString(),
  onChanged: (value) => viewModel.updateLevel(int.tryParse(value) ?? 1),
  keyboardType: TextInputType.number,
  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  icon: Icons.star,
)
```

#### DropdownFormFieldWidget<T>

Dropdown-Auswahlfeld für Typen, Klassen, Rassen, etc.

```dart
DropdownFormFieldWidget<DndClass>(
  label: 'Klasse',
  value: viewModel.selectedClass,
  items: allDndClasses,
  onChanged: (value) => viewModel.updateClass(value),
  validator: viewModel.validateClass,
  icon: Icons.shield,
)
```

**Parameter:**
- `label` - Bezeichnung des Feldes
- `value` - Aktueller Wert
- `items` - Liste der Optionen
- `onChanged` - Callback bei Änderung
- `validator` - Validierungsfunktion (optional)
- `icon` - Icon (optional)
- `enabled` - Aktiviert/Deaktiviert (Standard: true)

#### FormSectionWidget

Container für gruppierte Formularfelder mit Titel und Icon.

```dart
FormSectionWidget(
  title: 'Charakter-Informationen',
  icon: Icons.person,
  children: [
    FormFieldWidget(
      label: 'Name',
      value: name,
      onChanged: (value) => updateName(value),
    ),
    const SizedBox(height: 16),
    FormFieldWidget(
      label: 'Spielername',
      value: playerName,
      onChanged: (value) => updatePlayerName(value),
    ),
  ],
)
```

**Parameter:**
- `title` - Titel der Sektion
- `children` - Liste der Widgets
- `icon` - Icon (optional)
- `padding` - Padding (optional)
- `backgroundColor` - Hintergrundfarbe (optional)
- `borderRadius` - Eckenradius (optional)

---

### 2. Stats-Components (`stats/ability_score_widget.dart`)

Widgets für die Anzeige und Eingabe von Attributen und Kampfwerten.

#### AbilityScoreWidget

Einzelnes Attributswert-Widget mit Eingabefeld und Modifikator.

```dart
AbilityScoreWidget(
  name: 'Stärke',
  value: viewModel.strength,
  icon: Icons.fitness_center,
  color: Colors.red,
  onChanged: (value) => viewModel.updateStrength(value),
  minScore: 1,
  maxScore: 20,
)
```

**Parameter:**
- `name` - Name des Attributs
- `value` - Aktueller Wert
- `icon` - Icon
- `color` - Farbe
- `onChanged` - Callback bei Änderung
- `minScore` - Minimaler Wert (Standard: 1)
- `maxScore` - Maximaler Wert (Standard: 20)

#### AbilityScoreGrid

Grid für alle sechs Attribute (STR, DEX, CON, INT, WIS, CHA).

```dart
AbilityScoreGrid(
  strength: viewModel.strength,
  dexterity: viewModel.dexterity,
  constitution: viewModel.constitution,
  intelligence: viewModel.intelligence,
  wisdom: viewModel.wisdom,
  charisma: viewModel.charisma,
  onStrengthChanged: (value) => viewModel.updateStrength(value),
  onDexterityChanged: (value) => viewModel.updateDexterity(value),
  onConstitutionChanged: (value) => viewModel.updateConstitution(value),
  onIntelligenceChanged: (value) => viewModel.updateIntelligence(value),
  onWisdomChanged: (value) => viewModel.updateWisdom(value),
  onCharismaChanged: (value) => viewModel.updateCharisma(value),
)
```

#### CombatStatsRow

Zeile mit Kampfwerten (HP, AC, Initiative, Bewegung).

```dart
CombatStatsRow(
  maxHp: viewModel.maxHp,
  armorClass: viewModel.armorClass,
  initiativeBonus: viewModel.initiativeBonus,
  speed: viewModel.speed,
)
```

#### CurrencyWidget

Anzeige für Währung (Gold, Silber, Kupfer).

```dart
CurrencyWidget(
  gold: viewModel.gold,
  silver: viewModel.silver,
  copper: viewModel.copper,
)
```

---

### 3. Skill-Components (`skills/skill_list_widget.dart`)

Widgets für die Auswahl und Anzeige von Fertigkeiten.

#### SkillItemWidget

Einzelne Fertigkeit mit Proficiency-Checkbox und Bonus-Anzeige.

```dart
SkillItemWidget(
  skill: skill,
  bonus: viewModel.getSkillBonusString(skill),
  isProficient: viewModel.proficientSkills.contains(skill.name),
  onTap: () => viewModel.toggleSkillProficiency(skill.name),
)
```

#### SkillSectionWidget

Gruppe von Fertigkeiten nach Attribut sortiert.

```dart
SkillSectionWidget(
  ability: Ability.strength,
  skills: strengthSkills,
  skillBonuses: viewModel.skillBonuses,
  proficientSkills: viewModel.proficientSkills,
  onSkillToggle: (skillName) => viewModel.toggleSkillProficiency(skillName),
)
```

#### SkillSelectionWidget

Vollständige Fertigkeitsauswahl mit allen Sektionen.

```dart
SkillSelectionWidget(
  skillsByAbility: {
    Ability.strength: strengthSkills,
    Ability.dexterity: dexteritySkills,
    // ...
  },
  skillBonuses: viewModel.skillBonuses,
  proficientSkills: viewModel.proficientSkills,
  onSkillToggle: (skillName) => viewModel.toggleSkillProficiency(skillName),
  searchQuery: searchQuery,
)
```

#### SkillSearchField

Suchfeld für Fertigkeiten.

```dart
SkillSearchField(
  query: searchQuery,
  onChanged: (query) => setSearchQuery(query.toLowerCase()),
)
```

#### SkillSelectionWithSearch

Kombinierte Komponente aus Suchfeld und Fertigkeitsauswahl.

```dart
SkillSelectionWithSearch(
  skillsByAbility: skillsByAbility,
  skillBonuses: viewModel.skillBonuses,
  proficientSkills: viewModel.proficientSkills,
  onSkillToggle: (skillName) => viewModel.toggleSkillProficiency(skillName),
  searchQuery: searchQuery,
  onSearchChanged: (query) => setSearchQuery(query.toLowerCase()),
)
```

---

## Refactoring-Beispiel: Helden-Erstellungs-Screen

### Vorher (Original-Code)

```dart
Widget _buildCharacterCard() {
  return Container(
    padding: const EdgeInsets.all(DnDTheme.lg),
    decoration: BoxDecoration(
      color: DnDTheme.slateGrey,
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
    ),
    child: Column(
      children: [
        _buildTextField(
          'Name des Charakters',
          _viewModel.name,
          (value) => _viewModel.updateName(value),
          validator: _viewModel.validateName,
          icon: Icons.person,
        ),
        const SizedBox(height: DnDTheme.lg),
        _buildTextField(
          'Name des Spielers',
          _viewModel.playerName,
          (value) => _viewModel.updatePlayerName(value),
          validator: _viewModel.validatePlayerName,
          icon: Icons.person_outline,
        ),
      ],
    ),
  );
}

Widget _buildTextField(
  String label,
  String value,
  Function(String) onChanged, {
  String? Function(String?)? validator,
  IconData? icon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: DnDTheme.stoneGrey,
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
    ),
    child: TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: DnDTheme.bodyText2.copyWith(
          color: DnDTheme.ancientGold,
        ),
        prefixIcon: icon != null ? Icon(icon, color: DnDTheme.ancientGold) : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(DnDTheme.md),
      ),
      style: DnDTheme.bodyText1.copyWith(color: Colors.white),
      validator: validator,
      onChanged: onChanged,
    ),
  );
}
```

### Nachher (mit neuen Components)

```dart
Widget _buildCharacterCard() {
  return FormSectionWidget(
    title: 'Charakter-Informationen',
    icon: Icons.person,
    backgroundColor: DnDTheme.slateGrey,
    borderRadius: DnDTheme.radiusMedium,
    children: [
      FormFieldWidget(
        label: 'Name des Charakters',
        value: _viewModel.name,
        onChanged: (value) => _viewModel.updateName(value),
        validator: _viewModel.validateName,
        icon: Icons.person,
      ),
      const SizedBox(height: 16),
      FormFieldWidget(
        label: 'Name des Spielers',
        value: _viewModel.playerName,
        onChanged: (value) => _viewModel.updatePlayerName(value),
        validator: _viewModel.validatePlayerName,
        icon: Icons.person_outline,
      ),
    ],
  );
}
```

**Vorteile:**
- ✅ Keine duplizierten Styles mehr
- ✅ Konsistentes Erscheinungsbild
- ✅ Wiederverwendbar in anderen Screens
- ✅ Einfacher zu testen
- ✅ Weniger Code (ca. 40% Reduktion)

---

## Vorteile der neuen UI-Components

### 1. **Wiederverwendbarkeit**
- Components können in verschiedenen Screens verwendet werden
- Keine Code-Duplizierung mehr
- Zentralisierte Updates möglich

### 2. **Konsistenz**
- Einheitliches Design über alle Screens hinweg
- Gleiche Verhaltensweisen
- Keine Überraschungen für Benutzer

### 3. **Wartbarkeit**
- Änderungen müssen nur an einem Ort vorgenommen werden
- Klare Verantwortlichkeiten
- Einfaches Refactoring

### 4. **Testbarkeit**
- Isolierte Units können einzeln getestet werden
- Predictable Verhalten
- Einfache Mocks

### 5. **Erweiterbarkeit**
- Neue Features können einfach hinzugefügt werden
- Bestehende Components können erweitert werden
- Flexible Parameter

---

## Nächste Schritte

### 1. Refactoring des EnhancedEditPCScreen

Die Helden-Erstellungs-UI kann schrittweise migriert werden:

**Schritt 1:** Formular-Components verwenden
```dart
// Ersetze _buildTextField, _buildNumberField, _buildDropdownField, _buildMultilineField
// durch FormFieldWidget und DropdownFormFieldWidget
```

**Schritt 2:** Stats-Components verwenden
```dart
// Ersetze _buildAbilityScoreCard durch AbilityScoreGrid
// Ersetze _buildStatsRow durch CombatStatsRow
// Ersetze Währungsanzeige durch CurrencyWidget
```

**Schritt 3:** Skill-Components verwenden
```dart
// Ersetze _buildSkillsCard durch SkillSelectionWithSearch
```

### 2. Andere Screens optimieren

Die Components können auch in anderen Screens verwendet werden:
- Item-Erstellung
- Quest-Erstellung
- Session-Erstellung
- Beliebige Formulare im System

### 3. Weitere Components erstellen

Zusätzliche Components die noch fehlen:
- Inventory-List-Widget
- Spell-Slots-Widget
- Attack-List-Widget
- Feature/Trait-Widget

---

## Best Practices

### 1. Theme-Konsistenz

Verwende immer das Theme für Farben:
```dart
// ✅ GUT
Color cardColor = Theme.of(context).cardColor;
Color primaryColor = Theme.of(context).colorScheme.primary;

// ❌ SCHLECHT (Hardcodierte Farben)
Color cardColor = Colors.grey;
```

### 2. Parameter-Validierung

Stelle sicher, dass alle erforderlichen Parameter übergeben werden:
```dart
FormFieldWidget(
  label: 'Name',  // ✅ Erforderlich
  value: name,     // ✅ Erforderlich
  onChanged: (value) => updateName(value),  // ✅ Erforderlich
  icon: Icons.person,  // ✅ Optional
)
```

### 3. Bedingtes Rendering

Verwende bedingte Widgets für optionale Inhalte:
```dart
// Beschreibung nur anzeigen, wenn vorhanden
if (description != null && description!.isNotEmpty)
  FormFieldWidget(
    label: 'Beschreibung',
    value: description!,
    onChanged: (value) => updateDescription(value),
    maxLines: 4,
  ),
```

### 4. Spacing-Konstanz

Verwende konsistente Abstände:
```dart
// ✅ GUT
const SizedBox(height: 16),  // Standard-Abstand
const SizedBox(height: 8),   // Kleinerer Abstand

// ❌ SCHLECHT (Magic Numbers)
const SizedBox(height: 12.5),
```

---

## Troubleshooting

### Häufige Probleme

**Problem:** Component wird nicht richtig angezeigt
- **Lösung:** Prüfe ob alle erforderlichen Parameter übergeben werden

**Problem:** Farben stimmen nicht überein
- **Lösung:** Verwende Theme.of(context) statt hardcodierten Farben

**Problem:** Validierung funktioniert nicht
- **Lösung:** Prüfe ob der Validator übergeben wurde und das Form-Key korrekt ist

**Problem:** Callback wird nicht aufgerufen
- **Lösung:** Prüfe ob die Callback-Funktion korrekt definiert ist

---

## Zusammenfassung

Die neuen UI-Components bieten eine solide Basis für die Optimierung der Helden-Erstellungs-UI und anderer Formulare im System. Durch die Verwendung dieser Components wird der Code:

- ✅ Kürzer und lesbarer
- ✅ Einfacher zu warten
- ✅ Konsistenter im Design
- ✅ Einfacher zu testen
- ✅ Wiederverwendbar

Die Migration kann schrittweise erfolgen, ohne die Funktionalität zu beeinträchtigen.
