import 'dart:convert';
import 'dart:io';

/// Test-Skript für die Settings-MCP-Server-Funktionen
void main() async {
  print('Teste Settings MCP Server...\n');

  // Test-Methoden und ihre erwarteten Parameter
  final tests = [
    {
      'name': 'get_settings',
      'params': {},
      'description': 'Alle aktuellen Settings abrufen'
    },
    {
      'name': 'get_setting',
      'params': {'key': 'theme'},
      'description': 'Spezifischen Setting-Wert abrufen'
    },
    {
      'name': 'set_setting',
      'params': {'key': 'theme', 'value': 'dark'},
      'description': 'Theme auf dark setzen'
    },
    {
      'name': 'set_setting',
      'params': {'key': 'volume', 'value': 0.9},
      'description': 'Volume auf 0.9 setzen'
    },
    {
      'name': 'set_setting',
      'params': {'key': 'darkMode', 'value': true},
      'description': 'Dark Mode aktivieren'
    },
    {
      'name': 'update_settings',
      'params': {
        'settings': {
          'language': 'en',
          'autoSave': false,
          'autoSaveInterval': 600
        }
      },
      'description': 'Mehrere Settings auf einmal aktualisieren'
    },
    {
      'name': 'get_settings',
      'params': {},
      'description': 'Settings nach Updates überprüfen'
    },
    {
      'name': 'reset_settings',
      'params': {},
      'description': 'Alle Settings zurücksetzen'
    },
    {
      'name': 'get_settings',
      'params': {},
      'description': 'Settings nach Reset überprüfen'
    },
  ];

  // Führe alle Tests durch
  for (int i = 0; i < tests.length; i++) {
    final test = tests[i];
    print('Test ${i + 1}: ${test['description']}');
    print('Methode: ${test['name']}');
    print('Parameter: ${jsonEncode(test['params'])}');
    
    final request = {
      'jsonrpc': '2.0',
      'method': test['name'],
      'params': test['params'],
      'id': i + 1
    };
    
    try {
      final process = await Process.start('dart', ['run', 'bin/mcp_server.dart']);
      process.stdin.writeln(jsonEncode(request));
      process.stdin.close();
      
      final response = await process.stdout.transform(utf8.decoder).first;
      final result = jsonDecode(response) as Map<String, dynamic>;
      
      if (result.containsKey('result')) {
        print('✅ Erfolg: ${jsonEncode(result['result'])}');
      } else {
        print('❌ Fehler: ${jsonEncode(result['error'])}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
    
    print('---\n');
  }
  
  print('Tests abgeschlossen!');
}
