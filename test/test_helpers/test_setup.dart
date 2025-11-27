// Test Setup Helper für DungenManager Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

/// Globale Variable um mehrfache Initialisierungen zu vermeiden
bool _isDatabaseInitialized = false;

/// Initialisiert die Datenbank für Tests
Future<void> initializeTestDatabase() async {
  // Nur einmal initialisieren um Warnungen zu vermeiden
  if (!_isDatabaseInitialized) {
    // Setze databaseFactory für Tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _isDatabaseInitialized = true;
  }
}

/// Setzt die Datenbank für Tests zurück
Future<void> resetTestDatabase() async {
  try {
    await databaseFactory.getDatabasesPath();
    // Hier könnten Datenbank-Dateien gelöscht werden wenn nötig
  } catch (e) {
    // Ignoriere Fehler beim Cleanup
  }
}

/// Standard Test Setup mit Datenbank-Initialisierung
Future<void> setUpTestDatabase() async {
  await initializeTestDatabase();
}

/// Standard Test Teardown
Future<void> tearDownTestDatabase() async {
  await resetTestDatabase();
}
