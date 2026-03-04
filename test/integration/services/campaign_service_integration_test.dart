// Integration Test für Campaign Service
// Demonstriert Best Practices für Integration Tests in DungenManager

import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/services/campaign_service.dart';
import 'package:dungen_manager/models/campaign.dart';
import '../../test_helpers/test_setup.dart';
import '../../test_helpers/mock_data_factory.dart' as mock;

void main() {
  group('Campaign Service Integration Tests', () {
    late CampaignService campaignService;

    setUp(() async {
      await setUpTestDatabase();
      campaignService = CampaignService();
    });
    
    tearDown(() async {
      await tearDownTestDatabase();
    });
    
    group('Create Campaign', () {
      test('should create campaign successfully', () async {
        // Arrange
        final campaign = mock.MockCampaignFactory.create(
          title: 'New Campaign',
          description: 'A brand new campaign',
        );
        
        // Act
        final result = await campaignService.createCampaign(campaign);
        
        // Assert
        expect(result.isSuccess, true);
        expect(result.data?.title, 'New Campaign');
      });
      
      test('should handle empty title validation', () async {
        // Arrange
        final campaign = mock.MockCampaignFactory.create(title: '');
        
        // Act & Assert
        expect(campaign.isValid, false);
        expect(campaign.hasValidTitle, false);
      });
    });
    
    group('Campaign Serialization', () {
      test('should serialize and deserialize correctly', () async {
        // Arrange
        final original = mock.MockCampaignFactory.create(
          title: 'Serialization Test',
          description: 'Testing database serialization',
        );
        
        // Act
        final map = original.toMap();
        final restored = Campaign.fromMap(map);
        
        // Assert
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.status, original.status);
      });
    });
    
    group('Campaign List Operations', () {
      test('should create list of campaigns', () async {
        // Arrange
        final campaigns = mock.MockCampaignFactory.createList(5);
        
        // Act & Assert
        expect(campaigns.length, 5);
        expect(campaigns.every((c) => c.id.isNotEmpty), true);
      });
      
      test('should filter campaigns by status', () async {
        // Arrange
        final campaigns = [
          mock.MockCampaignFactory.createActive(),
          mock.MockCampaignFactory.createCompleted(),
          mock.MockCampaignFactory.create(),
        ];
        
        // Act
        final active = campaigns.where((c) => c.status == CampaignStatus.active);
        
        // Assert
        expect(active.length, 1);
        expect(active.first.status, CampaignStatus.active);
      });
    });
  });
}
