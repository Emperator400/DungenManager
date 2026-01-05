# Unified Search Bar

Wiederverwendbares Such-Widget für alle Screens im DungenManager.

## Übersicht

Das Unified Search System besteht aus zwei Komponenten:

1. **UnifiedSearchBar<T>** - Kompakte Suchleiste für Einbettung in Screens
2. **UnifiedSearchDialog<T>** - Vollbild-Suchdialog für umfangreiche Suchen

## Features

- ✅ **Generisch & Typsicher** - Funktioniert mit jedem Datentyp
- ✅ **Echtzeit-Suche** - Filtert während der Eingabe
- ✅ **Anpassbar** - Benutzerdefinierte Item-Widgets und Filter-Logik
- ✅ **DnD-Theme** - Integriert mit dem bestehenden Design
- ✅ **Empty States** - Schöne Feedback-Anzeige bei leeren Ergebnissen
- ✅ **Responsive** - Passt sich an verschiedene Screen-Größen an

## UnifiedSearchBar

Kompakte Suchleiste, die direkt in Screens eingebettet werden kann.

### Parameter

| Parameter | Typ | Erforderlich | Standard | Beschreibung |
|-----------|------|-------------|------------|--------------|
| `items` | `List<T>` | ✅ | - | Liste aller durchsuchbaren Elemente |
| `itemBuilder` | `Widget Function(BuildContext, T)` | ✅ | - | Widget-Builder für ein Element |
| `searchFilter` | `bool Function(T, String)` | ✅ | - | Filter-Funktion für Suche |
| `onItemSelected` | `void Function(T)` | ✅ | - | Callback bei Auswahl |
| `hintText` | `String` | ❌ | `'Suchen...'` | Platzhalter-Text |
| `searchIcon` | `IconData` | ❌ | `Icons.search` | Such-Icon |
| `maxResults` | `int` | ❌ | `10` | Maximale Ergebnis-Anzahl |
| `showEmptyState` | `bool` | ❌ | `true` | Zeige Empty State |
| `showSuggestionsWhenEmpty` | `bool` | ❌ | `false` | Zeige Vorschläge |
| `emptyStateTitle` | `String` | ❌ | `'Keine Ergebnisse gefunden'` | Titel Empty State |
| `emptyStateMessage` | `String` | ❌ | `'Versuche andere Suchbegriffe'` | Nachricht Empty State |

### Beispiel

```dart
UnifiedSearchBar<Campaign>(
  items: campaigns,
  hintText: 'Kampagnen suchen...',
  itemBuilder: (context, campaign) => ListTile(
    title: Text(campaign.title),
    subtitle: Text(campaign.description),
  ),
  searchFilter: (campaign, query) {
    final queryLower = query.toLowerCase();
    return campaign.title.toLowerCase().contains(queryLower) ||
           campaign.description.toLowerCase().contains(queryLower);
  },
  onItemSelected: (campaign) {
    // Navigation oder andere Aktion
    _navigateToCampaign(campaign);
  },
)
```

## UnifiedSearchDialog

Vollbild-Suchdialog für größere Suchansichten. Ideal für mobile Geräte mit vielen Elementen.

### Parameter

| Parameter | Typ | Erforderlich | Standard | Beschreibung |
|-----------|------|-------------|------------|--------------|
| `items` | `List<T>` | ✅ | - | Liste aller durchsuchbaren Elemente |
| `itemBuilder` | `Widget Function(BuildContext, T)` | ✅ | - | Widget-Builder für ein Element |
| `searchFilter` | `bool Function(T, String)` | ✅ | - | Filter-Funktion für Suche |
| `onItemSelected` | `void Function(T)` | ✅ | - | Callback bei Auswahl |
| `title` | `String` | ❌ | `'Suchen'` | Dialog-Titel |
| `hintText` | `String` | ❌ | `'Suchen...'` | Platzhalter-Text |

### Statische Methode

```dart
static Future<T?> show<T>({
  required BuildContext context,
  required List<T> items,
  required Widget Function(BuildContext, T) itemBuilder,
  required bool Function(T, String) searchFilter,
  String title = 'Suchen',
  String hintText = 'Suchen...',
})
```

### Beispiel

```dart
// Button oder IconButton
IconButton(
  icon: const Icon(Icons.search),
  onPressed: () async {
    final selectedCampaign = await UnifiedSearchDialog.show<Campaign>(
      context: context,
      items: campaigns,
      hintText: 'Kampagnen durchsuchen...',
      itemBuilder: (context, campaign) => UnifiedCampaignCard(
        campaign: campaign,
        onTap: () {},
      ),
      searchFilter: (campaign, query) {
        return campaign.title.toLowerCase().contains(query.toLowerCase());
      },
    );
    
    if (selectedCampaign != null) {
      _selectCampaign(selectedCampaign);
    }
  },
)
```

## Best Practices

### 1. Filter-Logik

Nutze `toLowerCase()` für case-insensitive Suche:

```dart
searchFilter: (item, query) {
  final queryLower = query.toLowerCase();
  return item.name.toLowerCase().contains(queryLower);
}
```

### 2. Mehrere Felder durchsuchen

```dart
searchFilter: (quest, query) {
  final queryLower = query.toLowerCase();
  return quest.title.toLowerCase().contains(queryLower) ||
         quest.description.toLowerCase().contains(queryLower) ||
         quest.tags.any((tag) => tag.toLowerCase().contains(queryLower));
}
```

### 3. Item-Builder optimieren

Nutze kompakte Widgets für bessere Performance:

```dart
itemBuilder: (context, campaign) => ListTile(
  leading: CircleAvatar(child: Text(campaign.title[0])),
  title: Text(campaign.title),
  subtitle: Text('${campaign.playerCharacterIds.length} Helden'),
  trailing: Icon(Icons.chevron_right),
)
```

### 4. Debouncing für große Listen

Für sehr große Listen (>1000 Elemente) nutze Debouncing:

```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    // Suche durchführen
  });
}
```

## Verwendung im Projekt

### Campaign Selection Screen

```dart
// In _showSearchDialog
UnifiedSearchDialog.show<Campaign>(
  context: context,
  items: viewModel.campaigns,
  hintText: 'Kampagnen durchsuchen...',
  itemBuilder: (context, campaign) => ListTile(
    leading: CircleAvatar(
      child: Text(campaign.title[0]),
      backgroundColor: DnDTheme.ancientGold,
    ),
    title: Text(campaign.title),
    subtitle: Text(campaign.statusDescription),
  ),
  searchFilter: (campaign, query) {
    final queryLower = query.toLowerCase();
    return campaign.title.toLowerCase().contains(queryLower) ||
           campaign.description.toLowerCase().contains(queryLower);
  },
)
```

### Quest Library Screen

```dart
UnifiedSearchBar<Quest>(
  items: quests,
  hintText: 'Quests suchen...',
  itemBuilder: (context, quest) => EnhancedQuestCardWidget(
    quest: quest,
    onTap: () {},
  ),
  searchFilter: (quest, query) {
    final queryLower = query.toLowerCase();
    return quest.title.toLowerCase().contains(queryLower) ||
           quest.description.toLowerCase().contains(queryLower);
  },
  onItemSelected: (quest) => _selectQuest(quest),
)
```

## Migration von bestehenden Search-Delegates

Bestehende `SearchDelegate` Implementierungen können leicht migriert werden:

**Vorher:**
```dart
showSearch(
  context: context,
  delegate: QuestSearchDelegate(allQuests: quests),
)
```

**Nachher:**
```dart
UnifiedSearchDialog.show<Quest>(
  context: context,
  items: quests,
  itemBuilder: (context, quest) => EnhancedQuestCardWidget(quest: quest),
  searchFilter: (quest, query) => quest.title.contains(query),
)
```

## Zukunftige Erweiterungen

- [ ] Verlauf der letzten Suchen speichern
- [ ] Erweiterte Filter (Datum, Status, etc.)
- [ ] Sortier-Optionen
- [ ] Keyboard Shortcuts
- [ ] Voice Search Integration

## Dateistruktur

```
lib/widgets/ui_components/search/
├── unified_search_bar.dart    # Haupt-Implementierung
└── README.md                  # Diese Dokumentation
