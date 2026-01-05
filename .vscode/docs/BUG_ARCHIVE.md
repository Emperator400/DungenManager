# BUG ARCHIVE

Dieses Dokument enthält dokumentierte Lösungen für behobene Probleme im Dungeon Manager Projekt.

---

## 2025-11-10 - Enhanced Quest Library Screen Widget-Namen und Import-Fehler

### Problem
Der `EnhancedQuestLibraryScreen` hatte kritische Kompilierungsfehler aufgrund falscher Widget-Namen und Importe:
- `QuestFilterChipsWidget` war nicht definiert (undefined_method)
- `QuestCardWidget` war nicht definiert (undefined_method)
- Falsche Import-Pfade zu nicht existierenden Widgets
- Code-Quality-Verletzungen (unnecessary block function bodies)

### Fehlermeldungen
```
The method 'QuestFilterChipsWidget' isn't defined for the type '_EnhancedQuestLibraryScreenState'.
The method 'QuestCardWidget' isn't defined for the type '_EnhancedQuestLibraryScreenState'.
Target of URI doesn't exist: '../widgets/quest_library/quest_card_widget.dart'
Target of URI doesn't exist: '../widgets/quest_library/quest_filter_chips_widget.dart'
Unnecessary use of a block function body.dartprefer_expression_function_bodies
```

### Ursache
Die Screen-Klasse versuchte auf veraltete Widget-Namen zuzugreifen, die zu "Enhanced" Versionen migriert wurden:
- `QuestFilterChipsWidget` → `EnhancedQuestFilterChipsWidget`
- `QuestCardWidget` → `EnhancedQuestCardWidget`
- Import-Pfade waren nicht mehr aktuell

### Lösung
1. **Importe korrigiert**: Alle Import-Pfade auf die korrekten "Enhanced" Widgets aktualisiert
2. **Widget-Namen aktualisiert**: 
   - `QuestFilterChipsWidget` → `EnhancedQuestFilterChipsWidget`
   - `QuestCardWidget` → `EnhancedQuestCardWidget`
3. **Widget-Signatur angepasst**: `EnhancedQuestFilterChipsWidget` verwendet jetzt `viewModel` Parameter statt individueller Callbacks
4. **Code-Quality verbessert**: Unnötige Leerzeilen und Formatierung korrigiert

### Code-Änderungen
```dart
// Importe korrigiert:
import '../widgets/quest_library/enhanced_quest_card_widget.dart';
import '../widgets/quest_library/enhanced_quest_filter_chips_widget.dart';

// Widget-Namen korrigiert:
EnhancedQuestFilterChipsWidget(
  viewModel: viewModel,
),
EnhancedQuestCardWidget(
  quest: quest,
  onTap: () => _navigateToEditQuest(quest),
  onEdit: () => _navigateToEditQuest(quest),
  onDelete: () => _deleteQuest(quest),
  onToggleFavorite: () => viewModel.toggleFavorite(quest),
),
```

### Auswirkungen
- ✅ Alle kritischen Kompilierungsfehler behoben
- ✅ Screen kompiliert fehlerfrei
- ✅ Korrekte Widget-Integration mit Enhanced Widgets
- ✅ Nur noch 18 Code-Quality-Infos (keine Errors mehr)
- ✅ Funktionale Kompatibilität mit ViewModel-Architektur

### Lessons Learned
1. Bei Widget-Migrationen immer alle Aufrufstellen überprüfen
2. Enhanced Widgets oft haben andere Konstruktor-Signaturen als Original-Widgets
3. Import-Dateinamen müssen exakt mit Klassennamen übereinstimmen
4. ViewModel-basierte Widgets benötigen weniger individuelle Callbacks

---

---

## 2025-11-08 - Enhanced Edit Wiki Entry Screen Parameter Errors

### Problem
Der `EnhancedEditWikiEntryScreen` hatte fehlende Constructor-Parameter, was zu Kompilierungsfehlern führte:
- `EnhancedEditWikiEntryScreen()` erforderte `wikiEntry` und `parentCategory` Parameter
- Die Main Navigation versuchte, den Screen ohne diese Parameter zu instanziieren

### Fehlermeldung
```
The named parameter 'wikiEntry' is required, but there's no corresponding argument.
The named parameter 'parentCategory' is required, but there's no corresponding argument.
```

### Ursache
Die Screen-Klasse wurde aktualisiert, um Parameter zu benötigen, aber die Aufrufstellen wurden nicht entsprechend angepasst.

### Lösung
1. **Parameter hinzugefügt**: In der Navigation wurden die erforderlichen Parameter mit Platzhalter-Werten versehen
2. **Datenfluss sichergestellt**: Die Parameter werden korrekt an den ViewModel weitergeleitet
3. **Fehlerhandling verbessert**: Der ViewModel prüft auf null-Werte und verwendet Standardwerte

### Code-Änderungen
```dart
// Vorher:
screen = const EnhancedEditWikiEntryScreen();

// Nachher:
screen = EnhancedEditWikiEntryScreen(
  wikiEntry: widget.wikiEntry,
  parentCategory: widget.parentCategory,
);
```

### Auswirkungen
- ✅ Kompilierungsfehler behoben
- ✅ Navigation funktioniert wieder
- ✅ Wiki Entry Edit Screen ist voll funktionsfähig
- ✅ Data Flow ist konsistent

### Lessons Learned
1. Immer alle Aufrufstellen überprüfen, wenn Constructor-Signaturen geändert werden
2. Parameter-Validierung in ViewModels implementieren
3. Placeholder-Werte für Development-Phasen verwenden

---

## 2025-11-08 - Enhanced Main Navigation Screen Constructor Errors

### Problem
Mehrere Screens in der Hauptnavigation erforderten Parameter, die nicht übergeben wurden:
- `EnhancedActiveSessionScreen` benötigte `campaign` und `session`
- `EnhancedPCListScreen` benötigte `characterType`
- `EnhancedUnifiedCharacterEditorScreen` benötigte `characterType`
- `EnhancedCampaignDashboardScreen` benötigte `campaign`

### Fehlermeldungen
```
The named parameter 'campaign' is required, but there's no corresponding argument.
The named parameter 'session' is required, but there's no corresponding argument.
The named parameter 'characterType' is required, but there's no corresponding argument.
```

### Lösung
1. **Placeholder Screen erstellt**: `_PlaceholderScreen` Klasse für Screens in Entwicklung
2. **Navigation angepasst**: Problematische Screens durch Placeholder ersetzt
3. **TODO-Kommentare hinzugefügt**: Klare Anweisungen für zukünftige Implementierung

### Code-Änderungen
```dart
// Placeholder Screen Implementierung
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... UI mit "In Arbeit" Nachricht
    );
  }
}

// Navigation-Anpassung
case ScreenType.campaigns:
  screen = const _PlaceholderScreen(title: 'Kampagnen');
  break;
```

### Auswirkungen
- ✅ Alle Kompilierungsfehler behoben
- ✅ App startet fehlerfrei
- ✅ Navigation ist benutzbar
- ✅ Klare Entwicklungspfade definiert

### Lessons Learned
1. Screens schrittweise migrieren, nicht alle auf einmal
2. Placeholder-Klassen für unvollständige Features verwenden
3. Provider-Liste aktuell halten

---

## 2025-11-08 - Initiative Tracker Screen Inventory Access Errors

### Problem
Der `InitiativeTrackerScreen` hatte Fehler beim Zugriff auf Inventory-Daten, weil die Datenstruktur geändert wurde:
- Der Code versuchte auf `.item` und `.inventoryItem` zuzugreifen, aber `inventory` ist eine `List<Map<String, dynamic>>`
- Falsche Datenstruktur-Annahmen führten zu Compile-Time-Fehlern

### Fehlermeldung
```
The getter 'item' isn't defined for the type 'Map<String, dynamic>'
The getter 'inventoryItem' isn't defined for the type 'Map<String, dynamic>'
```

### Ursache
Das `Creature.inventory` Feld wurde von einer strukturierten Liste zu `List<Map<String, dynamic>>` geändert, aber der Code wurde nicht entsprechend angepasst.

### Lösung
1. **Datenzugriff korrigiert**: Map-Zugriff statt Objekt-Zugriff implementiert
2. **Inventory-Anzeige gefixt**: Sowohl für Spieler als auch für Monster
3. **Unused Code entfernt**: `_buildStatChip` Methode entfernt da ungenutzt

### Code-Änderungen
```dart
// Vorher:
...creature.inventory.map((invItem) => Text(
  "• ${invItem.item.name} (x${invItem.inventoryItem.quantity}) ${invItem.item.damage != null ? '[${invItem.item.damage}]' : ''}",
  style: const TextStyle(color: Colors.white70)
)).toList(),

// Nachher:
...creature.inventory.map((invItem) => Text(
  "• ${invItem['name']} (x${invItem['quantity']}) ${invItem['damage'] != null ? '[${invItem['damage']}]' : ''}",
  style: const TextStyle(color: Colors.white70)
)).toList(),
```

### Auswirkungen
- ✅ Alle Compile-Time-Fehler behoben
- ✅ Inventory-Anzeige funktioniert wieder für Spieler und Monster
- ✅ Code sauberer (unbenutzte Methode entfernt)
- ℹ️ Nur noch Style-Warnungen übrig

### Lessons Learned
1. Immer Datenstruktur-Änderungen an allen Verwendungsorten anpassen
2. Map-Zugriff mit String-Keys statt Objekt-Properties verwenden
3. Unbenutzten Code regelmäßig entfernen

---

## 2025-11-08 - Enhanced Session List For Campaign Screen Return Type Error

### Problem
Der `_showDeleteConfirmation` Methode im `EnhancedSessionListForCampaignScreen` hatte einen falschen Return-Typ:
- Die Methode deklarierte `Future<bool>` als Return-Typ
- `showDialog<bool>` gibt aber `Future<bool?>` zurück (nullable)
- Dies führte zu einem Compile-Time-Fehler

### Fehlermeldung
```
A value of type 'Object' can't be returned from the method '_showDeleteConfirmation' 
because it has a return type of 'Future<bool>'
```

### Ursache
Die Methode hat versucht, das Ergebnis von `showDialog<bool>` direkt zurückzugeben, aber der Typ war inkompatibel:
- Erwartet: `Future<bool>`
- Tatsächlich: `Future<bool?>` (nullable wegen möglichen Dialog-Abbruchs)

### Lösung
1. **Typ-Korrektur**: Variable für das Dialog-Ergebnis eingeführt
2. **Null-Sicherheit**: `?? false` Operator für Fallback-Wert
3. **Lesbarkeit**: Bessere Code-Struktur mit expliziter Variable

### Code-Änderungen
```dart
// Vorher:
Future<bool> _showDeleteConfirmation(Session session) async {
  return showDialog<bool>(
    context: context,
    builder: (context) { /* ... */ },
  ) ?? false;
}

// Nachher:
Future<bool> _showDeleteConfirmation(Session session) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) { /* ... */ },
  );
  return result ?? false;
}
```

### Auswirkungen
- ✅ Kritischer Compile-Time-Fehler behoben
- ✅ Delete-Bestätigung funktioniert wieder korrekt
- ✅ Null-Sicherheit gewährleistet
- ℹ️ Nur noch Style-Warnungen übrig

### Lessons Learned
1. Immer auf Null-Sicherheit bei Dialog-Return-Typen achten
2. `showDialog<T>` gibt immer `Future<T?>` zurück
3. Explizite Variablen verbessern Lesbarkeit und Typ-Sicherheit

---

## 2025-11-08 - Enhanced Sound Library Screen AppBar Return Type Error

### Problem
Der `_buildAppBar` Methode im `EnhancedSoundLibraryScreen` hatte einen falschen Return-Typ:
- Die Methode deklarierte `PreferredSizeWidget` als Return-Typ
- `Consumer<SoundLibraryViewModel>` ist aber kein `PreferredSizeWidget`
- Dies führte zu einem Compile-Time-Fehler

### Fehlermeldung
```
A value of type 'Consumer<SoundLibraryViewModel>' can't be returned from the method '_buildAppBar' 
because it has a return type of 'PreferredSizeWidget'
```

### Ursache
Die Methode hat versucht, einen `Consumer` direkt zurückzugeben, aber `Consumer` implementiert nicht das `PreferredSizeWidget` Interface, das für `AppBar`-Methoden erforderlich ist.

### Lösung
1. **Struktur-Änderung**: `AppBar` als Haupt-Widget zurückgegeben
2. **Consumer-Integration**: `Consumer` Widgets innerhalb des `AppBar` platziert
3. **Typ-Kompatibilität**: Sicher gestellt, dass `AppBar` (das `PreferredSizeWidget` implementiert) zurückgegeben wird

### Code-Änderungen
```dart
// Vorher (falsch):
PreferredSizeWidget _buildAppBar() {
  return Consumer<SoundLibraryViewModel>(
    builder: (context, viewModel, child) {
      return AppBar(/* ... */);
    },
  );
}

// Nachher (korrigiert):
PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Column(/* ... */);
      },
    ),
    actions: [
      Consumer<SoundLibraryViewModel>(
        builder: (context, viewModel, child) {
          return PopupMenuButton(/* ... */);
        },
      ),
    ],
    // ... weitere AppBar Properties
  );
}
```

### Auswirkungen
- ✅ Kritischer Compile-Time-Fehler behoben
- ✅ Sound Library Screen funktioniert wieder
- ✅ AppBar mit dynamischen Inhalten korrekt integriert
- ✅ Provider-Pattern funktioniert wie erwartet
- ℹ️ Nur noch Style-Warnungen und Type-Inference-Warnungen übrig

### Lessons Learned
1. **Widget-Typ-Kompatibilität**: Immer prüfen ob der Return-Typ mit dem tatsächlichen Widget kompatibel ist
2. **AppBar-Struktur**: `Consumer` Widgets innerhalb von `AppBar` platzieren, nicht umgekehrt
3. **PreferredSizeWidget Interface**: `AppBar` implementiert dieses Interface, `Consumer` nicht
4. **Hierarchie-Planung**: Widget-Hierarchie sorgfältig planen bei Provider-Integration

---

## 2025-11-10 - Enhanced Quest Library Widgets QuestDifficulty Switch-Statement Fehler

### Problem
Beide Enhanced Quest Library Widgets hatten kritische Kompilierungsfehler aufgrund fehlender Fälle in Switch-Statements:
- `EnhancedQuestCardWidget` fehlte `QuestDifficulty.legendary` Fall
- `EnhancedQuestFilterChipsWidget` fehlte `QuestDifficulty.legendary` Fall

### Fehlermeldungen
```
The type 'QuestDifficulty' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'QuestDifficulty.legendary' - non_exhaustive_switch_statement
```

### Ursache
Die `QuestDifficulty` Enum wurde um `legendary` erweitert, aber die Switch-Statements in den Widgets wurden nicht aktualisiert. Dies führte zu nicht-exhaustiven Switch-Statements, die in Dart als Kompilierungsfehler gelten.

### Lösung
1. **Enhanced Quest Card Widget**: `QuestDifficulty.legendary` Fall mit `Colors.amber` Farbe hinzugefügt
2. **Enhanced Quest Filter Chips Widget**: 
   - `QuestDifficulty.legendary` Fall mit `Colors.amber` Farbe hinzugefügt
   - Zusätzlich "Legendär" Chip zur UI hinzugefügt

### Code-Änderungen
```dart
// Enhanced Quest Card Widget - _getDifficultyColor Methode
case QuestDifficulty.legendary:
  return Colors.amber;

// Enhanced Quest Filter Chips Widget - _buildDifficultySection
_buildDifficultyChip('Legendär', QuestDifficulty.legendary),

// Enhanced Quest Filter Chips Widget - _getDifficultyColor Methode
case QuestDifficulty.legendary:
  return Colors.amber;
```

### Auswirkungen
- ✅ Alle kritischen Kompilierungsfehler behoben
- ✅ Beide Widgets kompilieren fehlerfrei
- ✅ Quest Library kann jetzt legendäre Quests korrekt anzeigen und filtern
- ✅ UI unterstützt alle QuestDifficulty Werte inklusive "Legendär"
- ℹ️ Nur noch 37 Code-Quality-Infos (keine Errors mehr)

### Lessons Learned
1. Bei Enum-Erweiterungen IMMER alle Switch-Statements überprüfen
2. Exhaustive Switch-Statements sind in Dart zwingend erforderlich
3. Neue Enum-Werte müssen in UI und Business-Logik konsistent behandelt werden
4. Farb-Konsistenz über alle Widgets sicherstellen

---

## 2025-11-29 - Enhanced Character Editor Save Fix

### Problem
Der `enhanced_character_editor_controller` speicherte keine vollständigen Player-Objekte in der Datenbank, was dazu führte, dass gespeicherte Characters dem Nutzer nicht richtig angezeigt wurden.

### Fehlermeldung
Keine expliziten Fehlermeldungen, aber Datenverlust beim Speichern von Character-Informationen.

### Ursache
In der Konvertierung von `Map<String, dynamic>` zu `PlayerCharacter` im `CharacterEditorViewModel.savePlayerCharacter()` gingen Daten verloren. Fehlende Felder in der Datenerfassung und inkonsistente Datenübertragung zwischen Controller und ViewModel.

### Lösung
1. **Controller Fix** (`lib/widgets/character_editor/enhanced_character_editor_controller.dart`):
   - `_collectFormData()` Methode erweitert um fehlende Felder `attacks` und `specialAbilities`
   - Explizite Trennung zwischen PC- und NPC-spezifischen Feldern
   - Korrekte Datenübertragung für alle Character-Typen

2. **ViewModel Fix** (`lib/viewmodels/character_editor_viewmodel.dart`):
   - `savePlayerCharacter()` Methode korrigiert um tatsächliche Inventardaten zu verwenden statt `[]`
   - `saveCreature()` Methode Datenkonvertierung gefixt
   - Robuste Fehlerbehandlung bei der Map → Objekt Konvertierung

### Code-Änderungen
```dart
// Controller Fix - Erweiterte _collectFormData Methode
final baseData = {
  // ... bestehende Felder
  'attacks': attacksController.text.isNotEmpty ? attacksController.text : null,
  'specialAbilities': specialAbilitiesController.text.isNotEmpty ? specialAbilitiesController.text : null,
  'attackList': attackList, // Wichtig: Strukturierte Attack-Liste
};

// ViewModel Fix - Korrekte Inventar-Verwendung
final playerCharacter = PlayerCharacter(
  // ... andere Felder
  inventory: inventory, // Tatsächliche Inventardaten statt leere Liste
  attackList: List<Attack>.from(characterData['attackList'] as Iterable? ?? []),
);
```

### Auswirkungen
- ✅ Player Characters werden vollständig mit allen Attributen gespeichert
- ✅ Creatures werden vollständig mit allen Attributen gespeichert
- ✅ Attack-Liste wird korrekt übertragen und gespeichert
- ✅ Inventory-Daten werden korrekt übertragen und gespeichert
- ✅ Nach dem Speichern sind alle Daten in der UI sichtbar
- ✅ Keine Daten gehen bei der Map → Objekt Konvertierung verloren
- ✅ Alle Tests bestehen weiterhin

### Lessons Learned
1. Bei Map → Objekt Konvertierungen immer alle Felder explizit mappen
2. Strukturierte Daten (wie Listen) getrennt von String-Daten behandeln
3. Inkonsistente Datenflüsse zwischen Controller und ViewModel vermeiden
4. Robuste Fehlerbehandlung bei Datentransformationen implementieren
5. Komplette Datentests durchführen nach Datenkonvertierungs-Fixes


---

## 2025-11-29 - Inventory Database Column Fix

### Problem
SQL-Abfrage für Inventar schlug fehl wegen inkonsistenter Spaltennamen in der Datenbank.

### Fehlermeldung
```
SqfliteFfiException(sqlite_error: 1): no such column: ownerId
SQL: SELECT * FROM inventory_items WHERE owner_id = ? OR ownerId = ? ORDER BY isEquipped DESC, itemId ASC
```

### Ursache
Die `loadInventory` Methode in `lib/services/inventory_service.dart` verwendete eine SQL-Abfrage mit beiden Spaltennamen `owner_id` und `ownerId`, aber nur `owner_id` existiert in der Datenbank. Die Abfrage versuchte redundant auf dieselbe Spalte unter zwei verschiedenen Namen zuzugreifen.

### Lösung
1. **SQL-Abfrage korrigiert**: Die WHERE-Klausel wurde von `'owner_id = ? OR ownerId = ?'` zu `'owner_id = ?'` vereinfacht
2. **Parameter angepasst**: `whereArgs` wurde von `[ownerId, ownerId]` zu `[ownerId]` reduziert
3. **Doppelten Zugriff entfernt**: Die redundante Bedingung wurde vollständig entfernt

### Code-Änderungen
```dart
// Vorher (falsch):
where: 'owner_id = ? OR ownerId = ?',
whereArgs: [ownerId, ownerId],

// Nachher (korrigiert):
where: 'owner_id = ?',
whereArgs: [ownerId],
```

### Auswirkungen
- ✅ SQL-Fehler behoben - Inventar wird korrekt geladen
- ✅ Alle Inventar-Operationen funktionieren wieder fehlerfrei
- ✅ Konsistente Spaltennamen-Verwendung in der Abfrage
- ✅ Performance verbessert durch vereinfachte SQL-Abfrage
- ✅ Keine Datenverlust oder Inkonsistenzen

### Lessons Learned
1. Bei SQL-Abfragen immer konsistente Spaltennamen verwenden
2. Redundante Bedingungen vermeiden - sie führen zu Fehlern und Performance-Problemen
3. Datenbank-Schema genau prüfen bevor Abfragen geschrieben werden
4. Einfachere Abfragen sind oft besser und sicherer

---

## Template für zukünftige Einträge

### Datum - [Titel]

#### Problem
[Beschreibung des Problems]

#### Fehlermeldung
```
[Kopie der Fehlermeldung]
```

#### Ursache
[Analyse der Ursache]

#### Lösung
[Schritte zur Lösung]

#### Code-Änderungen
```dart
[Relevante Code-Änderungen]
```

#### Auswirkungen
- [Ergebnis der Änderungen]

#### Lessons Learned
1. [Lernpunkt 1]
2. [Lernpunkt 2]
3. [Lernpunkt 3]
