import 'dart:convert';
import 'dart:io';

/// Einfaches Demo-Skript für MCP Server Nutzung
void main() async {
  print('🚀 Einfache MCP Server Demo...');
  print('=====================================\n');

  // Demo 1: Projekt-Informationen
  print('=== DEMO 1: Projekt-Informationen ===');
  try {
    final result = await runMcpCommand({
      'jsonrpc': '2.0',
      'method': 'get_project_info',
      'params': {},
      'id': 1
    });
    
    print('📊 Projekt: ${result['result']['name']}');
    print('📝 Beschreibung: ${result['result']['description']}');
    final features = result['result']['features'] as List;
    print('⭐ Features: ${features.join(', ')}');
  } catch (e) {
    print('❌ Fehler: $e');
  }

  // Demo 2: Modelle auflisten
  print('\n=== DEMO 2: Modelle auflisten ===');
  try {
    final result = await runMcpCommand({
      'jsonrpc': '2.0',
      'method': 'list_models',
      'params': {},
      'id': 2
    });
    
    final models = result['result'] as List;
    print('📁 Modelle (${models.length}):');
    for (int i = 0; i < 5 && i < models.length; i++) {
      print('  • ${models[i]['name']} (${models[i]['type']})');
    }
    if (models.length > 5) {
      print('  ... und ${models.length - 5} weitere');
    }
  } catch (e) {
    print('❌ Fehler: $e');
  }

  // Demo 3: Datei-Analyse
  print('\n=== DEMO 3: Datei-Analyse ===');
  try {
    final result = await runMcpCommand({
      'jsonrpc': '2.0',
      'method': 'analyze_file',
      'params': {'file_path': 'lib/models/creature.dart'},
      'id': 3
    });
    
    final analysis = result['result'];
    print('📄 Datei: ${analysis['file_path']}');
    print('   📏 Zeilen: ${analysis['line_count']}');
    print('   📦 Größe: ${analysis['size_bytes']} Bytes');
    final classes = analysis['classes'] as List;
    print('   🏗️  Klassen: ${classes.join(', ')}');
    final imports = analysis['imports'] as List;
    print('   📥 Imports: ${imports.length}');
    
    // Qualitätsbewertung
    final lineCount = analysis['line_count'] as int;
    if (lineCount > 500) {
      print('   ⚠️  Datei ist sehr groß - könnte refactored werden');
    } else if (lineCount > 200) {
      print('   💡 Datei ist mittel-groß - aufteilen prüfen');
    } else {
      print('   ✅ Gute Dateigröße');
    }
  } catch (e) {
    print('❌ Fehler: $e');
  }

  // Demo 4: Symbol-Suche
  print('\n=== DEMO 4: Symbol-Suche ===');
  try {
    final result = await runMcpCommand({
      'jsonrpc': '2.0',
      'method': 'find_references',
      'params': {'symbol': 'Creature'},
      'id': 4
    });
    
    final refs = result['result'] as List;
    print('🔍 Symbol: Creature (${refs.length} Treffer)');
    
    if (refs.isNotEmpty) {
      print('   Beispiel-Verwendungen:');
      for (int i = 0; i < 3 && i < refs.length; i++) {
        final ref = refs[i];
        final file = ref['file_path'] as String;
        final relativePath = file.replaceFirst('lib\\', 'lib/');
        print('   📂 $relativePath: Zeile ${ref['line_number']}');
      }
      if (refs.length > 3) {
        print('   ... und ${refs.length - 3} weitere');
      }
    }
  } catch (e) {
    print('❌ Fehler: $e');
  }

  // Demo 5: D&D Daten
  print('\n=== DEMO 5: D&D Beispieldaten ===');
  try {
    final result = await runMcpCommand({
      'jsonrpc': '2.0',
      'method': 'get_creatures',
      'params': {},
      'id': 5
    });
    
    final creatures = result['result'] as List;
    print('🐉 Beispiele-Kreaturen:');
    for (final creature in creatures) {
      print('   • ${creature['name']} (CR ${creature['cr']}, ${creature['type']})');
    }
  } catch (e) {
    print('❌ Fehler: $e');
  }

  print('\n✅ Demo abgeschlossen!');
  print('💡 Der MCP Server ist ein mächtiges Tool für deine tägliche Entwicklung!');
}

/// Führt einen MCP Befehl aus und gibt das Ergebnis zurück
Future<Map<String, dynamic>> runMcpCommand(Map<String, dynamic> request) async {
  // Verwende echo für einfache Kommunikation
  final jsonRequest = jsonEncode(request);
  final command = 'echo "$jsonRequest" | dart run bin/mcp_server.dart';
  
  final process = await Process.start('cmd', ['/c', command]);
  
  // Warte auf Ausgabe
  final output = await process.stdout
      .transform(utf8.decoder)
      .join()
      .timeout(Duration(seconds: 10));
  
  // Finde die JSON-Antwort in der Ausgabe
  final lines = output.split('\n');
  for (final line in lines) {
    if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
      try {
        return jsonDecode(line) as Map<String, dynamic>;
      } catch (e) {
        // Ignoriere ungültige JSON-Zeilen
      }
    }
  }
  
  throw Exception('Keine gültige JSON-Antwort gefunden');
}
