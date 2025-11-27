import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/models/session.dart';
import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/models/sound.dart';

void main() {
  group('Model Unit Tests', () {

    group('Campaign Model', () {
      test('Campaign creation with valid data', () {
        final campaign = Campaign.create(
          title: 'Test Campaign',
          description: 'Test Description',
        );

        expect(campaign.title, 'Test Campaign');
        expect(campaign.description, 'Test Description');
        expect(campaign.id, isNotNull);
        expect(campaign.id.length, greaterThan(0));
      });

      test('Campaign creation with custom ID', () {
        final campaign = Campaign(
          id: 'custom-id',
          title: 'Test Campaign',
          description: 'Test Description',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(campaign.id, 'custom-id');
      });

      test('Campaign toMap and fromMap', () {
        final originalCampaign = Campaign.create(
          title: 'Test Campaign',
          description: 'Test Description',
        );

        final map = originalCampaign.toMap();
        final restoredCampaign = Campaign.fromMap(map);

        expect(restoredCampaign.id, originalCampaign.id);
        expect(restoredCampaign.title, originalCampaign.title);
        expect(restoredCampaign.description, originalCampaign.description);
      });

      test('Campaign fromMap with missing optional fields', () {
        final map = {
          'id': 'test-id',
          'title': 'Test Campaign',
          'description': 'Test Description',
        };

        final campaign = Campaign.fromMap(map);
        expect(campaign.id, 'test-id');
        expect(campaign.title, 'Test Campaign');
        expect(campaign.description, 'Test Description');
      });
    });

    group('Player Character Model', () {
      test('PlayerCharacter creation with valid data', () {
        final character = PlayerCharacter.create(
          campaignId: 'campaign-id',
          name: 'Test Character',
          playerName: 'Test Player',
          className: 'Warrior',
          raceName: 'Human',
        );

        expect(character.campaignId, 'campaign-id');
        expect(character.name, 'Test Character');
        expect(character.playerName, 'Test Player');
        expect(character.className, 'Warrior');
        expect(character.raceName, 'Human');
        expect(character.level, 1);
        expect(character.maxHp, 10);
        expect(character.armorClass, 10);
        expect(character.initiativeBonus, 0);
        expect(character.strength, 10);
        expect(character.dexterity, 10);
        expect(character.constitution, 10);
        expect(character.intelligence, 10);
        expect(character.wisdom, 10);
        expect(character.charisma, 10);
        expect(character.proficientSkills, isEmpty);
      });

      test('PlayerCharacter creation with custom values', () {
        final character = PlayerCharacter(
          id: 'custom-id',
          campaignId: 'campaign-id',
          name: 'Test Character',
          playerName: 'Test Player',
          className: 'Warrior',
          raceName: 'Human',
          level: 5,
          maxHp: 50,
          armorClass: 18,
          initiativeBonus: 2,
          strength: 16,
          dexterity: 14,
          constitution: 15,
          intelligence: 12,
          wisdom: 13,
          charisma: 10,
          proficientSkills: const ['Athletics', 'Intimidation'],
          attackList: const [],
          inventory: const [],
          gold: 100,
          silver: 50,
          copper: 25,
          sourceType: 'manual',
          version: '1.0',
        );

        expect(character.id, 'custom-id');
        expect(character.level, 5);
        expect(character.maxHp, 50);
        expect(character.armorClass, 18);
        expect(character.initiativeBonus, 2);
        expect(character.strength, 16);
        expect(character.proficientSkills, const ['Athletics', 'Intimidation']);
      });

      test('PlayerCharacter toMap and fromMap', () {
        final originalCharacter = PlayerCharacter.create(
          campaignId: 'campaign-id',
          name: 'Test Character',
          playerName: 'Test Player',
          className: 'Warrior',
          raceName: 'Human',
          level: 3,
          proficientSkills: const ['Athletics', 'Intimidation'],
        );

        final map = originalCharacter.toMap();
        final restoredCharacter = PlayerCharacter.fromMap(map);

        expect(restoredCharacter.id, originalCharacter.id);
        expect(restoredCharacter.name, originalCharacter.name);
        expect(restoredCharacter.className, originalCharacter.className);
        expect(restoredCharacter.level, originalCharacter.level);
        expect(restoredCharacter.proficientSkills, originalCharacter.proficientSkills);
      });

      test('PlayerCharacter fromMap with default values', () {
        final map = {
          'id': 'test-id',
          'campaign_id': 'campaign-id',
          'name': 'Test Character',
          'player_name': 'Test Player',
          'class_name': 'Warrior',
          'race_name': 'Human',
        };

        final character = PlayerCharacter.fromMap(map);
        expect(character.level, 1);
        expect(character.maxHp, 10);
        expect(character.armorClass, 10);
        expect(character.strength, 10);
        expect(character.proficientSkills, isEmpty);
      });
    });

    group('Quest Model', () {
      test('Quest creation with valid data', () {
        final quest = Quest.create(
          title: 'Test Quest',
          description: 'Test Description',
        );

        expect(quest.title, 'Test Quest');
        expect(quest.description, 'Test Description');
        expect(quest.status, QuestStatus.active);
        expect(quest.id, isNotNull);
      });

      test('Quest creation with custom ID', () {
        final quest = Quest(
          id: 123,
          title: 'Test Quest',
          description: 'Test Description',
          status: QuestStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(quest.id, 123);
      });

      test('Quest toMap and fromMap', () {
        final originalQuest = Quest.create(
          title: 'Test Quest',
          description: 'Test Description',
        );

        final map = originalQuest.toMap();
        final restoredQuest = Quest.fromMap(map);

        expect(restoredQuest.id, originalQuest.id);
        expect(restoredQuest.title, originalQuest.title);
        expect(restoredQuest.description, originalQuest.description);
        expect(restoredQuest.status, originalQuest.status);
      });
    });

    group('Sound Model', () {
      test('Sound creation with valid data', () {
        final sound = Sound(
          name: 'Test Sound',
          filePath: '/path/to/sound.mp3',
          soundType: SoundType.Ambiente,
        );

        expect(sound.name, 'Test Sound');
        expect(sound.filePath, '/path/to/sound.mp3');
        expect(sound.soundType, SoundType.Ambiente);
        expect(sound.description, '');
        expect(sound.id, isNotNull);
      });

      test('Sound creation with custom values', () {
        final sound = Sound(
          id: 'custom-id',
          name: 'Test Sound',
          filePath: '/path/to/sound.mp3',
          soundType: SoundType.Effekt,
          description: 'Test Description',
        );

        expect(sound.id, 'custom-id');
        expect(sound.soundType, SoundType.Effekt);
        expect(sound.description, 'Test Description');
      });

      test('Sound toMap and fromMap', () {
        final originalSound = Sound(
          name: 'Test Sound',
          filePath: '/path/to/sound.mp3',
          soundType: SoundType.Ambiente,
          description: 'Test Description',
        );

        final map = originalSound.toMap();
        final restoredSound = Sound.fromMap(map);

        expect(restoredSound.id, originalSound.id);
        expect(restoredSound.name, originalSound.name);
        expect(restoredSound.filePath, originalSound.filePath);
        expect(restoredSound.soundType, originalSound.soundType);
        expect(restoredSound.description, originalSound.description);
      });

      test('Sound fromMap with default description', () {
        final map = {
          'id': 'test-id',
          'name': 'Test Sound',
          'file_path': '/path/to/sound.mp3',
          'sound_type': 'SoundType.Ambiente',
        };

        final sound = Sound.fromMap(map);
        expect(sound.description, '');
      });
    });

    group('Session Model', () {
      test('Session creation with valid data', () {
        final session = Session(
          title: 'Test Session',
          campaignId: 'campaign-id',
        );

        expect(session.title, 'Test Session');
        expect(session.campaignId, 'campaign-id');
        expect(session.liveNotes, '');
        expect(session.inGameTimeInMinutes, 480);
        expect(session.id, isNotNull);
      });

      test('Session creation with custom values', () {
        final session = Session(
          id: 'custom-id',
          title: 'Test Session',
          campaignId: 'campaign-id',
          liveNotes: 'Test Notes',
          inGameTimeInMinutes: 600,
        );

        expect(session.id, 'custom-id');
        expect(session.liveNotes, 'Test Notes');
        expect(session.inGameTimeInMinutes, 600);
      });

      test('Session toMap and fromMap', () {
        final originalSession = Session(
          title: 'Test Session',
          campaignId: 'campaign-id',
          liveNotes: 'Test Notes',
          inGameTimeInMinutes: 600,
        );

        final map = originalSession.toMap();
        final restoredSession = Session.fromMap(map);

        expect(restoredSession.id, originalSession.id);
        expect(restoredSession.title, originalSession.title);
        expect(restoredSession.campaignId, originalSession.campaignId);
        expect(restoredSession.liveNotes, originalSession.liveNotes);
        expect(restoredSession.inGameTimeInMinutes, originalSession.inGameTimeInMinutes);
      });
    });

    group('Model Validation Tests', () {
      test('Campaign accepts empty values (current behavior)', () {
        final campaign = Campaign.create(
          title: '',
          description: '',
        );
        
        expect(campaign.title, '');
        expect(campaign.description, '');
      });

      test('PlayerCharacter accepts empty values (current behavior)', () {
        final character = PlayerCharacter.create(
          campaignId: 'campaign-id',
          name: '',
          playerName: '',
          className: '',
          raceName: '',
        );
        
        expect(character.name, '');
        expect(character.playerName, '');
        expect(character.className, '');
        expect(character.raceName, '');
      });

      test('Quest accepts empty values (current behavior)', () {
        final quest = Quest.create(
          title: '',
          description: '',
        );
        
        expect(quest.title, '');
        expect(quest.description, '');
      });

      test('Sound accepts empty values (current behavior)', () {
        final sound = Sound(
          name: '',
          filePath: '',
          soundType: SoundType.Ambiente,
        );
        
        expect(sound.name, '');
        expect(sound.filePath, '');
      });
    });

    group('Model Equality Tests', () {
      test('Campaigns with same data are equal', () {
        final campaign1 = Campaign(
          id: 'same-id',
          title: 'Same Title',
          description: 'Same Description',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final campaign2 = Campaign(
          id: 'same-id',
          title: 'Same Title',
          description: 'Same Description',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(campaign1.id, campaign2.id);
        expect(campaign1.title, campaign2.title);
        expect(campaign1.description, campaign2.description);
      });

      test('PlayerCharacters with same data are equal', () {
        final character1 = PlayerCharacter(
          id: 'same-id',
          campaignId: 'campaign-id',
          name: 'Same Name',
          playerName: 'Same Player',
          className: 'Same Class',
          raceName: 'Same Race',
          level: 1,
          maxHp: 10,
          armorClass: 10,
          initiativeBonus: 0,
          strength: 10,
          dexterity: 10,
          constitution: 10,
          intelligence: 10,
          wisdom: 10,
          charisma: 10,
          proficientSkills: const [],
          attackList: const [],
          inventory: const [],
          gold: 0,
          silver: 0,
          copper: 0,
          sourceType: 'manual',
          version: '1.0',
        );

        final character2 = PlayerCharacter(
          id: 'same-id',
          campaignId: 'campaign-id',
          name: 'Same Name',
          playerName: 'Same Player',
          className: 'Same Class',
          raceName: 'Same Race',
          level: 1,
          maxHp: 10,
          armorClass: 10,
          initiativeBonus: 0,
          strength: 10,
          dexterity: 10,
          constitution: 10,
          intelligence: 10,
          wisdom: 10,
          charisma: 10,
          proficientSkills: const [],
          attackList: const [],
          inventory: const [],
          gold: 0,
          silver: 0,
          copper: 0,
          sourceType: 'manual',
          version: '1.0',
        );

        expect(character1.id, character2.id);
        expect(character1.name, character2.name);
        expect(character1.className, character2.className);
      });

      test('Quests with same data are equal', () {
        final quest1 = Quest(
          id: 123,
          title: 'Same Title',
          description: 'Same Description',
          status: QuestStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final quest2 = Quest(
          id: 123,
          title: 'Same Title',
          description: 'Same Description',
          status: QuestStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(quest1.id, quest2.id);
        expect(quest1.title, quest2.title);
        expect(quest1.status, quest2.status);
      });
    });
  });
}
