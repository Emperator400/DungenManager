import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/database/core/database_connection.dart';
import 'package:dungen_manager/database/repositories/player_character_model_repository.dart';
import '../../test_helpers/test_setup.dart';

/// Stellt sicher, dass PlayerCharacter.toDatabaseMap() nur Spalten enthält,
/// die auch im Produktionsschema (DatabaseConnection) existieren.
///
/// Dieser Test erkennt Schema-Drifts frühzeitig — bevor sie in Produktion auftreten.
void main() {
  group('PlayerCharacter Schema Consistency Tests', () {
    late Database db;
    late PlayerCharacterModelRepository repo;

    setUp(() async {
      await setUpTestDatabase();
      db = await DatabaseConnection.instance.database;
      repo = PlayerCharacterModelRepository(DatabaseConnection.instance);
    });

    tearDown(() async {
      await tearDownTestDatabase();
    });

    test('toDatabaseMap() enthält nur Spalten die im Produktionsschema existieren', () async {
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id',
        name: 'Test Hero',
        playerName: 'Test Player',
        className: 'Barbar',
        raceName: 'Zwerg',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        equipment: {'helmet': 'steel helmet'},
      );

      final databaseMap = character.toDatabaseMap();
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final actualColumns = tableInfo.map((row) => row['name'] as String).toSet();

      final missingColumns = databaseMap.keys.where((k) => !actualColumns.contains(k)).toList();

      expect(
        missingColumns,
        isEmpty,
        reason: 'Spalten in toDatabaseMap() fehlen im Schema: ${missingColumns.join(", ")}',
      );
    });

    test('PlayerCharacter mit Equipment wird gespeichert und geladen', () async {
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id',
        name: 'Equipment Hero',
        playerName: 'Test Player',
        className: 'Barbar',
        raceName: 'Zwerg',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        equipment: {'helmet': 'steel helmet', 'shield': 'wooden shield', 'weapon': 'longsword'},
      );

      final saved = await repo.create(character);
      expect(saved.id, equals(character.id));
      expect(saved.equipment?['helmet'], equals('steel helmet'));
    });

    test('PlayerCharacter ohne Equipment wird gespeichert und geladen', () async {
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id',
        name: 'No Equipment Hero',
        playerName: 'Test Player',
        className: 'Schurke',
        raceName: 'Halbork',
        level: 1,
        maxHp: 10,
        armorClass: 10,
        equipment: null,
      );

      final saved = await repo.create(character);
      expect(saved.id, equals(character.id));
    });

    test('equipment Spalte existiert in der Datenbank', () async {
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final columns = tableInfo.map((row) => row['name'] as String).toSet();
      expect(columns, contains('equipment'));
      expect(columns, contains('hit_dice'));
      expect(columns, contains('hit_dice_count'));
      expect(columns, contains('hit_dice_remaining'));
    });
  });
}
