import 'package:flutter_test/flutter_test.dart';
import '../lib/database/repositories/campaign_repository.dart';
import '../lib/database/repositories/player_character_repository.dart';
import '../lib/database/repositories/quest_repository.dart';
import '../lib/models/campaign.dart';
import '../lib/models/player_character.dart';
import '../lib/models/quest.dart';

void main() {
  group('Database Migration Tests', () {
    late CampaignRepository campaignRepository;
    late PlayerCharacterRepository playerCharacterRepository;
    late QuestRepository questRepository;

    setUpAll(() async {
      // Initialize repositories
      campaignRepository = CampaignRepository();
      playerCharacterRepository = PlayerCharacterRepository();
      questRepository = QuestRepository();
    });

    test('CampaignRepository - Create and Read', () async {
      // Test Campaign creation
      final campaign = Campaign.create(
        name: 'Test Campaign',
        description: 'A test campaign for migration verification',
      );

      // Convert to entity and save
      final entity = campaignRepository.createEntityFromModel(campaign);
      await campaignRepository.create(entity);

      // Read back and verify
      final retrievedEntity = await campaignRepository.getById(campaign.id);
      expect(retrievedEntity, isNotNull);
      expect(retrievedEntity!.name, equals(campaign.title));

      final retrievedCampaign = retrievedEntity.toModel();
      expect(retrievedCampaign.title, equals(campaign.title));
      expect(retrievedCampaign.description, equals(campaign.description));

      // Cleanup
      await campaignRepository.delete(campaign.id);
    });

    test('PlayerCharacterRepository - Create and Read', () async {
      // Test PlayerCharacter creation
      final character = PlayerCharacter(
        id: 'test_character_${DateTime.now().millisecondsSinceEpoch}',
        campaignId: 'test_campaign',
        name: 'Test Character',
        playerName: 'Test Player',
        className: 'Fighter',
        raceName: 'Human',
        level: 5,
        maxHp: 50,
        armorClass: 16,
        sourceType: 'custom',
        version: '1.0',
      );

      // Convert to entity and save
      final entity = playerCharacterRepository.createEntityFromModel(character);
      await playerCharacterRepository.create(entity);

      // Read back and verify
      final retrievedEntity = await playerCharacterRepository.getById(character.id);
      expect(retrievedEntity, isNotNull);
      expect(retrievedEntity!.name, equals(character.name));

      final retrievedCharacter = retrievedEntity.toModel();
      expect(retrievedCharacter.name, equals(character.name));
      expect(retrievedCharacter.className, equals(character.className));
      expect(retrievedCharacter.level, equals(character.level));

      // Cleanup
      await playerCharacterRepository.delete(character.id);
    });

    test('QuestRepository - Create and Read', () async {
      // Test Quest creation
      final quest = Quest.create(
        title: 'Test Quest',
        description: 'A test quest for migration verification',
        questType: QuestType.side,
        difficulty: QuestDifficulty.medium,
        recommendedLevel: 5,
      );

      // Convert to entity and save
      final entity = questRepository.createEntityFromModel(quest);
      await questRepository.create(entity);

      // Read back and verify
      final retrievedEntity = await questRepository.getById(quest.id);
      expect(retrievedEntity, isNotNull);
      expect(retrievedEntity!.title, equals(quest.title));

      final retrievedQuest = retrievedEntity.toModel();
      expect(retrievedQuest.title, equals(quest.title));
      expect(retrievedQuest.description, equals(quest.description));
      expect(retrievedQuest.questType, equals(quest.questType));

      // Cleanup
      await questRepository.delete(quest.id);
    });

    test('Repository - getAll functionality', () async {
      // Create test data
      final campaign1 = Campaign.create(name: 'Campaign 1', description: 'Test 1');
      final campaign2 = Campaign.create(name: 'Campaign 2', description: 'Test 2');

      final entity1 = campaignRepository.createEntityFromModel(campaign1);
      final entity2 = campaignRepository.createEntityFromModel(campaign2);

      await campaignRepository.create(entity1);
      await campaignRepository.create(entity2);

      // Test getAll
      final allCampaigns = await campaignRepository.getAll();
      expect(allCampaigns.length, greaterThanOrEqualTo(2));

      // Verify our test campaigns are in the list
      final titles = allCampaigns.map((e) => e.name).toList();
      expect(titles, contains(campaign1.title));
      expect(titles, contains(campaign2.title));

      // Cleanup
      await campaignRepository.delete(campaign1.id);
      await campaignRepository.delete(campaign2.id);
    });

    test('Repository - Update functionality', () async {
      // Create initial campaign
      final campaign = Campaign.create(name: 'Original Name', description: 'Original Description');
      final entity = campaignRepository.createEntityFromModel(campaign);
      await campaignRepository.create(entity);

      // Update campaign
      final updatedCampaign = campaign.copyWith(
        title: 'Updated Name',
        description: 'Updated Description',
      );
      final updatedEntity = campaignRepository.createEntityFromModel(updatedCampaign);
      await campaignRepository.update(updatedEntity);

      // Verify update
      final retrievedEntity = await campaignRepository.getById(campaign.id);
      expect(retrievedEntity, isNotNull);
      expect(retrievedEntity!.name, equals('Updated Name'));
      expect(retrievedEntity.description, equals('Updated Description'));

      // Cleanup
      await campaignRepository.delete(campaign.id);
    });

    test('Repository - Delete functionality', () async {
      // Create campaign
      final campaign = Campaign.create(name: 'To Delete', description: 'Will be deleted');
      final entity = campaignRepository.createEntityFromModel(campaign);
      await campaignRepository.create(entity);

      // Verify it exists
      var retrievedEntity = await campaignRepository.getById(campaign.id);
      expect(retrievedEntity, isNotNull);

      // Delete it
      await campaignRepository.delete(campaign.id);

      // Verify it's gone
      retrievedEntity = await campaignRepository.getById(campaign.id);
      expect(retrievedEntity, isNull);
    });
  });
}
