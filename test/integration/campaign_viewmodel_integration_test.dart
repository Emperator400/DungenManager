// Integration Test für CampaignViewModel
// Testet das Laden von Campaigns ohne Endlosschleife

import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/viewmodels/campaign_viewmodel.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/database/repositories/campaign_model_repository.dart';
import 'package:dungen_manager/database/core/database_connection.dart';
import '../test_helpers/test_setup.dart';
import '../test_helpers/mock_data_factory.dart' as mock;

void main() {
  group('CampaignViewModel Integration Tests', () {
    late CampaignViewModel viewModel;
    late CampaignModelRepository campaignRepo;
    late DatabaseConnection dbConnection;

    setUp(() async {
      // Setup Test Database
      await setUpTestDatabase();
      
      // Get database connection
      dbConnection = DatabaseConnection.instance;
      campaignRepo = CampaignModelRepository(dbConnection);
      
      // Create ViewModel with dependencies
      viewModel = CampaignViewModel(
        campaignRepo: campaignRepo,
        characterRepo: null,
        sessionService: null,
      );
    });
    
    tearDown(() async {
      // Cleanup
      await tearDownTestDatabase();
    });
    
    group('Initialization', () {
      test('should initialize without infinite loop', () async {
        // Act & Assert
        // Wenn dieser Test durchläuft ohne Timeout, gibt es keine Endlosschleife
        // Warte auf den async _initializeCampaigns() Aufruf im Konstruktor
        await Future.delayed(const Duration(milliseconds: 500));
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        expect(viewModel.campaigns, isEmpty); // Sollte leer sein, da keine Daten
      });
      
      test('should load campaigns successfully from empty database', () async {
        // Arrange
        await viewModel.loadCampaigns();
        
        // Act & Assert
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        expect(viewModel.campaigns.length, 0); // Leere Datenbank
      });
    });
    
    group('Create Campaign', () {
      test('should create campaign and load without infinite loop', () async {
        // Arrange
        final campaign = Campaign.create(
          title: 'Test Campaign',
          description: 'A test campaign',
        );
        
        // Act
        await viewModel.createCampaign(
          title: campaign.title,
          description: campaign.description,
        );
        
        // Assert
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        expect(viewModel.campaigns.length, 1);
        expect(viewModel.campaigns.first.title, 'Test Campaign');
      });
      
      test('should create multiple campaigns and load all', () async {
        // Arrange
        for (int i = 1; i <= 5; i++) {
          await viewModel.createCampaign(
            title: 'Campaign $i',
            description: 'Description $i',
          );
        }
        
        // Act
        await viewModel.loadCampaigns();
        
        // Assert
        expect(viewModel.campaigns.length, 5);
        for (int i = 1; i <= 5; i++) {
          expect(
            viewModel.campaigns.any((c) => c.title == 'Campaign $i'),
            true,
          );
        }
      });
    });
    
    group('Load Campaigns', () {
      test('should load campaigns after creating multiple', () async {
        // Arrange
        final campaigns = mock.MockCampaignFactory.createList(3);
        for (final campaign in campaigns) {
          await campaignRepo.create(campaign);
        }
        
        // Act
        await viewModel.loadCampaigns();
        
        // Assert
        expect(viewModel.campaigns.length, 3);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
      });
      
      test('should handle empty database gracefully', () async {
        // Act
        await viewModel.loadCampaigns();
        
        // Assert
        expect(viewModel.campaigns, isEmpty);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
      });
    });
    
    group('Error Handling', () {
      test('should handle invalid campaign creation', () async {
        // Act
        await viewModel.createCampaign(
          title: '', // Invalid - empty title
          description: 'Test',
        );
        
        // Assert - Sollte nicht crashen
        expect(viewModel.isLoading, false);
      });
      
      test('should handle repository errors gracefully', () async {
        // Act - Versuche mit null repository zu laden
        final viewModelWithoutRepo = CampaignViewModel(
          campaignRepo: null,
          characterRepo: null,
          sessionService: null,
        );
        await viewModelWithoutRepo.loadCampaigns();
        
        // Assert
        expect(viewModelWithoutRepo.error, isNotNull);
        expect(viewModelWithoutRepo.error, contains('nicht verfügbar'));
      });
    });
    
    group('Multiple Load Operations', () {
      test('should handle multiple loadCampaigns calls without infinite loop', () async {
        // Arrange
        final campaigns = mock.MockCampaignFactory.createList(3);
        for (final campaign in campaigns) {
          await campaignRepo.create(campaign);
        }
        
        // Act - Mehrere Load-Aufrufe
        await viewModel.loadCampaigns();
        await viewModel.loadCampaigns();
        await viewModel.loadCampaigns();
        
        // Assert
        expect(viewModel.campaigns.length, 3);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
      });
      
      test('should handle refresh without infinite loop', () async {
        // Arrange
        await viewModel.createCampaign(
          title: 'Test',
          description: 'Test',
        );
        
        // Act
        viewModel.refresh();
        await Future.delayed(const Duration(milliseconds: 100)); // Warte auf async operation
        
        // Assert
        expect(viewModel.isLoading, false);
        expect(viewModel.campaigns.length, 1);
      });
    });
  });
}