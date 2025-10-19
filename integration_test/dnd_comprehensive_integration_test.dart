import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../lib/database/database_helper.dart';
import '../lib/models/campaign.dart';
import '../lib/models/creature.dart';
import '../lib/models/player_character.dart';
import '../lib/models/official_monster.dart';
import '../lib/models/official_spell.dart';
import '../lib/game_data/dnd_data_importer.dart';
import '../lib/screens/campaign_dashboard_screen.dart';
import '../lib/screens/official_monsters_screen.dart';
import '../lib/screens/edit_creature_screen.dart';
import '../lib/screens/encounter_setup_screen.dart';
import '../lib/screens/initiative_tracker_screen.dart';
import '../lib/widgets/campaign_dnd_data_tab.dart';

void main() {
  group('D&D Comprehensive Integration Tests', () {
    late DatabaseHelper dbHelper;
    late DndDataImporter importer;

    setUpAll(() async {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      dbHelper = DatabaseHelper.instance;
      importer = DndDataImporter();
      // Datenbank für Tests zurücksetzen
      await dbHelper.database;
      
      // Vorhandene Testdaten bereinigen
      await dbHelper.clearOfficialData('official_monsters');
      await dbHelper.clearOfficialData('official_spells');
      
      // Alle Kampagnen und zugehörige Daten löschen
      final campaigns = await dbHelper.getAllCampaigns();
      for (final campaign in campaigns) {
        if (campaign.id.startsWith('test_') || campaign.id.startsWith('dnd_')) {
          await dbHelper.deleteCampaignAndAssociatedData(campaign.id);
        }
      }
    });

    tearDownAll(() async {
      // Aufräumen
      await dbHelper.clearOfficialData('official_monsters');
      await dbHelper.clearOfficialData('official_spells');
    });

    testWidgets('Complete D&D Integration Flow', (WidgetTester tester) async {
      // 1. Demo-Daten importieren
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final monsterCount = await importer.importDemoMonsters();
      final spellCount = await importer.importDemoSpells();
      
      expect(monsterCount, greaterThan(0), reason: 'Demo-Monster sollten importiert werden');
      expect(spellCount, greaterThan(0), reason: 'Demo-Zauber sollten importiert werden');

      // 2. Kampagne mit D&D-Daten erstellen
      final campaign = Campaign(
        id: 'test_campaign',
        title: 'Test D&D Kampagne',
        description: 'Eine Testkampagne für D&D-Integration',
        availableMonsters: ['goblin', 'orc'],
        availableSpells: ['fireball', 'magic-missile'],
        availableItems: ['longsword'],
        availableNpcs: ['villager'],
      );

      await dbHelper.insertCampaign(campaign);

      // 3. Kampagne aus Datenbank laden und D&D-Daten überprüfen
      final loadedCampaigns = await dbHelper.getAllCampaigns();
      final loadedCampaign = loadedCampaigns.firstWhere((c) => c.id == 'test_campaign');
      
      expect(loadedCampaign.availableMonsters, contains('goblin'));
      expect(loadedCampaign.availableMonsters, contains('orc'));
      expect(loadedCampaign.availableSpells, contains('fireball'));
      expect(loadedCampaign.availableSpells, contains('magic-missile'));

      // 4. Offizielle Monster laden und überprüfen
      final monsters = await dbHelper.getAllOfficialMonsters();
      expect(monsters.length, greaterThan(0));
      
      final monster = OfficialMonster.fromMap(monsters.first);
      expect(monster.name, isNotNull);
      expect(monster.hitPoints, greaterThan(0));
      expect(monster.strength, greaterThan(0));

      // 5. Kreatur aus offiziellem Monster erstellen
      final creature = Creature.fromOfficialMonster(
        officialMonsterId: monster.id,
        name: monster.name,
        maxHp: monster.hitPoints,
        armorClass: int.tryParse(monster.armorClass) ?? 10,
        speed: monster.speed,
        strength: monster.strength,
        dexterity: monster.dexterity,
        constitution: monster.constitution,
        intelligence: monster.intelligence,
        wisdom: monster.wisdom,
        charisma: monster.charisma,
        size: monster.size,
        type: monster.type,
        subtype: monster.subtype,
        alignment: monster.alignment,
        challengeRating: monster.challengeRating.round(),
        specialAbilities: monster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n'),
        legendaryActions: monster.legendaryActions?.map((a) => '${a.name}: ${a.description}').join('\n'),
        description: monster.description,
        attacks: monster.actions.map((a) => '${a.name}: ${a.description}').join('\n'),
      );

      await dbHelper.insertCreature(creature);

      // 6. Kreatur aus Datenbank laden und D&D-Attribute überprüfen
      final loadedCreatures = await dbHelper.getAllCreatures();
      final loadedCreature = loadedCreatures.firstWhere((c) => c.id == creature.id);
      
      expect(loadedCreature.name, equals(monster.name));
      expect(loadedCreature.strength, equals(monster.strength));
      expect(loadedCreature.dexterity, equals(monster.dexterity));
      expect(loadedCreature.constitution, equals(monster.constitution));
      expect(loadedCreature.intelligence, equals(monster.intelligence));
      expect(loadedCreature.wisdom, equals(monster.wisdom));
      expect(loadedCreature.charisma, equals(monster.charisma));
      expect(loadedCreature.size, equals(monster.size));
      expect(loadedCreature.type, equals(monster.type));

      // 7. Spieler-Charakter mit D&D-Attributen erstellen
      final pc = PlayerCharacter(
        id: 'test_pc',
        campaignId: 'test_campaign',
        name: 'Testheld',
        playerName: 'Spieler 1',
        className: 'Krieger',
        raceName: 'Mensch',
        level: 3,
        maxHp: 30,
        armorClass: 16,
        initiativeBonus: 2,
        strength: 16,
        dexterity: 14,
        constitution: 15,
        intelligence: 10,
        wisdom: 12,
        charisma: 8,
        proficientSkills: ['Athletik', 'Einschüchtern'],
      );

      await dbHelper.insertPlayerCharacter(pc);

      // 8. Spieler-Charakter laden und D&D-Attribute überprüfen
      final loadedPcs = await dbHelper.getPlayerCharactersForCampaign('test_campaign');
      final loadedPc = loadedPcs.firstWhere((p) => p.id == 'test_pc');
      
      expect(loadedPc.strength, equals(16));
      expect(loadedPc.dexterity, equals(14));
      expect(loadedPc.constitution, equals(15));
      expect(loadedPc.intelligence, equals(10));
      expect(loadedPc.wisdom, equals(12));
      expect(loadedPc.charisma, equals(8));
      expect(loadedPc.className, equals('Krieger'));
      expect(loadedPc.raceName, equals('Mensch'));

      // 9. UI-Tests: Kampagnen-Dashboard mit D&D-Tab
      await tester.pumpWidget(MaterialApp(
        home: CampaignDashboardScreen(campaign: loadedCampaign),
      ));

      // Warten bis das Widget aufgebaut ist
      await tester.pumpAndSettle();

      // Überprüfen, ob der D&D-Tab vorhanden ist
      expect(find.text('D&D-Daten'), findsOneWidget);
      
      // Zum D&D-Tab wechseln
      await tester.tap(find.text('D&D-Daten'));
      await tester.pumpAndSettle();

      // Überprüfen, ob der D&D-Tab-Inhalt geladen wurde
      expect(find.byType(CampaignDndDataTab), findsOneWidget);
      expect(find.text('Monster'), findsOneWidget);
      expect(find.text('Zauber'), findsOneWidget);
      expect(find.text('Gegenstände'), findsOneWidget);

      // 10. UI-Tests: Offizielle Monster-Screen
      await tester.pumpWidget(MaterialApp(
        home: const OfficialMonstersScreen(),
      ));

      await tester.pumpAndSettle();

      // Überprüfen, ob der Monster-Screen geladen wurde
      expect(find.text('Offizielle Monster'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Suchfeld

      // 11. UI-Tests: Monster-Bearbeitung mit D&D-Import
      await tester.pumpWidget(MaterialApp(
        home: EditCreatureScreen(),
      ));

      await tester.pumpAndSettle();

      // Überprüfen, ob der Import-Button vorhanden ist
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.text('Aus offiziellem Monster importieren'), findsNothing); // Tooltip, nicht sichtbar

      // 12. Testen der Kampfvorbereitung mit D&D-Kreaturen
      await tester.pumpWidget(MaterialApp(
        home: EncounterSetupScreen(campaign: loadedCampaign),
      ));

      await tester.pumpAndSettle();

      // Überprüfen, ob der Encounter-Setup-Screen geladen wurde
      expect(find.text('Kampf zusammenstellen'), findsOneWidget);
      expect(find.text('Verfügbar'), findsOneWidget);
      expect(find.text('Im Kampf'), findsOneWidget);

      // 13. Testen des Initiativ-Trackers mit D&D-Daten
      final combatCreatures = [
        loadedCreature,
        Creature(
          id: loadedPc.id,
          name: loadedPc.name,
          maxHp: loadedPc.maxHp,
          currentHp: loadedPc.maxHp,
          armorClass: loadedPc.armorClass,
          speed: "30ft",
          attacks: "",
          initiativeBonus: loadedPc.initiativeBonus,
          isPlayer: true,
          strength: loadedPc.strength,
          dexterity: loadedPc.dexterity,
          constitution: loadedPc.constitution,
          intelligence: loadedPc.intelligence,
          wisdom: loadedPc.wisdom,
          charisma: loadedPc.charisma,
        )
      ];
      
      await tester.pumpWidget(MaterialApp(
        home: InitiativeTrackerScreen(creatures: combatCreatures),
      ));

      await tester.pumpAndSettle();

      // Überprüfen, ob der Initiativ-Tracker geladen wurde
      expect(find.text('Kampf-Tracker'), findsOneWidget);
      expect(find.text('Runde: 1'), findsOneWidget);
      expect(find.text('Zug beenden'), findsOneWidget);

      // Überprüfen, ob der Initiativ-Tracker die Kreaturen anzeigt
      expect(find.text(loadedCreature.name), findsOneWidget);
      expect(find.text(loadedPc.name), findsOneWidget);
      
      // Überprüfen, ob HP-Werte angezeigt werden
      expect(find.textContaining('HP'), findsAtLeastNWidgets(1));

      // 14. Performance-Test: Große Datenmengen verarbeiten
      final stopwatch = Stopwatch()..start();
      
      // Viele Monster erstellen
      for (int i = 0; i < 100; i++) {
        final testCreature = Creature.fromOfficialMonster(
          officialMonsterId: 'stress_$i',
          name: 'Stress Test Monster $i',
          maxHp: 50 + i,
          armorClass: 12 + (i % 10),
          speed: '30ft',
          strength: 10 + (i % 10),
          dexterity: 10 + (i % 10),
          constitution: 10 + (i % 10),
          intelligence: 10 + (i % 10),
          wisdom: 10 + (i % 10),
          charisma: 10 + (i % 10),
          attacks: 'Claw: +${i % 5} to hit',
        );
        await dbHelper.insertCreature(testCreature);
      }
      
      stopwatch.stop();
      print('100 Kreaturen in ${stopwatch.elapsedMilliseconds}ms erstellt');
      
      // Performance sollte akzeptabel sein (< 15 Sekunden für Testumgebung)
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));

      // 15. Datenbank-Abfrage-Performance testen
      stopwatch.reset();
      stopwatch.start();
      
      final allCreatures = await dbHelper.getAllCreatures();
      
      stopwatch.stop();
      print('${allCreatures.length} Kreaturen in ${stopwatch.elapsedMilliseconds}ms geladen');
      
      // Abfrage sollte schnell sein (< 3 Sekunden für Testumgebung)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(allCreatures.length, greaterThanOrEqualTo(100));

      // 16. Speicherbereinigung testen
      await dbHelper.deleteCreature(creature.id);
      await dbHelper.deletePlayerCharacter('test_pc');
      await dbHelper.deleteCampaignAndAssociatedData('test_campaign');

      // Überprüfen, ob die Daten gelöscht wurden
      final finalCreatures = await dbHelper.getAllCreatures();
      expect(finalCreatures.where((c) => c.id == creature.id), isEmpty);

      final finalPcs = await dbHelper.getPlayerCharactersForCampaign('test_campaign');
      expect(finalPcs.where((p) => p.id == 'test_pc'), isEmpty);

      final finalCampaigns = await dbHelper.getAllCampaigns();
      expect(finalCampaigns.where((c) => c.id == 'test_campaign'), isEmpty);

      print('D&D Comprehensive Integration Test erfolgreich abgeschlossen!');
    });

    testWidgets('D&D Data Import and Search', (WidgetTester tester) async {
      // Demo-Daten importieren
      await importer.importDemoMonsters();
      
      // Suchfunktionalität testen
      final monsters = await dbHelper.getAllOfficialMonsters();
      expect(monsters.length, greaterThan(0));

      // Suche nach spezifischen Monstern
      final goblin = monsters.firstWhere(
        (m) => m['name']?.toString().toLowerCase().contains('goblin') ?? false,
        orElse: () => monsters.first,
      );

      expect(goblin['name'], isNotNull);

      // Filter-Funktionen testen
      final filteredByType = await dbHelper.getAllOfficialMonsters(
        type: goblin['type']?.toString(),
      );

      expect(filteredByType.length, greaterThan(0));
      expect(filteredByType.first['type'], equals(goblin['type']));

      // Paginierung testen
      final page1 = await dbHelper.getAllOfficialMonsters(page: 0, limit: 10);
      final page2 = await dbHelper.getAllOfficialMonsters(page: 1, limit: 10);

      expect(page1.length, lessThanOrEqualTo(10));
      expect(page2.length, lessThanOrEqualTo(10));

      print('D&D Data Import and Search Test erfolgreich abgeschlossen!');
    });

    testWidgets('D&D Campaign Integration', (WidgetTester tester) async {
      // Kampagne mit umfassenden D&D-Daten erstellen
      final campaign = Campaign(
        id: 'dnd_test_campaign',
        title: 'D&D Integration Test',
        description: 'Umfassende D&D-Integration',
        availableMonsters: ['goblin', 'orc', 'dragon', 'lich'],
        availableSpells: ['fireball', 'magic-missile', 'heal', 'teleport'],
        availableItems: ['longsword', 'shield', 'potion'],
        availableNpcs: ['villager', 'merchant', 'guard'],
      );

      await dbHelper.insertCampaign(campaign);

      // Kampagne aktualisieren mit zusätzlichen D&D-Daten
      final updatedCampaign = campaign.copyWith(
        availableMonsters: [...campaign.availableMonsters, 'troll'],
        availableSpells: [...campaign.availableSpells, 'lightning-bolt'],
      );

      await dbHelper.updateCampaign(updatedCampaign);

      // Überprüfen der Aktualisierung
      final loadedCampaigns = await dbHelper.getAllCampaigns();
      final loadedCampaign = loadedCampaigns.firstWhere((c) => c.id == 'dnd_test_campaign');

      expect(loadedCampaign.availableMonsters, contains('troll'));
      expect(loadedCampaign.availableSpells, contains('lightning-bolt'));
      expect(loadedCampaign.availableMonsters.length, equals(5));
      expect(loadedCampaign.availableSpells.length, equals(5));

      // UI-Integration testen
      await tester.pumpWidget(MaterialApp(
        home: CampaignDashboardScreen(campaign: loadedCampaign),
      ));

      await tester.pumpAndSettle();

      // D&D-Tab testen
      await tester.tap(find.text('D&D-Daten'));
      await tester.pumpAndSettle();

      // Überprüfen, ob die D&D-Daten in der UI angezeigt werden
      expect(find.text('Monster'), findsOneWidget);
      
      // Aufräumen
      await dbHelper.deleteCampaignAndAssociatedData('dnd_test_campaign');

      print('D&D Campaign Integration Test erfolgreich abgeschlossen!');
    });
  });
}
