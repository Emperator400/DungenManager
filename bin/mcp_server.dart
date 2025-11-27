import 'dart:convert';
import 'dart:io';

/// Settings-Modell für die Konfiguration
class AppSettings {
  String theme;
  String language;
  bool darkMode;
  bool soundEnabled;
  double volume;
  String defaultCampaignPath;
  bool autoSave;
  int autoSaveInterval;
  Map<String, dynamic> customSettings;

  AppSettings({
    this.theme = 'default',
    this.language = 'de',
    this.darkMode = false,
    this.soundEnabled = true,
    this.volume = 0.8,
    this.defaultCampaignPath = '',
    this.autoSave = true,
    this.autoSaveInterval = 300,
    Map<String, dynamic>? customSettings,
  }) : customSettings = customSettings ?? {};

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'darkMode': darkMode,
      'soundEnabled': soundEnabled,
      'volume': volume,
      'defaultCampaignPath': defaultCampaignPath,
      'autoSave': autoSave,
      'autoSaveInterval': autoSaveInterval,
      'customSettings': customSettings,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      theme: (json['theme'] ?? 'default') as String,
      language: (json['language'] ?? 'de') as String,
      darkMode: (json['darkMode'] ?? false) as bool,
      soundEnabled: (json['soundEnabled'] ?? true) as bool,
      volume: ((json['volume'] ?? 0.8) as num).toDouble(),
      defaultCampaignPath: (json['defaultCampaignPath'] ?? '') as String,
      autoSave: (json['autoSave'] ?? true) as bool,
      autoSaveInterval: (json['autoSaveInterval'] ?? 300) as int,
      customSettings: Map<String, dynamic>.from(json['customSettings'] as Map? ?? {}),
    );
  }
}

/// Ein erweiterter MCP Server für Dart/Flutter Projekte mit Settings-Unterstützung
/// Bietet grundlegende Funktionen zur Interaktion mit dem DungenManager Projekt
class DartMcpServer {
  bool _isRunning = false;
  late AppSettings _settings;
  static const String _settingsFile = 'app_settings.json';

  /// Initialisiert die Settings
  void _initializeSettings() {
    final settingsFile = File(_settingsFile);
    if (settingsFile.existsSync()) {
      try {
        final content = settingsFile.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
      } catch (e) {
        print('Fehler beim Laden der Settings: $e, verwende Standardwerte');
        _settings = AppSettings();
      }
    } else {
      _settings = AppSettings();
      _saveSettings();
    }
  }

  /// Speichert die Settings in die Datei
  void _saveSettings() {
    final settingsFile = File(_settingsFile);
    settingsFile.writeAsStringSync(jsonEncode(_settings.toJson()));
  }

  /// Startet den MCP Server
  Future<void> start() async {
    if (_isRunning) return;
    
    _initializeSettings();
    _isRunning = true;
    print('Dart MCP Server mit Settings-Unterstützung gestartet auf stdin/stdout');
    
    // Lese von stdin und schreibe zu stdout für JSON-RPC Kommunikation
    await for (final line in stdin.transform(utf8.decoder)) {
      if (line.trim().isEmpty) continue;
      
      try {
        final request = jsonDecode(line) as Map<String, dynamic>;
        final response = await _handleRequest(request);
        stdout.writeln(jsonEncode(response));
      } catch (e) {
        final error = {
          'jsonrpc': '2.0',
          'error': {'code': -32603, 'message': e.toString()},
          'id': null
        };
        stdout.writeln(jsonEncode(error));
      }
    }
  }

  /// Verarbeitet eine JSON-RPC Anfrage
  Future<Map<String, dynamic>> _handleRequest(Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final params = request['params'] as Map<String, dynamic>? ?? {};
    final id = request['id'];

    try {
      dynamic result;
      
      switch (method) {
        case 'get_project_info':
          result = _getProjectInfo(params);
          break;
        case 'list_models':
          result = _listModels(params);
          break;
        case 'list_services':
          result = _listServices(params);
          break;
        case 'list_screens':
          result = _listScreens(params);
          break;
        case 'list_widgets':
          result = _listWidgets(params);
          break;
        case 'analyze_file':
          result = _analyzeFile(params);
          break;
        case 'find_references':
          result = _findReferences(params);
          break;
        case 'get_dependencies':
          result = _getDependencies(params);
          break;
        case 'create_file':
          result = _createFile(params);
          break;
        case 'read_file':
          result = _readFile(params);
          break;
        case 'write_file':
          result = _writeFile(params);
          break;
        case 'get_creatures':
          result = _getCreatures(params);
          break;
        case 'get_campaigns':
          result = _getCampaigns(params);
          break;
        case 'get_quests':
          result = _getQuests(params);
          break;
        case 'get_settings':
          result = _getSettings(params);
          break;
        case 'update_settings':
          result = _updateSettings(params);
          break;
        case 'reset_settings':
          result = _resetSettings(params);
          break;
        case 'get_setting':
          result = _getSetting(params);
          break;
        case 'set_setting':
          result = _setSetting(params);
          break;
        default:
          throw Exception('Methode nicht gefunden: $method');
      }

      return {
        'jsonrpc': '2.0',
        'result': result,
        'id': id
      };
    } catch (e) {
      return {
        'jsonrpc': '2.0',
        'error': {
          'code': -32603,
          'message': e.toString()
        },
        'id': id
      };
    }
  }

  // === Handler Implementationen ===

  /// Gibt Informationen über das aktuelle Projekt zurück
  Map<String, dynamic> _getProjectInfo(Map<String, dynamic> params) {
    return {
      'name': 'DungenManager',
      'description': 'Ein D&D Campaign Manager für Flutter',
      'version': '1.0.0',
      'dart_version': Platform.version,
      'flutter': true,
      'database': 'SQLite',
      'features': [
        'Character Management',
        'Campaign Tracking', 
        'Quest Management',
        'Wiki System',
        'Sound Mixer',
        'Scene Management'
      ]
    };
  }

  /// Listet alle Modelle im Projekt
  List<Map<String, dynamic>> _listModels(Map<String, dynamic> params) {
    final modelsDir = Directory('lib/models');
    if (!modelsDir.existsSync()) {
      return [];
    }

    return modelsDir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.dart'))
        .map((file) {
          final fileName = file.path.split('\\').last;
          return {
            'name': fileName.replaceFirst('.dart', ''),
            'path': file.path,
            'type': 'model'
          };
        })
        .toList();
  }

  /// Listet alle Services im Projekt
  List<Map<String, dynamic>> _listServices(Map<String, dynamic> params) {
    final servicesDir = Directory('lib/services');
    if (!servicesDir.existsSync()) {
      return [];
    }

    return servicesDir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.dart'))
        .map((file) {
          final fileName = file.path.split('\\').last;
          return {
            'name': fileName.replaceFirst('.dart', ''),
            'path': file.path,
            'type': 'service'
          };
        })
        .toList();
  }

  /// Listet alle Screens im Projekt
  List<Map<String, dynamic>> _listScreens(Map<String, dynamic> params) {
    final screensDir = Directory('lib/screens');
    if (!screensDir.existsSync()) {
      return [];
    }

    return screensDir
        .listSync()
        .where((entity) => entity is File && entity.path.endsWith('.dart'))
        .map((file) {
          final fileName = file.path.split('\\').last;
          return {
            'name': fileName.replaceFirst('.dart', ''),
            'path': file.path,
            'type': 'screen'
          };
        })
        .toList();
  }

  /// Listet alle Widgets im Projekt
  List<Map<String, dynamic>> _listWidgets(Map<String, dynamic> params) {
    final widgetsDir = Directory('lib/widgets');
    if (!widgetsDir.existsSync()) {
      return [];
    }

    final widgets = <Map<String, dynamic>>[];
    
    void scanDirectory(Directory dir, String relativePath) {
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileName = entity.path.split('\\').last;
          widgets.add({
            'name': fileName.replaceFirst('.dart', ''),
            'path': entity.path,
            'relative_path': '$relativePath${fileName}',
            'type': 'widget'
          });
        } else if (entity is Directory) {
          final dirName = entity.path.split('\\').last;
          scanDirectory(entity, '$relativePath$dirName/');
        }
      }
    }

    scanDirectory(widgetsDir, '');
    return widgets;
  }

  /// Analysiert eine spezifische Datei
  Map<String, dynamic> _analyzeFile(Map<String, dynamic> params) {
    final filePath = params['file_path'] as String?;
    if (filePath == null) {
      throw Exception('file_path ist erforderlich');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Datei nicht gefunden: $filePath');
    }

    final content = file.readAsStringSync();
    final lines = content.split('\n');
    
    // Einfache Analyse
    final imports = <String>[];
    final classes = <String>[];
    final functions = <String>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        imports.add(trimmed);
      } else if (trimmed.startsWith('class ')) {
        final className = trimmed.split(' ')[1].split(' ')[0];
        classes.add(className);
      } else if (trimmed.contains(' ') && trimmed.contains('(') && !trimmed.startsWith('//')) {
        final parts = trimmed.split(' ');
        for (int i = 0; i < parts.length - 1; i++) {
          if (parts[i + 1].contains('(') && !parts[i].contains('.')) {
            functions.add(parts[i]);
            break;
          }
        }
      }
    }

    return {
      'file_path': filePath,
      'line_count': lines.length,
      'imports': imports,
      'classes': classes,
      'functions': functions,
      'size_bytes': content.length
    };
  }

  /// Findet Referenzen zu einem Symbol im Projekt
  List<Map<String, dynamic>> _findReferences(Map<String, dynamic> params) {
    final symbol = params['symbol'] as String?;
    if (symbol == null) {
      throw Exception('symbol ist erforderlich');
    }

    final references = <Map<String, dynamic>>[];
    final libDir = Directory('lib');
    
    void searchInDirectory(Directory dir) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          try {
            final content = entity.readAsStringSync();
            final lines = content.split('\n');
            
            for (int i = 0; i < lines.length; i++) {
              if (lines[i].contains(symbol)) {
                references.add({
                  'file_path': entity.path,
                  'line_number': i + 1,
                  'line_content': lines[i].trim()
                });
              }
            }
          } catch (e) {
            print('Error searching references: $e');
          }
        }
      }
    }

    if (libDir.existsSync()) {
      searchInDirectory(libDir);
    }

    return references;
  }

  /// Gibt die Abhängigkeiten des Projekts zurück
  Map<String, dynamic> _getDependencies(Map<String, dynamic> params) {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return {'error': 'pubspec.yaml nicht gefunden'};
    }

    // Hier könnte man eine YAML Bibliothek verwenden für bessere Parsing
    // Für jetzt eine einfache Textanalyse
    
    return {
      'dependencies': 'siehe pubspec.yaml',
      'flutter_dependencies': [
        'sqflite', 'sqflite_common_ffi', 'path', 'image_picker',
        'flutter_markdown', 'uuid', 'http', 'file_picker', 'path_provider',
        'audioplayers', 'font_awesome_flutter', 'flutter_svg',
        'cupertino_icons', 'ultimate_flutter_icons', 'json_rpc_2'
      ]
    };
  }

  /// Erstellt eine neue Datei
  Map<String, dynamic> _createFile(Map<String, dynamic> params) {
    final filePath = params['file_path'] as String?;
    final content = params['content'] as String?;
    
    if (filePath == null || content == null) {
      throw Exception('file_path und content sind erforderlich');
    }

    final file = File(filePath);
    file.createSync(recursive: true);
    file.writeAsStringSync(content);
    
    return {
      'success': true,
      'file_path': filePath,
      'message': 'Datei erfolgreich erstellt'
    };
  }

  /// Liest den Inhalt einer Datei
  Map<String, dynamic> _readFile(Map<String, dynamic> params) {
    final filePath = params['file_path'] as String?;
    if (filePath == null) {
      throw Exception('file_path ist erforderlich');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Datei nicht gefunden: $filePath');
    }

    return {
      'file_path': filePath,
      'content': file.readAsStringSync(),
      'size_bytes': file.lengthSync()
    };
  }

  /// Schreibt Inhalt in eine Datei
  Map<String, dynamic> _writeFile(Map<String, dynamic> params) {
    final filePath = params['file_path'] as String?;
    final content = params['content'] as String?;
    
    if (filePath == null || content == null) {
      throw Exception('file_path und content sind erforderlich');
    }

    final file = File(filePath);
    file.writeAsStringSync(content);
    
    return {
      'success': true,
      'file_path': filePath,
      'message': 'Datei erfolgreich geschrieben'
    };
  }

  /// Gibt alle Kreaturen zurück
  List<Map<String, dynamic>> _getCreatures(Map<String, dynamic> params) {
    // Hier könnte man tatsächlich auf die Datenbank zugreifen
    // Für jetzt geben wir Beispieldaten zurück
    return [
      {'name': 'Goblin', 'cr': '1/4', 'type': 'Humanoid'},
      {'name': 'Dragon', 'cr': '20', 'type': 'Dragon'},
      {'name': 'Orc', 'cr': '1/2', 'type': 'Humanoid'}
    ];
  }

  /// Gibt alle Kampagnen zurück
  List<Map<String, dynamic>> _getCampaigns(Map<String, dynamic> params) {
    return [
      {'name': 'The Lost Mine of Phandelver', 'level': '1-5'},
      {'name': 'Curse of Strahd', 'level': '1-10'},
      {'name': 'Waterdeep: Dragon Heist', 'level': '1-5'}
    ];
  }

  /// Gibt alle Quests zurück
  List<Map<String, dynamic>> _getQuests(Map<String, dynamic> params) {
    return [
      {'title': 'Find Lost Artifact', 'status': 'active'},
      {'title': 'Defeat Dragon', 'status': 'pending'},
      {'title': 'Save Village', 'status': 'completed'}
    ];
  }

  // === Settings Handler ===

  /// Gibt alle aktuellen Settings zurück
  Map<String, dynamic> _getSettings(Map<String, dynamic> params) {
    return {
      'settings': _settings.toJson(),
      'file_path': _settingsFile,
      'last_modified': File(_settingsFile).lastModifiedSync().toIso8601String()
    };
  }

  /// Aktualisiert mehrere Settings auf einmal
  Map<String, dynamic> _updateSettings(Map<String, dynamic> params) {
    final newSettings = params['settings'] as Map<String, dynamic>?;
    if (newSettings == null) {
      throw Exception('settings Parameter ist erforderlich');
    }

    // Update erlaubte Felder
    if (newSettings.containsKey('theme')) {
      _settings.theme = newSettings['theme'] as String;
    }
    if (newSettings.containsKey('language')) {
      _settings.language = newSettings['language'] as String;
    }
    if (newSettings.containsKey('darkMode')) {
      _settings.darkMode = newSettings['darkMode'] as bool;
    }
    if (newSettings.containsKey('soundEnabled')) {
      _settings.soundEnabled = newSettings['soundEnabled'] as bool;
    }
    if (newSettings.containsKey('volume')) {
      _settings.volume = (newSettings['volume'] as num).toDouble();
    }
    if (newSettings.containsKey('defaultCampaignPath')) {
      _settings.defaultCampaignPath = newSettings['defaultCampaignPath'] as String;
    }
    if (newSettings.containsKey('autoSave')) {
      _settings.autoSave = newSettings['autoSave'] as bool;
    }
    if (newSettings.containsKey('autoSaveInterval')) {
      _settings.autoSaveInterval = newSettings['autoSaveInterval'] as int;
    }
    if (newSettings.containsKey('customSettings')) {
      _settings.customSettings = Map<String, dynamic>.from(newSettings['customSettings'] as Map);
    }

    _saveSettings();

    return {
      'success': true,
      'message': 'Settings erfolgreich aktualisiert',
      'current_settings': _settings.toJson()
    };
  }

  /// Setzt alle Settings auf Standardwerte zurück
  Map<String, dynamic> _resetSettings(Map<String, dynamic> params) {
    _settings = AppSettings();
    _saveSettings();

    return {
      'success': true,
      'message': 'Settings erfolgreich zurückgesetzt',
      'current_settings': _settings.toJson()
    };
  }

  /// Gibt einen spezifischen Setting-Wert zurück
  Map<String, dynamic> _getSetting(Map<String, dynamic> params) {
    final key = params['key'] as String?;
    if (key == null) {
      throw Exception('key Parameter ist erforderlich');
    }

    final allSettings = _settings.toJson();
    final value = allSettings[key];

    return {
      'key': key,
      'value': value,
      'exists': value != null
    };
  }

  /// Setzt einen spezifischen Setting-Wert
  Map<String, dynamic> _setSetting(Map<String, dynamic> params) {
    final key = params['key'] as String?;
    final value = params['value'];

    if (key == null) {
      throw Exception('key Parameter ist erforderlich');
    }
    if (value == null) {
      throw Exception('value Parameter ist erforderlich');
    }

    switch (key) {
      case 'theme':
        _settings.theme = value as String;
        break;
      case 'language':
        _settings.language = value as String;
        break;
      case 'darkMode':
        _settings.darkMode = value as bool;
        break;
      case 'soundEnabled':
        _settings.soundEnabled = value as bool;
        break;
      case 'volume':
        _settings.volume = (value as num).toDouble();
        break;
      case 'defaultCampaignPath':
        _settings.defaultCampaignPath = value as String;
        break;
      case 'autoSave':
        _settings.autoSave = value as bool;
        break;
      case 'autoSaveInterval':
        _settings.autoSaveInterval = value as int;
        break;
      default:
        if (key.startsWith('custom.')) {
          final customKey = key.substring(7);
          _settings.customSettings[customKey] = value;
        } else {
          throw Exception('Unbekannter Setting-Key: $key');
        }
    }

    _saveSettings();

    return {
      'success': true,
      'message': 'Setting $key erfolgreich aktualisiert',
      'key': key,
      'new_value': value
    };
  }
}

void main() async {
  final server = DartMcpServer();
  await server.start();
}
