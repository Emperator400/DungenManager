import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/database/repositories/player_character_model_repository.dart';
import 'package:dungen_manager/database/core/database_connection.dart';
import '../test_helpers/test_setup.dart';

/// Integration-Test für PlayerCharacter CRUD über PlayerCharacterModelRepository.
///
/// Stellt sicher, dass das Modell korrekt serialisiert, gespeichert und
/// aus der Datenbank gelesen werden kann — mit dem echten Produktionsschema.
void main() {
  group('PlayerCharacter Save Integration Tests', () {
    late PlayerCharacterModelRepository repo;

    setUp(() async {
      await setUpTestDatabase();
      repo = PlayerCharacterModelRepository(DatabaseConnection.instance);
    });

    tearDown(() async {
      await tearDownTestDatabase();
    });

    test('Speichert einen kompletten PlayerCharacter mit allen Feldern', () async {
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
        equipment: {'helm': 'Stahlhelm', 'waffe': 'Große Axt'},
        proficiencyBonus: 2,
        speed: 25,
        passivePerception: 11,
        spellSaveDc: 13,
        spellAttackBonus: 4,
      );

      final saved = await repo.create(character);

      expect(saved.id, equals(character.id));
      expect(saved.name, equals('Thorin Eisenfels'));
      expect(saved.className, equals('Barbar'));
      expect(saved.level, equals(3));
      expect(saved.gold, equals(15.5));
    });

    test('Speichert einen minimalen PlayerCharacter ohne optionale Felder', () async {
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

      final saved = await repo.create(character);

      expect(saved.id, equals(character.id));
      expect(saved.name, equals('Minimal Hero'));
      expect(saved.level, equals(1));
    });

    test('Aktualisiert einen bestehenden PlayerCharacter erfolgreich', () async {
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

      await repo.create(character);

      final updated = character.copyWith(level: 2, maxHp: 12, armorClass: 13);
      final saved = await repo.update(updated);

      expect(saved.level, equals(2));
      expect(saved.maxHp, equals(12));
      expect(saved.armorClass, equals(13));
    });

    test('Löscht einen PlayerCharacter erfolgreich', () async {
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

      await repo.create(character);
      await repo.delete(character.id);

      final found = await repo.findById(character.id);
      expect(found, isNull);
    });

    test('Speichert mehrere PlayerCharacters und liest sie zurück', () async {
      final names = ['Hero 1', 'Hero 2', 'Hero 3'];

      for (final name in names) {
        await repo.create(PlayerCharacter.create(
          campaignId: 'test-campaign-multi',
          name: name,
          playerName: 'Player',
          className: 'Krieger',
          raceName: 'Mensch',
          level: 1,
          maxHp: 10,
          armorClass: 10,
        ));
      }

      final all = await repo.findByCampaign('test-campaign-multi');
      expect(all.length, equals(3));
      expect(all.map((c) => c.name).toSet(), equals(names.toSet()));
    });
  });
}
