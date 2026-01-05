// test/inventory_fix_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:dungen_manager/database/database_helper.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/models/item.dart';
import 'package:dungen_manager/models/inventory_item.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('Inventory Fix Integration Tests', () {
    late DatabaseHelper dbHelper;
    const uuid = Uuid();

    setUpAll(() async {
      // Initialize sqflite_ffi for tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      // Delete and recreate the database for a clean state before each test
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'dnd_helper.db');
      await deleteDatabase(path);
      // This will trigger the _onCreate method with the new schema
      await dbHelper.database;
    });

    tearDown(() async {
      await dbHelper.closeDatabase();
    });

    test('Can create a character, add an item to inventory, and retrieve it', () async {
      // 1. Create a Campaign
      final campaign = Campaign.legacy(
        title: 'Inventory Test Campaign',
        description: 'A campaign to test inventory management.',
      );
      await dbHelper.insertCampaign(campaign);

      // 2. Create a Player Character
      final character = PlayerCharacter(
        id: uuid.v4(),
        campaignId: campaign.id,
        name: 'Test Hero',
        playerName: 'Tester',
        className: 'Fighter',
        raceName: 'Human',
        level: 1,
        maxHp: 10,
        armorClass: 16,
        initiativeBonus: 2,
        strength: 16,
        dexterity: 14,
        constitution: 14,
        intelligence: 10,
        wisdom: 12,
        charisma: 8,
        proficientSkills: 'Athletics, Intimidation',
      );
      await dbHelper.insertPlayerCharacter(character);

      // 3. Create an Item
      final item = Item(
        id: uuid.v4(),
        name: 'Longsword',
        description: 'A standard longsword.',
        itemType: 'Weapon',
        weight: 3.0,
        cost: 15.0,
      );
      await dbHelper.insertItem(item);

      // 4. Create an InventoryItem linking the character and the item
      final inventoryLink = InventoryItem(
        ownerId: character.id,
        itemId: item.id,
        quantity: 1,
      );
      await dbHelper.insertInventoryItem(inventoryLink);

      // 5. Retrieve the inventory for the character
      final retrievedInventory = await dbHelper.getInventoryForOwner(character.id);

      // 6. Assert the fix is working
      expect(retrievedInventory, isNotEmpty);
      expect(retrievedInventory.length, 1);
      expect(retrievedInventory.first.itemId, item.id);
      expect(retrievedInventory.first.ownerId, character.id);
    });
  });
}
