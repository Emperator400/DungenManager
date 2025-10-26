# Inventar-Neugestaltung

Die Ausrüstungskammer wurde vollständig visuell überarbeitet mit modernen Karten und einem seitlichen Info-Panel.

## Neue Komponenten

### 1. ItemColorHelper
- `lib/widgets/character_editor/item_color_helper.dart`
- Zentrale Farb-Verwaltung für alle Item-Typen
- Dunkles Farbschema optimiert
- Icons und Display-Namen für Item-Typen
- Rarity-Farben und Haltbarkeits-Indikatoren

### 2. ItemCardWidget
- `lib/widgets/character_editor/item_card_widget.dart`
- Moderne Karten-Darstellung für Items
- Größe: 120x150px (kompakter für bessere Übersicht)
- Zeigt: Icon, Name, Typ, Gewicht, Menge, Haltbarkeit
- Rarity-Rahmen und Selektions-Status
- Drag & Drop Unterstützung

### 3. ItemDetailPanel
- `lib/widgets/character_editor/item_detail_panel.dart`
- Seitliches Info-Panel (400px breit)
- Slidet von rechts mit Animation (300ms)
- Zeigt alle Item-Informationen strukturiert
- Typ-spezifische Details (Waffen, Rüstung, Zauber)
- Aktionen: Ausrüsten/Ablegen, Bearbeiten, Löschen

### 4. EnhancedInventoryGridWidget
- `lib/widgets/character_editor/enhanced_inventory_grid_widget.dart`
- **Seitenaufteilung**: Links Inventar (2/3 Breite), rechts Ausrüstung (1/3 Breite)
- Responsive Grid-Layout für Inventar-Items (3-6 Spalten)
- Kompakte Ausrüstungs-Slots in Kategorien gruppiert
- **Inventar-Statistik**: Gesamtgewicht und Gesamtwert aller Items
- Drag & Drop Targets für Ausrüstung
- Optimiert für schnelle Erkennung ausgerüsteter Items

### 5. EnhancedInventoryTabWidget
- `lib/widgets/character_editor/enhanced_inventory_tab_widget.dart`
- Haupt-Widget mit voller Funktionalität
- Animationen für Detail-Panel
- Dark Mode optimiert
- Gold-Management für NPCs/Monster
- Ansichts-Wechsel (Grid/Liste)

## Farbschema (Dark Mode)

### Item-Typ Farben
- Waffen: `Colors.red.shade800`
- Rüstung: `Colors.blue.shade800`
- Schild: `Colors.cyan.shade800`
- Ausrüstung: `Colors.green.shade800`
- Schatz: `Colors.amber.shade800`
- Magisches Item: `Colors.purple.shade800`
- Zauber: `Colors.deepPurple.shade800`
- Verbrauchbar: `Colors.orange.shade800`
- Werkzeug: `Colors.brown.shade800`
- Material: `Colors.grey.shade700`
- Komponente: `Colors.teal.shade800`
- Schriftrolle: `Colors.indigo.shade800`
- Trank: `Colors.pink.shade800`
- Währung: `Colors.yellow.shade800`

### Rarity-Farben
- Common: `Colors.grey.shade600`
- Uncommon: `Colors.green.shade700`
- Rare: `Colors.blue.shade700`
- Very Rare: `Colors.purple.shade700`
- Legendary: `Colors.orange.shade700`

## Animationen

### Slide-Animation
- Dauer: 300ms
- Curve: `Curves.easeInOut`
- Richtung: Von rechts nach links

### Fade-Animation
- Dauer: 200ms
- Curve: `Curves.easeInOut`
- Für Overlay-Hintergrund

## Responsive Design

### Breakpoints
- `< 500px`: 3 Spalten
- `500-700px`: 4 Spalten
- `700-1000px`: 5 Spalten
- `> 1000px`: 6 Spalten

### Item-Karten
- Feste Größe: 120x150px
- Abstände: 12px horizontal/vertikal
- Aspect Ratio: 120/150

## Benutzerinteraktionen

### Karten
- **Tap**: Öffnet Detail-Panel
- **Long Press**: Startet Drag & Drop
- **Hover**: Leichter Schatten-Effekt

### Detail-Panel
- **Overlay-Hintergrund**: Schließt Panel
- **Schließen-Button**: Schließt Panel
- **Aktionen**: Je nach Berechtigungen

### Ausrüstungs-Slots
- **Drag Target**: Highlight bei gültigem Item
- **Remove-Button**: Nur wenn editierbar

## Integration

Um die neue Inventar-Ansicht zu verwenden, ersetzen Sie in der `unified_character_editor_screen.dart`:

```dart
// Alt
InventoryTabWidget(...)

// Neu
EnhancedInventoryTabWidget(...)
```

Die neuen Widgets verwenden die gleichen Parameter und sind Drop-in-kompatibel.
