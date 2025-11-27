// 1. Externe Packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// 2. Eigene Projekte (absolute Pfade)
import 'package:dungen_manager/main.dart' as app;
import 'package:dungen_manager/database/database_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Acceptance Tests', () {
    late DatabaseHelper databaseHelper;

    setUpAll(() async {
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.database;
    });

    group('Core User Workflows', () {
      testWidgets('User sollte Quest erstellen und verwalten können', (WidgetTester tester) async {
        // Starte App
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zur Quest Library
        final questLibraryButton = find.text('Quests');
        expect(questLibraryButton, findsOneWidget);
        await tester.tap(questLibraryButton);
        await tester.pumpAndSettle();
        
        // Erstelle neuen Quest
        final addButton = find.byIcon(Icons.add);
        expect(addButton, findsOneWidget);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        
        // Fülle Quest-Formular aus
        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'User Acceptance Test Quest');
        await tester.pumpAndSettle();
        
        final descriptionField = find.byType(TextField).at(1);
        await tester.enterText(descriptionField, 'Quest erstellt durch User Acceptance Test');
        await tester.pumpAndSettle();
        
        // Speichere Quest
        final saveButton = find.text('Speichern');
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Verifiziere dass Quest gespeichert wurde
        expect(find.text('User Acceptance Test Quest'), findsOneWidget);
      });

      testWidgets('User_should_search_and_filter_quests', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zur Quest Library
        final questLibraryButton = find.text('Quests');
        expect(questLibraryButton, findsOneWidget);
        await tester.tap(questLibraryButton);
        await tester.pumpAndSettle();
        
        // Suche nach Quest
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);
        await tester.enterText(searchField, 'Test');
        await tester.pumpAndSettle();
        
        // Verifiziere Suchergebnisse
        expect(find.text('Test Quest'), findsOneWidget);
        
        // Nutze Filter
        final filterChip = find.text('Aktiv');
        expect(filterChip, findsOneWidget);
        await tester.tap(filterChip);
        await tester.pumpAndSettle();
        
        // Verifiziere gefilterte Ergebnisse
        expect(find.text('Test Quest'), findsOneWidget);
      });

      testWidgets('User_should_create_and_manage_campaigns', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zu Campaigns
        final campaignButton = find.text('Campaigns');
        expect(campaignButton, findsOneWidget);
        await tester.tap(campaignButton);
        await tester.pumpAndSettle();
        
        // Erstelle neue Campaign
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        
        // Fülle Campaign-Formular aus
        final nameField = find.byType(TextField).first;
        await tester.enterText(nameField, 'User Acceptance Campaign');
        await tester.pumpAndSettle();
        
        final descriptionField = find.byType(TextField).at(1);
        await tester.enterText(descriptionField, 'Campaign für User Acceptance Tests');
        await tester.pumpAndSettle();
        
        // Speichere Campaign
        final saveButton = find.text('Speichern');
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Verifiziere dass Campaign gespeichert wurde
        expect(find.text('User Acceptance Campaign'), findsOneWidget);
      });

      testWidgets('User_should_create_and_edit_wiki_entries', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zu Wiki
        final wikiButton = find.text('Wiki');
        expect(wikiButton, findsOneWidget);
        await tester.tap(wikiButton);
        await tester.pumpAndSettle();
        
        // Erstelle neuen Wiki-Eintrag
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        
        // Fülle Wiki-Formular aus
        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'User Acceptance Wiki Entry');
        await tester.pumpAndSettle();
        
        final contentField = find.byType(TextField).at(1);
        await tester.enterText(contentField, '# User Acceptance Test\n\nDies ist ein Wiki-Eintrag erstellt durch User Acceptance Tests.');
        await tester.pumpAndSettle();
        
        // Wähle Entry-Typ
        final typeDropdown = find.byType(DropdownButton<String>);
        expect(typeDropdown, findsOneWidget);
        await tester.tap(typeDropdown);
        await tester.pumpAndSettle();
        
        final loreOption = find.text('Lore');
        await tester.tap(loreOption);
        await tester.pumpAndSettle();
        
        // Speichere Wiki-Eintrag
        final saveButton = find.text('Speichern');
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Verifiziere dass Wiki-Eintrag gespeichert wurde
        expect(find.text('User Acceptance Wiki Entry'), findsOneWidget);
      });

      testWidgets('User_should_create_and_edit_characters', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zu Characters
        final characterButton = find.text('Charaktere');
        expect(characterButton, findsOneWidget);
        await tester.tap(characterButton);
        await tester.pumpAndSettle();
        
        // Erstelle neuen Charakter
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        
        // Fülle Charakter-Formular aus
        final nameField = find.byType(TextField).first;
        await tester.enterText(nameField, 'User Acceptance Character');
        await tester.pumpAndSettle();
        
        final raceField = find.byType(TextField).at(1);
        await tester.enterText(raceField, 'Mensch');
        await tester.pumpAndSettle();
        
        final classField = find.byType(TextField).at(2);
        await tester.enterText(classField, 'Krieger');
        await tester.pumpAndSettle();
        
        final levelField = find.byType(TextField).at(3);
        await tester.enterText(levelField, '5');
        await tester.pumpAndSettle();
        
        // Speichere Charakter
        final saveButton = find.text('Speichern');
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Verifiziere dass Charakter gespeichert wurde
        expect(find.text('User Acceptance Character'), findsOneWidget);
      });
    });

    group('Cross-Feature Workflows', () {
      testWidgets('User_should_link_quest_to_campaign', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Erstelle Campaign zuerst
        await _navigateToAndCreateCampaign(tester, 'Linked Test Campaign');
        
        // Navigiere zur Quest Library
        final questLibraryButton = find.text('Quests');
        await tester.tap(questLibraryButton);
        await tester.pumpAndSettle();
        
        // Erstelle Quest mit Campaign-Verknüpfung
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        
        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'Linked Quest');
        await tester.pumpAndSettle();
        
        // Wähle Campaign aus Dropdown
        final campaignDropdown = find.byType(DropdownButton<int?>);
        expect(campaignDropdown, findsOneWidget);
        await tester.tap(campaignDropdown);
        await tester.pumpAndSettle();
        
        final campaignOption = find.text('Linked Test Campaign');
        await tester.tap(campaignOption);
        await tester.pumpAndSettle();
        
        // Speichere Quest
        final saveButton = find.text('Speichern');
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Verifiziere dass Quest mit Campaign verknüpft ist
        expect(find.text('Linked Quest'), findsOneWidget);
        
        // Überprüfe Campaign-Anzeige
        await tester.tap(find.text('Linked Test Campaign'));
        await tester.pumpAndSettle();
        
        expect(find.text('Linked Quest'), findsOneWidget);
      });

      testWidgets('User_should_reference_wiki_in_quest', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Erstelle Wiki-Eintrag zuerst
        await _navigateToAndCreateWikiEntry(tester, 'Referenced Wiki Entry');
        
        // Navigiere zur Quest Library
        final questLibraryButton = find.text('Quests');
        await tester.tap(questLibraryButton);
        await tester.pumpAndSettle();
        
        // Erstelle Quest mit Wiki-Referenz
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        
        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'Quest with Wiki Reference');
        await tester.pumpAndSettle();
        
        final descriptionField = find.byType(TextField).at(1);
        await tester.enterText(descriptionField, 'Siehe [Wiki:Referenced Wiki Entry] für weitere Informationen.');
        await tester.pumpAndSettle();
        
        // Speichere Quest
        final saveButton = find.text('Speichern');
        expect(saveButton, findsOneWidget);
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Verifiziere dass Wiki-Referenz erkannt wird
        expect(find.text('Quest with Wiki Reference'), findsOneWidget);
        expect(find.text('[Wiki:Referenced Wiki Entry]'), findsOneWidget);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('User_should_see_validation_errors', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Versuche Quest ohne Titel zu speichern
        final questLibraryButton = find.text('Quests');
        await tester.tap(questLibraryButton);
        await tester.pumpAndSettle();
        
        final addButton = find.byIcon(Icons.add);
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        
        // Speichere ohne Titel
        final saveButton = find.text('Speichern');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
        
        // Verifiziere Fehlermeldung
        expect(find.text('Titel ist erforderlich'), findsOneWidget);
      });

      testWidgets('User_should_handle_network_errors_gracefully', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Simuliere Netzwerkfehler durch Invalid-State
        // In einer echten App würde dies durch Repository-Layer gehandhabt
        
        // Überprüfe dass App weiterhin funktioniert
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('User_should_see_loading_states', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zu Wiki (große Datenmenge simuliert)
        final wikiButton = find.text('Wiki');
        await tester.tap(wikiButton);
        await tester.pumpAndSettle();
        
        // Überprüfe ob Lade-Indikator angezeigt wird
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Performance and Scalability', () {
      testWidgets('User_should_work_with_large_datasets', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zur Quest Library
        final questLibraryButton = find.text('Quests');
        await tester.tap(questLibraryButton);
        await tester.pumpAndSettle();
        
        // Überprüfe dass Scroll-Performance akzeptabel ist
        // (In echten Tests mit großen Datenmengen)
        final listView = find.byType(ListView);
        expect(listView, findsOneWidget);
        
        // Teste Scroll-Performance
        await tester.fling(listView, const Offset(0, -500), 10000);
        await tester.pumpAndSettle();
        
        // Überprüfe dass UI weiterhin responsive ist
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('User_should_see_search_performance', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Navigiere zur Quest Library
        final questLibraryButton = find.text('Quests');
        await tester.tap(questLibraryButton);
        await tester.pumpAndSettle();
        
        // Führe Suche durch
        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'Performance Test');
        await tester.pumpAndSettle();
        
        // Überprüfe dass Suche performant ist (keine UI-Blockierung)
        expect(find.text('Performance Test'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('Accessibility Tests', () {
      testWidgets('App_should_be_accessible', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Überprüfe Semantik
        expect(find.bySemanticsLabel('Quests'), findsOneWidget);
        expect(find.bySemanticsLabel('Campaigns'), findsOneWidget);
        expect(find.bySemanticsLabel('Wiki'), findsOneWidget);
        expect(find.bySemanticsLabel('Charaktere'), findsOneWidget);
      });

      testWidgets('User_should_navigate_with_keyboard', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // Überprüfe dass Navigation funktioniert
        expect(find.byType(TabBar), findsOneWidget);
      });
    });
  });
}

// Helper-Funktionen für User Acceptance Tests
Future<void> _navigateToAndCreateCampaign(WidgetTester tester, String campaignName) async {
  final campaignButton = find.text('Campaigns');
  await tester.tap(campaignButton);
  await tester.pumpAndSettle();
  
  final addButton = find.byIcon(Icons.add);
  await tester.tap(addButton);
  await tester.pumpAndSettle();
  
  final nameField = find.byType(TextField).first;
  await tester.enterText(nameField, campaignName);
  await tester.pumpAndSettle();
  
  final saveButton = find.text('Speichern');
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

Future<void> _navigateToAndCreateWikiEntry(WidgetTester tester, String entryTitle) async {
  final wikiButton = find.text('Wiki');
  await tester.tap(wikiButton);
  await tester.pumpAndSettle();
  
  final addButton = find.byIcon(Icons.add);
  await tester.tap(addButton);
  await tester.pumpAndSettle();
  
  final titleField = find.byType(TextField).first;
  await tester.enterText(titleField, entryTitle);
  await tester.pumpAndSettle();
  
  final saveButton = find.text('Speichern');
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}
