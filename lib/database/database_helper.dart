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
  static const _databaseVersion = 17;

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
    final List<String> tables = [
      'campaigns', 'player_characters', 'sessions', 'creatures', 'wiki_entries',
      'inventory_items', 'items', 'quests', 'campaign_quests', 'scenes',
      'sounds', 'sound_scenes', 'scene_sound_links', 'campaign_wiki_links',
      'official_monsters', 'official_spells', 'official_classes', 'official_races',
      'official_items', 'official_locations'
    ];
    
    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
    
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
        description TEXT NOT NULL,
        available_monsters TEXT,
        available_spells TEXT,
        available_items TEXT,
        available_npcs TEXT
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
        initiativeBonus INTEGER NOT NULL,
        strength INTEGER NOT NULL,
        dexterity INTEGER NOT NULL,
        constitution INTEGER NOT NULL,
        intelligence INTEGER NOT NULL,
        wisdom INTEGER NOT NULL,
        charisma INTEGER NOT NULL,
        isPlayer INTEGER DEFAULT 0,
        official_monster_id TEXT,
        official_spell_ids TEXT,
        official_item_ids TEXT,
        size TEXT,
        type TEXT,
        subtype TEXT,
        alignment TEXT,
        challenge_rating INTEGER,
        special_abilities TEXT,
        legendary_actions TEXT,
        is_custom INTEGER DEFAULT 1,
        description TEXT
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
        soundType TEXT NOT NULL,
        description TEXT NOT NULL -- NEUE SPALTE
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

    // Offizielle D&D-Daten Tabellen
    await db.execute('''
      CREATE TABLE official_monsters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        size TEXT NOT NULL,
        type TEXT NOT NULL,
        subtype TEXT,
        alignment TEXT NOT NULL,
        armor_class TEXT NOT NULL,
        hit_points INTEGER NOT NULL,
        hit_dice TEXT NOT NULL,
        speed TEXT NOT NULL,
        strength INTEGER NOT NULL,
        dexterity INTEGER NOT NULL,
        constitution INTEGER NOT NULL,
        intelligence INTEGER NOT NULL,
        wisdom INTEGER NOT NULL,
        charisma INTEGER NOT NULL,
        saving_throws TEXT,
        skills TEXT,
        damage_vulnerabilities TEXT,
        damage_resistances TEXT,
        damage_immunities TEXT,
        condition_immunities TEXT,
        senses TEXT,
        languages TEXT,
        challenge_rating REAL NOT NULL,
        xp INTEGER NOT NULL,
        special_abilities TEXT,
        actions TEXT,
        legendary_actions TEXT,
        lair_actions TEXT,
        description TEXT,
        source TEXT NOT NULL,
        page INTEGER,
        is_custom INTEGER DEFAULT 0,
        version TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE official_spells (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        level INTEGER NOT NULL,
        school TEXT NOT NULL,
        ritual INTEGER DEFAULT 0,
        casting_time TEXT NOT NULL,
        range TEXT NOT NULL,
        duration TEXT NOT NULL,
        components TEXT,
        materials TEXT,
        description TEXT NOT NULL,
        higher_levels TEXT,
        classes TEXT,
        source TEXT NOT NULL,
        page INTEGER,
        is_custom INTEGER DEFAULT 0,
        version TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE official_classes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        hit_die TEXT NOT NULL,
        proficiency_choices TEXT,
        starting_proficiencies TEXT,
        equipment TEXT,
        class_table TEXT,
        spellcasting TEXT,
        features TEXT,
        subclasses TEXT,
        source TEXT NOT NULL,
        page INTEGER,
        is_custom INTEGER DEFAULT 0,
        version TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE official_races (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        ability_bonuses TEXT,
        age TEXT,
        alignment TEXT,
        size TEXT NOT NULL,
        speed TEXT NOT NULL,
        languages TEXT,
        traits TEXT,
        subraces TEXT,
        source TEXT NOT NULL,
        page INTEGER,
        is_custom INTEGER DEFAULT 0,
        version TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE official_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        item_type TEXT NOT NULL,
        rarity TEXT,
        requires_attunement INTEGER DEFAULT 0,
        weight REAL,
        cost REAL,
        weapon_category TEXT,
        weapon_range TEXT,
        damage TEXT,
        properties TEXT,
        armor_category TEXT,
        armor_class TEXT,
        stealth_disadvantage INTEGER DEFAULT 0,
        strength_requirement INTEGER,
        description TEXT NOT NULL,
        source TEXT NOT NULL,
        page INTEGER,
        is_custom INTEGER DEFAULT 0,
        version TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE official_locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location_type TEXT NOT NULL,
        description TEXT NOT NULL,
        region TEXT,
        parent_location_id TEXT,
        coordinates TEXT,
        notable_npcs TEXT,
        notable_locations TEXT,
        quests TEXT,
        encounters TEXT,
        source TEXT NOT NULL,
        page INTEGER,
        is_custom INTEGER DEFAULT 0,
        version TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Performance-Indizes für die offiziellen Tabellen
    await db.execute('CREATE INDEX idx_monsters_name ON official_monsters(name)');
    await db.execute('CREATE INDEX idx_monsters_cr ON official_monsters(challenge_rating)');
    await db.execute('CREATE INDEX idx_monsters_type ON official_monsters(type)');
    await db.execute('CREATE INDEX idx_spells_level ON official_spells(level)');
    await db.execute('CREATE INDEX idx_spells_school ON official_spells(school)');
    await db.execute('CREATE INDEX idx_items_name ON official_items(name)');
    await db.execute('CREATE INDEX idx_items_type ON official_items(item_type)');
    await db.execute('CREATE INDEX idx_locations_name ON official_locations(name)');
    await db.execute('CREATE INDEX idx_locations_type ON official_locations(location_type)');
  }

  // --- Campaign CRUD ---
  Future<int> insertCampaign(Campaign campaign) async => await (await database).insert('campaigns', campaign.toMap());
  Future<List<Campaign>> getAllCampaigns() async {
    final maps = await (await database).query('campaigns', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Campaign.fromMap(maps[i]));
  }
  Future<int> updateCampaign(Campaign campaign) async => await (await database).update('campaigns', campaign.toMap(), where: 'id = ?', whereArgs: [campaign.id]);
  Future<void> deleteCampaignAndAssociatedData(String campaignId) async {
    final db = await instance.database;
    // Beginne eine "Transaktion", um sicherzustellen, dass alles oder nichts gelöscht wird
    await db.transaction((txn) async {
      // 1. Finde alle Sessions, die zur Kampagne gehören
      final sessions = await txn.query('sessions', where: 'campaignId = ?', whereArgs: [campaignId]);
      for (var session in sessions) {
        // 2. Lösche alle Szenen, die zu jeder Session gehören
        await txn.delete('scenes', where: 'sessionId = ?', whereArgs: [session['id']]);
      }
      // 3. Lösche alle Sessions der Kampagne
      await txn.delete('sessions', where: 'campaignId = ?', whereArgs: [campaignId]);

      // 4. Finde alle Helden der Kampagne
      final playerCharacters = await txn.query('player_characters', where: 'campaignId = ?', whereArgs: [campaignId]);
      for (var pc in playerCharacters) {
        // 5. Lösche das gesamte Inventar für jeden Helden
        await txn.delete('inventory_items', where: 'ownerId = ?', whereArgs: [pc['id']]);
      }
      // 6. Lösche alle Helden der Kampagne
      await txn.delete('player_characters', where: 'campaignId = ?', whereArgs: [campaignId]);

      // 7. Lösche alle Quest-Verknüpfungen der Kampagne
      await txn.delete('campaign_quests', where: 'campaignId = ?', whereArgs: [campaignId]);

      // 8. Zum Schluss, lösche die Kampagne selbst
      await txn.delete('campaigns', where: 'id = ?', whereArgs: [campaignId]);
    });
    print("Kampagne $campaignId und alle zugehörigen Daten gelöscht.");
  }
  
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

  // --- Offizielle D&D-Daten CRUD Methoden ---

  // --- Official Monsters CRUD ---
  Future<int> insertOfficialMonster(Map<String, dynamic> monster) async => 
      await (await database).insert('official_monsters', monster);
  
  Future<List<Map<String, dynamic>>> getAllOfficialMonsters({
    int page = 0,
    int limit = 50,
    String? search,
    String? type,
    double? minCr,
    double? maxCr,
    String? orderBy = 'name',
    bool ascending = true,
  }) async {
    final offset = page * limit;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (search != null && search.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$search%');
    }
    
    if (type != null && type.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type);
    }
    
    if (minCr != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'challenge_rating >= ?';
      whereArgs.add(minCr);
    }
    
    if (maxCr != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'challenge_rating <= ?';
      whereArgs.add(maxCr);
    }
    
    final direction = ascending ? 'ASC' : 'DESC';
    
    return await (await database).query(
      'official_monsters',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: '$orderBy $direction',
    );
  }
  
  Future<Map<String, dynamic>?> getOfficialMonsterById(String id) async {
    final maps = await (await database).query(
      'official_monsters', 
      where: 'id = ?', 
      whereArgs: [id]
    );
    return maps.isNotEmpty ? maps.first : null;
  }
  
  Future<int> updateOfficialMonster(Map<String, dynamic> monster) async => 
      await (await database).update(
        'official_monsters', 
        monster, 
        where: 'id = ?', 
        whereArgs: [monster['id']]
      );
  
  Future<int> deleteOfficialMonster(String id) async => 
      await (await database).delete(
        'official_monsters', 
        where: 'id = ?', 
        whereArgs: [id]
      );

  // --- Official Spells CRUD ---
  Future<int> insertOfficialSpell(Map<String, dynamic> spell) async => 
      await (await database).insert('official_spells', spell);
  
  Future<List<Map<String, dynamic>>> getAllOfficialSpells({
    int page = 0,
    int limit = 50,
    String? search,
    String? school,
    int? minLevel,
    int? maxLevel,
    String? orderBy = 'name',
    bool ascending = true,
  }) async {
    final offset = page * limit;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (search != null && search.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$search%');
    }
    
    if (school != null && school.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'school = ?';
      whereArgs.add(school);
    }
    
    if (minLevel != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'level >= ?';
      whereArgs.add(minLevel);
    }
    
    if (maxLevel != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'level <= ?';
      whereArgs.add(maxLevel);
    }
    
    final direction = ascending ? 'ASC' : 'DESC';
    
    return await (await database).query(
      'official_spells',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: '$orderBy $direction',
    );
  }
  
  Future<Map<String, dynamic>?> getOfficialSpellById(String id) async {
    final maps = await (await database).query(
      'official_spells', 
      where: 'id = ?', 
      whereArgs: [id]
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // --- Official Classes CRUD ---
  Future<int> insertOfficialClass(Map<String, dynamic> dndClass) async => 
      await (await database).insert('official_classes', dndClass);
  
  Future<List<Map<String, dynamic>>> getAllOfficialClasses() async {
    return await (await database).query(
      'official_classes',
      orderBy: 'name ASC',
    );
  }
  
  Future<Map<String, dynamic>?> getOfficialClassById(String id) async {
    final maps = await (await database).query(
      'official_classes', 
      where: 'id = ?', 
      whereArgs: [id]
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // --- Official Races CRUD ---
  Future<int> insertOfficialRace(Map<String, dynamic> race) async => 
      await (await database).insert('official_races', race);
  
  Future<List<Map<String, dynamic>>> getAllOfficialRaces() async {
    return await (await database).query(
      'official_races',
      orderBy: 'name ASC',
    );
  }
  
  Future<Map<String, dynamic>?> getOfficialRaceById(String id) async {
    final maps = await (await database).query(
      'official_races', 
      where: 'id = ?', 
      whereArgs: [id]
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // --- Official Items CRUD ---
  Future<int> insertOfficialItem(Map<String, dynamic> item) async => 
      await (await database).insert('official_items', item);
  
  Future<List<Map<String, dynamic>>> getAllOfficialItems({
    int page = 0,
    int limit = 50,
    String? search,
    String? itemType,
    String? rarity,
    String? orderBy = 'name',
    bool ascending = true,
  }) async {
    final offset = page * limit;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (search != null && search.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$search%');
    }
    
    if (itemType != null && itemType.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'item_type = ?';
      whereArgs.add(itemType);
    }
    
    if (rarity != null && rarity.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'rarity = ?';
      whereArgs.add(rarity);
    }
    
    final direction = ascending ? 'ASC' : 'DESC';
    
    return await (await database).query(
      'official_items',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: '$orderBy $direction',
    );
  }
  
  Future<Map<String, dynamic>?> getOfficialItemById(String id) async {
    final maps = await (await database).query(
      'official_items', 
      where: 'id = ?', 
      whereArgs: [id]
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // --- Official Locations CRUD ---
  Future<int> insertOfficialLocation(Map<String, dynamic> location) async => 
      await (await database).insert('official_locations', location);
  
  Future<List<Map<String, dynamic>>> getAllOfficialLocations({
    int page = 0,
    int limit = 50,
    String? search,
    String? locationType,
    String? region,
    String? orderBy = 'name',
    bool ascending = true,
  }) async {
    final offset = page * limit;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (search != null && search.isNotEmpty) {
      whereClause += 'name LIKE ?';
      whereArgs.add('%$search%');
    }
    
    if (locationType != null && locationType.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'location_type = ?';
      whereArgs.add(locationType);
    }
    
    if (region != null && region.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'region = ?';
      whereArgs.add(region);
    }
    
    final direction = ascending ? 'ASC' : 'DESC';
    
    return await (await database).query(
      'official_locations',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: '$orderBy $direction',
    );
  }
  
  Future<Map<String, dynamic>?> getOfficialLocationById(String id) async {
    final maps = await (await database).query(
      'official_locations', 
      where: 'id = ?', 
      whereArgs: [id]
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  // --- Daten-Update Methoden ---
  Future<void> clearOfficialData(String tableName) async {
    await (await database).execute('DELETE FROM $tableName');
  }
  
  Future<int> getOfficialDataCount(String tableName) async {
    final result = await (await database).rawQuery('SELECT COUNT(*) as count FROM $tableName');
    return result.first['count'] as int;
  }
  
  Future<String?> getLatestVersion(String tableName) async {
    final result = await (await database).query(
      tableName,
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first['version'] as String? : null;
  }

}
