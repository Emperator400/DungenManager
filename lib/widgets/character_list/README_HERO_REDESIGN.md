# Helden-Darstellung Redesign

Dieses Dokument beschreibt die neue moderne Helden-Darstellung im DungenManager.

## Überblick

Die Helden-Ansicht wurde komplett überarbeitet, um eine bessere Benutzererfahrung und mehr Funktionalität zu bieten. Das neue System besteht aus mehreren wiederverwendbaren Widgets und bietet flexible Ansichtsmöglichkeiten.

## Hauptkomponenten

### 1. CharacterListHelpers
**Datei:** `character_list_helpers.dart`

Enthält alle Hilfsfunktionen für:
- Farben für Klassen und Attribute
- Sortier- und Filterlogik
- Status-Indikatoren (HP, Level, etc.)
- Textformatierung und -kürzung

### 2. HeroAvatarWidget
**Datei:** `hero_avatar_widget.dart`

Moderne Avatar-Anzeige mit:
- Dynamischen Klassenfarben und -icons
- Level-Badges
- Gesinnungs-Indikatoren
- Favoriten-Sternen
- Bild-Fallback mit Lade-Animation
- Responsive Größen

### 3. HeroStatsChipsWidget
**Datei:** `hero_stats_chips_widget.dart`

Drei Varianten für Statistik-Anzeige:
- **HeroStatsChipsWidget**: Vollständige Chips für Listenansicht
- **CompactHeroStatsChipsWidget**: Kompakte Icons für engen Platz
- **VerticalHeroStatsWidget**: Vertikale Ansicht für Detailseiten

### 4. EnhancedHeroCardWidget
**Datei:** `enhanced_hero_card_widget.dart`

Die Haupt-Heldenkarte mit drei Ansichtsmodi:

#### Kompakte Ansicht
- Avatar + Basis-Informationen
- Kompakte Stats-Chips
- Quick-Action Buttons

#### Detaillierte Ansicht
- Großer Avatar mit vollständigen Informationen
- Alle Stats-Chips
- Top-Attribute mit Farbindikatoren
- Aktion-Leiste mit Bearbeiten/Aktionen-Buttons

#### Grid-Ansicht
- Kompakte Karten für 2-Spalten-Layout
- Wichtige Informationen auf minimalem Raum
- Touch-freundliche Action-Icons

## Integration

### PC List Screen
**Datei:** `../screens/pc_list_screen.dart`

Vollständig überarbeitet mit:
- Suchleiste mit Echtzeit-Filterung
- Sortier-Optionen (Name, Level, Klasse, Spieler, Favoriten)
- Favoriten-Filter
- Ansichtswechsel (Kompakt/Detailliert/Grid)
- Moderne Empty-States mit Filter-Rücksetzung

### Campaign Heroes Tab
**Datei:** `../widgets/campaign_heroes_tab.dart`

Gleiche Funktionalität wie PC List Screen, aber als Tab-Implementierung:
- Identische Such- und Filter-Features
- Ansichtswechsel-Integration
- Konsistente User Experience

## Features

### Such- und Filterfunktionen
- **Echtzeitsuche**: Name, Klasse, Spieler
- **Favoriten-Filter**: Zeige nur favorisierte Helden
- **Sortier-Optionen**: Nach verschiedenen Kriterien sortieren
- **Filter-Rücksetzung**: Schnelles Zurücksetzen aller Filter

### Ansichtsmodi
- **Kompakt**: Optimal für große Listen mit schnellem Überblick
- **Detailliert**: Vollständige Informationen pro Held
- **Grid**: Platzsparende 2-Spalten-Ansicht

### Quick Actions
- **Bearbeiten**: Direkter Zugriff auf Character Editor
- **Duplizieren**: Schnelles Kopieren von Charakteren (TODO)
- **Favoriten**: Toggle für Favoriten-Status
- **Löschen**: Mit Bestätigungsdialog

### Visuelle Verbesserungen
- **Klassenfarben**: Jede Klasse hat charakteristische Farben
- **Status-Indikatoren**: Visuelle HP/AC/Initiative-Anzeigen
- **Level-Badges**: Farbcodierte Level-Anzeigen
- **Responsive Design**: Passt sich an verschiedene Bildschirmgrößen an

## Technische Details

### Farben
- **Krieger/Barbar**: Rot-Töne
- **Magier/Hexenmeister**: Blau/Violett
- **Kleriker/Paladin**: Gold/Weiß
- **Schurke/Schütze**: Grau/Schwarz
- **Druide/Mönch**: Grün/Braun
- **Barde**: Lila/Rosa

### Attribute-Qualität
- **Niedrig (1-8)**: Rot
- **Durchschnitt (9-12)**: Gelb
- **Gut (13-15)**: Grün
- **Hervorragend (16+)**: Blau

### Sortierlogik
- alphabetisch nach Namen
- numerisch nach Level
- alphabetisch nach Klasse
- alphabetisch nach Spielername
- Favoriten zuerst
- nach letzter Bearbeitung (TODO)

## Zukünftige Erweiterungen

### Geplant
- [ ] Datenbank-Integration für Favoriten/Lösch-Funktionen
- [ ] Duplizieren-Funktionalität
- [ ] RecentlyEdited Sortierung implementieren
- [ ] Drag & Drop für Listen-Reihenfolge
- [ ] Batch-Operationen (mehrere Helden auswählen)
- [ ] Export/Import-Funktionen

### Optinal
- [ ] Custom Klassenfarben
- [ ] Avatar-Upload-Integration
- [ ] Helden-Gruppen/Tags
- [ ] Erweiterte Statistik-Filter
- [ ] Vergleichs-Modus für Helden

## Nutzung

### Eigenen Widget erstellen
```dart
EnhancedHeroCardWidget(
  character: myCharacter,
  viewMode: HeroCardViewMode.compact,
  onTap: () => print('Tapped ${myCharacter.name}'),
  onEdit: () => navigateToEdit(myCharacter),
  onFavoriteToggle: () => toggleFavorite(myCharacter),
  onQuickAction: () => showActionMenu(myCharacter),
)
```

### Helper-Funktionen nutzen
```dart
// Klassenfarbe erhalten
final color = CharacterListHelpers.getClassColor(character.className);

// Attribute sortieren
final sorted = CharacterListHelpers.compareCharacters(char1, char2, SortOption.level);

// HP-Status erhalten
final hpColor = CharacterListHelpers.getHpStatusColor(currentHp, maxHp);
```

## Performance

Die neue Implementierung ist optimiert für:
- **Memory**: Wiederverwendbare Widgets und konstante Farben
- **Rendering**: Lazy Loading in Listen und Grids
- **Animation**: Minimalistische, flüssige Übergänge
- **Suche**: Effiziente Filterung mit Delay

## Compatibility

Die neuen Widgets sind vollständig abwärtskompatibel mit:
- Existierenden `PlayerCharacter` Modellen
- Aktuellem `UnifiedCharacterEditorScreen`
- Bestehender Datenbankstruktur

Keine Breaking Changes wurden eingeführt.
