# State Widgets

Wiederverwendbare Widgets für konsistente Statusanzeigen in der App.

## Übersicht

Diese Widgets bieten standardisierte UI-Elemente für die drei häufigsten Zustände in Listenansichten:
- **LoadingStateWidget** - Wird beim Laden von Daten angezeigt
- **ErrorStateWidget** - Wird bei Fehlern angezeigt
- **EmptyStateWidget** - Wird angezeigt, wenn keine Daten vorhanden sind

## LoadingStateWidget

Zeigt einen konsistenten Ladezustand mit optionaler Nachricht.

### Nutzung

```dart
// Standard Loading
LoadingStateWidget.standard()

// Loading mit Nachricht
LoadingStateWidget.withMessage(message: 'Lade Kampagnen...')

// Mit benutzerdefinierter Farbe
LoadingStateWidget.standard(color: DnDTheme.ancientGold)
```

### Parameter

- `message` (optional) - Zusätzliche Nachricht unter dem Lade-Indikator
- `color` (optional) - Farbe des Lade-Indikators
- `size` (optional) - Größe des Lade-Indikators

## ErrorStateWidget

Zeigt einen konsistenten Fehlerzustand mit optionalen Aktionen.

### Nutzung

```dart
// Mit "Erneut versuchen" Button
ErrorStateWidget.withRetry(
  title: 'Fehler beim Laden',
  message: 'Verbindung zum Server fehlgeschlagen',
  onRetry: () => viewModel.refresh(),
)

// Minimaler Error ohne Aktion
ErrorStateWidget.minimal(
  title: 'Keine Verbindung',
  message: 'Bitte überprüfe deine Internetverbindung',
)

// Mit benutzerdefinierter Aktion
ErrorStateWidget(
  title: 'Fehler',
  message: 'Etwas ist schiefgelaufen',
  action: ElevatedButton(
    onPressed: () => doSomething(),
    child: Text('Zurück'),
  ),
)
```

### Parameter

- `title` (erforderlich) - Haupttitel des Fehlers
- `message` (optional) - Detaillierte Fehlerbeschreibung
- `action` (optional) - Benutzerdefinierte Aktion
- `icon` (optional) - Eigener Icon (Standard: Icons.error_outline)
- `iconColor` (optional) - Farbe des Icons (Standard: DnDTheme.errorRed)

### Factory Methoden

- `.withRetry()` - Erstellt Error mit "Erneut versuchen" Button
- `.minimal()` - Erstellt minimalen Error ohne Aktion

## EmptyStateWidget

Zeigt einen konsistenten Leerer-Zustand mit optionalen Aktionen.

### Nutzung

```dart
// Mit "Erstellen" Button
EmptyStateWidget.withCreate(
  title: 'Noch keine Kampagnen',
  message: 'Erstelle deine erste Kampagne',
  onCreate: () => showCreateDialog(),
  buttonText: 'Kampagne erstellen',
)

// Mit "Filter zurücksetzen" Button
EmptyStateWidget.withClearFilters(
  title: 'Keine Kampagnen gefunden',
  message: 'Keine Kampagnen entsprechen den aktuellen Filtern',
  onClearFilters: () => viewModel.clearAllFilters(),
)

// Minimaler Empty State
EmptyStateWidget.minimal(
  title: 'Keine Elemente',
  message: 'Es gibt hier nichts zu sehen',
)

// Mit benutzerdefinierter Aktion
EmptyStateWidget.withAction(
  title: 'Leere Liste',
  message: 'Füge Elemente hinzu',
  action: ElevatedButton(
    onPressed: () => doSomething(),
    child: Text('Aktion'),
  ),
)
```

### Parameter

- `title` (erforderlich) - Haupttitel
- `message` (optional) - Zusätzliche Nachricht
- `action` (optional) - Benutzerdefinierte Aktion
- `icon` (optional) - Eigener Icon (Standard: Icons.folder_open)
- `iconColor` (optional) - Farbe des Icons
- `showAction` (optional) - Ob die Aktion angezeigt werden soll

### Factory Methoden

- `.withCreate()` - Erstellt Empty State mit "Erstellen" Button
- `.withClearFilters()` - Erstellt Empty State mit "Filter zurücksetzen" Button
- `.minimal()` - Erstellt minimalen Empty State ohne Aktion
- `.withAction()` - Erstellt Empty State mit benutzerdefinierter Aktion

## Beispiele aus der Praxis

### In einem Campaign ViewModel Screen

```dart
Widget _buildCampaignList() {
  return Consumer<CampaignViewModel>(
    builder: (context, viewModel, child) {
      // Loading State
      if (viewModel.isLoading) {
        return LoadingStateWidget.standard();
      }

      // Error State
      if (viewModel.error != null) {
        return ErrorStateWidget.withRetry(
          title: 'Fehler beim Laden der Kampagnen',
          message: viewModel.error,
          onRetry: () => viewModel.refresh(),
        );
      }

      // Empty State
      if (viewModel.filteredCampaigns.isEmpty) {
        return EmptyStateWidget.withCreate(
          title: 'Noch keine Kampagnen',
          message: 'Erstelle deine erste Kampagne',
          onCreate: () => _showCreateCampaignDialog(),
          buttonText: 'Kampagne erstellen',
        );
      }

      // Normaler Content
      return ListView.builder(
        itemCount: viewModel.filteredCampaigns.length,
        itemBuilder: (context, index) {
          return CampaignCard(campaign: viewModel.filteredCampaigns[index]);
        },
      );
    },
  );
}
```

### Mit Filter-Empty State

```dart
Widget _buildQuestList() {
  return Consumer<QuestViewModel>(
    builder: (context, viewModel, child) {
      if (viewModel.filteredQuests.isEmpty) {
        // Unterschiedliche Empty States je nach Situation
        if (viewModel.hasActiveFilters) {
          return EmptyStateWidget.withClearFilters(
            title: 'Keine Quests gefunden',
            message: 'Keine Quests entsprechen den aktuellen Filtern',
            onClearFilters: () => viewModel.clearAllFilters(),
          );
        } else {
          return EmptyStateWidget.withCreate(
            title: 'Noch keine Quests',
            message: 'Erstelle deine erste Quest',
            onCreate: () => _showCreateQuestDialog(),
          );
        }
      }

      return ListView.builder(/* ... */);
    },
  );
}
```

## Best Practices

1. **Konsistente Icons**: Verwende themenbezogene Icons für jeden Screen
   - Kampagnen: `Icons.campaign_outlined`
   - Quests: `Icons.assignment_outlined`
   - Items: `Icons.inventory_2_outlined`

2. **Kontextabhängige Messages**: Passe die Nachrichten an den Kontext an
   - "Keine Kampagnen" für Campaign Screen
   - "Keine Quests" für Quest Library

3. **Aktionen sinnvoll nutzen**: Biete nur sinnvolle Aktionen an
   - "Erstellen" wenn noch keine Daten
   - "Filter zurücksetzen" wenn aktiv gefiltert
   - "Erneut versuchen" bei Fehlern

4. **Theming**: Verwende DnDTheme Farben für konsistentes Design
