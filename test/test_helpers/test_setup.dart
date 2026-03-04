// Globale Test-Konfiguration und Setup-Funktionen
// Dieses Modul stellt zentrale Setup-Funktionen für alle Tests zur Verfügung

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

/// Globale Variable um mehrfache Initialisierungen zu vermeiden
bool _isDatabaseInitialized = false;

/// Initialisiert die SQLite FFI Datenbank für Tests
/// 
/// Diese Funktion sollte einmal vor dem Ausführen von Tests aufgerufen werden,
/// die Datenbankzugriffe benötigen.
Future<void> initializeTestDatabase() async {
  if (!_isDatabaseInitialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _isDatabaseInitialized = true;
  }
}

/// Setzt die Datenbank-Factory für Tests zurück
Future<void> resetTestDatabase() async {
  try {
    await databaseFactory.getDatabasesPath();
    // Hier können Datenbank-Dateien gelöscht werden wenn nötig
  } catch (e) {
    // Ignoriere Fehler beim Cleanup
  }
}

/// Standard Test Setup mit Datenbank-Initialisierung
/// 
/// Verwende dies im setUp() Block deiner Tests:
/// ```dart
/// setUp(() async {
///   await setUpTestDatabase();
/// });
/// ```
Future<void> setUpTestDatabase() async {
  await initializeTestDatabase();
}

/// Standard Test Teardown
/// 
/// Verwende dies im tearDown() Block deiner Tests:
/// ```dart
/// tearDown(() async {
///   await tearDownTestDatabase();
/// });
/// ```
Future<void> tearDownTestDatabase() async {
  await resetTestDatabase();
}

/// Prüft ob die Datenbank bereits initialisiert wurde
bool get isDatabaseInitialized => _isDatabaseInitialized;

/// Setzt den Initialisierungsstatus der Datenbank zurück
/// 
/// Nützlich für Test-Suites die eine frische Datenbank benötigen
void resetDatabaseInitializationStatus() {
  _isDatabaseInitialized = false;
}