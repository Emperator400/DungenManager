import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/database/entities/player_character_entity.dart';

/// Integration-Test für das vollständige Speichern eines PlayerCharacters
/// 
/// Dieser Test simuliert den tatsächlichen Speichervorgang und stellt sicher,
/// dass keine SQL-Fehler auftreten, wie z.B. "table player_characters has no column named equipment".
void main() {
  group('PlayerCharacter Save Integration Tests', () {
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
          
          // Erstelle Indizes
          for (final indexSql in entity.createIndexes) {
            await db.execute(indexSql);
          }
        },
      );
    });

    tearDownAll(() async {
      await db.close();
    });

    test('Speichert einen kompletten PlayerCharacter mit allen Feldern', () async {
      // Erstelle einen vollständigen PlayerCharacter
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id-123',
        name: 'Thorin Eisenfels',
        playerName: 'Max Mustermann',
        className: 'Barbar',
        raceName: 'Zwerg',
        level: 3,
        maxHp: 28,
        armorClass: 16,
        initiativeBonus: 2,
        imagePath: '/images/thorin.jpg',
        strength: 16,
        dexterity: 12,
        constitution: 16,
        intelligence: 10,
        wisdom: 13,
        charisma: 8,
        proficientSkills: ['Athletik', 'Überleben', 'Einschüchtern'],
        size: 'Medium',
        type: 'Humanoid',
        subtype: 'Zwerg',
        alignment: 'Chaotisch Neutral',
        description: 'Ein tapferer Zwergenkrieger aus dem Eisengebirge',
        specialAbilities: 'Wüteraus, Unverwundbarkeit (Böses)',
        attacks: 'Große Axt: +6 zu treffen, 1d12+4 Schaden',
        inventory: [],
        gold: 15.5,
        silver: 30.0,
        copper: 7.0,
        sourceType: 'custom',
        version: '1.0',
        equipment: {
          'helm': 'Stahlhelm',
          'schild': 'Holzschild',
          'waffe': 'Große Axt',
          'rüstung': 'Kettenhemd',
        },
        proficiencyBonus: 2,
        speed: 25,
        passivePerception: 11,
        spellSlots: null,
        spellSaveDc: 13,
        spellAttackBonus: 4,
      );

      // Serialisiere das Modell
      final databaseMap = character.toDatabaseMap();

      // Versuche, das Character in die Datenbank zu schreiben
      final id = await db.insert('player_characters', databaseMap);

      // Überprüfe, dass die Speicherung erfolgreich war
      expect(id, isNotNull);
      expect(id, isPositive);

      // Überprüfe, dass der Character tatsächlich in der Datenbank ist
      final savedCharacters = await db.query(
        'player_characters',
        where: 'id = ?',
        whereArgs: [character.id],
      );

      expect(savedCharacters.length, equals(1));
      expect(savedCharacters.first['name'], equals('Thorin Eisenfels'));
      expect(savedCharacters.first['class_name'], equals('Barbar'));
      expect(savedCharacters.first['equipment'], isNotNull);
    });

    test('Speichert einen minimalen PlayerCharacter ohne optionale Felder', () async {
      // Erstelle einen minimalen PlayerCharacter
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id-456',
        name: 'Minimal Hero',
        playerName: 'Simple Player',
        className: 'Krieger',
        raceName: 'Mensch',
        level: 1,
        maxHp: 10,
        armorClass: 10,
      );

      // Serialisiere das Modell
      final databaseMap = character.toDatabaseMap();

      // Versuche, das Character in die Datenbank zu schreiben
      final id = await db.insert('player_characters', databaseMap);

      // Überprüfe, dass die Speicherung erfolgreich war
      expect(id, isNotNull);
      expect(id, isPositive);

      // Überprüfe, dass der Character tatsächlich in der Datenbank ist
      final savedCharacters = await db.query(
        'player_characters',
        where: 'id = ?',
        whereArgs: [character.id],
      );

      expect(savedCharacters.length, equals(1));
      expect(savedCharacters.first['name'], equals('Minimal Hero'));
    });

    test('Aktualisiert einen bestehenden PlayerCharacter erfolgreich', () async {
      // Erstelle und speichere einen PlayerCharacter
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id-789',
        name: 'Update Hero',
        playerName: 'Update Player',
        className: 'Magier',
        raceName: 'Elf',
        level: 1,
        maxHp: 8,
        armorClass: 12,
      );

      final databaseMap = character.toDatabaseMap();
      await db.insert('player_characters', databaseMap);

      // Aktualisiere den Character
      final updatedCharacter = character.copyWith(
        level: 2,
        maxHp: 12,
        armorClass: 13,
        equipment: {'stab': 'Magierstab', 'buch': 'Zauberbuch'},
      );

      final updatedMap = updatedCharacter.toDatabaseMap();
      final rowsAffected = await db.update(
        'player_characters',
        updatedMap,
        where: 'id = ?',
        whereArgs: [character.id],
      );

      // Überprüfe, dass das Update erfolgreich war
      expect(rowsAffected, equals(1));

      // Überprüfe, dass die Änderungen gespeichert wurden
      final savedCharacters = await db.query(
        'player_characters',
        where: 'id = ?',
        whereArgs: [character.id],
      );

      expect(savedCharacters.length, equals(1));
      expect(savedCharacters.first['level'], equals(2));
      expect(savedCharacters.first['max_hp'], equals(12));
      expect(savedCharacters.first['equipment'], isNotNull);
    });

    test('Löscht einen PlayerCharacter erfolgreich', () async {
      // Erstelle und speichere einen PlayerCharacter
      final character = PlayerCharacter.create(
        campaignId: 'test-campaign-id-delete',
        name: 'Delete Hero',
        playerName: 'Delete Player',
        className: 'Schurke',
        raceName: 'Halbork',
        level: 1,
        maxHp: 10,
        armorClass: 12,
      );

      final databaseMap = character.toDatabaseMap();
      await db.insert('player_characters', databaseMap);

      // Lösche den Character
      final rowsAffected = await db.delete(
        'player_characters',
        where: 'id = ?',
        whereArgs: [character.id],
      );

      // Überprüfe, dass das Delete erfolgreich war
      expect(rowsAffected, equals(1));

      // Überprüfe, dass der Character nicht mehr in der Datenbank ist
      final savedCharacters = await db.query(
        'player_characters',
        where: 'id = ?',
        whereArgs: [character.id],
      );

      expect(savedCharacters.length, equals(0));
    });

    test('Speichert mehrere PlayerCharacters hintereinander', () async {
      final characters = [
        PlayerCharacter.create(
          campaignId: 'test-campaign-multi',
          name: 'Hero 1',
          playerName: 'Player 1',
          className: 'Krieger',
          raceName: 'Mensch',
          level: 1,
          maxHp: 10,
          armorClass: 10,
        ),
        PlayerCharacter.create(
          campaignId: 'test-campaign-multi',
          name: 'Hero 2',
          playerName: 'Player 2',
          className: 'Magier',
          raceName: 'Elf',
          level: 1,
          maxHp: 8,
          armorClass: 12,
        ),
        PlayerCharacter.create(
          campaignId: 'test-campaign-multi',
          name: 'Hero 3',
          playerName: 'Player 3',
          className: 'Kleriker',
          raceName: 'Zwerg',
          level: 1,
          maxHp: 10,
          armorClass: 16,
        ),
      ];

      // Speichere alle Characters
      for (final character in characters) {
        final databaseMap = character.toDatabaseMap();
        final id = await db.insert('player_characters', databaseMap);
        expect(id, isNotNull);
        expect(id, isPositive);
      }

      // Überprüfe, dass alle Characters gespeichert wurden
      final allCharacters = await db.query(
        'player_characters',
        where: 'campaign_id = ?',
        whereArgs: ['test-campaign-multi'],
      );

      expect(allCharacters.length, equals(3));
    });
  });
}