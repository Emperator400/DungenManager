// lib/database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/campaign.dart';
import '../models/creature.dart';
import '../models/player_character.dart';
import '../models/session.dart';
import '../models/wiki_entry.dart';
import '../models/quest.dart';
import '../models/inventory_item.dart';
import '../models/scene.dart';
import '../models/item.dart';
import '../models/sound.dart';
import '../models/sound_scene.dart';
import '../models/scene_sound_link.dart';


class DatabaseHelper {
  static const _databaseName = "dnd_helper.db";
  static const _databaseVersion = 14;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }


  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade);
  }

  // --- Datenbank-Struktur (Erstellen & Upgraden) ---
  Future _onCreate(Database db, int version) async => await _createTables(db, version);

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Einfache Entwicklungs-Strategie: Alles löschen und neu erstellen
    await db.execute('DROP TABLE IF EXISTS campaigns');
    await db.execute('DROP TABLE IF EXISTS player_characters');
    await db.execute('DROP TABLE IF EXISTS sessions');
    await db.execute('DROP TABLE IF EXISTS creatures');
    await db.execute('DROP TABLE IF EXISTS wiki_entries');
    await db.execute('DROP TABLE IF EXISTS inventory_items');
    await db.execute('DROP TABLE IF EXISTS items');
    await db.execute('DROP TABLE IF EXISTS quests');
    await db.execute('DROP TABLE IF EXISTS campaign_quests');
    await db.execute('DROP TABLE IF EXISTS scenes');
    await db.execute('DROP TABLE IF EXISTS sounds');
    await db.execute('DROP TABLE IF EXISTS sound_scenes');
    await db.execute('DROP TABLE IF EXISTS scene_sound_links');
    await _createTables(db, newVersion);
  }

  // Diese eine Methode erstellt den GESAMTEN, AKTUELLEN Zustand der Datenbank
  Future _createTables(Database db, int version) async {

      await db.execute('''
      CREATE TABLE player_characters (
        id TEXT PRIMARY KEY, campaignId TEXT NOT NULL, name TEXT NOT NULL, playerName TEXT NOT NULL, 
        className TEXT NOT NULL, 
        raceName TEXT NOT NULL,
        level INTEGER NOT NULL, maxHp INTEGER NOT NULL, armorClass INTEGER NOT NULL, 
        initiativeBonus INTEGER NOT NULL, imagePath TEXT, strength INTEGER NOT NULL, dexterity INTEGER NOT NULL, 
        constitution INTEGER NOT NULL, intelligence INTEGER NOT NULL, wisdom INTEGER NOT NULL, charisma INTEGER NOT NULL,
        proficientSkills TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        itemType TEXT NOT NULL,
        weight REAL NOT NULL,
        cost REAL NOT NULL,
        damage TEXT,
        properties TEXT,
        acFormula TEXT,
        strengthRequirement INTEGER,
        stealthDisadvantage INTEGER,
        rarity TEXT,
        requiresAttunement INTEGER
      )
    ''');

       await db.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        ownerId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        quantity INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE campaigns (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY, 
        campaignId TEXT NOT NULL, 
        title TEXT NOT NULL,
        inGameTimeInMinutes INTEGER NOT NULL,
        liveNotes TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE creatures (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        maxHp INTEGER NOT NULL,
        armorClass INTEGER NOT NULL,
        speed TEXT NOT NULL,
        attacks TEXT NOT NULL,
        initiativeBonus INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE wiki_entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        entryType TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE campaign_wiki_links (
        campaignId TEXT NOT NULL,
        wikiEntryId TEXT NOT NULL,
        PRIMARY KEY (campaignId, wikiEntryId)
      )
    ''');
     await db.execute('''
      CREATE TABLE quests (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        goal TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE campaign_quests (
        campaignId TEXT NOT NULL,
        questId TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        PRIMARY KEY (campaignId, questId)
      )
    ''');

    await db.execute('''
      CREATE TABLE scenes (
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL,
        orderIndex INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        linkedWikiEntryIds TEXT NOT NULL,
        linkedQuestIds TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sounds (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        filePath TEXT NOT NULL,
        soundType TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sound_scenes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE scene_sound_links (
        id TEXT PRIMARY KEY,
        sceneId TEXT NOT NULL,
        soundId TEXT NOT NULL,
        volume REAL NOT NULL
      )
    ''');
  }

  // --- Campaign CRUD ---
  Future<int> insertCampaign(Campaign campaign) async => await (await database).insert('campaigns', campaign.toMap());
  Future<List<Campaign>> getAllCampaigns() async {
    final maps = await (await database).query('campaigns', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Campaign.fromMap(maps[i]));
  }
  Future<int> updateCampaign(Campaign campaign) async => await (await database).update('campaigns', campaign.toMap(), where: 'id = ?', whereArgs: [campaign.id]);
  Future<int> deleteCampaign(String id) async => await (await database).delete('campaigns', where: 'id = ?', whereArgs: [id]);

  // --- PlayerCharacter CRUD ---
  Future<int> insertPlayerCharacter(PlayerCharacter pc) async => await (await database).insert('player_characters', pc.toMap());
  Future<List<PlayerCharacter>> getPlayerCharactersForCampaign(String campaignId) async {
    final maps = await (await database).query('player_characters', where: 'campaignId = ?', whereArgs: [campaignId], orderBy: 'name ASC');
    return List.generate(maps.length, (i) => PlayerCharacter.fromMap(maps[i]));
  }
  Future<int> updatePlayerCharacter(PlayerCharacter pc) async => await (await database).update('player_characters', pc.toMap(), where: 'id = ?', whereArgs: [pc.id]);
  Future<int> deletePlayerCharacter(String id) async => await (await database).delete('player_characters', where: 'id = ?', whereArgs: [id]);
  
  // --- Session CRUD ---
  Future<int> insertSession(Session session) async => await (await database).insert('sessions', session.toMap());
  Future<List<Session>> getSessionsForCampaign(String campaignId) async {
    final maps = await (await database).query('sessions', where: 'campaignId = ?', whereArgs: [campaignId], orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Session.fromMap(maps[i]));
  }
  Future<int> updateSession(Session session) async => await (await database).update('sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  Future<int> deleteSession(String id) async => await (await database).delete('sessions', where: 'id = ?', whereArgs: [id]);
  Future<Session?> getSessionById(String id) async {
    final maps = await (await database).query('sessions', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Session.fromMap(maps.first);
    return null;
  }

  // --- Scene CRUD ---
  Future<int> insertScene(Scene scene) async => await (await database).insert('scenes', scene.toMap());
  Future<List<Scene>> getScenesForSession(String sessionId) async {
    final maps = await (await database).query('scenes', where: 'sessionId = ?', whereArgs: [sessionId], orderBy: 'orderIndex ASC');
    return List.generate(maps.length, (i) => Scene.fromMap(maps[i]));
  }
  Future<int> updateScene(Scene scene) async => await (await database).update('scenes', scene.toMap(), where: 'id = ?', whereArgs: [scene.id]);
  Future<int> deleteScene(String id) async => await (await database).delete('scenes', where: 'id = ?', whereArgs: [id]);
  Future<void> updateSceneOrder(List<Scene> scenes) async {
    final db = await instance.database;
    final batch = db.batch();
    for (int i = 0; i < scenes.length; i++) {
      scenes[i].orderIndex = i;
      batch.update('scenes', {'orderIndex': i}, where: 'id = ?', whereArgs: [scenes[i].id]);
    }
    await batch.commit(noResult: true);
  }

  // --- Creature (Bestiary) CRUD ---
  Future<int> insertCreature(Creature creature) async => await (await database).insert('creatures', creature.toMap());
  Future<List<Creature>> getAllCreatures() async {
    final maps = await (await database).query('creatures', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Creature.fromMap(maps[i]));
  }
  Future<int> updateCreature(Creature creature) async => await (await database).update('creatures', creature.toMap(), where: 'id = ?', whereArgs: [creature.id]);
  Future<int> deleteCreature(String id) async => await (await database).delete('creatures', where: 'id = ?', whereArgs: [id]);

  // --- Item (Armory) CRUD ---
  Future<int> insertItem(Item item) async => await (await database).insert('items', item.toMap());
  Future<List<Item>> getAllItems() async {
    final maps = await (await database).query('items', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Item.fromMap(maps[i]));
  }
  Future<Item?> getItemById(String id) async {
    final maps = await (await database).query('items', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Item.fromMap(maps.first);
    return null;
  }
  Future<int> updateItem(Item item) async => await (await database).update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  Future<int> deleteItem(String id) async => await (await database).delete('items', where: 'id = ?', whereArgs: [id]);

  // --- InventoryItem (Link) CRUD ---
  Future<int> insertInventoryItem(InventoryItem item) async => await (await database).insert('inventory_items', item.toMap());
  Future<List<InventoryItem>> getInventoryForOwner(String ownerId) async {
    final maps = await (await database).query('inventory_items', where: 'ownerId = ?', whereArgs: [ownerId]);
    return List.generate(maps.length, (i) => InventoryItem.fromMap(maps[i]));
  }
  Future<int> updateInventoryItem(InventoryItem item) async => await (await database).update('inventory_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  Future<int> deleteInventoryItem(String id) async => await (await database).delete('inventory_items', where: 'id = ?', whereArgs: [id]);
  Future<List<DisplayInventoryItem>> getDisplayInventoryForOwner(String ownerId) async {
    final List<InventoryItem> inventoryItems = await getInventoryForOwner(ownerId);
    final List<DisplayInventoryItem> displayItems = [];
    for (final invItem in inventoryItems) {
      final itemDetails = await getItemById(invItem.itemId);
      if (itemDetails != null) {
        displayItems.add(DisplayInventoryItem(inventoryItem: invItem, item: itemDetails));
      }
    }
    return displayItems;
  }

  // --- WikiEntry (Lore Keeper) CRUD ---
  Future<int> insertWikiEntry(WikiEntry entry) async => await (await database).insert('wiki_entries', entry.toMap());
  Future<List<WikiEntry>> getAllWikiEntries() async {
    final maps = await (await database).query('wiki_entries', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => WikiEntry.fromMap(maps[i]));
  }
  Future<WikiEntry?> getWikiEntryById(String id) async {
    final maps = await (await database).query('wiki_entries', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return WikiEntry.fromMap(maps.first);
    return null;
  }
  Future<int> updateWikiEntry(WikiEntry entry) async => await (await database).update('wiki_entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  Future<int> deleteWikiEntry(String id) async => await (await database).delete('wiki_entries', where: 'id = ?', whereArgs: [id]);
  Future<List<WikiEntry>> getWikiEntriesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await (await database).query('wiki_entries', where: 'id IN ($placeholders)', whereArgs: ids);
    return List.generate(maps.length, (i) => WikiEntry.fromMap(maps[i]));
  }

  // --- Quest (Template) CRUD ---
  Future<int> insertQuest(Quest quest) async => await (await database).insert('quests', quest.toMap());
  Future<List<Quest>> getAllQuests() async {
    final maps = await (await database).query('quests', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }
  Future<Quest?> getQuestById(String id) async {
    final maps = await (await database).query('quests', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Quest.fromMap(maps.first);
    return null;
  }
  Future<int> updateQuest(Quest quest) async => await (await database).update('quests', quest.toMap(), where: 'id = ?', whereArgs: [quest.id]);
  Future<int> deleteQuest(String id) async => await (await database).delete('quests', where: 'id = ?', whereArgs: [id]);
  Future<List<Quest>> getQuestsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await (await database).query('quests', where: 'id IN ($placeholders)', whereArgs: ids);
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }

  // --- Campaign-Quest Link CRUD ---
  Future<void> addQuestToCampaign(String campaignId, String questId) async => await (await database).insert('campaign_quests', {'campaignId': campaignId, 'questId': questId, 'status': QuestStatus.verfuegbar.toString(), 'notes': ''});
  Future<List<Map<String, dynamic>>> getQuestLinksForCampaign(String campaignId) async => await (await database).query('campaign_quests', where: 'campaignId = ?', whereArgs: [campaignId]);
  Future<void> updateCampaignQuest(String campaignId, String questId, QuestStatus status, String notes) async => await (await database).update('campaign_quests', {'status': status.toString(), 'notes': notes}, where: 'campaignId = ? AND questId = ?', whereArgs: [campaignId, questId]);
  Future<void> removeQuestFromCampaign(String campaignId, String questId) async => await (await database).delete('campaign_quests', where: 'campaignId = ? AND questId = ?', whereArgs: [campaignId, questId]);
  Future<List<CampaignQuest>> getQuestsForCampaign(String campaignId) async {
    final List<Map<String, dynamic>> links = await getQuestLinksForCampaign(campaignId);
    final List<CampaignQuest> campaignQuests = [];
    for (final link in links) {
      final questTemplate = await getQuestById(link['questId']);
      if (questTemplate != null) {
        campaignQuests.add(CampaignQuest(
          quest: questTemplate,
          status: QuestStatus.values.firstWhere((e) => e.toString() == link['status']),
          notes: link['notes'],
        ));
      }
    }
    return campaignQuests;
  }

  // --- Sound CRUD ---
  Future<int> insertSound(Sound sound) async => await (await database).insert('sounds', sound.toMap());
  Future<List<Sound>> getAllSounds() async {
    final maps = await (await database).query('sounds', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Sound.fromMap(maps[i]));
  }
  Future<int> updateSound(Sound sound) async => await (await database).update('sounds', sound.toMap(), where: 'id = ?', whereArgs: [sound.id]);
  Future<int> deleteSound(String id) async => await (await database).delete('sounds', where: 'id = ?', whereArgs: [id]);

  // --- SoundScene CRUD ---
  Future<int> insertSoundScene(SoundScene scene) async => await (await database).insert('sound_scenes', scene.toMap());
  Future<List<SoundScene>> getAllSoundScenes() async {
    final maps = await (await database).query('sound_scenes', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => SoundScene.fromMap(maps[i]));
  }
  Future<int> updateSoundScene(SoundScene scene) async => await (await database).update('sound_scenes', scene.toMap(), where: 'id = ?', whereArgs: [scene.id]);
  Future<int> deleteSoundScene(String id) async => await (await database).delete('sound_scenes', where: 'id = ?', whereArgs: [id]);
  
  // Lösche eine Sound-Szene und alle zugehörigen Links
    Future<void> deleteSoundSceneAndLinks(String sceneId) async {
    final db = await instance.database;
    // Lösche zuerst alle Verknüpfungen zu dieser Szene
    await db.delete('scene_sound_links', where: 'sceneId = ?', whereArgs: [sceneId]);
    // Dann lösche die Szene selbst
    await db.delete('sound_scenes', where: 'id = ?', whereArgs: [sceneId]);
  }


  // --- SceneSoundLink CRUD ---
  Future<int> insertSceneSoundLink(SceneSoundLink link) async => await (await database).insert('scene_sound_links', link.toMap());
  Future<List<SceneSoundLink>> getLinksForScene(String sceneId) async {
    final maps = await (await database).query('scene_sound_links', where: 'sceneId = ?', whereArgs: [sceneId]);
    return List.generate(maps.length, (i) => SceneSoundLink.fromMap(maps[i]));
  }
  Future<int> updateSceneSoundLink(SceneSoundLink link) async => await (await database).update('scene_sound_links', link.toMap(), where: 'id = ?', whereArgs: [link.id]);
  Future<int> deleteSceneSoundLink(String id) async => await (await database).delete('scene_sound_links', where: 'id = ?', whereArgs: [id]);
  // Helfer-Methode: Holt einen einzelnen Sound anhand seiner ID
  Future<Sound?> getSoundById(String id) async {
    final db = await instance.database;
    final maps = await db.query('sounds', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Sound.fromMap(maps.first);
    }
    return null;
  }

  // Die neue, leistungsstarke Methode für den Szenen-Editor
  Future<List<DisplaySceneSound>> getDisplaySoundsForScene(String sceneId) async {
    final List<SceneSoundLink> links = await getLinksForScene(sceneId);
    final List<DisplaySceneSound> displaySounds = [];

    for (final link in links) {
      final soundDetails = await getSoundById(link.soundId);
      if (soundDetails != null) {
        displaySounds.add(DisplaySceneSound(link: link, sound: soundDetails));
      }
    }
    return displaySounds;
  }




}