# Filter Components

Wiederverwendbare Widgets für konsistente Filter- und Suchfunktionen in der App.

## Übersicht

Diese Komponenten bieten standardisierte UI-Elemente für Filter- und Suchfunktionen:
- **UnifiedSearchBar** - Vollständige Such- und Filterkomponente
- **UnifiedSearchDialog** - Vollbild-Suche für mobile Screens
- **FilterSectionBase** - Abstrakte Basis-Klasse für Filter-Sektionen

## UnifiedSearchBar

Ein flexibles Such-Widget mit Echtzeit-Suche, Vorschlägen und benutzerdefinierten Result-Widgets.

### Nutzung

```dart
UnifiedSearchBar<Campaign>(
  items: campaigns,
  hintText: 'Kampagnen durchsuchen...',
  itemBuilder: (context, campaign) => CampaignCard(campaign: campaign),
  searchFilter: (campaign, query) => 
    campaign.title.toLowerCase().contains(query.toLowerCase()),
  onItemSelected: (campaign) => _navigateToCampaign(campaign),
  maxResults: 10,
)
```

### Parameter

- `items` (erforderlich) - Liste aller durchsuchbaren Elemente
- `itemBuilder` (erforderlich) - Widget-Builder für ein Element
- `searchFilter` (erforderlich) - Filter-Funktion
- `onItemSelected` (erforderlich) - Callback bei Auswahl
- `hintText` - Platzhalter-Text (Standard: "Suchen...")
- `searchIcon` - Icon für Suchfeld (Standard: Icons.search)
- `maxResults` - Maximale Anzahl Ergebnisse (Standard: 10)
- `showEmptyState` - Zeige leere Ergebnisse (Standard: true)
- `showSuggestionsWhenEmpty` - Zeige Vorschläge wenn leer (Standard: false)
- `emptyStateTitle` - Titel für leeren Zustand
- `emptyStateMessage` - Nachricht für leeren Zustand

## UnifiedSearchDialog

Vollbild-Suche mit größerer Anzeige und erweiterten Funktionen. Ideal für mobile Screens mit vielen Elementen.

### Nutzung

```dart
final selectedCampaign = await UnifiedSearchDialog.show<Campaign>(
  context: context,
  items: campaigns,
  itemBuilder: (context, campaign) => CampaignCard(campaign: campaign),
  searchFilter: (campaign, query) => 
    campaign.title.toLowerCase().contains(query.toLowerCase()),
  title: 'Kampagne suchen',
  hintText: 'Suche nach Kampagnen...',
);

if (selectedCampaign != null) {
  _navigateToCampaign(selectedCampaign);
}
```

## FilterSectionBase

Abstrakte Basis-Klasse für Filter-Sektionen. Konkrete Implementierungen überschreiben die Methoden für ihre spezifischen Filter.

### Eigene Filter-Sektion erstellen

```dart
class MyFilterSection extends FilterSectionBase {
  final MyViewModel viewModel;

  const MyFilterSection({
    super.key,
    required this.viewModel,
  }) : super(
    hasActiveFilters: viewModel.hasActiveFilters,
    onClearAllFilters: viewModel.clearAllFilters,
  );

  @override
  String getFilterTitle() => 'Meine Filter';

  @override
  List<Widget> buildFilterSections(BuildContext context) {
    return [
      // Typ-Filter
      buildSectionTitle(context, 'Typ'),
      const SizedBox(height: 8),
      buildChipWrap(
        children: [
          buildFilterChip(
            context: context,
            label: 'Alle',
            isSelected: viewModel.selectedType == null,
            onTap: () => viewModel.setType(null),
            icon: Icons.list,
          ),
          buildFilterChip(
            context: context,
            label: 'Typ A',
            isSelected: viewModel.selectedType == MyType.typeA,
            onTap: () => viewModel.setType(MyType.typeA),
            icon: Icons.star,
            selectedColor: Colors.blue,
          ),
        ],
      ),
      
      // Schwierigkeits-Filter
      const SizedBox(height: 16),
      buildSectionTitle(context, 'Schwierigkeit'),
      const SizedBox(height: 8),
      buildChipWrap(
        children: [
          buildFilterChip(
            context: context,
            label: 'Leicht',
            isSelected: viewModel.selectedDifficulty == Difficulty.easy,
            onTap: () => viewModel.setDifficulty(Difficulty.easy),
            selectedColor: Colors.green,
          ),
          buildFilterChip(
            context: context,
            label: 'Schwer',
            isSelected: viewModel.selectedDifficulty == Difficulty.hard,
            onTap: () => viewModel.setDifficulty(Difficulty.hard),
            selectedColor: Colors.red,
          ),
        ],
      ),
    ];
  }
}
```

### Verfügbare Hilfsmethoden

- `buildFilterChip()` - Erstellt eine standardisierte FilterChip
- `buildChipWrap()` - Erstellt eine Wrap-Sektion für Chips
- `buildSectionTitle()` - Erstellt eine Sektionsüberschrift

### buildFilterChip Parameter

- `context` (erforderlich) - BuildContext
- `label` (erforderlich) - Label-Text
- `isSelected` (erforderlich) - Ob die Chip ausgewählt ist
- `onTap` (erforderlich) - Callback bei Auswahl
- `icon` (optional) - IconData für das Label
- `selectedColor` (optional) - Farbe für ausgewählten Zustand
- `checkmarkColor` (optional) - Farbe des Häkchens

## Best Practices

### 1. Konsistentes Layout
- Verwende `buildSectionTitle()` für alle Sektionsüberschriften
- Verwende `buildChipWrap()` für Chip-Container
- Verwende `buildFilterChip()` für alle Chips

### 2. Farbschemata
- Verwende konsistente Farben für ähnliche Filtertypen
- Leichte Schwierigkeit = Grüntöne
- Schwere Schwierigkeit = Rottöne
- Hauptquests = Rot/Pink
- Sidequests = Blau

### 3. Filter-Logik
- `hasActiveFilters` sollte alle aktiven Filter prüfen
- `onClearAllFilters` sollte alle Filter zurücksetzen
- Filter sollten sich gegenseitig ergänzen, nicht widersprechen

### 4. Performance
- Verwende `const` Widgets wo möglich
- Vermeide komplexe Berechnungen in Filter-Funktionen
- Cache-gefilterte Listen wenn möglich

## Beispiele aus der Praxis

### Campaign Filter

```dart
class CampaignFilterSection extends FilterSectionBase {
  final CampaignViewModel viewModel;

  const CampaignFilterSection({
    super.key,
    required this.viewModel,
  }) : super(
    hasActiveFilters: viewModel.searchQuery.isNotEmpty,
    onClearAllFilters: viewModel.searchQuery.isEmpty 
        ? null 
        : () => viewModel.searchCampaigns(''),
  );

  @override
  String getFilterTitle() => 'Kampagnen Filter';

  @override
  List<Widget> buildFilterSections(BuildContext context) {
    return [
      buildSectionTitle(context, 'Sortierung'),
      const SizedBox(height: 8),
      buildChipWrap(
        children: [
          buildFilterChip(
            context: context,
            label: 'Name',
            isSelected: viewModel.sortOption == CampaignSortOption.name,
            onTap: () => viewModel.setSortOption(CampaignSortOption.name),
            icon: Icons.sort_by_alpha,
            selectedColor: Colors.blue,
          ),
          buildFilterChip(
            context: context,
            label: 'Datum',
            isSelected: viewModel.sortOption == CampaignSortOption.createdDate,
            onTap: () => viewModel.setSortOption(CampaignSortOption.createdDate),
            icon: Icons.calendar_today,
            selectedColor: Colors.green,
          ),
        ],
      ),
    ];
  }
}
```

### Quest Filter mit Tags

```dart
class QuestFilterSection extends FilterSectionBase {
  final QuestLibraryViewModel viewModel;

  const QuestFilterSection({
    super.key,
    required this.viewModel,
  }) : super(
    hasActiveFilters: viewModel.hasActiveFilters,
    onClearAllFilters: viewModel.clearAllFilters,
  );

  @override
  List<Widget> buildFilterSections(BuildContext context) {
    final sections = <Widget>[];

    // Typ-Filter
    sections.addAll([
      buildSectionTitle(context, 'Quest-Typ'),
      const SizedBox(height: 8),
      buildChipWrap(
        children: [
          buildFilterChip(
            context: context,
            label: 'Hauptquest',
            isSelected: viewModel.selectedType == QuestType.main,
            onTap: () => viewModel.setTypeFilter(QuestType.main),
            icon: Icons.flag,
            selectedColor: Colors.red,
          ),
          buildFilterChip(
            context: context,
            label: 'Sidequest',
            isSelected: viewModel.selectedType == QuestType.side,
            onTap: () => viewModel.setTypeFilter(QuestType.side),
            icon: Icons.explore,
            selectedColor: Colors.blue,
          ),
        ],
      ),
    ]);

    // Tags-Filter (nur wenn verfügbar)
    if (viewModel.availableTags.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 16),
        buildSectionTitle(context, 'Tags'),
        const SizedBox(height: 8),
        buildChipWrap(
          children: viewModel.availableTags.map((tag) {
            final isSelected = viewModel.selectedTags.contains(tag);
            return buildFilterChip(
              context: context,
              label: tag,
              isSelected: isSelected,
              onTap: () => viewModel.toggleTag(tag),
              selectedColor: Colors.purple,
            );
          }).toList(),
        ),
      ]);
    }

    return sections;
  }
}
```

## Struktur

```
lib/widgets/ui_components/
├── search/
│   ├── unified_search_bar.dart
│   └── README.md
└── filter/
    ├── filter_section_base.dart
    └── README.md
```

## Migration bestehender Filter

Um bestehende Filter-Widgets zu migrieren:

1. Erstelle eine neue Klasse, die `FilterSectionBase` erweitert
2. Übergebe `hasActiveFilters` und `onClearAllFilters` an den Konstruktor
3. Überschreibe `buildFilterSections()` mit deiner Logik
4. Ersetze bestehende Chips durch `buildFilterChip()` Aufrufe
5. Ersetze Wraps durch `buildChipWrap()` Aufrufe

Dies sorgt für konsistentes Styling und reduzierten Boilerplate-Code.
