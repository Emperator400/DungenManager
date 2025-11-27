import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/viewmodels/campaign_viewmodel.dart';
import '../lib/screens/campaign_selection_screen.dart';
import '../lib/screens/enhanced_main_navigation_screen.dart';

void main() {
  group('Provider Simple Tests', () {
    testWidgets('CampaignViewModel should be available in CampaignSelectionScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CampaignViewModel>(
          create: (_) => CampaignViewModel(),
          child: MaterialApp(
            home: CampaignSelectionScreen(),
          ),
        ),
      );

      expect(find.byType(CampaignSelectionScreen), findsOneWidget);
      
      // Check if CampaignViewModel is available without throwing
      expect(() {
        final campaignViewModel = Provider.of<CampaignViewModel>(tester.element(find.byType(CampaignSelectionScreen)), listen: false);
        expect(campaignViewModel, isNotNull);
      }, returnsNormally);
    });

    testWidgets('EnhancedMainNavigationScreen should build without provider errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EnhancedMainNavigationScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(EnhancedMainNavigationScreen), findsOneWidget);
    });

    testWidgets('EnhancedMainNavigationScreen with campaign should have CampaignViewModel', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<CampaignViewModel>(
          create: (_) => CampaignViewModel(),
          child: MaterialApp(
            home: EnhancedMainNavigationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(EnhancedMainNavigationScreen), findsOneWidget);
      
      // Should not throw when accessing CampaignViewModel
      expect(() {
        final campaignViewModel = Provider.of<CampaignViewModel>(tester.element(find.byType(EnhancedMainNavigationScreen)), listen: false);
        expect(campaignViewModel, isNotNull);
      }, returnsNormally);
    });
  });
}
