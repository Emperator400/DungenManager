# Unified Card System - Dokumentation

## Übersicht

Das Unified Card System bietet ein konsistentes, wiederverwendbares UI-System für alle Card-Widgets in der Anwendung. Es basiert auf einer modularen Architektur, die Code-Duplizierung minimiert und ein einheitliches Design sicherstellt.

## Architektur

### Ordnerstruktur

```
lib/widgets/ui_components/
├── base/                      # Basiskomponenten
│   ├── unified_card_base.dart
│   ├── card_header_widget.dart
│   ├── card_content_widget.dart
│   ├── card_actions_widget.dart
│   └── card_metadata_widget.dart
├── cards/                     # Spezifische Card-Implementierungen
│   └── unified_campaign_card.dart
├── shared/                    # Gemeinsame Utilities
│   └── unified_card_theme.dart
└── README.md                  # Diese Datei
```

## Basiskomponenten

### 1. UnifiedCardBase

Abstrakte Basisklasse für alle Card-Widgets. Bietet gemeinsame Funktionalität und Standard-Styling.

**Hauptfunktionen:**
- Standardisiertes Card-Layout
- Konfigurierbare Elevation und Border-Radius
- Tap-Handling und Selektionsstatus
- Favorite-Toggle Unterstützung

**Verwendung:**
```dart
class MyCard extends UnifiedCardBase {
  final MyModel model;

  const MyCard({
    super.key,
    required this.model,
    super.onTap,
    super.onEdit,
    super.onDelete,
  });

  @override
  Widget buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
      child: Column(
        children: [
          // Card-Inhalt
        ],
      ),
    );
  }
}
```

### 2. CardHeaderWidget

Standardisierter Header für Cards mit:
- Icon/Avatar
- Titel und Subtitle
- Additional Info Chips
- Favorite Button
- Popup Menu

**Beispiel:**
```dart
CardHeaderWidget(
  title: campaign.title,
  subtitle: 'Homebrew • Aktiv',
  leadingIcon: Icons.campaign,
  iconColor: UnifiedCardTheme.getIconColor('campaign'),
  iconBackgroundColor: UnifiedCardTheme.getIconBackgroundColor('campaign'),
  additionalInfo: [
    _buildInfoChip(Icons.people, '5 Helden'),
    _buildInfoChip(Icons.calendar_today, '12 Sessions'),
  ],
  onFavoriteToggle: () => toggleFavorite(),
  isFavorite: isFavorite,
  popupMenuItems: [
    const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
    const PopupMenuItem(value: 'delete', child: Text('Löschen')),
  ],
  onPopupMenuItemSelected: (value) => handleMenuAction(value),
)
```

### 3. CardContentWidget

Flexibler Content-Container für:
- Beschreibungstext
- Tags
- Zusätzlicher benutzerdefinierter Inhalt

**Beispiel:**
```dart
CardContentWidget(
  description: 'Eine epische Kampagne...',
  descriptionMaxLines: 3,
  tags: ['Fantasy', 'High Level'],
  additionalContent: [
    if (hasRewards) RewardBadge(),
  ],
  onTagTap: (tag) => filterByTag(tag),
)
```

### 4. CardActionsWidget

Standardisierte Action-Bar mit:
- Edit Button
- Delete Button (mit Bestätigungsdialog)
- Quick Action Button
- Konfigurierbare Ausrichtung

**Beispiel:**
```dart
CardActionsWidget(
  onEdit: () => editItem(),
  onDelete: () => deleteItem(),
  onQuickAction: () => showQuickActions(),
  alignment: MainAxisAlignment.end,
)
```

### 5. CardMetadataWidget

Widget für Metadaten-Informationen:
- Erstellungs- und Aktualisierungsdatum
- Status mit farbcodierter Anzeige
- Priorität mit farbcodierter Anzeige
- Item Counts
- Custom Metadata

**Beispiel:**
```dart
CardMetadataWidget(
  createdAt: campaign.createdAt,
  updatedAt: campaign.updatedAt,
  status: campaign.statusDescription,
  priority: 'Hoch',
  itemCount: campaign.questIds.length,
)
```

## Theme-System

Das UnifiedCardTheme stellt konsistente Farben und Styles für verschiedene Card-Typen bereit.

### Unterstützte Typen

- `campaign` - Kampagnen (Grün)
- `quest` - Quests (Helles Grün)
- `hero` - Helden/Charaktere (Olive)
- `item` - Gegenstände (Olivegrün)
- `sound` - Sounds (Blau)
- `wiki` - Wiki-Einträge (Lila)
- `session` - Sessions (Braun)
- `creature` - Kreaturen (Rot)
- `default` - Standard (Grau)

### Verwendung

```dart
// Farbe abrufen
Color cardColor = UnifiedCardTheme.getCardColor('campaign');
Color iconColor = UnifiedCardTheme.getIconColor('campaign');
Color iconBg = UnifiedCardTheme.getIconBackgroundColor('campaign');

// Status-Farbe abrufen
Color statusColor = UnifiedCardTheme.getStatusColor('Aktiv');

// Prioritäts-Farbe abrufen
Color priorityColor = UnifiedCardTheme.getPriorityColor('Hoch');
```

## Spezifische Card-Implementierungen

### UnifiedCampaignCard

Beispielimplementierung für Campaigns.

**Features:**
- Zeigt Campaign-Informationen
- Shows Helden-, Sessions- und Quest-Counts
- Quick Actions Bottom Sheet
- Popup Menu mit Duplizieren, Exportieren, Archivieren, Einstellungen

**Verwendung:**
```dart
UnifiedCampaignCard(
  campaign: myCampaign,
  onTap: () => navigateToDetail(campaign.id),
  onEdit: () => openEditor(campaign),
  onDelete: () => deleteCampaign(campaign),
  isSelected: selectedCampaignId == campaign.id,
)
```

## Best Practices

### 1. Neue Cards erstellen

Erstelle eine neue Card-Klasse, die von `UnifiedCardBase` erbt:

```dart
class MyNewCard extends UnifiedCardBase {
  final MyModel model;

  const MyNewCard({
    super.key,
    required this.model,
    super.onTap,
    super.onEdit,
    super.onDelete,
  });

  @override
  Widget buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          CardHeaderWidget(...),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Content
          CardContentWidget(...),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Metadata
          CardMetadataWidget(...),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Actions
          CardActionsWidget(...),
        ],
      ),
    );
  }
}
```

### 2. Theme-Konsistenz

Verwende immer das `UnifiedCardTheme` für Farben:

```dart
// ✅ GUT
iconColor: UnifiedCardTheme.getIconColor('quest')

// ❌ SCHLECHT (Hardcodierte Farben)
iconColor: Colors.green
```

### 3. Konsistentes Spacing

Verwende die definierten Konstanten:

```dart
// ✅ GUT
const SizedBox(height: UnifiedCardBase.defaultSpacing)

// ❌ SCHLECHT (Magic Numbers)
const SizedBox(height: 8)
```

### 4. Bedingte Rendering

Verwende bedingte Widgets für optionale Inhalte:

```dart
// Beschreibung nur anzeigen, wenn vorhanden
if (campaign.description.isNotEmpty)
  CardContentWidget(
    description: campaign.description,
  ),

// Tags nur anzeigen, wenn vorhanden
if (campaign.tags != null && campaign.tags!.isNotEmpty)
  Wrap(
    children: campaign.tags!.map((tag) => TagChip(tag)).toList(),
  ),
```

## Migration von alten Cards

Alte Card-Widgets schrittweise migrieren:

### Schritte:

1. **Analyse**: Untersuche die Struktur der alten Card
2. **Extrahiere**: Identifiziere gemeinsame Elemente (Header, Content, Actions)
3. **Ersetze**: Ersetze mit neuen Basiskomponenten
4. **Testen**: Prüfe, ob alle Features noch funktionieren
5. **Cleanup**: Entferne den alten Code

### Beispiel-Migration

**Vorher:**
```dart
class OldCampaignCard extends StatelessWidget {
  final Campaign campaign;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.campaign),
              Text(campaign.title),
            ],
          ),
          Text(campaign.description),
          Row(
            children: [
              IconButton(icon: Icon(Icons.edit)),
              IconButton(icon: Icon(Icons.delete)),
            ],
          ),
        ],
      ),
    );
  }
}
```

**Nachher:**
```dart
class UnifiedCampaignCard extends UnifiedCardBase {
  final Campaign campaign;

  const UnifiedCampaignCard({
    super.key,
    required this.campaign,
    super.onTap,
    super.onEdit,
    super.onDelete,
  });

  @override
  Widget buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeaderWidget(
            title: campaign.title,
            leadingIcon: Icons.campaign,
            iconColor: UnifiedCardTheme.getIconColor('campaign'),
          ),
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          if (campaign.description.isNotEmpty)
            CardContentWidget(description: campaign.description),
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          CardActionsWidget(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}
```

## Vorteile des Unified Card Systems

### 1. **Konsistenz**
- Alle Cards sehen gleich aus
- Einheitliches Verhalten
- Keine Überraschungen für Benutzer

### 2. **Wiederverwendbarkeit**
- Gemeinsame Komponenten
- Kein Code-Duplizierung
- Einfache Erweiterung

### 3. **Wartbarkeit**
- Zentralisierte Updates
- Einfaches Refactoring
- Klare Verantwortlichkeiten

### 4. **Flexibilität**
- Konfigurierbare Komponenten
- Einfach zu erweitern
- Anpassbar an verschiedene Anforderungen

### 5. **Zukunftssicherheit**
- Leicht neue Features hinzuzufügen
- Skalierbar
- Testbar

## Testing

### Unit Tests

Teste die Basiskomponenten separat:

```dart
test('CardHeaderWidget displays title correctly', () {
  final widget = CardHeaderWidget(
    title: 'Test Campaign',
    subtitle: 'Test Description',
  );
  
  expect(find.text('Test Campaign'), findsOneWidget);
});
```

### Widget Tests

Teste die komplette Card:

```dart
testWidgets('UnifiedCampaignCard renders correctly', (tester) async {
  final campaign = Campaign.create(
    title: 'Test Campaign',
    description: 'Test Description',
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: UnifiedCampaignCard(campaign: campaign),
    ),
  );
  
  expect(find.text('Test Campaign'), findsOneWidget);
  expect(find.text('Test Description'), findsOneWidget);
});
```

## Zukünftige Erweiterungen

### Geplante Features

1. **Mehr Card-Typen**
   - UnifiedQuestCard
   - UnifiedHeroCard
   - UnifiedItemCard
   - UnifiedWikiEntryCard

2. **Animationen**
   - Smooth Transitions
   - Swipe Actions
   - Expand/Collapse

3. **Zustandsmanagement**
   - Integration mit Provider
   - Optimistic Updates
   - Offline Support

4. **Barrierefreiheit**
   - Screen Reader Support
   - Keyboard Navigation
   - High Contrast Mode

5. **Performance**
   - Lazy Loading
   - Virtual Scrolling
   - Efficient Rebuilding

## Troubleshooting

### Häufige Probleme

**Problem**: Card wird nicht richtig angezeigt
- **Lösung**: Prüfe, ob `buildCardContent` überschrieben ist

**Problem**: Farben stimmen nicht überein
- **Lösung**: Verwende `UnifiedCardTheme` statt hardcodierten Farben

**Problem**: Aktionen werden nicht ausgelöst
- **Lösung**: Prüfe, ob Callbacks korrekt übergeben werden

**Problem**: Spacing ist inkonsistent
- **Lösung**: Verwende `UnifiedCardBase.defaultSpacing`

## Ressourcen

- Flutter Material Design: https://m3.material.io/
- Flutter Widgets: https://api.flutter.dev/flutter/widgets/widgets-library.html
- Flutter Best Practices: https://flutter.dev/docs/development/best-practices

## Support

Bei Fragen oder Problemen:
1. Prüfe diese Dokumentation
2. Schau dir die Beispiel-Implementierungen an
3. Konsultiere das Flutter Widget-Katalog
4. Eröffne ein Issue im Repository

## Änderungsprotokoll

### Version 1.0.0 (2026-01-04)
- Initiale Veröffentlichung
- Basiskomponenten erstellt
- UnifiedCampaignCard implementiert
- Theme-System eingeführt
- Dokumentation erstellt
