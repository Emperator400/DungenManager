import 'package:flutter_test/flutter_test.dart';
import '../lib/database/core/database_connection.dart';
import '../lib/database/migrations/refactoring_migration_v2.dart';
import '../lib/models/player_character.dart';
import '../lib/models/campaign.dart';
import '../lib/models/creature.dart';

/// Tests für die RefactoringMigrationV2
void main() {
  late DatabaseConnection connection;
  
  setUpAll(() async {
    // Verwende In-Memory Datenbank für Tests
    connection = DatabaseConnection.instance;
  });
  
  tearDownAll(() async {
    await connection.close();
  });
  
  group('RefactoringMigrationV2', () {
    test('Migration kann erstellt werden', () {
      final migration = RefactoringMigrationV2(connection);
      expect(migration, isNotNull);
    });
    
    test('Migration-Prüfung funktioniert', () async {
      final migration = RefactoringMigrationV2(connection);
      final isApplied = await migration.isMigrationApplied();
      expect(isApplied, isA<bool>());
    });
    
    test('Migration führt keine Fehler auf wenn keine Tabellen existieren', () async {
      final migration = RefactoringMigrationV2(connection);
      
      // Migration sollte erfolgreich sein, auch wenn keine Tabellen existieren
      final result = await migration.migrate();
      
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.logs, isNotEmpty);
      expect(result.version, equals(2));
    });
  });
  
  group('PlayerCharacter Migration', () {
    test('toDatabaseMap und fromDatabaseMap sind konsistent', () {
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign',
        name: 'Test Hero',
        playerName: 'Test Player',
        className: 'Fighter',
        raceName: 'Human',
      );
      
      final dbMap = character.toDatabaseMap();
      final restored = PlayerCharacter.fromDatabaseMap(dbMap);
      
      expect(restored.name, equals(character.name));
      expect(restored.playerName, equals(character.playerName));
      expect(restored.className, equals(character.className));
      expect(restored.raceName, equals(character.raceName));
    });
    
    test('Feldnamen sind snake_case', () {
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign',
        name: 'Test',
        playerName: 'Player',
        className: 'Wizard',
        raceName: 'Elf',
      );
      
      final dbMap = character.toDatabaseMap();
      
      expect(dbMap.containsKey('name'), isTrue);
      expect(dbMap.containsKey('player_name'), isTrue);
      expect(dbMap.containsKey('class_name'), isTrue);
      expect(dbMap.containsKey('race_name'), isTrue);
      expect(dbMap.containsKey('max_hp'), isTrue);
      expect(dbMap.containsKey('armor_class'), isTrue);
      
      // Alte Feldnamen sollten nicht mehr existieren
      expect(dbMap.containsKey('playerName'), isFalse);
      expect(dbMap.containsKey('className'), isFalse);
      expect(dbMap.containsKey('raceName'), isFalse);
      expect(dbMap.containsKey('maxHp'), isFalse);
    });
  });
  
  group('Campaign Migration', () {
    test('toDatabaseMap und fromDatabaseMap sind konsistent', () {
      final campaign = Campaign.create(
        title: 'Test Campaign',
        description: 'Test Description',
        dungeonMasterId: 'test-dm',
      );
      
      final dbMap = campaign.toDatabaseMap();
      final restored = Campaign.fromDatabaseMap(dbMap);
      
      expect(restored.title, equals(campaign.title));
      expect(restored.dungeonMasterId, equals(campaign.dungeonMasterId));
    });
    
    test('Settings und Stats werden serialisiert', () {
      final campaign = Campaign.create(
        title: 'Test',
        description: 'Test Description',
        dungeonMasterId: 'dm-id',
      );
      
      final dbMap = campaign.toDatabaseMap();
      
      expect(dbMap.containsKey('settings'), isTrue);
      expect(dbMap.containsKey('stats'), isTrue);
      expect(dbMap['settings'], isA<String>());
      expect(dbMap['stats'], isA<String>());
    });
  });
  
  group('Creature Migration', () {
    test('toDatabaseMap und fromDatabaseMap sind konsistent', () {
      final creature = Creature(
        id: 'test-id',
        name: 'Test Monster',
        maxHp: 10,
        challengeRating: 1,
        type: 'Beast',
      );
      
      final dbMap = creature.toDatabaseMap();
      final restored = Creature.fromDatabaseMap(dbMap);
      
      expect(restored.name, equals(creature.name));
      expect(restored.challengeRating, equals(creature.challengeRating));
      expect(restored.type, equals(creature.type));
    });
    
    test('Feldnamen sind snake_case', () {
      final creature = Creature(
        id: 'test-id',
        name: 'Dragon',
        maxHp: 100,
        challengeRating: 10,
        type: 'Dragon',
      );
      
      final dbMap = creature.toDatabaseMap();
      
      expect(dbMap.containsKey('max_hp'), isTrue);
      expect(dbMap.containsKey('armor_class'), isTrue);
      
      // Alte Feldnamen sollten nicht mehr existieren
      expect(dbMap.containsKey('maxHitPoints'), isFalse);
      expect(dbMap.containsKey('armorClass'), isFalse);
    });
  });
  
  group('MigrationResult', () {
    test('Erfolgreiches Ergebnis hat korrekte Werte', () {
      final result = MigrationResult(
        success: true,
        version: 2,
        duration: const Duration(seconds: 5),
        logs: ['Test log'],
      );
      
      expect(result.success, isTrue);
      expect(result.version, equals(2));
      expect(result.duration.inSeconds, equals(5));
      expect(result.logs.length, equals(1));
      expect(result.error, isNull);
    });
    
    test('Fehlerhaftes Ergebnis enthält Fehlerinformation', () {
      final result = MigrationResult(
        success: false,
        version: 2,
        duration: const Duration(seconds: 1),
        logs: ['Error log'],
        error: 'Migration failed',
      );
      
      expect(result.success, isFalse);
      expect(result.error, equals('Migration failed'));
      expect(result.logs.contains('Error log'), isTrue);
    });
    
    test('toString() gibt lesbare Rückgabe', () {
      final result = MigrationResult(
        success: true,
        version: 2,
        duration: const Duration(seconds: 3),
        logs: ['Success'],
      );
      
      final output = result.toString();
      
      expect(output, contains('Erfolgreich'));
      expect(output, contains('Version: 2'));
      expect(output, contains('Dauer: 3s'));
      expect(output, contains('Details:'));
    });
  });
}
