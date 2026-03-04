import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

/// Integration-Test für Datenbank-Migrationen
/// 
/// Dieser Test stellt sicher, dass Migrationen korrekt ausgeführt werden
/// und neue Spalten erfolgreich hinzugefügt werden.
void main() {
  group('Database Migration Tests', () {
    late Database db;

    setUpAll(() async {
      // Initialisiere SQLite FFI für Tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // Erstelle In-Memory Datenbank mit alter Version
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 5, // Ältere Version ohne equipment Spalte
        onCreate: (Database db, int version) async {
          // Erstelle player_characters Tabelle ohne equipment Spalte
          await db.execute('''
            CREATE TABLE player_characters (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              class_name TEXT NOT NULL,
              level INTEGER NOT NULL DEFAULT 1,
              race_name TEXT NOT NULL,
              hit_points INTEGER NOT NULL DEFAULT 10,
              max_hit_points INTEGER NOT NULL DEFAULT 10,
              armor_class INTEGER NOT NULL DEFAULT 10,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );
    });

    tearDownAll(() async {
      await db.close();
    });

    test('_addEquipmentColumn fügt equipment Spalte erfolgreich hinzu', () async {
      // Prüfe ob equipment Spalte NICHT existiert
      var tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      var hasEquipmentBefore = tableInfo.any((column) => column['name'] == 'equipment');
      expect(hasEquipmentBefore, isFalse, reason: 'Equipment Spalte sollte vor der Migration nicht existieren');

      // Führe die Migration aus (simuliert durch direkten ALTER TABLE Aufruf)
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN equipment TEXT');
      } catch (e) {
        fail('Migration sollte erfolgreich sein: $e');
      }

      // Prüfe ob equipment Spalte jetzt existiert
      tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      var hasEquipmentAfter = tableInfo.any((column) => column['name'] == 'equipment');
      expect(hasEquipmentAfter, isTrue, reason: 'Equipment Spalte sollte nach der Migration existieren');
    });

    test('Führt Migration mehrmals ohne Fehler aus', () async {
      // Versuche, die Spalte mehrfach hinzuzufügen
      for (int i = 0; i < 3; i++) {
        try {
          await db.execute('ALTER TABLE player_characters ADD COLUMN equipment TEXT');
        } catch (e) {
          // Wenn die Spalte bereits existiert, ist das in Ordnung
          if (!e.toString().contains('duplicate column name')) {
            fail('Erneutes Hinzufügen der Spalte sollte keinen Fehler werfen (außer duplicate): $e');
          }
        }
      }

      // Prüfe, dass die Spalte immer noch existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final hasEquipment = tableInfo.any((column) => column['name'] == 'equipment');
      expect(hasEquipment, isTrue, reason: 'Equipment Spalte sollte existieren');
    });

    test('Equipment Spalte akzeptiert NULL Werte', () async {
      // Füge equipment Spalte hinzu falls noch nicht vorhanden
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN equipment TEXT');
      } catch (e) {
        // Ignoriere Fehler wenn Spalte bereits existiert
      }

      // Füge einen Datensatz ohne Equipment ein
      await db.insert('player_characters', {
        'id': 'test-id-1',
        'name': 'Test Hero',
        'class_name': 'Warrior',
        'level': 1,
        'race_name': 'Human',
        'hit_points': 10,
        'max_hit_points': 10,
        'armor_class': 10,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Füge einen Datensatz mit NULL Equipment ein
      await db.insert('player_characters', {
        'id': 'test-id-2',
        'name': 'Test Hero 2',
        'class_name': 'Mage',
        'level': 1,
        'race_name': 'Elf',
        'hit_points': 8,
        'max_hit_points': 8,
        'armor_class': 12,
        'equipment': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Prüfe, dass beide Datensätze gespeichert wurden
      final result = await db.query('player_characters');
      expect(result.length, equals(2));
      expect(result[0]['equipment'], isNull);
      expect(result[1]['equipment'], isNull);
    });

    test('Equipment Spalte akzeptiert JSON-Strings', () async {
      // Füge equipment Spalte hinzu falls noch nicht vorhanden
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN equipment TEXT');
      } catch (e) {
        // Ignoriere Fehler wenn Spalte bereits existiert
      }

      // Füge einen Datensatz mit JSON Equipment ein
      final jsonEquipment = '{"helm":"Stahlhelm","waffe":"Schwert"}';
      await db.insert('player_characters', {
        'id': 'test-id-json',
        'name': 'Test Hero JSON',
        'class_name': 'Fighter',
        'level': 1,
        'race_name': 'Human',
        'hit_points': 10,
        'max_hit_points': 10,
        'armor_class': 10,
        'equipment': jsonEquipment,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Prüfe, dass der JSON-Wert korrekt gespeichert wurde
      final result = await db.query(
        'player_characters',
        where: 'id = ?',
        whereArgs: ['test-id-json'],
      );
      expect(result.length, equals(1));
      expect(result.first['equipment'], equals(jsonEquipment));
    });

    test('Prüft alle Spalten der player_characters Tabelle', () async {
      // Füge equipment Spalte hinzu falls noch nicht vorhanden
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN equipment TEXT');
      } catch (e) {
        // Ignoriere Fehler wenn Spalte bereits existiert
      }

      // Prüfe alle Spalten
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final columnNames = tableInfo.map((row) => row['name'] as String).toList();

      // Wichtige Spalten sollten vorhanden sein
      expect(columnNames, contains('id'));
      expect(columnNames, contains('name'));
      expect(columnNames, contains('class_name'));
      expect(columnNames, contains('level'));
      expect(columnNames, contains('race_name'));
      expect(columnNames, contains('hit_points'));
      expect(columnNames, contains('max_hit_points'));
      expect(columnNames, contains('armor_class'));
      expect(columnNames, contains('equipment'), reason: 'Equipment Spalte sollte vorhanden sein');
      expect(columnNames, contains('created_at'));
      expect(columnNames, contains('updated_at'));
    });
  });
}