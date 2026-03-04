// Unit Test für Campaign Model
// Demonstriert Best Practices für Unit Tests in DungenManager

import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/campaign.dart';
import '../../test_helpers/mock_data_factory.dart' as mock;

void main() {
  group('Campaign Model Tests', () {
    group('Creation', () {
      test('should create valid campaign with factory', () {
        // Arrange
        final campaign = mock.MockCampaignFactory.create(
          title: 'Test Campaign',
          description: 'Test Description',
        );
        
        // Act & Assert
        expect(campaign.title, 'Test Campaign');
        expect(campaign.description, 'Test Description');
        expect(campaign.id, isNotNull);
        expect(campaign.status, CampaignStatus.planning);
        expect(campaign.type, CampaignType.homebrew);
      });
      
      test('should be invalid with empty title', () {
        // Arrange
        final campaign = mock.MockCampaignFactory.create(title: '');
        
        // Act & Assert
        expect(campaign.hasValidTitle, false);
        expect(campaign.isValid, false);
      });
      
      test('should be invalid with empty description', () {
        // Arrange
        final campaign = mock.MockCampaignFactory.create(description: '');
        
        // Act & Assert
        expect(campaign.hasValidDescription, false);
        expect(campaign.isValid, false);
      });
    });
    
    group('Status Management', () {
      test('should change status correctly', () {
        // Arrange
        final campaign = mock.MockCampaignFactory.create();
        
        // Act
        final updated = campaign.copyWith(status: CampaignStatus.active);
        
        // Assert
        expect(updated.status, CampaignStatus.active);
        expect(updated.id, campaign.id);
      });
      
      test('should return correct status description', () {
        // Arrange
        final campaign = mock.MockCampaignFactory.create();
        
        // Act & Assert
        expect(campaign.statusDescription, 'Planung');
        
        final active = campaign.copyWith(status: CampaignStatus.active);
        expect(active.statusDescription, 'Aktiv');
      });
    });
    
    group('Type Management', () {
      test('should return correct type description', () {
        // Arrange
        final campaign = mock.MockCampaignFactory.create();
        
        // Act & Assert
        expect(campaign.typeDescription, 'Homebrew');
        
        final module = campaign.copyWith(type: CampaignType.module);
        expect(module.typeDescription, 'Module');
      });
    });
    
    group('Equality', () {
      test('should consider campaigns with same ID as equal', () {
        // Arrange
        final campaign1 = mock.MockCampaignFactory.create(id: 'same-id');
        final campaign2 = mock.MockCampaignFactory.create(id: 'same-id');
        
        // Act & Assert
        expect(campaign1 == campaign2, true);
      });
      
      test('should consider campaigns with different IDs as not equal', () {
        // Arrange
        final campaign1 = mock.MockCampaignFactory.create(id: 'id-1');
        final campaign2 = mock.MockCampaignFactory.create(id: 'id-2');
        
        // Act & Assert
        expect(campaign1 == campaign2, false);
      });
    });
    
    group('Serialization', () {
      test('should convert to map and back correctly', () {
        // Arrange
        final original = mock.MockCampaignFactory.create(
          title: 'Serialization Test',
          description: 'Testing serialization',
        );
        
        // Act
        final map = original.toMap();
        final restored = Campaign.fromMap(map);
        
        // Assert
        expect(restored.id, original.id);
        expect(restored.title, original.title);
        expect(restored.description, original.description);
        expect(restored.status, original.status);
        expect(restored.type, original.type);
      });
    });
  });
}