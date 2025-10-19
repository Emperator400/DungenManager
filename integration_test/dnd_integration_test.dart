// integration_test/dnd_integration_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:DoungenMenager/main.dart';
import 'package:DoungenMenager/database/database_helper.dart';
import 'package:DoungenMenager/game_data/dnd_data_importer.dart';
import 'package:DoungenMenager/models/official_monster.dart';
import 'package:DoungenMenager/models/official_spell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('D&D Daten Integration Test', () {
    late DatabaseHelper dbHelper;
    late DndDataImporter importer;

    setUpAll(() async {
      dbHelper = DatabaseHelper.instance;
      importer = DndDataImporter();
    });

    testWidgets('Vollständiger D&D Daten Import Test', (WidgetTester tester) async {
      // Starte die App
      await tester.pumpWidget(const DmApp());
      await tester.pumpAndSettle();

      // 1. Teste Datenbank-Verbindung
      final db = await dbHelper.database;
      expect(db, isNotNull);

      // 2. Teste Import-Funktionen mit Mock-Daten (ohne Netzwerk)
      print('Teste Datenimport-Funktionen...');

      // 3. Teste Monster-Modell
      final testMonsterData = {
        'id': 'test_goblin',
        'name': 'Test Goblin',
        'size': 'Small',
        'type': 'humanoid',
        'subtype': 'goblinoid',
        'alignment': 'neutral evil',
        'armor_class': '15 (leather armor)',
        'hit_points': 7,
        'hit_dice': '2d6',
        'speed': '30 ft.',
        'strength': 8,
        'dexterity': 14,
        'constitution': 10,
        'intelligence': 10,
        'wisdom': 8,
        'charisma': 8,
        'saving_throws': null,
        'skills': null,
        'damage_vulnerabilities': null,
        'damage_resistances': null,
        'damage_immunities': null,
        'condition_immunities': null,
        'senses': null,
        'languages': 'Common, Goblin',
        'challenge_rating': 0.25,
        'xp': 50,
        'special_abilities': null,
        'actions': null,
        'legendary_actions': null,
        'lair_actions': null,
        'description': null,
        'source': 'TEST',
        'page': 1,
        'is_custom': 0,
        'version': '1.0',
      };

      final monster = OfficialMonster.fromMap(testMonsterData);
      expect(monster.name, equals('Test Goblin'));
      expect(monster.challengeRating, equals(0.25));
      expect(monster.strength, equals(8));

      // 4. Teste Datenbank-CRUD für Monster
      await dbHelper.insertOfficialMonster(testMonsterData);
      final retrievedMonster = await dbHelper.getOfficialMonsterById('test_goblin');
      expect(retrievedMonster, isNotNull);
      expect(retrievedMonster!['name'], equals('Test Goblin'));

      // 5. Teste Paginierte Abfragen
      final monsters = await dbHelper.getAllOfficialMonsters(
        page: 0,
        limit: 10,
        search: 'goblin',
      );
      expect(monsters.length, greaterThanOrEqualTo(1));

      // 6. Teste Filter-Funktionen
      final filteredMonsters = await dbHelper.getAllOfficialMonsters(
        page: 0,
        limit: 10,
        minCr: 0.1,
        maxCr: 1.0,
      );
      expect(filteredMonsters.length, greaterThanOrEqualTo(1));

      // 7. Teste Spells-Modell
      final testSpellData = {
        'id': 'test_firebolt',
        'name': 'Test Fire Bolt',
        'level': 0,
        'school': 'Evocation',
        'ritual': 0,
        'casting_time': '1 action',
        'range': '120 feet',
        'duration': 'Instantaneous',
        'components': 'V, S',
        'materials': null,
        'description': 'You hurl a mote of fire at a creature or object.',
        'higher_levels': null,
        'classes': 'Wizard, Sorcerer',
        'source': 'TEST',
        'page': 1,
        'is_custom': 0,
        'version': '1.0',
      };

      final spell = OfficialSpell.fromMap(testSpellData);
      expect(spell.name, equals('Test Fire Bolt'));
      expect(spell.level, equals(0));
      expect(spell.school, equals('Evocation'));

      // 8. Teste Datenbank-CRUD für Spells
      await dbHelper.insertOfficialSpell(testSpellData);
      final retrievedSpell = await dbHelper.getOfficialSpellById('test_firebolt');
      expect(retrievedSpell, isNotNull);
      expect(retrievedSpell!['name'], equals('Test Fire Bolt'));

      // 9. Teste Datenbereinigung
      await dbHelper.clearOfficialData('official_monsters');
      await dbHelper.clearOfficialData('official_spells');
      
      final monsterCount = await dbHelper.getOfficialDataCount('official_monsters');
      final spellCount = await dbHelper.getOfficialDataCount('official_spells');
      expect(monsterCount, equals(0));
      expect(spellCount, equals(0));

      print('D&D Daten Integration Test erfolgreich abgeschlossen!');
    });

    testWidgets('UI Navigation und Monster-Screen Test', (WidgetTester tester) async {
      // Starte die App
      await tester.pumpWidget(const DmApp());
      await tester.pumpAndSettle();

      // 1. Prüfe, ob die Hauptseite geladen wurde
      expect(find.text('Meine Kampagnen'), findsOneWidget);

      // 2. Navigiere zur Monster-Screen
      final monsterButton = find.byTooltip('Offizielle D&D Monster');
      expect(monsterButton, findsOneWidget);
      await tester.tap(monsterButton);
      await tester.pumpAndSettle();

      // 3. Prüfe, ob die Monster-Screen geladen wurde
      expect(find.text('Offizielle Monster'), findsOneWidget);

      // 4. Teste Suchfunktion
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // 5. Teste Filter-Button
      final filterButton = find.byTooltip('Filter');
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // 6. Schließe Filter-Dialog
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // 7. Kehre zur Hauptseite zurück
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Meine Kampagnen'), findsOneWidget);
      print('UI Navigation Test erfolgreich abgeschlossen!');
    });

    testWidgets('Performance-Test für große Datenmengen', (WidgetTester tester) async {
      // Starte die App
      await tester.pumpWidget(const DmApp());
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 1. Erzeuge viele Test-Monster
      for (int i = 0; i < 100; i++) {
        final monsterData = {
          'id': 'test_monster_$i',
          'name': 'Test Monster $i',
          'size': 'Medium',
          'type': 'humanoid',
          'alignment': 'neutral',
          'armor_class': '12',
          'hit_points': 10,
          'hit_dice': '2d8',
          'speed': '30 ft.',
          'strength': 10,
          'dexterity': 10,
          'constitution': 10,
          'intelligence': 10,
          'wisdom': 10,
          'charisma': 10,
          'challenge_rating': 0.5,
          'xp': 100,
          'source': 'TEST',
          'page': 1,
          'is_custom': 0,
          'version': '1.0',
        };
        await dbHelper.insertOfficialMonster(monsterData);
      }

      // 2. Teste Abfrage-Performance
      final queryTime = Stopwatch()..start();
      final monsters = await dbHelper.getAllOfficialMonsters(
        page: 0,
        limit: 50,
        search: 'test',
      );
      queryTime.stop();

      expect(monsters.length, greaterThanOrEqualTo(50));
      expect(queryTime.elapsedMilliseconds, lessThan(1000)); // Sollte unter 1s dauern

      // 3. Teste Filter-Performance
      final filterTime = Stopwatch()..start();
      final filteredMonsters = await dbHelper.getAllOfficialMonsters(
        page: 0,
        limit: 50,
        minCr: 0.1,
        maxCr: 1.0,
      );
      filterTime.stop();

      expect(filteredMonsters.length, greaterThanOrEqualTo(50));
      expect(filterTime.elapsedMilliseconds, lessThan(1000));

      // 4. Teste Paginierung
      final page1 = await dbHelper.getAllOfficialMonsters(page: 0, limit: 20);
      final page2 = await dbHelper.getAllOfficialMonsters(page: 1, limit: 20);
      
      expect(page1.length, equals(20));
      expect(page2.length, equals(20));
      expect(page1.first['id'], isNot(equals(page2.first['id'])));

      stopwatch.stop();
      print('Performance-Test abgeschlossen in ${stopwatch.elapsedMilliseconds}ms');
      print('Abfrage-Zeit: ${queryTime.elapsedMilliseconds}ms');
      print('Filter-Zeit: ${filterTime.elapsedMilliseconds}ms');

      // Aufräumen
      await dbHelper.clearOfficialData('official_monsters');
    });

    testWidgets('Daten-Import mit Fehlerbehandlung', (WidgetTester tester) async {
      // Starte die App
      await tester.pumpWidget(const DmApp());
      await tester.pumpAndSettle();

      // 1. Teste mit ungültigen Daten
      final invalidMonsterData = {
        'id': 'invalid_monster',
        'name': null, // Ungültiger Wert
        'size': 'Medium',
        'type': 'humanoid',
        'challenge_rating': 0.5,
        'xp': 100,
        'source': 'TEST',
        'page': 1,
        'is_custom': 0,
        'version': '1.0',
      };

      // Sollte einen Fehler werfen
      expect(
        () async => await dbHelper.insertOfficialMonster(invalidMonsterData),
        throwsA(anything),
      );

      // 2. Teste Daten-Validierung im Modell
      final incompleteData = {
        'id': 'incomplete_monster',
        'name': 'Incomplete',
        // Fehlende Pflichtfelder
      };

      expect(
        () => OfficialMonster.fromMap(incompleteData),
        throwsA(anything),
      );

      // 3. Teste Datenbank-Integrität
      final validMonsterData = {
        'id': 'valid_monster',
        'name': 'Valid Monster',
        'size': 'Medium',
        'type': 'humanoid',
        'alignment': 'neutral',
        'armor_class': '12',
        'hit_points': 10,
        'hit_dice': '2d8',
        'speed': '30 ft.',
        'strength': 10,
        'dexterity': 10,
        'constitution': 10,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
        'challenge_rating': 0.5,
        'xp': 100,
        'source': 'TEST',
        'page': 1,
        'is_custom': 0,
        'version': '1.0',
      };

      await dbHelper.insertOfficialMonster(validMonsterData);
      final retrieved = await dbHelper.getOfficialMonsterById('valid_monster');
      expect(retrieved, isNotNull);

      // Aufräumen
      await dbHelper.clearOfficialData('official_monsters');
      print('Fehlerbehandlungs-Test erfolgreich abgeschlossen!');
    });
  });
}
