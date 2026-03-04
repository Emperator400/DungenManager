// Widget Test für Campaign-related Widgets
// Demonstriert Best Practices für Widget Tests in DungenManager

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/campaign.dart';
import '../../test_helpers/mock_data_factory.dart' as mock;

void main() {
  group('Campaign Widget Tests', () {
    testWidgets('should display campaign information', (tester) async {
      // Arrange
      final campaign = mock.MockCampaignFactory.create(
        title: 'Test Campaign',
        description: 'Test Description',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampaignDisplayWidget(campaign: campaign),
          ),
        ),
      );
      
      // Act
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Test Campaign'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });
    
    testWidgets('should show status badge', (tester) async {
      // Arrange
      final activeCampaign = mock.MockCampaignFactory.createActive();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampaignStatusWidget(campaign: activeCampaign),
          ),
        ),
      );
      
      // Act
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Aktiv'), findsOneWidget);
    });
    
    testWidgets('should handle empty state', (tester) async {
      // Arrange
      final emptyCampaigns = <Campaign>[];
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampaignListWidget(campaigns: emptyCampaigns),
          ),
        ),
      );
      
      // Act
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('No campaigns yet'), findsOneWidget);
    });
  });
}

// Dummy Widgets für Testzwecke
class CampaignDisplayWidget extends StatelessWidget {
  final Campaign campaign;
  
  const CampaignDisplayWidget({super.key, required this.campaign});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(campaign.title),
        Text(campaign.description),
      ],
    );
  }
}

class CampaignStatusWidget extends StatelessWidget {
  final Campaign campaign;
  
  const CampaignStatusWidget({super.key, required this.campaign});
  
  @override
  Widget build(BuildContext context) {
    return Text(campaign.statusDescription);
  }
}

class CampaignListWidget extends StatelessWidget {
  final List<Campaign> campaigns;
  
  const CampaignListWidget({super.key, required this.campaigns});
  
  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) {
      return const Text('No campaigns yet');
    }
    return ListView.builder(
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(campaigns[index].title));
      },
    );
  }
}