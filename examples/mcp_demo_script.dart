import 'dart:convert';
import 'dart:io';

/// Praktisches Demo-Skript für MCP Server Nutzung
/// Zeigt verschiedene Anwendungsfälle für die Entwicklung
class McpDemo {
  
  /// Führt eine MCP Anfrage aus und gibt das Ergebnis zurück
  Future<Map<String, dynamic>> _sendRequest(Map<String, dynamic> request) async {
    final process = await Process.start('dart', ['bin/mcp_server.dart']);
    
    // Sende Anfrage
    process.stdin.writeln(jsonEncode(request));
    await process.stdin.close();
    
    // Lese Antwort
    final response = await process.stdout
        .transform(utf8.decoder)
        .first
        .then((data) => jsonDecode(data) as Map<String, dynamic>);
    
    process.kill();
    return response;
  }

  /// Demo 1: Projekt-Analyse
  Future<void> demoProjectAnalysis() async {
    print('\n=== DEMO 1: Projekt-Analyse ===');
    
    // Projekt-Info
    final projectInfo = await _sendRequest({
      'jsonrpc': '2.0',
      'method': 'get_project_info',
      'params': {},
      'id': 1
    });
    
    print('📊 Projekt: ${projectInfo['result']['name']}');
    print('📝 Beschreibung: ${projectInfo['result']['description']}');
    final features = projectInfo['result']['features'] as List;
    print('⭐ Features: ${features.join(', ')}');
    
    // Modelle auflisten
    final models = await _sendRequest({
      'jsonrpc': '2.0',
      'method': 'list_models',
      'params': {},
      'id': 2
    });
    
    final modelList = models['result'] as List;
    print('\n📁 Modelle (${modelList.length}):');
    for (final model in modelList) {
      print('  • ${model['name']} (${model['type']})');
    }
  }

  /// Demo 2: Code-Qualitätsprüfung
  Future<void> demoCodeQuality() async {
    print('\n=== DEMO 2: Code-Qualitätsprüfung ===');
    
    // Analysiere wichtige Dateien
    final importantFiles = [
      'lib/models/creature.dart',
      'lib/services/creature_helper_service.dart',
      'lib/screens/bestiary_screen.dart'
    ];
    
    for (final filePath in importantFiles) {
      try {
        final analysis = await _sendRequest({
          'jsonrpc': '2.0',
          'method': 'analyze_file',
          'params': {'file_path': filePath},
          'id': 3
        });
        
        final result = analysis['result'];
        print('\n📄 Datei: ${result['file_path']}');
        print('   📏 Zeilen: ${result['line_count']}');
        print('   📦 Größe: ${result['size_bytes']} Bytes');
        final classes = result['classes'] as List;
        print('   🏗️  Klassen: ${classes.join(', ')}');
        final imports = result['imports'] as List;
        print('   📥 Imports: ${imports.length}');
        
        // Qualitätsbewertung
        final lineCount = result['line_count'] as int;
        if (lineCount > 500) {
          print('   ⚠️  Datei ist sehr groß - könnte refactored werden');
        } else if (lineCount > 200) {
          print('   💡 Datei ist mittel-groß - aufteilen prüfen');
        } else {
          print('   ✅ Gute Dateigröße');
        }
        
      } catch (e) {
        print('   ❌ Fehler bei Analyse: $e');
      }
    }
  }

  /// Demo 3: Symbol-Suche und Refactoring
  Future<void> demoSymbolSearch() async {
    print('\n=== DEMO 3: Symbol-Suche und Refactoring ===');
    
    final symbols = ['Creature', 'DatabaseHelper', 'Campaign'];
    
    for (final symbol in symbols) {
      try {
        final references = await _sendRequest({
          'jsonrpc': '2.0',
          'method': 'find_references',
          'params': {'symbol': symbol},
          'id': 4
        });
        
        final refs = references['result'] as List;
        print('\n🔍 Symbol: $symbol (${refs.length} Treffer)');
        
        // Top 5 Dateien mit meisten Treffern
        final fileCounts = <String, int>{};
        for (final ref in refs) {
          final file = ref['file_path'] as String;
          fileCounts[file] = (fileCounts[file] ?? 0) + 1;
        }
        
        final sortedFiles = fileCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        for (int i = 0; i < sortedFiles.length && i < 5; i++) {
          final entry = sortedFiles[i];
          final relativePath = entry.key.replaceFirst('lib\\', 'lib/');
          print('   📂 $relativePath: ${entry.value}x');
        }
        
        if (refs.length > 50) {
          print('   💡 Refactoring-Tipp: $symbol wird sehr oft verwendet - überlege Factory-Pattern');
        }
        
      } catch (e) {
        print('   ❌ Fehler bei Suche: $e');
      }
    }
  }

  /// Demo 4: Automatische Dokumentation
  Future<void> demoAutoDocumentation() async {
    print('\n=== DEMO 4: Automatische Dokumentation ===');
    
    try {
      // Services analysieren
      final services = await _sendRequest({
        'jsonrpc': '2.0',
        'method': 'list_services',
        'params': {},
        'id': 5
      });
      
      print('🔧 Service-Übersicht:');
      final serviceList = services['result'] as List;
      for (final service in serviceList) {
        final serviceName = service['name'] as String;
        if (!serviceName.contains('_test')) {
          print('\n📋 $serviceName');
          print('   🔗 Pfad: ${service['path']}');
          
          // Versuche, die Datei zu analysieren
          try {
            final analysis = await _sendRequest({
              'jsonrpc': '2.0',
              'method': 'analyze_file',
              'params': {'file_path': service['path']},
              'id': 6
            });
            
            final result = analysis['result'];
            final classes = result['classes'] as List;
            print('   📚 Klassen: ${classes.join(', ')}');
            final imports = result['imports'] as List;
            print('   📦 Imports: ${imports.length}');
          } catch (e) {
            print('   ⚠️  Analyse fehlgeschlagen');
          }
        }
      }
      
    } catch (e) {
      print('❌ Fehler bei Dokumentation: $e');
    }
  }

  /// Demo 5: D&D Daten-Inspektion
  Future<void> demoDndDataInspection() async {
    print('\n=== DEMO 5: D&D Daten-Inspektion ===');
    
    try {
      final creatures = await _sendRequest({
        'jsonrpc': '2.0',
        'method': 'get_creatures',
        'params': {},
        'id': 7
      });
      
      print('🐉 Beispiele-Kreaturen:');
      final creatureList = creatures['result'] as List;
      for (final creature in creatureList) {
        print('   • ${creature['name']} (CR ${creature['cr']}, ${creature['type']})');
      }
      
      final campaigns = await _sendRequest({
        'jsonrpc': '2.0',
        'method': 'get_campaigns',
        'params': {},
        'id': 8
      });
      
      print('\n🏰 Beispiele-Kampagnen:');
      final campaignList = campaigns['result'] as List;
      for (final campaign in campaignList) {
        print('   • ${campaign['name']} (Level ${campaign['level']})');
      }
      
    } catch (e) {
      print('❌ Fehler bei Daten-Inspektion: $e');
    }
  }

  /// Hauptdemo-Funktion
  Future<void> runAllDemos() async {
    print('🚀 MCP Server Demo gestartet...');
    print('=====================================');
    
    try {
      await demoProjectAnalysis();
      await demoCodeQuality();
      await demoSymbolSearch();
      await demoAutoDocumentation();
      await demoDndDataInspection();
      
      print('\n✅ Demo erfolgreich abgeschlossen!');
      print('💡 Tipp: Nutze diese Techniken für deine tägliche Entwicklung!');
      
    } catch (e) {
      print('\n❌ Demo fehlgeschlagen: $e');
    }
  }
}

void main() async {
  final demo = McpDemo();
  await demo.runAllDemos();
}
