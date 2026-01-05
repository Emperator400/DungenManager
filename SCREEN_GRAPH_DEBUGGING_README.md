# Screen Graph Visualizer - Debugging Tool

## Übersicht

Der Screen Graph Visualizer ist ein interaktives Debugging-Tool, das alle Screens der Dungeon Manager Anwendung und ihre Navigation-Verbindungen als Graph visualisiert. Dies hilft bei der gezielten Verbesserung einzelner Screens.

## Features

### 📊 Interaktiver Graph
- **Visuelle Darstellung aller Screens** mit their Verbindungen
- **Kategorie-basierte Filterung** (Navigation, Campaign, Quests, Wiki/Lore, Character, Bestiary, Items, Audio, Sessions, Utility, Testing)
- **Farbcodierte Verbindungen** nach Typ:
  - 🟢 **Grün**: Normale Navigation
  - 🟣 **Lila**: Deep Link (mit Parametern)
  - 🟠 **Orange**: Modal/Dialog
  - 🔵 **Blau**: Button/Action

### 🎯 Screen-Details
- **Klick auf Screen**: Zeigt detaillierte Informationen im rechten Panel
- **Parameter-Warnung**: Zeigt an, ob ein Screen Parameter benötigt
- **Verbindungs-Übersicht**: Listet alle Navigation-Verbindungen mit Trigger und Beschreibung

### 🔧 Navigations-Optionen
- **Verbindungen ein/ausblenden**: Toggle für Verbindungslinien
- **Parameter ein/ausblenden**: Toggle für Parameter-Indikatoren
- **Filter-Chips**: Schnelles Filtern nach Kategorien
- **Listenansicht**: Übersicht aller Screens in einer Liste
- **Info-Dialog**: Erklärung der Bedienung

## Installation

Das Tool ist bereits Teil der Anwendung und benötigt keine zusätzliche Installation.

## Verwendung

### Zugriff auf den Screen Graph Visualizer

Es gibt mehrere Möglichkeiten, auf das Tool zuzugreifen:

#### Option 1: Über die AllScreensScreen
```dart
// In lib/screens/all_screens_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ScreenGraphVisualizationScreen(),
  ),
);
```

#### Option 2: Direkter Import
```dart
import 'lib/screens/screen_graph_visualization_screen.dart';

// Verwendung
ScreenGraphVisualizationScreen()
```

### Bedienung

1. **Graph navigieren**:
   - Der Graph zeigt alle Screens gruppiert nach Kategorien
   - Screens sind als Kreise mit farbcodierten Rahmen dargestellt
   - Klick auf einen Screen zeigt Details an

2. **Filter verwenden**:
   - Oben befinden sich Filter-Chips für jede Kategorie
   - Klick auf einen Chip zeigt nur Screens dieser Kategorie

3. **Details anzeigen**:
   - Klick auf einen Screen im Graph
   - Rechtes Panel zeigt:
     - Screen-Name
     - Dateiname
     - Kategorie
     - Parameter-Anforderungen (falls vorhanden)
     - Alle Verbindungen mit Triggern

4. **Verbindungen verstehen**:
   - Die Pfeile zeigen Navigations-Richtung an
   - Die Farbe gibt den Verbindungstyp an
   - Hover über einer Verbindung zeigt Details (in zukünftigen Versionen)

## Screen-Kategorien

| Kategorie | Farbe | Beschreibung |
|-----------|--------|--------------|
| Navigation | 🟣 Lila | Haupt-Navigations-Screens |
| Campaign | 🟡 Gold | Kampagnen-Management |
| Quest Management | 🟢 Grün | Quest-Bibliothek und -Verwaltung |
| Wiki/Lore | 🔵 Blau | Wissen- und Lore-Management |
| Character | 🟠 Orange | Charakter- und Creature-Management |
| Bestiary | 🔴 Rot | Monster- und Bestiarium-Screens |
| Item | ⚪ Grau | Item-Bibliothek und -Verwaltung |
| Audio | 🔵 Blau | Sound-Bibliothek und -Mixing |
| Session | 🟢 Grün | Session- und Scene-Management |
| Utility | 🟠 Orange | Hilfs-Screens für Links und Hinzufügen |
| Testing | 🟣 Lila | Test- und Debugging-Screens |

## Verbindungstypen

### Navigation (Grün)
Normale Navigation von einem Screen zu einem anderen ohne spezielle Parameter.

### Deep Link (Lila)
Navigation mit Parametern, z.B. `EnhancedMainNavigationScreen` → `EnhancedPlayerCharacterListScreen` mit Campaign-Parameter.

### Modal (Orange)
Öffnet einen Dialog oder Modal-Screen über dem aktuellen Screen.

### Action (Blau)
Button-basierte Aktion, die zu einem anderen Screen navigiert.

## Parameter-Anforderungen

Screens, die Parameter benötigen, werden mit einem orangenen Indikator gekennzeichnet:

⚠️ **Benötigt: Campaign**
⚠️ **Benötigt: Quest**
⚠️ **Benötigt: PlayerCharacter**
⚠️ **Benötigt: Creature**
⚠️ **Benötigt: Session**
⚠️ **Benötigt: WikiEntry, ParentCategory**
⚠️ **Benötigt: Item**
⚠️ **Benötigt: Sound**
⚠️ **Benötigt: Scene**

## Debugging-Tipps

### 1. Navigation-Flüsse analysieren
- Verwenden Sie den Graph, um zu verstehen, wie Screens miteinander verbunden sind
- Identifizieren Sie kritische Pfade und mögliche Navigations-Schleifen
- Prüfen Sie, ob alle wichtigen Screens erreichbar sind

### 2. Parameter-Abhängigkeiten identifizieren
- Suchen Sie nach Screens mit Parameter-Warnungen
- Verstehen Sie, welche Parameter von welchem Screen benötigt werden
- Stellen Sie sicher, dass Parameter beim Navigieren korrekt übergeben werden

### 3. Screens kategorisieren
- Verwenden Sie die Filter, um Screens nach Bereich zu gruppieren
- Prüfen Sie, ob die Kategorisierung sinnvoll ist
- Identifizieren Sie Screens, die möglicherweise falsch kategorisiert sind

### 4. Unnötige Verbindungen finden
- Suchen Sie nach nicht verwendeten Screens
- Prüfen Sie, ob Verbindungen zu nicht existierenden Screens führen
- Identifizieren Sie broken links oder todt code

## Aktuelle Screens (Stand: 2026-01-04)

**Gesamt: 28 Screens in 11 Kategorien**

### Navigation (1 Screen)
- Enhanced Main Navigation

### Campaign (3 Screens)
- Campaign Dashboard
- Edit Campaign
- Campaign Selection

### Quest Management (4 Screens)
- Quest Library
- Edit Quest
- Add Quest from Library
- Edit Campaign Quest
- Link Quest to Scene

### Wiki/Lore (4 Screens)
- Lore Keeper
- Edit Wiki Entry
- Link Wiki Entries
- Link Entry to Scene

### Character (5 Screens)
- Unified Character Editor
- Edit Player Character
- Player Character List
- Encounter Setup
- Initiative Tracker

### Bestiary (2 Screens)
- Bestiary
- Official Monsters
- Edit Creature

### Item (3 Screens)
- Item Library
- Edit Item
- Add Item from Library

### Audio (3 Screens)
- Sound Library
- Edit Sound
- Add Sound to Scene

### Session (4 Screens)
- Session List for Campaign
- Active Session
- Edit Session
- Edit Scene

### Utility (3 Screens)
- Add Quest from Library
- Add Item from Library
- Add Sound to Scene
- Link Quest to Scene
- Link Entry to Scene
- Link Wiki Entries
- Edit Campaign Quest

### Testing (1 Screen)
- All Screens (Testing)

## Erweiterungsmöglichkeiten

### Geplant
- [ ] **Export-Funktion**: Graph als PNG/SVG/JSON exportieren
- [ ] **Suche**: Screens nach Name oder Dateiname durchsuchen
- [ ] **Zoom/Pan**: Interaktives Navigieren im Graph
- [ ] **Connection-Details**: Hover über Verbindungen zeigt Trigger
- [ ] **Live-Update**: Automatische Aktualisierung bei Änderungen
- [ ] **Historie**: Änderungen am Graph über Zeit verfolgen

### Zukünftige Verbesserungen
- [ ] **Code-Integration**: Direktes Springen zum Code aus dem Graph
- [ ] **Dependency-Tree**: Zeigt Abhängigkeiten zwischen Screens
- [ ] **Heatmap**: Häufigkeit der Screen-Nutzung visualisieren
- [ ] **User-Flow-Tracking**: Benutzer-Navigationspfade aufzeichnen

## Technische Details

### Dateistruktur
```
lib/
├── models/
│   └── screen_node.dart              # Modelle für Screen-Nodes und Verbindungen
├── services/
│   └── screen_graph_service.dart      # Service für Screen-Analyse
└── screens/
    └── screen_graph_visualization_screen.dart  # UI-Komponente
```

### Key Komponenten

#### ScreenNode
```dart
class ScreenNode {
  final String name;
  final String fileName;
  final String category;
  final List<ScreenConnection> connections;
  final bool requiresParameters;
  final String? parameterInfo;
}
```

#### ScreenConnection
```dart
class ScreenConnection {
  final String targetScreen;
  final String? triggerAction;
  final String? description;
  final ConnectionType type;  // navigation, modal, deepLink, action
}
```

### CustomPaint
Der Graph wird mit einem `CustomPaint` gerendert, der:
- Knoten positioniert (kategorisiert in einem Raster)
- Verbindungen als Pfeile zeichnet
- Hover-Effekte und Selection-Highlighting implementiert

## Troubleshooting

### Graph wird nicht angezeigt
**Problem**: Der Graph-Bereich bleibt leer oder zeigt Lade-Indikator.

**Lösung**:
1. Prüfen Sie, ob `ScreenGraphService.getManualScreenData()` Daten zurückgibt
2. Stellen Sie sicher, dass alle Screen-Dateien existieren
3. Prüfen Sie die Konsole auf Fehlermeldungen

### Screens fehlen
**Problem**: Einige Screens werden im Graph nicht angezeigt.

**Lösung**:
1. Prüfen Sie `screen_graph_service.dart` - ist der Screen in `getManualScreenData()` definiert?
2. Stellen Sie sicher, dass der Screen-Name korrekt ist
3. Aktualisieren Sie den Service und laden Sie die Daten neu

### Verbindungen fehlen
**Problem**: Einige Navigations-Pfeile werden nicht angezeigt.

**Lösung**:
1. Prüfen Sie, ob `showConnections` aktiviert ist
2. Stellen Sie sicher, dass `targetScreen` exakt mit dem Ziel-Screen-Namen übereinstimmt
3. Prüfen Sie die ConnectionType-Klassifikation

## Beiträge

Wenn Sie Fehler finden oder Verbesserungen vorschlagen möchten:
1. Öffnen Sie ein Issue im Repository
2. Beschreiben Sie das Problem oder den Vorschlag
3. Fügen Sie wenn möglich Screenshots hinzu

## Lizenz

Dieses Tool ist Teil des Dungeon Manager Projekts und unterliegt der gleichen Lizenz.

---

**Erstellt am**: 2026-01-04  
**Version**: 1.0.0  
**Autor**: Dungeon Manager Development Team
