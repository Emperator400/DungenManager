# MCP Server Nutzungshandbuch für DungenManager

## 🚀 Schnellstart

Der MCP Server ist ein leistungsstarkes Tool zur Interaktion mit dem DungenManager Projekt über JSON-RPC.

### 1. Server starten

```bash
# Methode 1: Direkte Ausführung mit Echo
echo '{"jsonrpc":"2.0","method":"get_project_info","params":{},"id":1}' | dart run bin/mcp_server.dart

# Methode 2: Interaktiver Modus (für mehrere Anfragen)
dart run bin/mcp_server.dart
# Dann JSON-RPC Anfragen eingeben
```

### 2. Grundlegende Anfragen

#### Projekt-Informationen abrufen
```json
{"jsonrpc":"2.0","method":"get_project_info","params":{},"id":1}
```

#### Alle Modelle auflisten
```json
{"jsonrpc":"2.0","method":"list_models","params":{},"id":2}
```

#### Datei analysieren
```json
{"jsonrpc":"2.0","method":"analyze_file","params":{"file_path":"lib/models/creature.dart"},"id":3}
```

## 📋 Verfügbare Methoden

### Projekt-Management
- `get_project_info` - Projektübersicht
- `get_dependencies` - Abhängigkeiten auflisten

### Struktur-Analyse
- `list_models` - Alle Modelle (`lib/models/`)
- `list_services` - Alle Services (`lib/services/`)
- `list_screens` - Alle Screens (`lib/screens/`)
- `list_widgets` - Alle Widgets (`lib/widgets/`)

### Datei-Operationen
- `analyze_file` - Datei analysieren (Imports, Klassen, Funktionen)
- `find_references` - Symbol-Suche im gesamten Projekt
- `read_file` - Dateiinhalt lesen
- `write_file` - Datei schreiben
- `create_file` - Neue Datei erstellen

### D&D Daten
- `get_creatures` - Kreaturen-Beispieldaten
- `get_campaigns` - Kampagnen-Beispieldaten
- `get_quests` - Quest-Beispieldaten

## 🛠️ Praktische Anwendungsfälle

### Fall 1: Code-Refactoring
```bash
# Finde alle Verwendungen von "Creature"
echo '{"jsonrpc":"2.0","method":"find_references","params":{"symbol":"Creature"},"id":4}' | dart run bin/mcp_server.dart
```

### Fall 2: Projekt-Dokumentation
```bash
# Analysiere die Projektstruktur
echo '{"jsonrpc":"2.0","method":"list_services","params":{},"id":5}' | dart run bin/mcp_server.dart
```

### Fall 3: Code-Qualitätsprüfung
```bash
# Analysiere eine wichtige Modelldatei
echo '{"jsonrpc":"2.0","method":"analyze_file","params":{"file_path":"lib/models/player_character.dart"},"id":6}' | dart run bin/mcp_server.dart
```

## 📊 Beispiel-Antworten

### Projekt-Info Antwort
```json
{
  "jsonrpc": "2.0",
  "result": {
    "name": "DungenManager",
    "description": "Ein D&D Campaign Manager für Flutter",
    "version": "1.0.0",
    "features": ["Character Management", "Campaign Tracking", "Quest Management"]
  },
  "id": 1
}
```

### Datei-Analyse Antwort
```json
{
  "jsonrpc": "2.0",
  "result": {
    "file_path": "lib/models/creature.dart",
    "line_count": 370,
    "imports": ["import 'condition.dart';", "import 'inventory_item.dart';"],
    "classes": ["Creature"],
    "functions": ["factory", "return", "copyWith"],
    "size_bytes": 13104
  },
  "id": 3
}
```

## 🔧 Integration mit externen Tools

### VS Code Extension
Der MCP Server kann mit VS Code Extensions integriert werden für:
- Intelligente Code-Analyse
- Automatische Refactoring-Vorschläge
- Projekt-Übersichten

### CI/CD Pipeline
```yaml
# Beispiel für GitHub Actions
- name: Analyze Project Structure
  run: |
    echo '{"jsonrpc":"2.0","method":"get_project_info","params":{},"id":1}' | dart run bin/mcp_server.dart
```

### KI-Assistenten
Der Server kann als Backend für KI-gestützte Entwicklung dienen:
- Code-Generierung basierend auf Projektstruktur
- Automatische Dokumentation
- intelligente Suchfunktionen

## 🚀 Erweiterungsmöglichkeiten

### 1. Datenbank-Integration
```dart
// Beispiel für echte Datenabfragen
Future<List<Map<String, dynamic>>> _getRealCreatures() async {
  final dbHelper = DatabaseHelper();
  final creatures = await dbHelper.getAllCreatures();
  return creatures.map((c) => c.toMap()).toList();
}
```

### 2. Code-Generierung
```dart
// Beispiel für automatische Code-Generierung
Map<String, dynamic> _generateModelCode(Map<String, dynamic> params) {
  final modelName = params['model_name'];
  final fields = params['fields'];
  // Generiere Dart Code für das Modell
  return {'generated_code': 'class $modelName { ... }'};
}
```

### 3. Test-Generierung
```dart
// Beispiel für automatische Test-Generierung
Map<String, dynamic> _generateUnitTest(Map<String, dynamic> params) {
  final filePath = params['file_path'];
  // Analysiere Datei und generiere Unit-Test
  return {'test_code': 'void main() { ... }'};
}
```

## 📈 Performance-Optimierung

### Caching
Der Server könnte implementiert werden mit:
- File-System-Caching für wiederholte Anfragen
- Index-Struktur für schnellere Symbol-Suche
- Asynchrone Verarbeitung für große Dateien

### Batch-Operationen
```json
// Beispiel für Batch-Anfragen
{
  "jsonrpc": "2.0",
  "method": "batch_operation",
  "params": {
    "operations": [
      {"method": "analyze_file", "params": {"file_path": "lib/models/creature.dart"}},
      {"method": "analyze_file", "params": {"file_path": "lib/models/player_character.dart"}}
    ]
  },
  "id": 10
}
```

## 🔍 Fehlerbehandlung

### Häufige Fehler
```json
// Methode nicht gefunden
{
  "jsonrpc": "2.0",
  "error": {"code": -32601, "message": "Methode nicht gefunden: unknown_method"},
  "id": 1
}

// Datei nicht gefunden
{
  "jsonrpc": "2.0",
  "error": {"code": -32603, "message": "Datei nicht gefunden: lib/models/unknown.dart"},
  "id": 2
}
```

## 🎯 Best Practices

1. **Strukturierte Anfragen**: Immer gültiges JSON-RPC 2.0 Format verwenden
2. **Fehlerbehandlung**: Immer auf Fehler-Antworten prüfen
3. **Performance**: Große Dateien in kleineren Chunks analysieren
4. **Caching**: Ergebnisse für wiederholte Anfragen zwischenspeichern
5. **Logging**: Anfragen und Antworten für Debugging protokollieren

## 📚 Weiterführende Ressourcen

- [JSON-RPC 2.0 Spezifikation](https://www.jsonrpc.org/specification)
- [Dart Process API](https://api.dart.dev/stable/dart-io/Process-class.html)
- [Flutter Development Best Practices](https://flutter.dev/docs/development/tools/formatting)

---

**Tipp**: Der MCP Server ist ein hervorragendes Beispiel für moderne Software-Architektur - er trennt die Anwendungslogik von der Präsentationsschicht und ermöglicht flexible Integrationen!
