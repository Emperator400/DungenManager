// test/dnd_integration_test_simple.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/models/creature.dart';
import 'package:dungen_manager/models/official_monster.dart';
import 'package:dungen_manager/services/creature_factory_service.dart';
import 'package:dungen_manager/utils/string_list_parser.dart';

void main() {
  group('D&D Integration Simple Tests', () {
    test('Campaign model supports D&D data integration', () async {
      final campaign = Campaign.legacy(
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
      expect(map['settings']['available_monsters'], 'goblin,orc');
      expect(map['settings']['available_spells'], 'fireball,magic-missile');
      expect(map['settings']['available_items'], 'longsword,shield');
      expect(map['settings']['available_npcs'], 'villager,guard');

      // Teste die Wiederherstellung aus der Map
      final restoredCampaign = Campaign.fromMap(map);
      expect(restoredCampaign.availableMonsters, containsAll(['goblin', 'orc']));
      expect(restoredCampaign.availableSpells, containsAll(['fireball', 'magic-missile']));
      expect(restoredCampaign.availableItems, containsAll(['longsword', 'shield']));
      expect(restoredCampaign.availableNpcs, containsAll(['villager', 'guard']));
    });

    test('Creature model supports D&D integration', () async {
      final officialMonster = OfficialMonster(
        id: 'goblin',
        name: 'Goblin',
        hitPoints: 7,
        armorClass: '15',
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
        challengeRating: 1.0,
        xp: 50,
        hitDice: '2d6',
        source: 'SRD',
        specialAbilities: [
          MonsterAbility(
            name: 'Nimble Escape',
            description: 'The goblin can take the Disengage or Hide action as a bonus action on each of its turns.',
          ),
        ],
        actions: [
          MonsterAction(
            name: 'Scimitar',
            description: '+4 to hit, 1d6 + 2 slashing damage',
          ),
        ],
        description: 'Small, green-skinned humanoids.',
      );
      
      final creature = CreatureFactoryService.fromOfficialMonster(
        officialMonsterId: officialMonster.id,
        name: officialMonster.name,
        maxHp: officialMonster.hitPoints,
        armorClass: int.tryParse(officialMonster.armorClass) ?? 10,
        speed: officialMonster.speed,
        strength: officialMonster.strength,
        dexterity: officialMonster.dexterity,
        constitution: officialMonster.constitution,
        intelligence: officialMonster.intelligence,
        wisdom: officialMonster.wisdom,
        charisma: officialMonster.charisma,
        size: officialMonster.size,
        type: officialMonster.type,
        subtype: officialMonster.subtype,
        alignment: officialMonster.alignment,
        challengeRating: officialMonster.challengeRating?.toInt(),
        specialAbilities: officialMonster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n'),
        description: officialMonster.description,
        attacks: officialMonster.actions.map((a) => '${a.name}: ${a.description}').join('\n'),
      );

      expect(creature.officialMonsterId, 'goblin');
      expect(creature.isCustom, false);
      expect(creature.size, 'Small');
      expect(creature.type, 'Humanoid (goblinoid)');
      expect(creature.subtype, 'goblinoid');
      expect(creature.alignment, 'Neutral Evil');
      expect(creature.challengeRating, 1);
      expect(creature.specialAbilities, contains('Nimble Escape'));
      expect(creature.description, 'Small, green-skinned humanoids.');

      // Teste die Map-Konvertierung
      final map = creature.toMap();
      expect(map['official_monster_id'], 'goblin');
      expect(map['is_custom'], false);
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
        id: 'test-creature',
        name: 'Test Creature',
        maxHp: 10,
        currentHp: 10,
        armorClass: 12,
        speed: '30ft',
        attacks: 'Claw: +2 to hit, 1d4 + 1 slashing',
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10,
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
      final campaign = Campaign.legacy(
        title: 'Original Campaign',
        description: 'Original description',
        availableMonsters: ['goblin'],
      );

      final updatedCampaign = campaign.copyWith(
        title: 'Updated Campaign',
        settings: campaign.settings.copyWith(
          availableMonsters: ['goblin', 'orc', 'dragon'],
          availableSpells: ['fireball'],
        ),
      );

      expect(updatedCampaign.title, 'Updated Campaign');
      expect(updatedCampaign.description, 'Original description'); // Unverändert
      expect(updatedCampaign.availableMonsters, containsAll(['goblin', 'orc', 'dragon']));
      expect(updatedCampaign.availableSpells, contains('fireball'));
      expect(updatedCampaign.availableItems, isEmpty); // Unverändert
    });

    test('String list parsing handles edge cases', () async {
      // Teste leere Strings
      final emptyList = StringListParser.parseStringListForTest(null);
      expect(emptyList, isEmpty);

      final emptyList2 = StringListParser.parseStringListForTest('');
      expect(emptyList2, isEmpty);

      // Teste Strings mit nur Kommas
      final commaList = StringListParser.parseStringListForTest(',,,');
      expect(commaList, isEmpty);

      // Teste normale Strings
      final normalList = StringListParser.parseStringListForTest('goblin,orc,dragon');
      expect(normalList, containsAll(['goblin', 'orc', 'dragon']));

      // Teste Strings mit Leerzeichen
      final spacedList = StringListParser.parseStringListForTest('goblin, orc, dragon');
      expect(spacedList, containsAll(['goblin', 'orc', 'dragon']));
    });
  });
}
