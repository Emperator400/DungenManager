import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/database/core/database_connection.dart';
import '../lib/database/entities/campaign_entity.dart';
import '../lib/database/repositories/campaign_repository.dart';
import '../lib/database/migrations/database_migration.dart';

void main() {
  group('Database Architecture Integration Tests', () {
    late DatabaseConnection connection;
    late CampaignRepository repository;
    late DatabaseMigration migration;

    setUpAll(() {
      // Initialisiere FFI für Tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      connection = DatabaseConnection();
      repository = CampaignRepository(connection);
      migration = DatabaseMigration(connection);
      
      await migration.runMigrations();
    });

    tearDown(() async {
      await connection.close();
    });

    test('should create campaign successfully', () async {
      // Arrange
      final campaign = CampaignEntity.create(
        name: 'Test Campaign',
        description: 'A test campaign for integration testing',
        gameMaster: 'Test DM',
        tags: ['test', 'integration'],
      );

      // Act
      final createdCampaign = await repository.create(campaign);

      // Assert
      expect(createdCampaign.id, isNotEmpty);
      expect(createdCampaign.name, equals('Test Campaign'));
      expect(createdCampaign.description, equals('A test campaign for integration testing'));
      expect(createdCampaign.gameMaster, equals('Test DM'));
      expect(createdCampaign.tags, equals(['test', 'integration']));
      expect(createdCampaign.isActive, isTrue);
      expect(createdCampaign.isValid, isTrue);
    });

    test('should find campaign by ID', () async {
      // Arrange
      final campaign = CampaignEntity.create(
        name: 'Find Me Campaign',
        description: 'Campaign to test find by ID',
      );
      final createdCampaign = await repository.create(campaign);

      // Act
      final foundCampaign = await repository.findById(createdCampaign.id);

      // Assert
      expect(foundCampaign, isNotNull);
      expect(foundCampaign!.id, equals(createdCampaign.id));
      expect(foundCampaign.name, equals('Find Me Campaign'));
    });

    test('should find all campaigns', () async {
      // Arrange
      final campaigns = [
        CampaignEntity.create(name: 'Campaign 1', description: 'First campaign'),
        CampaignEntity.create(name: 'Campaign 2', description: 'Second campaign'),
        CampaignEntity.create(name: 'Campaign 3', description: 'Third campaign'),
      ];

      for (final campaign in campaigns) {
        await repository.create(campaign);
      }

      // Act
      final allCampaigns = await repository.findAll();

      // Assert
      expect(allCampaigns.length, equals(3));
      expect(allCampaigns.every((c) => c.isValid), isTrue);
    });

    test('should update campaign successfully', () async {
      // Arrange
      final campaign = CampaignEntity.create(
        name: 'Original Name',
        description: 'Original description',
      );
      final createdCampaign = await repository.create(campaign);

      // Act
      final updatedCampaign = createdCampaign.copyWith(
        name: 'Updated Name',
        description: 'Updated description',
      );
      final result = await repository.update(updatedCampaign);

      // Assert
      expect(result.name, equals('Updated Name'));
      expect(result.description, equals('Updated description'));
      expect(result.updatedAt.isAfter(createdCampaign.updatedAt), isTrue);
    });

    test('should delete campaign successfully', () async {
      // Arrange
      final campaign = CampaignEntity.create(
        name: 'To Delete',
        description: 'This campaign will be deleted',
      );
      final createdCampaign = await repository.create(campaign);

      // Act
      await repository.delete(createdCampaign.id);
      final foundCampaign = await repository.findById(createdCampaign.id);

      // Assert
      expect(foundCampaign, isNull);
    });

    test('should search campaigns by term', () async {
      // Arrange
      final campaigns = [
        CampaignEntity.create(name: 'Dragon Adventure', description: 'Slay dragons'),
        CampaignEntity.create(name: 'City Mystery', description: 'Solve urban crimes'),
        CampaignEntity.create(name: 'Dragon Heist', description: 'Steal dragon treasure'),
      ];

      for (final campaign in campaigns) {
        await repository.create(campaign);
      }

      // Act
      final dragonCampaigns = await repository.searchCampaigns(searchTerm: 'dragon');

      // Assert
      expect(dragonCampaigns.length, equals(2));
      expect(dragonCampaigns.every((c) => 
        c.name.contains('Dragon') || c.description.contains('dragon')
      ), isTrue);
    });

    test('should filter campaigns by tags', () async {
      // Arrange
      final campaigns = [
        CampaignEntity.create(
          name: 'Fantasy Quest',
          description: 'A fantasy adventure',
          tags: ['fantasy', 'magic'],
        ),
        CampaignEntity.create(
          name: 'Horror Story',
          description: 'A scary adventure',
          tags: ['horror', 'supernatural'],
        ),
        CampaignEntity.create(
          name: 'Fantasy Horror',
          description: 'Mix of genres',
          tags: ['fantasy', 'horror'],
        ),
      ];

      for (final campaign in campaigns) {
        await repository.create(campaign);
      }

      // Act
      final fantasyCampaigns = await repository.findByTags(['fantasy']);

      // Assert
      expect(fantasyCampaigns.length, equals(2));
      expect(fantasyCampaigns.every((c) => c.tags.contains('fantasy')), isTrue);
    });

    test('should get campaign statistics', () async {
      // Arrange
      final campaigns = [
        CampaignEntity.create(
          name: 'Active Campaign 1',
          description: 'First active campaign',
          gameMaster: 'DM Alpha',
        ),
        CampaignEntity.create(
          name: 'Active Campaign 2',
          description: 'Second active campaign',
          gameMaster: 'DM Beta',
        ),
        CampaignEntity.create(
          name: 'Inactive Campaign',
          description: 'Inactive campaign',
          gameMaster: 'DM Alpha',
        ),
      ];

      for (final campaign in campaigns) {
        await repository.create(campaign);
      }

      // Deactivate one campaign
      await repository.deactivateCampaigns([campaigns.last.id]);

      // Act
      final stats = await repository.getCampaignStatistics();

      // Assert
      expect(stats['totalCampaigns'], equals(3));
      expect(stats['activeCampaigns'], equals(2));
      expect(stats['inactiveCampaigns'], equals(1));
      expect(stats['activationRate'], equals(66.7)); // 2/3 * 100
      expect(stats['topGameMasters'], isA<List>());
    });

    test('should validate campaign entity', () async {
      // Test valid campaign
      final validCampaign = CampaignEntity.create(
        name: 'Valid Campaign',
        description: 'A valid campaign with proper data',
        gameMaster: 'Valid DM',
      );
      expect(validCampaign.isValid, isTrue);
      expect(validCampaign.validationErrors, isEmpty);

      // Test invalid campaign (empty name)
      final invalidCampaign = CampaignEntity(
        id: 'test',
        name: '',
        description: 'Invalid campaign',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(invalidCampaign.isValid, isFalse);
      expect(invalidCampaign.validationErrors, contains('Campaign name cannot be empty'));
    });

    test('should handle campaign tags correctly', () async {
      // Arrange
      final campaign = CampaignEntity.create(
        name: 'Tag Test Campaign',
        description: 'Testing tag functionality',
        tags: ['initial'],
      );
      final createdCampaign = await repository.create(campaign);

      // Act - Add tags
      final withNewTags = createdCampaign.addTag('newTag');
      final updatedCampaign = await repository.update(withNewTags);

      // Assert
      expect(updatedCampaign.tags, contains('newTag'));
      expect(updatedCampaign.tags, contains('initial'));
      expect(updatedCampaign.tags.length, equals(2));

      // Act - Remove tag
      final withoutTag = updatedCampaign.removeTag('initial');
      final finalCampaign = await repository.update(withoutTag);

      // Assert
      expect(finalCampaign.tags, isNot(contains('initial')));
      expect(finalCampaign.tags, contains('newTag'));
    });

    test('should handle batch operations', () async {
      // Arrange
      final campaigns = [
        CampaignEntity.create(name: 'Batch 1', description: 'First batch'),
        CampaignEntity.create(name: 'Batch 2', description: 'Second batch'),
        CampaignEntity.create(name: 'Batch 3', description: 'Third batch'),
      ];

      // Act
      final createdCampaigns = await repository.createAll(campaigns);

      // Assert
      expect(createdCampaigns.length, equals(3));
      expect(createdCampaigns.every((c) => c.id.isNotEmpty), isTrue);

      // Act - Update all
      final updatedCampaigns = createdCampaigns.map((c) => 
        c.copyWith(description: 'Updated ${c.name}')
      ).toList();
      await repository.updateAll(updatedCampaigns);

      // Assert
      for (final campaign in updatedCampaigns) {
        final found = await repository.findById(campaign.id);
        expect(found!.description, startsWith('Updated'));
      }
    });

    test('should check database integrity', () async {
      // Act
      await migration.seedSampleData();
      final integrity = await migration.checkIntegrity();

      // Assert
      expect(integrity['campaigns']['exists'], isTrue);
      expect(integrity['campaigns']['status'], equals('ok'));
      expect(integrity['campaigns']['count'], greaterThan(0));
      expect(integrity['indexes']['count'], greaterThan(0));
    });

    test('should handle database migration', () async {
      // Act
      final status = await migration.getMigrationStatus();

      // Assert
      expect(status['version'], equals(1));
      expect(status['status'], equals('ok'));
      expect(status['lastRun'], isA<String>());
      expect(status['integrity'], isA<Map>());
    });
  });

  group('Campaign Entity Edge Cases', () {
    test('should handle maximum length validation', () {
      final tooLongName = 'a' * 101; // Exceeds 100 character limit
      final campaign = CampaignEntity(
        id: 'test',
        name: tooLongName,
        description: 'Valid description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(campaign.isValid, isFalse);
      expect(campaign.validationErrors, contains('Campaign name too long (max 100 characters)'));
    });

    test('should handle date range validation', () {
      final startDate = DateTime(2023, 1, 1);
      final endDate = DateTime(2022, 1, 1); // Before start date

      final campaign = CampaignEntity(
        id: 'test',
        name: 'Invalid Date Range',
        description: 'Campaign with invalid date range',
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(campaign.isValid, isFalse);
      expect(campaign.validationErrors, contains('Start date cannot be after end date'));
    });

    test('should handle tag limits', () {
      final tooManyTags = List.generate(11, (i) => 'tag$i'); // Exceeds 10 tag limit

      final campaign = CampaignEntity(
        id: 'test',
        name: 'Too Many Tags',
        description: 'Campaign with too many tags',
        tags: tooManyTags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(campaign.isValid, isFalse);
      expect(campaign.validationErrors, contains('Too many tags (max 10)'));
    });
  });
}
