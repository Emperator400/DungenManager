# Code-Review: enhanced_edit_pc_screen.dart & edit_pc_viewmodel.dart

## Zusammenfassung
Der Code ist gut strukturiert und folgt dem Provider-Pattern. Es gibt jedoch mehrere Bereiche, die optimiert werden können, um Performance, Wartbarkeit und Benutzererfahrung zu verbessern.

---

## 1. KRITISCHE PROBLEME

### 1.1 Unnötige setState-Aufrufe im State
**Standort:** `enhanced_edit_pc_screen.dart`, Zeile 67

**Problem:**
```dart
String _skillSearchQuery = '';

void _initializeViewModel() {
  setState(() {
    _isInitialized = true;
  });
}
```

Die lokale Variable `_skillSearchQuery` wird mit `setState()` aktualisiert, was unnötige Rebuilds verursacht.

**Lösung:**
Verwende `setState()` nur für Variablen, die tatsächlich das UI beeinflussen.

### 1.2 Veraltete Print-Statements im ViewModel
**Standort:** `edit_pc_viewmodel.dart`, Zeile 275+

**Problem:**
Extensive `print()`-Statements für Debugging-Informationen sind noch im Produktionscode.

**Lösung:**
Ersetze `print()` durch ein Logging-Framework oder entferne sie komplett.

### 1.3 Initialisierung mit `await Future.delayed()`
**Standort:** `enhanced_edit_pc_screen.dart`, Zeile 569

**Problem:**
```dart
await Future.delayed(const Duration(milliseconds: 100));
await Future.delayed(const Duration(milliseconds: 500));
```

Arbitrary Delays sind schlechte Praxis und führen zu schlechter UX.

**Lösung:**
Verwende `setState()` mit `mounted`-Check ohne Delays.

---

## 2. PERFORMANCE-OPTIMIERUNGEN

### 2.1 Excessive Rebuilds durch Consumer-Widgets
**Standort:** Mehrere Consumer<EditPCViewModel> Aufrufe

**Problem:**
Jedes Consumer-Widget rebuildet bei JEDEM `notifyListeners()` Aufruf, selbst wenn sich nur ein Feld geändert hat.

**Lösung:**
Verwende `Selector` aus dem provider Paket für selektive Updates:
```dart
Selector<EditPCViewModel, String>(
  selector: (context, viewModel) => viewModel.name,
  builder: (context, name, child) {
    return _buildTextField(...);
  },
)
```

### 2.2 Wiederverwendbarkeit von Build-Methoden
**Standort:** `_buildTextField`, `_buildNumberField`, `_buildDropdownField`

**Problem:**
Ähnliche Code-Patterns werden dreimal implementiert.

**Lösung:**
Extrahiere gemeinsame Logik in eine Basisklasse oder Parameter-freundliche Funktion.

### 2.3 Skill-Suchfilter inefficient
**Standort:** `_buildSkillsCard`, Zeile 344+

**Problem:**
Die Filterung wird bei jedem Tastendruck neu berechnet und rendert alle Skills.

**Lösung:**
Debouncing implementieren oder Suchlogik in ViewModel verlagern.

### 2.4 Grid-Building bei jedem Rebuild
**Standort:** `_buildAbilityGrid`, Zeile 281

**Problem:**
Das Grid wird bei jedem Rebuild komplett neu erstellt.

**Lösung:**
Verwende `const` Konstruktoren wo möglich oder extrahiere Widgets.

---

## 3. ARCHITEKTUR & DESIGN

### 3.1 Große Widget-Klasse
**Standort:** `EnhancedEditPCScreen` (~700 Zeilen)

**Problem:**
Die Widget-Klasse ist zu groß und schwer zu warten.

**Lösung:**
Extrahiere Tabs in separate Widgets:
```
lib/widgets/character_editor/
├── pc_basic_info_tab.dart
├── pc_attributes_tab.dart
├── pc_dnd_details_tab.dart
└── pc_inventory_tab.dart
```

### 3.2 ViewModel mit zu vielen Verantwortlichkeiten
**Standort:** `EditPCViewModel` (~600 Zeilen)

**Problem:**
Das ViewModel kümmert sich um UI-State, Business-Logik, Validierung und Datenbank-Operationen.

**Lösung:**
Aufteilung in:
- `PCFormData` (State-Management)
- `PCValidator` (Validierung)
- `PCService` (Business-Logik)

### 3.3 Hardcoded Strings
**Standort:** Überall im Code

**Problem:**
Texte sind hardcodiert und nicht internationalisierbar.

**Lösung:**
Verwende `AppLocalizations` für alle UI-Texte.

### 3.4 Fehlende Trennung von UI und Business-Logik
**Problem:**
Berechnungen wie `getModifier()` und `getSkillBonus()` sind im ViewModel.

**Lösung:**
Verschiebe in separate Service-Klassen oder Utility-Funktionen.

---

## 4. FEHLERBEHANDLUNG

### 4.1 Inconsistent Error Handling
**Problem:**
Manche Fehler werden mit `SnackBarHelper` angezeigt, andere silently ignoriert.

**Lösung:**
Konsistentes Error-Handling-Pattern implementieren:
- Alle Fehler loggen
- User-friendly Error-Messages
- Fallback-Mechanismen

### 4.2 Kein Loading State für Initialisierung
**Standort:** `_isInitialized` wird verwendet, aber kein Loading-Indicator

**Problem:**
Während `_initializeViewModel()` läuft, ist das Screen leer.

**Lösung:**
Füge `CircularProgressIndicator` hinzu während der Initialisierung.

### 4.3 Try-Catch-Blöcke zu breit
**Standort:** `_initializeViewModel`, Zeile 59

**Problem:**
Ein riesiger try-catch Block fängt alle Fehler ab.

**Lösung:**
Spezifischere Fehlerbehandlung mit granularen catch-Blöcken.

---

## 5. CODE-QUALITÄT & BEST PRACTICES

### 5.1 Magic Numbers
**Standort:** Überall

**Problem:**
```dart
TabController(length: 4, vsync: this);
if (newValueInt >= 1 && newValueInt <= 20)
```

**Lösung:**
Extrahiere zu benannten Konstanten:
```dart
static const int _tabCount = 4;
static const int _minAbilityScore = 1;
static const int _maxAbilityScore = 20;
```

### 5.2 Duplicate Code
**Standort:** `_buildTextField`, `_buildNumberField`, `_buildMultilineField`

**Problem:**
Ähnliche Implementationen mit kleineren Unterschieden.

**Lösung:**
Konsolidiere zu einem Builder mit optionalen Parametern.

### 5.3 Fehlende Null-Safety Optimierungen
**Problem:**
Viele `!` und `?` Operatoren können durch besseres Design vermieden werden.

**Lösung:**
Verwende late initialization oder better null-handling.

### 5.4 Inconsistent Naming
**Problem:**
Mix von `_name`, `updateName()`, `getSkillBonusString()` vs `_strength`, `updateStrength()`

**Lösung:**
Konsistente Benennungskonvention für getter/setter.

---

## 6. USER EXPERIENCE

### 6.1 Kein Auto-Save
**Problem:**
Nur manueller Save-Button - Daten gehen bei Absturz verloren.

**Lösung:**
Implementiere Auto-Save mit Debouncing.

### 6.2 Kein Confirmation bei Unsaved Changes
**Problem:**
User kann Screen verlassen ohne Warnung bei ungespeicherten Änderungen.

**Lösung:**
Füge `WillPopScope` mit Confirmation Dialog hinzu.

### 6.3 Fehlende Feedback für Skill-Toggles
**Problem:**
Skill-Proficiency Toggle gibt visuelles Feedback, aber kein Haptisches.

**Lösung:**
Füge `HapticFeedback.lightImpact()` hinzu.

### 6.4 Inventory Tab nicht verfügbar beim Erstellen
**Standort:** Zeile 251

**Problem:**
Inventory Tab zeigt "Speichere zuerst" statt deaktiviert zu sein.

**Lösung:**
Disable den Tab oder zeige deaktiviert mit Tooltip.

---

## 7. TESTABILITY

### 7.1 ViewModel schwer zu testen
**Problem:**
Direkte Database-Dependencies im ViewModel Constructor.

**Lösung:**
Verwende Dependency Injection mit Interfaces.

### 7.2 Keine Test-Doubles
**Problem:**
Keine Mock-Repositories für Unit-Tests.

**Lösung:**
Erstelle Mock-Implementierungen für Repositories.

### 7.3 Widget-Tests fehlen
**Problem:**
Keine Widget-Tests für die Screen-Komponenten.

**Lösung:**
Füge Widget-Tests für kritische Pfade hinzu:
- Save Character
- Toggle Skill Proficiency
- Add/Remove Inventory Item

---

## 8. SICHERHEIT

### 8.1 Keine Input Sanitization
**Problem:**
User-Input wird direkt übernommen ohne Validierung außer Required-Check.

**Lösung:**
Füge umfassende Input-Sanitization für alle Text-Felder hinzu.

### 8.2 Kein Length Validation
**Problem:**
Text-Felder haben keine Max-Längen-Validierung.

**Lösung:**
Füge `maxLength` Validierung für alle Text-Felder.

---

## 9. ZUSÄTZLICHE OPTIMIERUNGEN

### 9.1 Constants für D&D-Daten
**Problem:**  
D&D-Klassen und Rassen werden aus globalen Listen geladen.

**Lösung:**
Zentralisiere D&D-Daten in einer separaten Konfigurations-Datei.

### 9.2 Theme-Consistency
**Problem:**
Color-Werte sind hardcodiert statt aus Theme zu nutzen.

**Lösung:**
Verwende konsistent `Theme.of(context).` statt direkter Colors.

### 9.3 Keyboard-Handling
**Problem:**
Keyboard wird nicht automatisch dismissed bei Save.

**Lösung:**
Füge `FocusScope.of(context).unfocus()` vor Save hinzu.

---

## 10. PRIORITÄSIERTE OPTIMIERUNGSLISTE

### HOHE PRIORITÄT (Sofort umsetzen):
1. ✅ Excessive `notifyListeners()` reduzieren (mit Selector)
2. ✅ Print-Statements entfernen oder durch Logging ersetzen
3. ✅ Arbiträre Delays entfernen
4. ✅ Loading State für Initialisierung hinzufügen
5. ✅ Auto-Save implementieren
6. ✅ Confirmation bei ungespeicherten Änderungen

### MITTLERE PRIORITÄT (Bald umsetzen):
1. ✅ Widget-Klassenaufteilung in separate Dateien
2. ✅ Magic Numbers zu Konstanten
3. ✅ Duplicate Code konsolidieren
4. ✅ Konsistente Error-Handling
5. ✅ Input-Sanitization und Length-Validation

### NIEDRIGE PRIORITÄT (Langfristig):
1. ✅ Internationalisierung (i18n)
2. ✅ Comprehensive Unit-Tests
3. ✅ ViewModel-Refactoring (Separation of Concerns)
4. ✅ Haptic Feedback
5. ✅ Theme-Consistency

---

## 11. KONKRETE IMPLEMENTIERUNGSVORSCHLÄGE

### Vorschlag 1: Selector für selektive Updates
```dart
// Statt:
Consumer<EditPCViewModel>(
  builder: (context, viewModel, child) {
    return _buildTextField(...);
  },
)

// Verwende:
Selector<EditPCViewModel, String>(
  selector: (context, viewModel) => viewModel.name,
  builder: (context, name, child) {
    return _buildTextField(...);
  },
)
```

### Vorschlag 2: Konsolidierte Field Builder
```dart
Widget _buildField({
  required String label,
  required String value,
  required Function(String) onChanged,
  String? Function(String?)? validator,
  IconData? icon,
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return Container(
    decoration: BoxDecoration(
      color: DnDTheme.stoneGrey,
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
    ),
    child: TextFormField(
      key: ValueKey<String>('$_isInitialized-$label'),
      initialValue: value,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: DnDTheme.bodyText2.copyWith(
          color: DnDTheme.ancientGold,
        ),
        prefixIcon: icon != null ? Icon(icon, color: DnDTheme.ancientGold) : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(DnDTheme.md),
      ),
      style: DnDTheme.bodyText1.copyWith(color: Colors.white),
      validator: validator,
      onChanged: onChanged,
    ),
  );
}
```

### Vorschlag 3: Debouncing für Search
```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 300), () {
    setState(() {
      _skillSearchQuery = query.toLowerCase();
    });
  });
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
```

### Vorschlag 4: WillPopScope mit Confirmation
```dart
@override
Widget build(BuildContext context) {
  return ChangeNotifierProvider<EditPCViewModel>.value(
    value: _viewModel,
    child: WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(...),
    ),
  );
}

Future<bool> _onWillPop() async {
  if (!_viewModel.hasUnsavedChanges) {
    return true;
  }
  
  final shouldPop = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ungespeicherte Änderungen'),
      content: const Text('Möchtest du wirklich ohne Speichern gehen?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Verlassen'),
        ),
      ],
    ),
  );
  
  return shouldPop ?? false;
}
```

---

## FAZIT

Der Code ist funktional und gut strukturiert, hat aber deutliches Verbesserungspotential in:
- **Performance** (durch reduzierte Rebuilds)
- **User Experience** (durch Auto-Save und Confirmation)
- **Code Quality** (durch Refactoring und Konsolidierung)
- **Testability** (durch Dependency Injection)

Die vorgeschlagenen Optimierungen würden die App deutlich robuster, performanter und benutzerfreundlicher machen.
