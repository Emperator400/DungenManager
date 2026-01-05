# List Components

Wiederverwendbare Widgets für konsistente Listen- und Anzeigekomponenten in der App.

## Übersicht

Diese Komponenten bieten standardisierte UI-Elemente für Listen und Anzeigen:
- **ItemCountHeader** - Header mit Item-Anzahl und optionalen Aktionen
- **PaginatedListView** - Performante paginierte Liste mit automatischem Laden

## ItemCountHeader

Zeigt konsistent die Anzahl der Elemente mit optionalen Aktionen und Sortier-Optionen an.

### Nutzung

```dart
// Einfache Item-Anzeige
ItemCountHeader.simple(
  itemCount: campaigns.length,
  singular: 'Kampagne',
  plural: 'Kampagnen',
  additionalInfo: 'Letzter Update: vor 2 Tagen',
)

// Mit Sortier-Button
ItemCountHeader.withSort(
  itemCount: campaigns.length,
  singular: 'Kampagne',
  plural: 'Kampagnen',
  isAscending: viewModel.sortAscending,
  onSortToggle: () => viewModel.toggleSortOrder(),
  additionalInfo: 'Aktiv: 3 von 5',
)
```

### Parameter

- `itemCount` (erforderlich) - Anzahl der Elemente
- `singular` (erforderlich) - Singular-Form des Elementnamens
- `plural` (optional) - Plural-Form (Standard: `${singular}s`)
- `actions` (optional) - Zusätzliche Aktionen
- `showSortButton` (optional) - Zeige Sortier-Button (Standard: false)
- `isAscending` (optional) - Aktuelle Sortier-Richtung (Standard: true)
- `onSortToggle` (optional) - Callback für Sortier-Button
- `additionalInfo` (optional) - Zusätzliche Nachricht

### Factory Methoden

- `.simple()` - Einfache Item-Anzeige ohne Aktionen
- `.withSort()` - Item-Anzeige mit Sortier-Button

## PaginatedListView

Bietet eine performante ListView mit Pagination, Loading-States und automatischem Laden weiterer Elemente beim Scrollen.

### Nutzung

```dart
PaginatedListView<Campaign>(
  items: viewModel.campaigns,
  itemBuilder: (context, campaign) => CampaignCard(campaign: campaign),
  isLoadingMore: viewModel.isLoadingMore,
  hasReachedEnd: viewModel.hasReachedEnd,
  onLoadMore: () => viewModel.loadMore(),
  padding: const EdgeInsets.all(8),
  emptyState: EmptyStateWidget.withCreate(
    title: 'Keine Kampagnen',
    message: 'Erstelle deine erste Kampagne',
    onCreate: () => _showCreateDialog(),
  ),
  separatorBuilder: (context, index) => const Divider(height: 1),
  pageSize: 20,
  loadMoreThreshold: 5,
)
```

### Parameter

- `items` (erforderlich) - Alle Elemente
- `itemBuilder` (erforderlich) - Widget-Builder für ein Element
- `isLoadingMore` - Ob mehr Elemente geladen werden (Standard: false)
- `hasReachedEnd` - Ob alle Elemente geladen wurden (Standard: false)
- `onLoadMore` (optional) - Callback zum Laden weiterer Elemente
- `separatorBuilder` (optional) - Separator zwischen Elementen
- `padding` (optional) - Padding für die Liste
- `emptyState` (optional) - Widget für leeren Zustand
- `loadingState` (optional) - Widget für Ladezustand
- `pageSize` - Item-Anzahl pro Seite (Standard: 20)
- `loadMoreThreshold` - Schwellenwert für Load More (Standard: 5)

## Beispiele aus der Praxis

### Campaign List mit Pagination

```dart
Widget _buildCampaignList() {
  return Consumer<CampaignViewModel>(
    builder: (context, viewModel, child) {
      return Column(
        children: [
          // Item-Count Header
          ItemCountHeader.withSort(
            itemCount: viewModel.filteredCampaigns.length,
            singular: 'Kampagne',
            plural: 'Kampagnen',
            isAscending: viewModel.sortAscending,
            onSortToggle: () => viewModel.toggleSortOrder(),
          ),
          
          // Paginierte Liste
          Expanded(
            child: PaginatedListView<Campaign>(
              items: viewModel.filteredCampaigns,
              itemBuilder: (context, campaign) => CampaignCard(campaign: campaign),
              isLoadingMore: viewModel.isLoadingMore,
              hasReachedEnd: viewModel.hasReachedEnd,
              onLoadMore: () => viewModel.loadMoreCampaigns(),
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          ),
        ],
      );
    },
  );
}
```

### Quest List mit Custom Empty State

```dart
Widget _buildQuestList() {
  return Consumer<QuestViewModel>(
    builder: (context, viewModel, child) {
      return Column(
        children: [
          ItemCountHeader.simple(
            itemCount: viewModel.filteredQuests.length,
            singular: 'Quest',
            plural: 'Quests',
            additionalInfo: viewModel.hasActiveFilters ? 'Gefiltert' : null,
          ),
          
          Expanded(
            child: PaginatedListView<Quest>(
              items: viewModel.filteredQuests,
              itemBuilder: (context, quest) => QuestCard(quest: quest),
              isLoadingMore: viewModel.isLoadingMore,
              hasReachedEnd: viewModel.hasReachedEnd,
              onLoadMore: () => viewModel.loadMoreQuests(),
              emptyState: EmptyStateWidget.withClearFilters(
                title: 'Keine Quests gefunden',
                message: viewModel.hasActiveFilters 
                  ? 'Keine Quests entsprechen den aktuellen Filtern'
                  : 'Erstelle deine erste Quest',
                onClearFilters: () => viewModel.clearAllFilters(),
                onCreate: viewModel.hasActiveFilters 
                  ? null 
                  : () => _showCreateQuestDialog(),
              ),
            ),
          ),
        ],
      );
    },
  );
}
```

### Item List mit Actions

```dart
Widget _buildItemList() {
  return Consumer<ItemViewModel>(
    builder: (context, viewModel, child) {
      return Column(
        children: [
          ItemCountHeader(
            itemCount: viewModel.items.length,
            singular: 'Item',
            plural: 'Items',
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(),
                tooltip: 'Filter',
              ),
              IconButton(
                icon: const Icon(Icons.view_list),
                onPressed: () => viewModel.toggleViewMode(),
                tooltip: 'Ansicht ändern',
              ),
            ],
          ),
          
          Expanded(
            child: PaginatedListView<Item>(
              items: viewModel.items,
              itemBuilder: (context, item) => ItemCard(item: item),
              isLoadingMore: viewModel.isLoadingMore,
              hasReachedEnd: viewModel.hasReachedEnd,
              onLoadMore: () => viewModel.loadMore(),
            ),
          ),
        ],
      );
    },
  );
}
```

## Best Practices

### 1. Pagination
- Verwende `PaginatedListView` für Listen mit mehr als 100 Elementen
- Setze `pageSize` basierend auf der Komplexität der Items (10-20)
- Passe `loadMoreThreshold` basierend auf der Item-Größe an

### 2. Item-Count Header
- Zeige immer die aktuelle Anzahl der gefilterten Elemente
- Verwende `additionalInfo` für Kontext (z.B. "Gefiltert", "Aktiv")
- Biete Sortier-Optionen an, wenn sinnvoll

### 3. Performance
- Verwende `const` Widgets für Item-Builder wo möglich
- Implementiere `separatorBuilder` für Trenner statt separate Widgets
- Cache-gefilterte Listen im ViewModel

### 4. Empty States
- Kombiniere `PaginatedListView` mit `EmptyStateWidget`
- Passe Empty State an den Kontext an (leer vs. gefiltert)
- Biete sinnvolle Aktionen an (Erstellen, Filter zurücksetzen)

## Struktur

```
lib/widgets/ui_components/lists/
├── item_count_header.dart
├── paginated_list_view.dart
└── README.md
```

## Migration bestehender Listen

Um bestehende Listen zu migrieren:

### Von ListView zu PaginatedListView

1. Ersetze `ListView.builder` durch `PaginatedListView`
2. Übergebe `items` und `itemBuilder`
3. Implementiere `onLoadMore` im ViewModel
4. Füge `isLoadingMore` und `hasReachedEnd` hinzu
5. Verwende `ItemCountHeader` für die Anzeige

### Vorher:

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return MyItemCard(item: items[index]);
  },
)
```

### Nachher:

```dart
Column(
  children: [
    ItemCountHeader.simple(
      itemCount: items.length,
      singular: 'Item',
    ),
    Expanded(
      child: PaginatedListView<Item>(
        items: items,
        itemBuilder: (context, item) => MyItemCard(item: item),
        isLoadingMore: viewModel.isLoadingMore,
        hasReachedEnd: viewModel.hasReachedEnd,
        onLoadMore: viewModel.loadMore,
      ),
    ),
  ],
)
```

## ViewModel Integration

Für die Pagination muss das ViewModel folgende Methoden bereitstellen:

```dart
class MyViewModel extends ChangeNotifier {
  List<Item> _items = [];
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  
  List<Item> get items => _filteredItems ?? _items;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasReachedEnd => _hasReachedEnd;
  
  Future<void> loadMore() async {
    if (_isLoadingMore || _hasReachedEnd) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      final newItems = await repository.fetchMore(
        offset: _items.length,
        limit: 20,
      );
      
      if (newItems.isEmpty) {
        _hasReachedEnd = true;
      } else {
        _items.addAll(newItems);
      }
    } catch (e) {
      // Fehlerbehandlung
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
```

Diese Struktur sorgt für performante und konsistente Listen in der gesamten App.
