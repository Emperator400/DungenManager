# Settings MCP Server Dokumentation

Dieses Dokument beschreibt die neuen Settings-Funktionen, die zum DungenManager MCP Server hinzugefügt wurden.

## Übersicht

Der Settings MCP Server ermöglicht die Verwaltung von Anwendungseinstellungen über JSON-RPC Anfragen. Die Settings werden in einer `app_settings.json` Datei gespeichert und automatisch beim Serverstart geladen.

## verfügbare Methoden

### 1. get_settings

Gibt alle aktuellen Settings zurück.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "get_settings",
  "params": {},
  "id": 1
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "settings": {
      "theme": "default",
      "language": "de",
      "darkMode": false,
      "soundEnabled": true,
      "volume": 0.8,
      "defaultCampaignPath": "",
      "autoSave": true,
      "autoSaveInterval": 300,
      "customSettings": {}
    },
    "file_path": "app_settings.json",
    "last_modified": "2025-11-04T21:43:15.000"
  },
  "id": 1
}
```

### 2. get_setting

Gibt einen spezifischen Setting-Wert zurück.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "get_setting",
  "params": {
    "key": "theme"
  },
  "id": 2
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "key": "theme",
    "value": "default",
    "exists": true
  },
  "id": 2
}
```

### 3. set_setting

Setzt einen spezifischen Setting-Wert.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "set_setting",
  "params": {
    "key": "theme",
    "value": "dark"
  },
  "id": 3
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "message": "Setting theme erfolgreich aktualisiert",
    "key": "theme",
    "new_value": "dark"
  },
  "id": 3
}
```

### 4. update_settings

Aktualisiert mehrere Settings auf einmal.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "update_settings",
  "params": {
    "settings": {
      "language": "en",
      "autoSave": false,
      "autoSaveInterval": 600
    }
  },
  "id": 4
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "message": "Settings erfolgreich aktualisiert",
    "current_settings": {
      "theme": "default",
      "language": "en",
      "darkMode": false,
      "soundEnabled": true,
      "volume": 0.8,
      "defaultCampaignPath": "",
      "autoSave": false,
      "autoSaveInterval": 600,
      "customSettings": {}
    }
  },
  "id": 4
}
```

### 5. reset_settings

Setzt alle Settings auf ihre Standardwerte zurück.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "reset_settings",
  "params": {},
  "id": 5
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "success": true,
    "message": "Settings erfolgreich zurückgesetzt",
    "current_settings": {
      "theme": "default",
      "language": "de",
      "darkMode": false,
      "soundEnabled": true,
      "volume": 0.8,
      "defaultCampaignPath": "",
      "autoSave": true,
      "autoSaveInterval": 300,
      "customSettings": {}
    }
  },
  "id": 5
}
```

## verfügbare Settings

| Key | Typ | Standardwert | Beschreibung |
|------|------|---------------|-------------|
| `theme` | String | "default" | Das Theme der Anwendung |
| `language` | String | "de" | Die Sprache der Anwendung |
| `darkMode` | Boolean | false | Dark Mode aktiv/deaktiviert |
| `soundEnabled` | Boolean | true | Sound aktiv/deaktiviert |
| `volume` | Double | 0.8 | Lautstärke (0.0 - 1.0) |
| `defaultCampaignPath` | String | "" | Standardpfad für Kampagnen |
| `autoSave` | Boolean | true | Auto-Save aktiv/deaktiviert |
| `autoSaveInterval` | Integer | 300 | Auto-Save Intervall in Sekunden |
| `customSettings` | Map | {} | Benutzerdefinierte Settings |

## Benutzerdefinierte Settings

Benutzerdefinierte Settings können mit dem Präfix `custom.` gesetzt werden:

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "set_setting",
  "params": {
    "key": "custom.mySetting",
    "value": "myValue"
  },
  "id": 6
}
```

## Fehlerbehandlung

Bei Fehlern gibt der Server eine Fehlerantwort im JSON-RPC 2.0 Format zurück:

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32603,
    "message": "Fehlerbeschreibung"
  },
  "id": null
}
```

## Verwendung mit der Kommandozeile

### Settings abrufen
```bash
echo '{"jsonrpc":"2.0","method":"get_settings","params":{},"id":1}' | dart run bin/mcp_server.dart
```

### Theme ändern
```bash
echo '{"jsonrpc":"2.0","method":"set_setting","params":{"key":"theme","value":"dark"},"id":2}' | dart run bin/mcp_server.dart
```

### Mehrere Settings ändern
```bash
echo '{"jsonrpc":"2.0","method":"update_settings","params":{"settings":{"language":"en","darkMode":true}},"id":3}' | dart run bin/mcp_server.dart
```

### Settings zurücksetzen
```bash
echo '{"jsonrpc":"2.0","method":"reset_settings","params":{},"id":4}' | dart run bin/mcp_server.dart
```

## Integration mit VSCode

Der MCP Server ist bereits in der `.vscode/settings.json` konfiguriert:

```json
{
  "mcpServers": {
    "dart": {
      "command": "dart",
      "args": ["run", "mcp_server"],
      "cwd": "${workspaceFolder}"
    }
  }
}
```

## Speicherort

Die Settings werden in der Datei `app_settings.json` im Projektverzeichnis gespeichert. Diese Datei wird automatisch erstellt, wenn sie nicht existiert.

## Sicherheit

- Alle Settings werden als JSON im Klartext gespeichert
- Der Server validiert die Eingabeparameter
- Unbekannte Setting-Keys führen zu einer Fehlermeldung
- Custom Settings müssen mit dem Präfix `custom.` beginnen

## Erweiterungsmöglichkeiten

Der Settings-Server kann leicht um neue Funktionen erweitert werden:

1. **Settings-Validierung**: Hinzufügen von Validierungsregeln für bestimmte Settings
2. **Settings-History**: Protokollierung von Änderungen
3. **Settings-Profiles**: Unterstützung für verschiedene Settings-Profile
4. **Remote-Sync**: Synchronisation mit externen Konfigurationsservices

## Beispiel-Integration

Die Settings können in Flutter-Anwendungen einfach integriert werden:

```dart
// Settings vom MCP Server laden
final response = await mcpServer.call('get_settings', {});
final settings = response['result']['settings'];

// Settings aktualisieren
await mcpServer.call('set_setting', {
  'key': 'theme',
  'value': 'dark'
});
```

---

**Hinweis:** Dieser Settings MCP Server ist eine Erweiterung des bestehenden DungenManager MCP Servers und kann parallel zu allen anderen Funktionen verwendet werden.
