# Dart MCP Server für DungenManager

Ein einfacher MCP (Model Context Protocol) Server für das DungenManager Flutter-Projekt.

## Übersicht

Der MCP Server bietet eine JSON-RPC Schnittstelle zur Interaktion mit dem DungenManager Projekt. Er kann verwendet werden, um Projektinformationen abzurufen, Dateien zu analysieren, und auf die Projektstruktur zuzugreifen.

## Starten des Servers

```bash
dart run bin/mcp_server.dart
```

Der Server läuft auf stdin/stdout und erwartet JSON-RPC Anfragen im folgenden Format:

```json
{
  "jsonrpc": "2.0",
  "method": "methoden_name",
  "params": { ... },
  "id": 1
}
```

## Verfügbare Methoden

### Projekt-Informationen

- `get_project_info` - Gibt grundlegende Informationen über das Projekt zurück
- `get_dependencies` - Listet die Projektabhängigkeiten auf

### Struktur-Analyse

- `list_models` - Listet alle Modelle im `lib/models` Verzeichnis
- `list_services` - Listet alle Services im `lib/services` Verzeichnis  
- `list_screens` - Listet alle Screens im `lib/screens` Verzeichnis
- `list_widgets` - Listet alle Widgets im `lib/widgets` Verzeichnis

### Datei-Operationen

- `analyze_file` - Analysiert eine spezifische Datei
- `find_references` - Findet Referenzen zu einem Symbol im Projekt
- `read_file` - Liest den Inhalt einer Datei
- `write_file` - Schreibt Inhalt in eine Datei
- `create_file` - Erstellt eine neue Datei

### D&D Spezifische Funktionen

- `get_creatures` - Gibt Kreaturen zurück (Beispieldaten)
- `get_campaigns` - Gibt Kampagnen zurück (Beispieldaten)
- `get_quests` - Gibt Quests zurück (Beispieldaten)

## Beispiele

### Projekt-Informationen abrufen

```bash
echo '{"jsonrpc":"2.0","method":"get_project_info","params":{},"id":1}' | dart run bin/mcp_server.dart
```

### Modelle auflisten

```bash
echo '{"jsonrpc":"2.0","method":"list_models","params":{},"id":2}' | dart run bin/mcp_server.dart
```

### Datei analysieren

```bash
echo '{"jsonrpc":"2.0","method":"analyze_file","params":{"file_path":"lib/models/creature.dart"},"id":3}' | dart run bin/mcp_server.dart
```

## Antwort-Format

Alle Antworten folgen dem JSON-RPC 2.0 Standard:

```json
{
  "jsonrpc": "2.0",
  "result": { ... },
  "id": 1
}
```

Bei Fehlern:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32603,
    "message": "Fehlerbeschreibung"
  },
  "id": 1
}
```

## Implementierungsdetails

- **Sprache**: Dart
- **Protokoll**: JSON-RPC 2.0
- **Kommunikation**: stdin/stdout
- **Projekt**: DungenManager (D&D Campaign Manager für Flutter)

## Erweiterungsmöglichkeiten

Der Server kann leicht um zusätzliche Funktionen erweitert werden:

1. **Datenbank-Integration**: Echte Daten aus der SQLite-Datenbank abrufen
2. **Code-Generierung**: Automatische Erstellung von Boilerplate-Code
3. **Refactoring-Tools**: Automatisierte Code-Transformationen
4. **Test-Generierung**: Automatische Erstellung von Unit-Tests
5. **Dokumentation**: Generierung von API-Dokumentation

## Verwendung mit externen Tools

Der MCP Server kann mit verschiedenen Tools integriert werden:

- **IDE-Plugins**: Für erweiterte Entwicklungswerkzeuge
- **CI/CD-Pipelines**: Für automatisierte Code-Analyse
- **Chat-Systeme**: Für KI-gestützte Code-Unterstützung
- **Build-Tools**: Für intelligente Build-Prozesse

## Testen

Ein einfacher Test-Client ist in `test_mcp_server.dart` enthalten:

```bash
dart run test_mcp_server.dart
```

## Lizenz

Dieser MCP Server ist Teil des DungenManager Projekts.
