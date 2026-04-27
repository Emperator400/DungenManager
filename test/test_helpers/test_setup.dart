// Globale Test-Konfiguration und Setup-Funktionen

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dungen_manager/database/core/database_connection.dart';

/// Richtet eine isolierte In-Memory-SQLite-Datenbank für jeden Test ein.
///
/// Verwendung:
/// ```dart
/// setUp(() async => setUpTestDatabase());
/// tearDown(() async => tearDownTestDatabase());
/// ```
///
/// Nach dem Setup ist [DatabaseConnection.instance] so konfiguriert, dass es
/// auf die In-Memory-Datenbank zeigt. Repositories und Services können
/// ohne Änderungen verwendet werden.
Future<void> setUpTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await DatabaseConnection.initializeForTesting();
}

/// Schließt die In-Memory-Datenbank und setzt den Singleton zurück.
Future<void> tearDownTestDatabase() async {
  await DatabaseConnection.resetForTesting();
}
