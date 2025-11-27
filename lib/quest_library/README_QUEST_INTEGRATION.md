# Quest-System Integration in Lore Keeper

## Übersicht

Das Quest-System wurde erfolgreich in den Lore Keeper integriert und bietet eine moderne, benutzerfreundliche Oberfläche zur Verwaltung von Quest-Vorlagen für D&D-Kampagnen.

## 🎯 Hauptziele der Integration

- **Zentrale Verwaltung**: Alle Quest-Vorlagen an einem Ort
- **Schneller Zugriff**: Über den Lore Keeper auf Quest-Bibliothek zugreifen
- **Konsistentes Design**: Gleiche UI-Komponenten wie Wiki-Einträge
- **Flexible Filterung**: Nach Typ, Schwierigkeit, Tags und Favoriten filtern
- **Volltextsuche**: Intelligente Suche über alle Quest-Felder

## 📁 Dateistruktur

```
lib/
├── models/
│   └── quest.dart                    # Erweitertes Quest-Modell
├── widgets/quest_library/
│   ├── quest_card_widget.dart        # Quest-Karte
│   ├── quest_filter_chips_widget.dart # Filter-Chips
│   └── quest_search_delegate.dart    # Suchfunktion
├── screens/
│   ├── enhanced_quest_library_screen.dart # Moderne Quest-Bibliothek
│   └── enhanced_edit_quest_screen.dart     # Quest-Editor
└── database/
    └── database_helper.dart         # Erweiterte Datenbank-Methoden
```

## 🏗️ Architektur

### 1. Datenmodell

Das Quest-Modell wurde um folgende Felder erweitert:

- **QuestType**: `main`, `side`, `personal`, `faction`
- **QuestDifficulty**: `easy`, `medium`, `hard`, `deadly`, `epic`
- **Metadaten**: Level-Empfehlung, Dauer, Tags, Belohnungen
- **Lore-Integration**: Ort, beteiligte NPCs
- **Favoriten-System**: Schneller Zugriff auf wichtige Quests

### 2. UI-Komponenten

#### QuestCardWidget
- Moderne Karten-Darstellung
- Farbliche Kodierung nach Schwierigkeit
- Direkte Aktionen (Bearbeiten, Löschen, Favorit)
- Responsive Metadaten-Anzeige

#### QuestFilterChipsWidget
- Filter nach Typ und Schwierigkeit
- Dynamische Tag-Filterung
- Favoriten-Filter
- "Alle Filter löschen" Funktion

#### QuestSearchDelegate
- Volltextsuche über alle Felder
- Intelligente Sortierung (Relevanz, Alphabetisch)
- Vorschläge für schnellen Zugriff
- Kontextbezogene Suche

### 3. Screens

#### EnhancedQuestLibraryScreen
- Tab-basierte Navigation (Alle, Hauptquests, Favoriten)
- Integrierte Filterung und Suche
- Drag-to-Refresh Funktionalität
- Floating Action Button für neue Quests

#### EnhancedEditQuestScreen
- Formular-basierte Quest-Erstellung/Bearbeitung
- Organisiert in Sektionen (Grundinfos, Beschreibung, etc.)
- Echtzeit-Validierung
- CSV-Eingabe für Listen (Tags, Belohnungen, NPCs)

## 🔗 Integration mit Lore Keeper

### 1. Navigations-Integration

Die Quest-Bibliothek kann über verschiedene Punkte erreicht werden:

```dart
// Von der Hauptnavigation
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => EnhancedQuestLibraryScreen()),
);

// Vom Lore Keeper
// (TODO: Navigationspunkt im Lore Keeper hinzufügen)
```

### 2. Wiki-Verknüpfungen

Quests können mit Wiki-Einträgen verknüpft werden:

- **Orte**: Quest-Location → Wiki-Ortsseite
- **NPCs**: Beteiligte NPCs → Wiki-Charakterseiten
- **Fraktionen**: Quest-Typ → Wiki-Fraktionsseite
- **Tags**: Flexible Verknüpfungen zu Wiki-Kategorien

### 3. Kampagnen-Integration

Quest-Vorlagen können in Kampagnen verwendet werden:

```dart
class CampaignQuest {
  final Quest quest;           // Vorlage aus Bibliothek
  final QuestStatus status;     // Status in Kampagne
  final String? notes;         // Kampagnenspezifische Notizen
}
```

## 🎨 Design-System

### Farb-Kodierung

- **Leicht (Easy)**: Grün (`successGreen`)
- **Mittel (Medium)**: Blau (`mysticalPurple`)
- **Schwer (Hard)**: Orange (`ancientGold`)
- **Tödlich (Deadly)**: Rot (`errorRed`)
- **Episch (Epic)**: Lila (`ancientGold`)

### Icons

- **Hauptquest**: `Icons.flag`
- **Sidequest**: `Icons.explore`
- **Persönlich**: `Icons.person`
- **Fraktion**: `Icons.group`

### Typography

Konsistente Verwendung des DnDTheme für:
- Überschriften (18px, Bold)
- Metadaten (14px, Medium)
- Beschreibungen (12px, Regular)

## 🚀 Verwendung

### 1. Neue Quest erstellen

```dart
// Öffne Quest-Bibliothek
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => EnhancedQuestLibraryScreen()),
);

// Klicke auf FloatingActionButton → EnhancedEditQuestScreen
```

### 2. Quest suchen und filtern

```dart
// Volltextsuche
final selectedQuest = await showSearch<Quest?>(
  context: context,
  delegate: QuestSearchDelegate(
    allQuests: quests,
    // Filter können übergeben werden
  ),
);

// Direkte Filterung über QuestFilterChipsWidget
```

### 3. Quest in Kampagne integrieren

```dart
final campaignQuest = CampaignQuest(
  quest: selectedQuestFromLibrary,
  status: QuestStatus.verfuegbar,
  notes: "Für die aktuelle Party geeignet",
);

// Zur Kampagne hinzufügen
campaign.addQuest(campaignQuest);
```

## 🔄 Datenbank-Migration

Die Datenbank wurde um folgende Felder erweitert:

```sql
ALTER TABLE quests ADD COLUMN quest_type TEXT DEFAULT 'side';
ALTER TABLE quests ADD COLUMN difficulty TEXT DEFAULT 'medium';
ALTER TABLE quests ADD COLUMN recommended_level INTEGER;
ALTER TABLE quests ADD COLUMN estimated_duration_hours INTEGER;
ALTER TABLE quests ADD COLUMN tags TEXT DEFAULT '';
ALTER TABLE quests ADD COLUMN rewards TEXT DEFAULT '';
ALTER TABLE quests ADD COLUMN location TEXT;
ALTER TABLE quests ADD COLUMN involved_npcs TEXT DEFAULT '';
ALTER TABLE quests ADD COLUMN is_favorite INTEGER DEFAULT 0;
ALTER TABLE quests ADD COLUMN created_at INTEGER;
ALTER TABLE quests ADD COLUMN updated_at INTEGER;
```

## 🎯 Zukunftige Erweiterungen

### 1. Automatische Verknüpfungen

- NPCs automatisch im Wiki anlegen
- Ortsverknüpfungen automatisch erstellen
- Tag-basierte Wiki-Kategorien

### 2. Quest-Verläufe

- Status-Verfolgung für Kampagnen
- Zeitleisten für Quest-Entwicklung
- Spieler-Notizen integrieren

### 3. Import/Export

- Quest-Vorlagen exportieren/importieren
- Community-Quest-Bibliothek
- Vorlagen aus anderen Systemen

### 4. Erweiterte Filterung

- Datum-basierte Filter
- Komplexe Tag-Kombinationen
- Spieler-Level-basierte Empfehlungen

## 🧪 Tests

Die Quest-Bibliothek umfasst folgende Tests:

```dart
// Unit-Tests
test('Quest Modell korrekt serialisiert', () { ... });
test('Quest Filter funktioniert', () { ... });

// Widget-Tests
testWidgets('QuestCardWidget rendert korrekt', (tester) async { ... });
testWidgets('QuestFilterChipsWidget funktioniert', (tester) async { ... });

// Integration-Tests
testWidgets('Gesamter Quest-Workflow', (tester) async { ... });
```

## 📱 Performance-Optimierungen

- **Lazy Loading**: Quests werden bei Bedarf geladen
- **Effiziente Filterung**: Client-seitige Filterung mit Listen
- **Caching**: Häufig verwendete Quests werden gecacht
- **Deduplizierung**: Keine doppelten Datenbank-Abfragen

## 🔧 Konfiguration

Die Quest-Bibliothek kann über folgende Parameter konfiguriert werden:

```dart
class QuestConfig {
  static const int maxTagsPerQuest = 10;
  static const int maxRewardsPerQuest = 20;
  static const int maxNpcsPerQuest = 15;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 2000;
}
```

## 🎨 Themen-Anpassung

Die Quest-Bibliothek verwendet das DnDTheme und passt sich automatisch an:

```dart
// Farben für Schwierigkeitsgrade
static const Map<QuestDifficulty, Color> difficultyColors = {
  QuestDifficulty.easy: DnDTheme.successGreen,
  QuestDifficulty.medium: DnDTheme.mysticalPurple,
  QuestDifficulty.hard: DnDTheme.ancientGold,
  QuestDifficulty.deadly: DnDTheme.errorRed,
  QuestDifficulty.epic: Colors.deepPurple,
};
```

---

Diese Integration schafft eine nahtlose Verbindung zwischen Quest-Management und Lore-Keeper, sodass Dungeon Masters alle Aspekte ihrer Kampagne an einem Ort verwalten können.
