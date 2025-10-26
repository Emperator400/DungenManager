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
import '../models/equip_slot.dart';
import '../models/sound.dart';
import '../models/sound_scene.dart';
import '../models/scene_sound_link.dart';
import '../models/official_monster.dart';
import '../models/item_effect.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid();


class DatabaseHelper {
  static const _databaseName = "dnd_helper.db";
  static const _databaseVersion = 20;

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
    // Schrittweise Migration für bestehende Daten
    if (oldVersion < 18) {
      // Gold-Felder zur creatures-Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN gold REAL DEFAULT 0.0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN silver REAL DEFAULT 0.0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN copper REAL DEFAULT 0.0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Neue Felder zur creatures-Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN source_type TEXT DEFAULT \'custom\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN source_id TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN is_favorite INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN version TEXT DEFAULT \'1.0\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Performance-Indizes für die neue Felder
      try {
        await db.execute('CREATE INDEX idx_creatures_source_type ON creatures(source_type)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_creatures_is_favorite ON creatures(is_favorite)');
      } catch (e) {
        // Index existiert bereits
      }
      
      // Sicherstellen, dass quantity Spalte in inventory_items existiert und DEFAULT 1 hat
      try {
        await db.execute('ALTER TABLE inventory_items ADD COLUMN quantity INTEGER DEFAULT 1');
      } catch (e) {
        // Spalte existiert bereits
      }
    }
    
    // Migration für Version 19: Ausrüstungs-System
    if (oldVersion < 19) {
      // Ausrüstungs-Felder zur inventory_items Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE inventory_items ADD COLUMN isEquipped INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE inventory_items ADD COLUMN equipSlot TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Durability-Felder zur items Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE items ADD COLUMN hasDurability INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN maxDurability INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN isRepairable INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Performance-Indizes für Ausrüstung
      try {
        await db.execute('CREATE INDEX idx_inventory_equipped ON inventory_items(isEquipped)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_inventory_slot ON inventory_items(equipSlot)');
      } catch (e) {
        // Index existiert bereits
      }
    }
    
    // NEU: Migration für Version 20: PlayerCharacter Erweiterung mit D&D-Feldern
    if (oldVersion < 20) {
      // D&D-Klassifikation zur player_characters Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN size TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN type TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN subtype TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN alignment TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Beschreibung und Fähigkeiten hinzufügen
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN description TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN special_abilities TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN attacks TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Währung hinzufügen
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN gold REAL DEFAULT 0.0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN silver REAL DEFAULT 0.0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN copper REAL DEFAULT 0.0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Erweiterte Felder hinzufügen
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN source_type TEXT DEFAULT \'custom\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN source_id TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN is_favorite INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN version TEXT DEFAULT \'1.0\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Performance-Indizes für neue Felder
      try {
        await db.execute('CREATE INDEX idx_players_source_type ON player_characters(source_type)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_players_is_favorite ON player_characters(is_favorite)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_players_campaign ON player_characters(campaignId)');
      } catch (e) {
        // Index existiert bereits
      }
    }
    
    // Für größere Versionsunterschiede könnten hier weitere Migrationen folgen
    if (oldVersion < 17) {
      // Alte Migrationen für Version 17 und darunter
      await _migrateToVersion17(db);
    }
  }
  
  // Alte Migration für Version 17
  Future _migrateToVersion17(Database db) async {
    // Hier könnten alte Migrationen für Version 17 implementiert werden
    // Aktuell nicht benötigt, da wir direkt auf Version 18 migrieren
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
        proficientSkills TEXT NOT NULL,
        -- NEU: D&D-Klassifikation
        size TEXT,
        type TEXT,
        subtype TEXT,
        alignment TEXT,
        -- NEU: Beschreibung und Fähigkeiten
        description TEXT,
        special_abilities TEXT,
        attacks TEXT,
        -- NEU: Währung
        gold REAL DEFAULT 0.0,
        silver REAL DEFAULT 0.0,
        copper REAL DEFAULT 0.0,
        -- NEU: Erweiterte Felder
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        version TEXT DEFAULT '1.0'
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
        requiresAttunement INTEGER,
        hasDurability INTEGER DEFAULT 0,
        maxDurability INTEGER,
        isRepairable INTEGER DEFAULT 0
      )
    ''');

       await db.execute('''
      CREATE TABLE inventory_items (
        id TEXT PRIMARY KEY,
        ownerId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        isEquipped INTEGER DEFAULT 0,
        equipSlot TEXT
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
        gold REAL DEFAULT 0.0,
        silver REAL DEFAULT 0.0,
        copper REAL DEFAULT 0.0,
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
        description TEXT,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        version TEXT DEFAULT '1.0'
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

    // Item Effects Tabellen
    await db.execute('''
      CREATE TABLE item_effects (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        effect_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        duration TEXT NOT NULL,
        duration_value INTEGER,
        requires_concentration INTEGER DEFAULT 0,
        requires_attunement INTEGER DEFAULT 0,
        max_charges INTEGER DEFAULT 1,
        current_charges INTEGER DEFAULT 1,
        last_used TEXT,
        is_active INTEGER DEFAULT 0,
        activated_at TEXT,
        target_character_id TEXT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE active_effects (
        id TEXT PRIMARY KEY,
        character_id TEXT NOT NULL,
        item_effect_id TEXT NOT NULL,
        source_item_name TEXT NOT NULL,
        effect_name TEXT NOT NULL,
        description TEXT NOT NULL,
        effect_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        expires_at TEXT,
        requires_concentration INTEGER DEFAULT 0,
        FOREIGN KEY (character_id) REFERENCES player_characters (id) ON DELETE CASCADE,
        FOREIGN KEY (item_effect_id) REFERENCES item_effects (id) ON DELETE CASCADE
      )
    ''');

    // Performance-Indizes für Item Effects
    await db.execute('CREATE INDEX idx_item_effects_item_id ON item_effects(item_id)');
    await db.execute('CREATE INDEX idx_item_effects_type ON item_effects(effect_type)');
    await db.execute('CREATE INDEX idx_active_effects_character_id ON active_effects(character_id)');
    await db.execute('CREATE INDEX idx_active_effects_item_effect_id ON active_effects(item_effect_id)');

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
  
  // NEU: PlayerCharacter Favoriten-Management
  Future<void> togglePlayerCharacterFavorite(String id) async {
    final pc = await getPlayerCharacterById(id);
    if (pc != null) {
      await (await database).update(
        'player_characters',
        {'is_favorite': pc.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
  
  Future<List<PlayerCharacter>> getFavoritePlayerCharacters() async {
    final maps = await (await database).query(
      'player_characters',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => PlayerCharacter.fromMap(maps[i]));
  }
  
  Future<PlayerCharacter?> getPlayerCharacterById(String id) async {
    final maps = await (await database).query('player_characters', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return PlayerCharacter.fromMap(maps.first);
    return null;
  }
  
  // NEU: PlayerCharacter Duplizieren
  Future<String> duplicatePlayerCharacter(String id) async {
    final original = await getPlayerCharacterById(id);
    if (original == null) throw Exception('Character nicht gefunden: $id');
    
    // Neue ID und Name generieren
    final newId = _uuid.v4();
    final newName = '${original.name} (Kopie)';
    
    // Kopie erstellen
    final copy = PlayerCharacter(
      id: newId,
      campaignId: original.campaignId,
      name: newName,
      playerName: original.playerName,
      className: original.className,
      raceName: original.raceName,
      level: original.level,
      maxHp: original.maxHp,
      armorClass: original.armorClass,
      initiativeBonus: original.initiativeBonus,
      imagePath: null, // Bild zurücksetzen
      strength: original.strength,
      dexterity: original.dexterity,
      constitution: original.constitution,
      intelligence: original.intelligence,
      wisdom: original.wisdom,
      charisma: original.charisma,
      proficientSkills: original.proficientSkills,
      size: original.size,
      type: original.type,
      subtype: original.subtype,
      alignment: original.alignment,
      description: original.description,
      specialAbilities: original.specialAbilities,
      attacks: original.attacks,
      gold: original.gold,
      silver: original.silver,
      copper: original.copper,
      sourceType: 'custom',
      sourceId: null,
      isFavorite: false, // Kopien sind nicht favorisiert
      version: '1.0',
    );
    
    await insertPlayerCharacter(copy);
    
    // Inventar kopieren
    final inventory = await getInventoryForOwner(id);
    for (final item in inventory) {
      final newInventoryItem = InventoryItem(
        id: _uuid.v4(),
        ownerId: newId,
        itemId: item.itemId,
        quantity: item.quantity,
        isEquipped: false, // Kopien sind nicht ausgerüstet
        equipSlot: null,
      );
      await insertInventoryItem(newInventoryItem);
    }
    
    return newId;
  }
  
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
  
  // Neue Methoden für Unified Bestiarum
  Future<List<Creature>> getAllCreaturesUnified({
    int page = 0,
    int limit = 50,
    String? search,
    String? sourceType,
    String? type,
    double? minCr,
    double? maxCr,
    bool? isFavorite,
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
    
    if (sourceType != null && sourceType.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'source_type = ?';
      whereArgs.add(sourceType);
    }
    
    if (type != null && type.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type);
    }
    
    if (minCr != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(challenge_rating >= ? OR challenge_rating IS NULL)';
      whereArgs.add(minCr);
    }
    
    if (maxCr != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(challenge_rating <= ? OR challenge_rating IS NULL)';
      whereArgs.add(maxCr);
    }
    
    if (isFavorite != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'is_favorite = ?';
      whereArgs.add(isFavorite ? 1 : 0);
    }
    
    final direction = ascending ? 'ASC' : 'DESC';
    
    return await (await database).query(
      'creatures',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      limit: limit,
      offset: offset,
      orderBy: '$orderBy $direction',
    ).then((maps) => List.generate(maps.length, (i) => Creature.fromMap(maps[i])));
  }
  
  Future<List<Creature>> getCreaturesBySourceType(String sourceType) async {
    final maps = await (await database).query(
      'creatures',
      where: 'source_type = ?',
      whereArgs: [sourceType],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Creature.fromMap(maps[i]));
  }
  
  Future<List<Creature>> getFavoriteCreatures() async {
    final maps = await (await database).query(
      'creatures',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Creature.fromMap(maps[i]));
  }
  
  Future<void> toggleCreatureFavorite(String id) async {
    final creature = await getCreatureById(id);
    if (creature != null) {
      await (await database).update(
        'creatures',
        {'is_favorite': creature.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
  
  Future<void> updateCreatureSource(String id, String sourceType, String? sourceId) async {
    await (await database).update(
      'creatures',
      {
        'source_type': sourceType,
        'source_id': sourceId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<Creature?> getCreatureById(String id) async {
    final maps = await (await database).query('creatures', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? Creature.fromMap(maps.first) : null;
  }
  
  Future<int> updateCreature(Creature creature) async => await (await database).update('creatures', creature.toMap(), where: 'id = ?', whereArgs: [creature.id]);
  Future<int> deleteCreature(String id) async => await (await database).delete('creatures', where: 'id = ?', whereArgs: [id]);
  Future<int> deleteAllCreatures() async => await (await database).delete('creatures');
  
  // Neue Methoden für Synchronisation mit offiziellen Monstern
  Future<List<Creature>> syncOfficialMonstersToCreatures() async {
    final officialMonsters = await getAllOfficialMonsters(limit: 1000);
    final syncedCreatures = <Creature>[];
    
    for (final officialData in officialMonsters) {
      final officialMonster = OfficialMonster.fromMap(officialData);
      
      // Prüfen, ob das Monster bereits als Creature existiert
      final existing = await (await database).query(
        'creatures',
        where: 'source_id = ? AND source_type = ?',
        whereArgs: [officialMonster.id, 'official'],
      );
      
      if (existing.isEmpty) {
        // Neues Creature aus offiziellem Monster erstellen
        final creature = Creature.fromOfficialMonster(
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
          challengeRating: officialMonster.challengeRating.toInt(),
          specialAbilities: officialMonster.specialAbilities.isNotEmpty 
              ? officialMonster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n')
              : null,
          legendaryActions: officialMonster.legendaryActions?.isNotEmpty == true
              ? officialMonster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n')
              : null,
          description: officialMonster.description,
        );
        
        await insertCreature(creature);
        syncedCreatures.add(creature);
      }
    }
    
    return syncedCreatures;
  }
  
  Future<int> getCreaturesCount({String? sourceType}) async {
    if (sourceType != null) {
      final result = await (await database).rawQuery(
        'SELECT COUNT(*) as count FROM creatures WHERE source_type = ?',
        [sourceType],
      );
      return result.first['count'] as int;
    } else {
      final result = await (await database).rawQuery('SELECT COUNT(*) as count FROM creatures');
      return result.first['count'] as int;
    }
  }

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

  // --- Ausrüstungs-spezifische Methoden ---
  
  // Item ausrüsten
  Future<void> equipItem(String inventoryItemId, EquipSlot slot) async {
    final db = await database;
    
    // Prüfen, ob bereits ein Item in diesem Slot ausgerüstet ist
    final existingItems = await db.query(
      'inventory_items',
      where: 'ownerId = (SELECT ownerId FROM inventory_items WHERE id = ?) AND equipSlot = ? AND isEquipped = 1',
      whereArgs: [inventoryItemId, slot.toString()],
    );
    
    // Bestehendes Item im selben Slot unequirüsten
    if (existingItems.isNotEmpty) {
      for (final existing in existingItems) {
        await db.update(
          'inventory_items',
          {'isEquipped': 0, 'equipSlot': null},
          where: 'id = ?',
          whereArgs: [existing['id']],
        );
      }
    }
    
    // Neues Item ausrüsten
    await db.update(
      'inventory_items',
      {'isEquipped': 1, 'equipSlot': slot.toString()},
      where: 'id = ?',
      whereArgs: [inventoryItemId],
    );
  }
  
  // Item unequirüsten
  Future<void> unequipItem(String inventoryItemId) async {
    final db = await database;
    await db.update(
      'inventory_items',
      {'isEquipped': 0, 'equipSlot': null},
      where: 'id = ?',
      whereArgs: [inventoryItemId],
    );
  }
  
  // Alle ausgerüsteten Items eines Charakters holen
  Future<List<DisplayInventoryItem>> getEquippedItems(String ownerId) async {
    final maps = await (await database).query(
      'inventory_items',
      where: 'ownerId = ? AND isEquipped = 1',
      whereArgs: [ownerId],
    );
    
    final List<DisplayInventoryItem> equippedItems = [];
    for (final map in maps) {
      final inventoryItem = InventoryItem.fromMap(map);
      final item = await getItemById(inventoryItem.itemId);
      if (item != null) {
        equippedItems.add(DisplayInventoryItem(inventoryItem: inventoryItem, item: item));
      }
    }
    return equippedItems;
  }
  
  // Nicht ausgerüstete Items eines Charakters holen
  Future<List<DisplayInventoryItem>> getUnequippedItems(String ownerId) async {
    final maps = await (await database).query(
      'inventory_items',
      where: 'ownerId = ? AND isEquipped = 0',
      whereArgs: [ownerId],
    );
    
    final List<DisplayInventoryItem> unequippedItems = [];
    for (final map in maps) {
      final inventoryItem = InventoryItem.fromMap(map);
      final item = await getItemById(inventoryItem.itemId);
      if (item != null) {
        unequippedItems.add(DisplayInventoryItem(inventoryItem: inventoryItem, item: item));
      }
    }
    return unequippedItems;
  }
  
  // Prüfen, ob ein Item in einen bestimmten Slot kann
  Future<bool> canEquipInSlot(String itemId, EquipSlot slot) async {
    final item = await getItemById(itemId);
    if (item == null) return false;
    
    return slot.allowedItemTypes.contains(item.itemType);
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

  // --- Item Effects CRUD ---
  Future<int> insertItemEffect(ItemEffect effect) async => 
      await (await database).insert('item_effects', effect.toMap());
  
  Future<List<ItemEffect>> getEffectsForItem(String itemId) async {
    final maps = await (await database).query(
      'item_effects', 
      where: 'item_id = ?', 
      whereArgs: [itemId],
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => ItemEffect.fromMap(maps[i]));
  }
  
  Future<int> updateItemEffect(ItemEffect effect) async => 
      await (await database).update(
        'item_effects', 
        effect.toMap(), 
        where: 'id = ?', 
        whereArgs: [effect.id]
      );
  
  Future<int> deleteItemEffect(String id) async => 
      await (await database).delete(
        'item_effects', 
        where: 'id = ?', 
        whereArgs: [id]
      );

  // --- Active Effects CRUD ---
  Future<int> insertActiveEffect(ActiveEffect effect) async => 
      await (await database).insert('active_effects', effect.toMap());
  
  Future<List<ActiveEffect>> getActiveEffectsForCharacter(String characterId) async {
    final maps = await (await database).query(
      'active_effects', 
      where: 'character_id = ?', 
      whereArgs: [characterId],
      orderBy: 'started_at DESC',
    );
    return List.generate(maps.length, (i) => ActiveEffect.fromMap(maps[i]));
  }
  
  Future<int> updateActiveEffect(ActiveEffect effect) async => 
      await (await database).update(
        'active_effects', 
        effect.toMap(), 
        where: 'id = ?', 
        whereArgs: [effect.id]
      );
  
  Future<int> deleteActiveEffect(String id) async => 
      await (await database).delete(
        'active_effects', 
        where: 'id = ?', 
        whereArgs: [id]
      );
  
  Future<void> deleteExpiredActiveEffects() async {
    final db = await database;
    await db.delete(
      'active_effects',
      where: 'expires_at IS NOT NULL AND expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  // --- Effect Application Methods ---
  Future<void> useItemEffect(String itemId, String characterId) async {
    final effects = await getEffectsForItem(itemId);
    
    for (final effect in effects) {
      if (effect.canUse) {
        // Aufladungen reduzieren
        final updatedEffect = effect.copyWith(
          currentCharges: effect.currentCharges - 1,
          lastUsed: DateTime.now(),
        );
        await updateItemEffect(updatedEffect);
        
        // Wenn sofortiger Effekt, direkt anwenden
        if (effect.effectType == EffectType.healHitPoints) {
          final activeEffect = ActiveEffect(
            id: _uuid.v4(),
            characterId: characterId,
            itemEffectId: effect.id,
            sourceItemName: (await getItemById(itemId))?.name ?? 'Unbekanntes Item',
            effectName: effect.name,
            description: effect.description,
            effectType: effect.effectType,
            value: effect.value,
            startedAt: DateTime.now(),
            expiresAt: effect.duration == EffectDuration.instant 
                ? DateTime.now().add(const Duration(seconds: 1))
                : _calculateExpiryTime(effect.duration, effect.durationValue),
            requiresConcentration: effect.requiresConcentration,
          );
          await insertActiveEffect(activeEffect);
        } else if (effect.duration != EffectDuration.instant) {
          // Temporären Effekt aktivieren
          final updatedEffect = effect.copyWith(
            isActive: true,
            activatedAt: DateTime.now(),
            targetCharacterId: characterId,
          );
          await updateItemEffect(updatedEffect);
        }
      }
    }
  }

  DateTime? _calculateExpiryTime(EffectDuration duration, int? durationValue) {
    final now = DateTime.now();
    
    switch (duration) {
      case EffectDuration.shortRest:
        return now.add(const Duration(hours: 1));
      case EffectDuration.longRest:
        return now.add(const Duration(hours: 8));
      case EffectDuration.oneHour:
        return now.add(const Duration(hours: 1));
      case EffectDuration.eightHours:
        return now.add(const Duration(hours: 8));
      case EffectDuration.twentyFourHours:
        return now.add(const Duration(hours: 24));
      case EffectDuration.custom:
        if (durationValue != null) {
          return now.add(Duration(minutes: durationValue!));
        }
        return null;
      case EffectDuration.permanent:
      case EffectDuration.concentration:
        return null; // Kein Ablauf
      default:
        return null;
    }
  }

  Future<void> endActiveEffect(String activeEffectId) async {
    final effect = await (await database).query(
      'active_effects',
      where: 'id = ?',
      whereArgs: [activeEffectId],
    );
    
    if (effect.isNotEmpty) {
      final itemEffectId = effect.first['item_effect_id'] as String;
      
      // Item-Effect deaktivieren
      await (await database).update(
        'item_effects',
        {'is_active': 0, 'activated_at': null},
        where: 'id = ?',
        whereArgs: [itemEffectId],
      );
      
      // Aktiven Effekt entfernen
      await deleteActiveEffect(activeEffectId);
    }
  }

  Future<int> getActiveEffectsCount(String characterId) async {
    final result = await (await database).rawQuery(
      'SELECT COUNT(*) as count FROM active_effects WHERE character_id = ? AND expires_at > ?',
      [characterId, DateTime.now().toIso8601String()],
    );
    return result.first['count'] as int;
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
