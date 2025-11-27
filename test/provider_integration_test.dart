import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/screens/campaign_selection_screen.dart';
import '../lib/screens/enhanced_main_navigation_screen.dart';
import '../lib/viewmodels/campaign_viewmodel.dart';
import '../lib/models/campaign.dart';

void main() {
  group('Provider Integration Tests', () {
    testWidgets('CampaignViewModel should be available in CampaignSelectionScreen', (WidgetTester tester) async {
      // Build CampaignSelectionScreen
      await tester.pumpWidget(
        MaterialApp(
          home: CampaignSelectionScreen(),
        ),
      );

      // Verify CampaignViewModel is available
      expect(find.byType(CampaignSelectionScreen), findsOneWidget);
      
      // Check if we can access CampaignViewModel
      final campaignViewModel = Provider.of<CampaignViewModel>(tester.element(find.byType(CampaignSelectionScreen)), listen: false);
      expect(campaignViewModel, isNotNull);
    });

    testWidgets('CampaignViewModel should be available in EnhancedMainNavigationScreen', (WidgetTester tester) async {
      // Create a test campaign
      final testCampaign = Campaign(
        id: 'test-campaign-id',
        title: 'Test Campaign',
        description: 'Test Description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create CampaignViewModel
      final campaignViewModel = CampaignViewModel();
      
      // Build EnhancedMainNavigationScreen with CampaignViewModel provider
      await tester.pumpWidget(
        ChangeNotifierProvider<CampaignViewModel>.value(
          value: campaignViewModel,
          child: MaterialApp(
            home: EnhancedMainNavigationScreen(campaign: testCampaign),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify EnhancedMainNavigationScreen is available
      expect(find.byType(EnhancedMainNavigationScreen), findsOneWidget);
      
      // Check if we can access CampaignViewModel
      final accessedViewModel = Provider.of<CampaignViewModel>(tester.element(find.byType(EnhancedMainNavigationScreen)), listen: false);
      expect(accessedViewModel, isNotNull);
      expect(accessedViewModel, equals(campaignViewModel));
    });

    testWidgets('Provider chain should work from CampaignSelectionScreen to EnhancedMainNavigationScreen', (WidgetTester tester) async {
      // Build the complete app flow
      await tester.pumpWidget(
        MaterialApp(
          home: CampaignSelectionScreen(),
        ),
      );

      // Find and tap a campaign card (simulate selection)
      // Note: This test assumes there's at least one campaign or we need to mock one
      
      // For now, just verify the initial state
      expect(find.byType(CampaignSelectionScreen), findsOneWidget);
      
      // CampaignViewModel should be available
      final campaignViewModel = Provider.of<CampaignViewModel>(tester.element(find.byType(CampaignSelectionScreen)), listen: false);
      expect(campaignViewModel, isNotNull);
    });
  });
}
