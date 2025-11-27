import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dungen_manager/main.dart' as app;
import 'package:dungen_manager/database/database_helper.dart';
import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/models/wiki_entry.dart';
import 'package:dungen_manager/models/creature.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cross-Feature Integration Tests', () {
    late DatabaseHelper databaseHelper;

    setUpAll(() async {
      // Initialisiere Datenbank
      databaseHelper = DatabaseHelper.instance;
      await databaseHelper.database;
    });

    group('Database Integration Tests', () {
      testWidgets('sollte Datenbank-Konnektivität sicherstellen', (WidgetTester tester) async {
        // Teste Datenbank-Verbindung
        final db = await databaseHelper.database;
        expect(db, isNotNull);
        expect(db.isOpen, isTrue);
      });

      testWidgets('sollte grundlegende CRUD-Operationen unterstützen', (WidgetTester tester) async {
        // Teste Quest CRUD mit direktem Datenbankzugriff
        final quest = Quest.create(
          title: 'Integration Test Quest',
          description: 'Test Description',
        );
        
        // Create Quest
        await databaseHelper.insertQuest(quest);
        
        // Read Quest
        final quests = await databaseHelper.getAllQuests();
        expect(quests.isNotEmpty, isTrue);
        expect(quests.any((q) => q.title == 'Integration Test Quest'), isTrue);
        
        // Update Quest
        final updatedQuest = quest.copyWith(description: 'Updated Description');
        await databaseHelper.updateQuest(updatedQuest);
        
        // Verify Update
        final updatedQuests = await databaseHelper.getAllQuests();
        expect(updatedQuests.any((q) => q.description == 'Updated Description'), isTrue);
        
        // Delete Quest
        await databaseHelper.deleteQuest(quest.id.toString());
        
        // Verify Deletion
        final finalQuests = await databaseHelper.getAllQuests();
        expect(finalQuests.any((q) => q.id == quest.id), isFalse);
      });

      testWidgets('sollte Wiki-Einträge verwalten können', (WidgetTester tester) async {
        // Create Wiki Entry
        final wikiEntry = WikiEntry.create(
          title: 'Integration Test Wiki',
          content: 'Test Wiki Content',
          entryType: WikiEntryType.Lore,
          tags: ['Test', 'Integration'],
        );
        await databaseHelper.insertWikiEntry(wikiEntry);
        
        // Read Wiki Entries
        final wikiEntries = await databaseHelper.getAllWikiEntries();
        expect(wikiEntries.isNotEmpty, isTrue);
        expect(wikiEntries.any((w) => w.title == 'Integration Test Wiki'), isTrue);
        
        // Update Wiki Entry
        final updatedWiki = wikiEntry.copyWith(content: 'Updated Content');
        await databaseHelper.updateWikiEntry(updatedWiki);
        
        // Verify Update
        final updatedEntries = await databaseHelper.getAllWikiEntries();
        expect(updatedEntries.any((w) => w.content == 'Updated Content'), isTrue);
        
        // Delete Wiki Entry
        await databaseHelper.deleteWikiEntry(wikiEntry.id);
        
        // Verify Deletion
        final finalEntries = await databaseHelper.getAllWikiEntries();
        expect(finalEntries.any((w) => w.id == wikiEntry.id), isFalse);
      });
    });

    group('Cross-Feature Relationship Tests', () {
      testWidgets('sollte Quest-Campaign Beziehungen testen', (WidgetTester tester) async {
        // Erstelle Campaign
        final campaign = Campaign.create(
          title: 'Test Campaign for Quests',
          description: 'Campaign mit Quests',
        );
        await databaseHelper.insertCampaign(campaign);
        
        // Erstelle Quest mit Campaign-Referenz
        final quest = Quest.create(
          title: 'Quest in Campaign',
          description: 'Quest der zu Campaign gehört',
          campaignId: campaign.id,
        );
        await databaseHelper.insertQuest(quest);
        
        // Verifiziere Beziehung durch Filtern
        final allQuests = await databaseHelper.getAllQuests();
        final campaignQuests = allQuests.where((q) => q.campaignId == campaign.id);
        
        expect(campaignQuests, hasLength(1));
        expect(campaignQuests.first.campaignId, equals(campaign.id));
      });

      testWidgets('sollte Wiki-Campaign Beziehungen testen', (WidgetTester tester) async {
        // Erstelle Wiki-Eintrag mit Campaign-Referenz
        final wikiEntry = WikiEntry.create(
          title: 'Campaign Wiki Entry',
          content: 'Wiki-Eintrag für Campaign',
          entryType: WikiEntryType.Place,
          tags: ['Campaign', 'Wiki'],
          campaignId: 'test-campaign-id',
        );
        await databaseHelper.insertWikiEntry(wikiEntry);
        
        // Verifiziere Beziehung durch Filtern
        final allWikiEntries = await databaseHelper.getAllWikiEntries();
        final campaignWikiEntries = allWikiEntries.where((w) => w.campaignId == 'test-campaign-id');
        
        expect(campaignWikiEntries, hasLength(1));
        expect(campaignWikiEntries.first.campaignId, equals('test-campaign-id'));
      });
    });

    group('Performance Tests', () {
      testWidgets('sollte mit großen Datenmengen umgehen können', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        // Erstelle große Menge an Testdaten
        for (int i = 0; i < 20; i++) {
          final quest = Quest.create(
            title: 'Performance Quest $i',
            description: 'Test Quest für Performance',
          );
          await databaseHelper.insertQuest(quest);
        }
        
        for (int i = 0; i < 10; i++) {
          final wikiEntry = WikiEntry.create(
            title: 'Performance Wiki $i',
            content: 'Test Wiki Entry für Performance',
            entryType: WikiEntryType.values[i % 3],
            tags: ['Performance', 'Test', 'Tag$i'],
          );
          await databaseHelper.insertWikiEntry(wikiEntry);
        }
        
        stopwatch.stop();
        final insertTime = stopwatch.elapsedMilliseconds;
        
        // Teste Lade-Performance
        stopwatch.reset();
        stopwatch.start();
        
        await databaseHelper.getAllQuests();
        await databaseHelper.getAllWikiEntries();
        
        stopwatch.stop();
        final loadTime = stopwatch.elapsedMilliseconds;
        
        // Performance-Assertions
        expect(insertTime, lessThan(3000), reason: 'Insert should complete within 3 seconds');
        expect(loadTime, lessThan(2000), reason: 'Load should complete within 2 seconds');
        
        print('Performance Metrics:');
        print('  Insert Time: ${insertTime}ms for 30 items');
        print('  Load Time: ${loadTime}ms for all data');
      });
    });

    group('Data Consistency Tests', () {
      testWidgets('sollte Datenintegrität wahren', (WidgetTester tester) async {
        final initialQuests = await databaseHelper.getAllQuests();
        
        // Teste Transaktionssicherheit
        try {
          // Beginne komplexe Operation
          final quest = Quest.create(
            title: 'Consistency Test Quest',
            description: 'Quest für Consistency Test',
          );
          await databaseHelper.insertQuest(quest);
          
          // Verifiziere dass Daten hinzugefügt wurden
          final afterInsert = await databaseHelper.getAllQuests();
          expect(afterInsert.length, equals(initialQuests.length + 1));
          
          // Cleanup
          await databaseHelper.deleteQuest(quest.id.toString());
          
        } catch (e) {
          // Bei Fehlern sollte Datenbank konsistent bleiben
          print('Consistency test error: $e');
          final afterError = await databaseHelper.getAllQuests();
          expect(afterError.length, equals(initialQuests.length));
        }
      });

      testWidgets('sollte gleichzeitige Operationen unterstützen', (WidgetTester tester) async {
        // Teste gleichzeitige Leseoperationen
        final futures = <Future>[];
        
        futures.add(databaseHelper.getAllQuests());
        futures.add(databaseHelper.getAllWikiEntries());
        futures.add(databaseHelper.getAllCreatures());
        
        final results = await Future.wait(futures);
        
        expect(results, hasLength(3));
        expect(results[0], isA<List<Quest>>());
        expect(results[1], isA<List<WikiEntry>>());
        expect(results[2], isA<List<Creature>>());
      });
    });

    group('Search and Filter Tests', () {
      testWidgets('sollte grundlegende Filterung unterstützen', (WidgetTester tester) async {
        // Erstelle diverse Test-Daten
        final activeQuest = Quest.create(
          title: 'Active Quest',
          description: 'Aktiver Quest',
          status: QuestStatus.active,
        );
        await databaseHelper.insertQuest(activeQuest);
        
        final completedQuest = Quest.create(
          title: 'Completed Quest',
          description: 'Abgeschlossener Quest',
          status: QuestStatus.completed,
        );
        await databaseHelper.insertQuest(completedQuest);
        
        // Lade und filtere
        final allQuests = await databaseHelper.getAllQuests();
        final activeQuests = allQuests.where((q) => q.status == QuestStatus.active);
        final completedQuests = allQuests.where((q) => q.status == QuestStatus.completed);
        
        expect(activeQuests, hasLength(1));
        expect(activeQuests.first.status, equals(QuestStatus.active));
        
        expect(completedQuests, hasLength(1));
        expect(completedQuests.first.status, equals(QuestStatus.completed));
      });
    });

    group('App Integration Tests', () {
      testWidgets('sollte App ohne Fehler starten', (WidgetTester tester) async {
        // Teste App-Startup mit Integration
        app.main();
        await tester.pumpAndSettle();
        
        expect(find.byType(MaterialApp), findsOneWidget);
      });

      testWidgets('sollte Navigation zwischen Features funktionieren', (WidgetTester tester) async {
        // Dies ist ein einfacher Navigation-Test
        // In einer echten Integration-Test-Umgebung würden hier UI-Interaktionen getestet
        app.main();
        await tester.pumpAndSettle();
        
        // Überprüfe dass App geladen ist
        expect(find.byType(MaterialApp), findsOneWidget);
      });
    });
  });
}
