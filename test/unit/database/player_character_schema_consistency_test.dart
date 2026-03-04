import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/database/entities/player_character_entity.dart';

/// Testet die Konsistenz zwischen PlayerCharacter Modell und Datenbank-Schema
/// 
/// Dieser Test stellt sicher, dass alle Felder, die das Modell in toDatabaseMap()
/// serialisiert, auch in der Datenbanktabelle existieren. Dies verhindert Fehler
/// wie "table player_characters has no column named xyz".
void main() {
  group('PlayerCharacter Schema Consistency Tests', () {
    late Database db;

    setUpAll(() async {
      // Initialisiere SQLite FFI für Tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      // Erstelle In-Memory Datenbank
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (Database db, int version) async {
          // Erstelle die player_characters Tabelle mit dem Schema aus PlayerCharacterEntity
          final entity = PlayerCharacterEntity(
            id: '',
            name: '',
            characterClass: '',
            level: 1,
            race: '',
            hitPoints: 10,
            maxHitPoints: 10,
            armorClass: 10,
            speed: 30,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          for (final sql in entity.createTableSql) {
            await db.execute(sql);
          }
        },
      );
    });

    tearDownAll(() async {
      await db.close();
    });

    test('PlayerCharacter Modell toDatabaseMap() enthält nur Felder, die in der Datenbank existieren', () async {
      // Erstelle ein Beispiel-PlayerCharacter
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id',
        name: 'Test Hero',
        playerName: 'Test Player',
        className: 'Barbar',
        raceName: 'Zwerg',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        equipment: {'helmet': 'steel helmet', 'shield': 'wooden shield'},
      );

      // Serialisiere das Modell
      final databaseMap = character.toDatabaseMap();

      // Hole die tatsächlichen Spalten aus der Datenbank
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final actualColumns = tableInfo.map((row) => row['name'] as String).toSet();

      // Prüfe, ob alle Keys aus toDatabaseMap in der Datenbank existieren
      final missingColumns = <String>[];
      for (final key in databaseMap.keys) {
        if (!actualColumns.contains(key)) {
          missingColumns.add(key);
        }
      }

      expect(
        missingColumns,
        isEmpty,
        reason: 'Folgende Felder fehlen in der Datenbanktabelle: ${missingColumns.join(", ")}',
      );
    });

    test('PlayerCharacterEntity.databaseFields enthält alle Felder, die in createTableSql definiert sind', () {
      final entity = PlayerCharacterEntity(
        id: 'test-id',
        name: 'Test',
        characterClass: 'Barbar',
        level: 1,
        race: 'Zwerg',
        hitPoints: 10,
        maxHitPoints: 10,
        armorClass: 10,
        speed: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final databaseFields = entity.databaseFields;
      
      // Extrahiere Spalten aus CREATE TABLE SQL
      final createTableSql = entity.createTableSql.first;
      final sqlFields = _extractColumnsFromCreateTableSql(createTableSql);

      // Prüfe, ob alle databaseFields im SQL definiert sind
      final missingInSql = <String>[];
      for (final field in databaseFields) {
        if (!sqlFields.contains(field)) {
          missingInSql.add(field);
        }
      }

      expect(
        missingInSql,
        isEmpty,
        reason: 'Folgende databaseFields sind nicht in createTableSql definiert: ${missingInSql.join(", ")}',
      );
    });

    test('Migration fügt equipment Spalte erfolgreich hinzu', () async {
      // Prüfe ob equipment Spalte existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final hasEquipment = tableInfo.any((column) => column['name'] == 'equipment');

      expect(
        hasEquipment,
        isTrue,
        reason: 'Die equipment Spalte sollte nach der Migration existieren',
      );
    });

    test('PlayerCharacter mit Equipment kann ohne Fehler gespeichert werden', () async {
      // Erstelle ein Character mit Equipment
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id',
        name: 'Test Hero',
        playerName: 'Test Player',
        className: 'Barbar',
        raceName: 'Zwerg',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        equipment: {
          'helmet': 'steel helmet',
          'shield': 'wooden shield',
          'weapon': 'longsword',
        },
      );

      // Versuche, das Character in die Datenbank zu schreiben
      final databaseMap = character.toDatabaseMap();

      // Dies sollte keinen Fehler werfen
      expect(
        () async => await db.insert('player_characters', databaseMap),
        returnsNormally,
        reason: 'Ein PlayerCharacter mit Equipment sollte ohne SQL-Fehler gespeichert werden können',
      );
    });

    test('PlayerCharacter ohne Equipment kann ohne Fehler gespeichert werden', () async {
      // Erstelle ein Character ohne Equipment
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id',
        name: 'Test Hero',
        playerName: 'Test Player',
        className: 'Barbar',
        raceName: 'Zwerg',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        equipment: null,
      );

      // Versuche, das Character in die Datenbank zu schreiben
      final databaseMap = character.toDatabaseMap();

      // Dies sollte keinen Fehler werfen
      expect(
        () async => await db.insert('player_characters', databaseMap),
        returnsNormally,
        reason: 'Ein PlayerCharacter ohne Equipment sollte ohne SQL-Fehler gespeichert werden können',
      );
    });
  });
}

/// Hilfsfunktion zum Extrahieren von Spaltennamen aus CREATE TABLE SQL
Set<String> _extractColumnsFromCreateTableSql(String sql) {
  final columns = <String>{};
  
  // Entferne CREATE TABLE ... ( und das schließende )
  final startIndex = sql.indexOf('(');
  final endIndex = sql.lastIndexOf(')');
  
  if (startIndex == -1 || endIndex == -1) {
    return columns;
  }
  
  final columnDefinitions = sql.substring(startIndex + 1, endIndex).split(',');
  
  for (final definition in columnDefinitions) {
    final trimmed = definition.trim();
    if (trimmed.isEmpty) continue;
    
    // Der erste Teil ist der Spaltenname
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      final columnName = parts.first.trim();
      // Ignoriere CONSTRAINTS, FOREIGN KEY etc.
      if (columnName.toUpperCase() != 'CONSTRAINT' && 
          columnName.toUpperCase() != 'FOREIGN' &&
          columnName.toUpperCase() != 'PRIMARY') {
        columns.add(columnName);
      }
    }
  }
  
  return columns;
}