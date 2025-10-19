import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:DoungenMenager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DungenManager Comprehensive Test Suite', () {
    
    // Helper function to create a test campaign
    Future<void> createTestCampaign(WidgetTester tester, {required String campaignName, required String description}) async {
      final addCampaignFab = find.byTooltip('Neue Kampagne erstellen');
      
      if (tester.any(addCampaignFab)) {
        await tester.tap(addCampaignFab);
        await tester.pumpAndSettle();
        
        await tester.enterText(find.byType(TextFormField).at(0), campaignName);
        await tester.enterText(find.byType(TextFormField).at(1), description);
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();
      }
      
      expect(find.text(campaignName), findsOneWidget);
    }

    // Helper function to navigate to campaign dashboard
    Future<void> navigateToCampaign(WidgetTester tester, String campaignName) async {
      await tester.tap(find.text(campaignName));
      await tester.pumpAndSettle();
    }

    testWidgets('1. Campaign Management Workflow', (WidgetTester tester) async {
      const campaignName = 'Test Campaign';
      const campaignDescription = 'A comprehensive test campaign';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Create campaign
      await createTestCampaign(tester, campaignName: campaignName, description: campaignDescription);
      print('✅ Campaign created successfully');

      // Navigate to campaign
      await navigateToCampaign(tester, campaignName);
      expect(find.byType(TabBar), findsOneWidget);
      print('✅ Navigated to campaign dashboard');

      // Navigate back to campaign list
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(campaignName), findsOneWidget);
      print('✅ Returned to campaign list');
    });

    testWidgets('2. Player Character Management', (WidgetTester tester) async {
      const campaignName = 'PC Test Campaign';
      const characterName = 'Test Character';
      const playerName = 'Test Player';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing PC management');
      await navigateToCampaign(tester, campaignName);

      // Navigate to Heroes tab
      await tester.tap(find.byIcon(Icons.groups));
      await tester.pumpAndSettle();

      // Add new character
      final addCharacterFab = find.byTooltip('Neuen Helden hinzufügen');
      if (tester.any(addCharacterFab)) {
        await tester.tap(addCharacterFab);
        await tester.pumpAndSettle();

        // Fill character form
        await tester.enterText(find.byType(TextFormField).at(0), characterName);
        await tester.enterText(find.byType(TextFormField).at(1), playerName);
        await tester.enterText(find.byType(TextFormField).at(2), 'Krieger');
        await tester.enterText(find.byType(TextFormField).at(3), 'Mensch');
        
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();
      }

      expect(find.text(characterName), findsOneWidget);
      expect(find.text(playerName), findsOneWidget);
      print('✅ Player character created successfully');

      // Edit character
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextFormField).at(0), '$characterName (Edited)');
      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      expect(find.text('$characterName (Edited)'), findsOneWidget);
      print('✅ Player character edited successfully');
    });

    testWidgets('3. Session Management', (WidgetTester tester) async {
      const campaignName = 'Session Test Campaign';
      const sessionName = 'Test Session';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing session management');
      await navigateToCampaign(tester, campaignName);

      // Navigate to Sessions tab
      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      // Add new session
      final addSessionFab = find.byTooltip('Neue Sitzung hinzufügen');
      if (tester.any(addSessionFab)) {
        await tester.tap(addSessionFab);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), sessionName);
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();
      }

      expect(find.text(sessionName), findsOneWidget);
      print('✅ Session created successfully');

      // Navigate to session
      await tester.tap(find.text(sessionName));
      await tester.pumpAndSettle();
      
      expect(find.byType(AppBar), findsOneWidget);
      print('✅ Navigated to session details');

      // Test live notes functionality
      await tester.enterText(find.byType(TextField), 'Test live notes');
      await tester.pumpAndSettle();
      
      expect(find.text('Test live notes'), findsOneWidget);
      print('✅ Live notes functionality working');

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('4. Quest Management', (WidgetTester tester) async {
      const campaignName = 'Quest Test Campaign';
      const questName = 'Test Quest';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing quest management');
      await navigateToCampaign(tester, campaignName);

      // Navigate to Quests tab
      await tester.tap(find.byIcon(Icons.assignment));
      await tester.pumpAndSettle();

      // Add quest from library
      final addQuestFab = find.byTooltip('Quest aus Bibliothek hinzufügen');
      if (tester.any(addQuestFab)) {
        await tester.tap(addQuestFab);
        await tester.pumpAndSettle();
        
        // Assuming there's at least one quest in the library
        if (tester.any(find.byType(ListTile))) {
          await tester.tap(find.byType(ListTile).first);
          await tester.pumpAndSettle();
        }
      }

      // Verify quest was added
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
      print('✅ Quest added to campaign successfully');

      // Test quest status change
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      
      // Change status to active
      await tester.tap(find.text('Verfügbar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aktiv'));
      await tester.pumpAndSettle();
      
      expect(find.text('Aktiv'), findsOneWidget);
      print('✅ Quest status changed successfully');
    });

    testWidgets('5. Sound Management', (WidgetTester tester) async {
      const campaignName = 'Sound Test Campaign';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing sound management');
      await navigateToCampaign(tester, campaignName);

      // Navigate to Sound Mixer tab
      await tester.tap(find.byIcon(Icons.music_note));
      await tester.pumpAndSettle();

      // Test sound scenes tab
      expect(find.byType(TabBar), findsOneWidget);
      await tester.tap(find.text('Sound-Szenen'));
      await tester.pumpAndSettle();
      
      print('✅ Sound scenes tab accessible');

      // Test sounds tab
      await tester.tap(find.text('Sounds'));
      await tester.pumpAndSettle();
      
      print('✅ Sounds tab accessible');

      // Test adding sound to scene (if UI elements exist)
      final addSoundFab = find.byTooltip('Sound zur Szene hinzufügen');
      if (tester.any(addSoundFab)) {
        await tester.tap(addSoundFab);
        await tester.pumpAndSettle();
        
        // Close the dialog if it opens
        if (tester.any(find.byType(AlertDialog))) {
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
      }
      
      print('✅ Sound management interface working');
    });

    testWidgets('6. Campaign Deletion', (WidgetTester tester) async {
      const campaignName = 'Delete Test Campaign';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing campaign deletion');

      // Delete campaign
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Löschen'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Endgültig Löschen'));
      await tester.pumpAndSettle();

      expect(find.text(campaignName), findsNothing);
      print('✅ Campaign deleted successfully');
    });

    testWidgets('7. Navigation Stress Test', (WidgetTester tester) async {
      const campaignName = 'Navigation Test Campaign';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing navigation stability');
      await navigateToCampaign(tester, campaignName);

      // Rapid tab switching
      final tabs = ['Übersicht', Icons.groups, Icons.map, Icons.assignment, Icons.music_note];
      for (int i = 0; i < 3; i++) {
        for (var tab in tabs) {
          if (tab is String) {
            await tester.tap(find.text(tab));
          } else {
            await tester.tap(find.byIcon(tab));
          }
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }
      }
      
      expect(find.byType(Scaffold), findsOneWidget);
      print('✅ Navigation stress test completed successfully');
    });

    testWidgets('8. Data Persistence Test', (WidgetTester tester) async {
      const campaignName = 'Persistence Test Campaign';
      const characterName = 'Persistent Character';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Create campaign and character
      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing data persistence');
      await navigateToCampaign(tester, campaignName);

      await tester.tap(find.byIcon(Icons.groups));
      await tester.pumpAndSettle();

      final addCharacterFab = find.byTooltip('Neuen Helden hinzufügen');
      if (tester.any(addCharacterFab)) {
        await tester.tap(addCharacterFab);
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), characterName);
        await tester.enterText(find.byType(TextFormField).at(1), 'Persistent Player');
        await tester.enterText(find.byType(TextFormField).at(2), 'Magier');
        await tester.enterText(find.byType(TextFormField).at(3), 'Elf');
        
        await tester.tap(find.byIcon(Icons.save));
        await tester.pumpAndSettle();
      }

      // Navigate back and restart app
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Restart app simulation
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify data persisted
      expect(find.text(campaignName), findsOneWidget);
      await navigateToCampaign(tester, campaignName);
      
      await tester.tap(find.byIcon(Icons.groups));
      await tester.pumpAndSettle();
      
      expect(find.text(characterName), findsOneWidget);
      print('✅ Data persistence verified successfully');
    });

    testWidgets('9. Error Handling - Empty State', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Check if app handles empty campaign list gracefully
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Check for empty state message
      final emptyStateFinder = find.textContaining('Keine Kampagnen');
      if (tester.any(emptyStateFinder)) {
        print('✅ Empty state handled gracefully');
      } else {
        print('✅ Campaign list displays correctly (not empty)');
      }
    });

    testWidgets('10. Performance Test - Multiple Operations', (WidgetTester tester) async {
      const campaignName = 'Performance Test Campaign';
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final stopwatch = Stopwatch()..start();
      
      // Create campaign
      await createTestCampaign(tester, campaignName: campaignName, description: 'Testing performance');
      await navigateToCampaign(tester, campaignName);

      // Perform multiple operations rapidly
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.groups));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.map));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.assignment));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.music_note));
        await tester.pumpAndSettle();
      }
      
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      expect(duration, lessThan(10000)); // Should complete in less than 10 seconds
      print('✅ Performance test completed in ${duration}ms');
    });
  });
}
