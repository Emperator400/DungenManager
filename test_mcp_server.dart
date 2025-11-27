import 'dart:convert';
import 'dart:io';

/// Test-Client für den MCP Server
Future<void> main() async {
  print('Teste MCP Server...');
  
  // Teste get_project_info
  final request1 = {
    'jsonrpc': '2.0',
    'method': 'get_project_info',
    'params': {},
    'id': 1
  };
  
  // Teste list_models
  final request2 = {
    'jsonrpc': '2.0',
    'method': 'list_models',
    'params': {},
    'id': 2
  };
  
  // Teste analyze_file
  final request3 = {
    'jsonrpc': '2.0',
    'method': 'analyze_file',
    'params': {'file_path': 'bin/mcp_server.dart'},
    'id': 3
  };
  
  for (final request in [request1, request2, request3]) {
    print('\nSende: ${jsonEncode(request)}');
    
    // Simuliere Server-Antwort
    final process = await Process.start('dart', ['bin/mcp_server.dart']);
    
    // Sende Anfrage
    process.stdin.writeln(jsonEncode(request));
    process.stdin.write('\n');
    
    // Warte auf Antwort
    final response = await process.stdout.transform(utf8.decoder).first;
    print('Antwort: $response');
    
    // Beende den Prozess
    process.kill();
  }
}
