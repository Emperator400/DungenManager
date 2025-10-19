// test/dnd_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../lib/database/database_helper.dart';
import '../lib/models/campaign.dart';
import '../lib/models/creature.dart';
import '../lib/models/official_monster.dart';
import '../lib/game_data/dnd_data_importer.dart';

void main() {
  group('D&D Integration Tests', () {
    late DatabaseHelper dbHelper;
    late DndDataImporter dataImporter;

    setUpAll(() async {
      // Initialisiere sqflite_ffi für Tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      dbHelper = DatabaseHelper.instance;
      dataImporter = DndDataImporter();
      
      // Lösche und erstelle die Datenbank neu
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, 'dnd_helper.db');
      await deleteDatabase(path);
      await dbHelper.database;
    });

    test('Campaign model supports D&D data integration', () async {
      final campaign = Campaign(
        title: 'Test Campaign',
        description: 'A test campaign for D&D integration',
        availableMonsters: ['goblin', 'orc'],
        availableSpells: ['fireball', 'magic-missile'],
        availableItems: ['longsword', 'shield'],
        availableNpcs: ['villager', 'guard'],
      );

      expect(campaign.availableMonsters, contains('goblin'));
      expect(campaign.availableSpells, contains('fireball'));
      expect(campaign.availableItems, contains('longsword'));
      expect(campaign.availableNpcs, contains('villager'));

      // Teste die Map-Konvertierung
      final map = campaign.toMap();
      expect(map['available_monsters'], 'goblin,orc');
      expect(map['available_spells'], 'fireball,magic-missile');
      expect(map['available_items'], 'longsword,shield');
      expect(map['available_npcs'], 'villager,guard');

      // Teste die Wiederherstellung aus der Map
      final restoredCampaign = Campaign.fromMap(map);
      expect(restoredCampaign.availableMonsters, containsAll(['goblin', 'orc']));
      expect(restoredCampaign.availableSpells, containsAll(['fireball', 'magic-missile']));
      expect(restoredCampaign.availableItems, containsAll(['longsword', 'shield']));
      expect(restoredCampaign.availableNpcs, containsAll(['villager', 'guard']));
    });

    test('Creature model supports D&D integration', () async {
      final creature = Creature.fromOfficialMonster(
        officialMonsterId: 'goblin',
        name: 'Goblin',
        maxHp: 7,
        armorClass: 15,
        speed: '30ft',
        strength: 8,
        dexterity: 14,
        constitution: 10,
        intelligence: 10,
        wisdom: 8,
        charisma: 8,
        size: 'Small',
        type: 'Humanoid (goblinoid)',
        subtype: 'goblinoid',
        alignment: 'Neutral Evil',
        challengeRating: 1,
        specialAbilities: 'Nimble Escape: The goblin can take the Disengage or Hide action as a bonus action on each of its turns.',
        legendaryActions: null,
        description: 'Small, green-skinned humanoids.',
        attacks: 'Scimitar: +4 to hit, 1d6 + 2 slashing damage',
      );

      expect(creature.officialMonsterId, 'goblin');
      expect(creature.isCustom, false);
      expect(creature.size, 'Small');
      expect(creature.type, 'Humanoid (goblinoid)');
      expect(creature.subtype, 'goblinoid');
      expect(creature.alignment, 'Neutral Evil');
      expect(creature.challengeRating, 1);
      expect(creature.specialAbilities, isNotNull);
      expect(creature.description, isNotNull);

      // Teste die Map-Konvertierung
      final map = creature.toMap();
      expect(map['official_monster_id'], 'goblin');
      expect(map['is_custom'], 0);
      expect(map['size'], 'Small');
      expect(map['type'], 'Humanoid (goblinoid)');
      expect(map['challenge_rating'], 1);

      // Teste die Wiederherstellung aus der Map
      final restoredCreature = Creature.fromMap(map);
      expect(restoredCreature.officialMonsterId, 'goblin');
      expect(restoredCreature.isCustom, false);
      expect(restoredCreature.size, 'Small');
      expect(restoredCreature.type, 'Humanoid (goblinoid)');
      expect(restoredCreature.challengeRating, 1);
    });

    test('Creature copyWith method works correctly', () async {
      final creature = Creature(
        name: 'Test Creature',
        maxHp: 10,
        currentHp: 10,
        armorClass: 12,
        speed: '30ft',
        attacks: 'Claw: +2 to hit, 1d4 + 1 slashing',
        initiativeBonus: 0,
      );

      final updatedCreature = creature.copyWith(
        name: 'Updated Creature',
        maxHp: 15,
        officialMonsterId: 'wolf',
        isCustom: false,
      );

      expect(updatedCreature.name, 'Updated Creature');
      expect(updatedCreature.maxHp, 15);
      expect(updatedCreature.officialMonsterId, 'wolf');
      expect(updatedCreature.isCustom, false);
      expect(updatedCreature.armorClass, 12); // Unverändert
      expect(updatedCreature.speed, '30ft'); // Unverändert
    });

    test('Campaign copyWith method works correctly', () async {
      final campaign = Campaign(
        title: 'Original Campaign',
        description: 'Original description',
        availableMonsters: ['goblin'],
      );

      final updatedCampaign = campaign.copyWith(
        title: 'Updated Campaign',
        availableMonsters: ['goblin', 'orc', 'dragon'],
        availableSpells: ['fireball'],
      );

      expect(updatedCampaign.title, 'Updated Campaign');
      expect(updatedCampaign.description, 'Original description'); // Unverändert
      expect(updatedCampaign.availableMonsters, containsAll(['goblin', 'orc', 'dragon']));
      expect(updatedCampaign.availableSpells, contains('fireball'));
      expect(updatedCampaign.availableItems, isEmpty); // Unverändert
    });

    test('Database can store and retrieve D&D integrated campaigns', () async {
      final campaign = Campaign(
        title: 'D&D Test Campaign',
        description: 'Campaign with D&D data',
        availableMonsters: ['goblin', 'orc', 'dragon'],
        availableSpells: ['fireball', 'magic-missile'],
        availableItems: ['longsword', 'shield'],
        availableNpcs: ['villager', 'merchant'],
      );

      // Speichere die Kampagne
      final id = await dbHelper.insertCampaign(campaign);
      expect(id, greaterThan(0));

      // Lade alle Kampagnen
      final campaigns = await dbHelper.getAllCampaigns();
      final retrievedCampaign = campaigns.firstWhere((c) => c.title == 'D&D Test Campaign');

      expect(retrievedCampaign.description, 'Campaign with D&D data');
      expect(retrievedCampaign.availableMonsters, containsAll(['goblin', 'orc', 'dragon']));
      expect(retrievedCampaign.availableSpells, containsAll(['fireball', 'magic-missile']));
      expect(retrievedCampaign.availableItems, containsAll(['longsword', 'shield']));
      expect(retrievedCampaign.availableNpcs, containsAll(['villager', 'merchant']));
    });

    test('Database can store and retrieve D&D integrated creatures', () async {
      final creature = Creature.fromOfficialMonster(
        officialMonsterId: 'goblin',
        name: 'Goblin Scout',
        maxHp: 7,
        armorClass: 15,
        speed: '30ft',
        strength: 8,
        dexterity: 14,
        constitution: 10,
        intelligence: 10,
        wisdom: 8,
        charisma: 8,
        size: 'Small',
        type: 'Humanoid (goblinoid)',
        alignment: 'Neutral Evil',
        challengeRating: 1,
        specialAbilities: 'Nimble Escape',
        legendaryActions: null,
        description: 'A stealthy goblin scout',
        attacks: 'Shortbow: +4 to hit, 1d6 + 2 piercing',
      );

      // Speichere die Kreatur
      final id = await dbHelper.insertCreature(creature);
      expect(id, greaterThan(0));

      // Lade alle Kreaturen
      final creatures = await dbHelper.getAllCreatures();
      final retrievedCreature = creatures.firstWhere((c) => c.name == 'Goblin Scout');

      expect(retrievedCreature.officialMonsterId, 'goblin');
      expect(retrievedCreature.isCustom, false);
      expect(retrievedCreature.size, 'Small');
      expect(retrievedCreature.type, 'Humanoid (goblinoid)');
      expect(retrievedCreature.alignment, 'Neutral Evil');
      expect(retrievedCreature.challengeRating, 1);
      expect(retrievedCreature.specialAbilities, 'Nimble Escape');
      expect(retrievedCreature.attacks, contains('Shortbow'));
    });

    test('String list parsing handles edge cases', () async {
      // Teste leere Strings
      final emptyList = Campaign.parseStringListForTest(null);
      expect(emptyList, isEmpty);

      final emptyList2 = Campaign.parseStringListForTest('');
      expect(emptyList2, isEmpty);

      // Teste Strings mit nur Kommas
      final commaList = Campaign.parseStringListForTest(',,,');
      expect(commaList, isEmpty);

      // Teste normale Strings
      final normalList = Campaign.parseStringListForTest('goblin,orc,dragon');
      expect(normalList, containsAll(['goblin', 'orc', 'dragon']));

      // Teste Strings mit Leerzeichen
      final spacedList = Campaign.parseStringListForTest('goblin, orc, dragon');
      expect(spacedList, containsAll(['goblin', 'orc', 'dragon']));
    });

    tearDownAll(() async {
      // Datenbankverbindung wird automatisch geschlossen
    });
  });
}
