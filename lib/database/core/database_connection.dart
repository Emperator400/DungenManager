import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../migrations/refactoring_migration_v2.dart';

/// Verwaltet die Datenbankverbindung und sorgt für Singleton-Pattern
class DatabaseConnection {
  static DatabaseConnection? _instance;
  static Database? _database;
  RefactoringMigrationV2? _migration;

  DatabaseConnection._();

  /// Singleton-Instanz
  static DatabaseConnection get instance {
    _instance ??= DatabaseConnection._();
    return _instance!;
  }

  // ===== TEST SUPPORT =====

  /// Initialisiert eine In-Memory-Datenbank mit dem vollständigen Schema für Tests.
  ///
  /// Nur in Tests verwenden. Ersetzt den Singleton durch eine isolierte
  /// In-Memory-Datenbank, die nach dem Test mit [resetForTesting] bereinigt wird.
  @visibleForTesting
  static Future<void> initializeForTesting() async {
    final conn = DatabaseConnection._();
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, _) async => conn._createAllTables(db),
      onOpen: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    );
    _instance = conn;
    _database = db;
  }

  /// Setzt den Singleton nach einem Test zurück.
  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _database?.close();
    _database = null;
    _instance = null;
  }
  
  /// Datenbank-Instanz
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Holt den sicheren Speicherpfad für die Datenbank in Dokumente/DungenManager/saves/
  Future<String> _getCustomDatabasePath() async {
    // Holt den "Dokumente"-Ordner des Benutzers (bzw. App-Docs auf Mobile)
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final String savesDirPath = join(documentsDir.path, 'DungenManager', 'saves');
    final Directory savesDir = Directory(savesDirPath);
    
    // Erstelle die Ordnerstruktur, falls sie noch nicht existiert
    if (!await savesDir.exists()) {
      await savesDir.create(recursive: true);
    }
    
    final String newPath = join(savesDirPath, 'dnd_helper_v2.db');
    final String oldPath = join(await getDatabasesPath(), 'dnd_helper_v2.db');
    
    final File newDbFile = File(newPath);
    final File oldDbFile = File(oldPath);
    
    // Automatischer Daten-Umzug: Falls die DB am neuen sicheren Ort fehlt, am alten aber existiert
    if (!await newDbFile.exists() && await oldDbFile.exists()) {
      debugPrint('📦 [DatabaseConnection] Migriere bestehende Datenbank an neuen, sicheren Ort...');
      await oldDbFile.copy(newPath);
      debugPrint('✅ [DatabaseConnection] Datenbank erfolgreich nach $newPath kopiert');
    }
    
    return newPath;
  }
  
  /// Initialisiert die Datenbankverbindung
  Future<Database> _initDatabase() async {
    final path = await _getCustomDatabasePath();
    debugPrint('📁 [DatabaseConnection] Datenbank-Pfad: $path');

    final db = await openDatabase(
      path,
      version: 26,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      singleInstance: true,
    );

    return db;
  }
  
  /// Erstellt die Tabellen bei der ersten Installation
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📦 Erstelle Datenbank-Tabellen...');
    
    await _createAllTables(db);
    
    debugPrint('✅ Alle Datenbank-Tabellen erstellt');
  }
  
  /// Erstellt alle Tabellen der Datenbank
  Future<void> _createAllTables(Database db) async {
    await _createCampaignsTable(db);
    await _createPlayerCharactersTable(db);
    await _createInventoryItemsTable(db);
    await _createItemsTable(db);
    await _createCreaturesTable(db);
    await _createOfficialMonstersTable(db);
    await _createOfficialSpellsTable(db);
    await _createSoundsTable(db);
    await _createWikiEntriesTable(db);
    // Session-Management Tabellen
    await _createSessionsTable(db);
    await _createScenesTable(db);
    await _createEncountersTable(db);
    await _createEncounterParticipantsTable(db);
    await _createSessionQuestProgressTable(db);
    await _createSessionCharacterTrackingTable(db);
    await _createSceneQuestStatusTable(db); // SceneQuestStatus Tabelle hinzugefügt
    await _createQuestsTable(db); // Quests Tabelle hinzugefügt
    await _createSoundScenesTable(db); // SoundScenes Tabelle
    await _createSoundSceneItemsTable(db); // SoundSceneItems Junction Table
  }
  
  /// Erstellt die wiki_entries Tabelle
  Future<void> _createWikiEntriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wiki_entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        entry_type TEXT NOT NULL DEFAULT 'Lore',
        location_data TEXT,
        tags TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        campaign_id TEXT,
        image_url TEXT,
        created_by TEXT,
        parent_id TEXT,
        child_ids TEXT NOT NULL DEFAULT '',
        is_markdown INTEGER NOT NULL DEFAULT 0,
        is_favorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wiki_entries_title ON wiki_entries(title)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wiki_entries_entry_type ON wiki_entries(entry_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wiki_entries_campaign_id ON wiki_entries(campaign_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wiki_entries_parent_id ON wiki_entries(parent_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wiki_entries_is_favorite ON wiki_entries(is_favorite)');
    
    debugPrint('✅ wiki_entries Tabelle erstellt');
  }
  
  /// Erstellt die campaigns Tabelle
  Future<void> _createCampaignsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS campaigns (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'planning',
        type TEXT NOT NULL DEFAULT 'homebrew',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        dungeon_master_id TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        last_opened_at TEXT,
        player_character_ids TEXT,
        quest_ids TEXT,
        wiki_entry_ids TEXT,
        session_ids TEXT,
        settings TEXT,
        stats TEXT,
        accent_color TEXT DEFAULT '#7c3aed',
        system TEXT,
        is_template INTEGER NOT NULL DEFAULT 0,
        template_id TEXT,
        verlaufsplan TEXT,
        verlaufs_karte_image_path TEXT,
        karte_image_path TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_campaigns_title ON campaigns(title)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_campaigns_dungeon_master ON campaigns(dungeon_master_id)');
    
    debugPrint('✅ campaigns Tabelle erstellt');
  }
  
  /// Erstellt die player_characters Tabelle
  Future<void> _createPlayerCharactersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_characters (
        id TEXT PRIMARY KEY,
        campaign_id TEXT,
        name TEXT NOT NULL,
        player_name TEXT NOT NULL,
        class_name TEXT NOT NULL,
        race_name TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        max_hp INTEGER NOT NULL DEFAULT 10,
        current_hp INTEGER NOT NULL DEFAULT 10,
        armor_class INTEGER NOT NULL DEFAULT 10,
        initiative_bonus INTEGER NOT NULL DEFAULT 0,
        image_path TEXT,
        strength INTEGER NOT NULL DEFAULT 10,
        dexterity INTEGER NOT NULL DEFAULT 10,
        constitution INTEGER NOT NULL DEFAULT 10,
        intelligence INTEGER NOT NULL DEFAULT 10,
        wisdom INTEGER NOT NULL DEFAULT 10,
        charisma INTEGER NOT NULL DEFAULT 10,
        proficient_skills TEXT,
        special_abilities TEXT,
        attacks TEXT,
        attack_list TEXT,
        inventory TEXT,
        equipment TEXT,
        size TEXT DEFAULT 'Medium',
        type TEXT DEFAULT 'Humanoid',
        subtype TEXT,
        alignment TEXT DEFAULT 'Neutral',
        description TEXT,
        gold REAL NOT NULL DEFAULT 0.0,
        silver REAL NOT NULL DEFAULT 0.0,
        copper REAL NOT NULL DEFAULT 0.0,
        source_type TEXT NOT NULL DEFAULT 'custom',
        source_id TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        version TEXT NOT NULL DEFAULT '1.0',
        proficiency_bonus INTEGER NOT NULL DEFAULT 2,
        speed INTEGER NOT NULL DEFAULT 30,
        passive_perception INTEGER NOT NULL DEFAULT 10,
        spell_slots TEXT,
        spell_save_dc INTEGER NOT NULL DEFAULT 0,
        spell_attack_bonus INTEGER NOT NULL DEFAULT 0,
        saving_throw_proficiencies TEXT DEFAULT '[]',
        hit_dice TEXT NOT NULL DEFAULT 'd8',
        hit_dice_count INTEGER NOT NULL DEFAULT 1,
        hit_dice_remaining INTEGER NOT NULL DEFAULT 1,
        player_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_campaign_id ON player_characters(campaign_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_name ON player_characters(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_level ON player_characters(level)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_class ON player_characters(class_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_race ON player_characters(race_name)');
    
    debugPrint('✅ player_characters Tabelle erstellt');
  }
  
  /// Erstellt die inventory_items Tabelle
  Future<void> _createInventoryItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_items (
        id TEXT PRIMARY KEY,
        character_id TEXT NOT NULL,
        item_id TEXT,
        name TEXT NOT NULL,
        description TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        is_equipped INTEGER NOT NULL DEFAULT 0,
        equip_slot TEXT,
        weight REAL DEFAULT 0.0,
        value REAL DEFAULT 0.0,
        rarity TEXT,
        item_type TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (character_id) REFERENCES player_characters (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_items_character_id ON inventory_items(character_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_items_name ON inventory_items(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_items_is_equipped ON inventory_items(is_equipped)');
    
    debugPrint('✅ inventory_items Tabelle erstellt');
  }
  
  /// Erstellt die items Tabelle
  Future<void> _createItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        item_type TEXT NOT NULL,
        weight REAL DEFAULT 0.0,
        cost REAL DEFAULT 0.0,
        image_url TEXT,
        damage TEXT,
        properties TEXT,
        ac_formula TEXT,
        strength_requirement INTEGER,
        stealth_disadvantage INTEGER DEFAULT 0,
        rarity TEXT,
        requires_attunement INTEGER DEFAULT 0,
        has_durability INTEGER DEFAULT 0,
        max_durability INTEGER,
        is_repairable INTEGER DEFAULT 0,
        spell_id TEXT,
        is_spell INTEGER DEFAULT 0,
        spell_level INTEGER,
        spell_school TEXT,
        is_cantrip INTEGER DEFAULT 0,
        max_casts_per_day INTEGER,
        requires_concentration INTEGER DEFAULT 0,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_custom INTEGER DEFAULT 1,
        is_favorite INTEGER DEFAULT 0,
        version TEXT DEFAULT '1.0',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_name ON items(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_item_type ON items(item_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_rarity ON items(rarity)');
    
    debugPrint('✅ items Tabelle erstellt');
  }
  
  /// Erstellt die creatures Tabelle
  Future<void> _createCreaturesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS creatures (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        max_hp INTEGER NOT NULL DEFAULT 10,
        current_hp INTEGER NOT NULL DEFAULT 10,
        armor_class INTEGER NOT NULL DEFAULT 10,
        speed TEXT NOT NULL DEFAULT '30ft',
        attacks TEXT NOT NULL DEFAULT '',
        initiative_bonus INTEGER NOT NULL DEFAULT 0,
        strength INTEGER NOT NULL DEFAULT 10,
        dexterity INTEGER NOT NULL DEFAULT 10,
        constitution INTEGER NOT NULL DEFAULT 10,
        intelligence INTEGER NOT NULL DEFAULT 10,
        wisdom INTEGER NOT NULL DEFAULT 10,
        charisma INTEGER NOT NULL DEFAULT 10,
        is_player INTEGER NOT NULL DEFAULT 0,
        inventory TEXT NOT NULL DEFAULT '[]',
        gold REAL NOT NULL DEFAULT 0.0,
        silver REAL NOT NULL DEFAULT 0.0,
        copper REAL NOT NULL DEFAULT 0.0,
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
        is_custom INTEGER NOT NULL DEFAULT 1,
        description TEXT,
        attack_list TEXT NOT NULL DEFAULT '[]',
        source_type TEXT NOT NULL DEFAULT 'custom',
        source_id TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        version TEXT NOT NULL DEFAULT '1.0',
        initiative INTEGER,
        conditions TEXT NOT NULL DEFAULT ''
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_creatures_name ON creatures(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_creatures_type ON creatures(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_creatures_source_type ON creatures(source_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_creatures_is_favorite ON creatures(is_favorite)');
    
    debugPrint('✅ creatures Tabelle erstellt');
  }
  
  /// Erstellt die official_monsters Tabelle
  Future<void> _createOfficialMonstersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS official_monsters (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        size TEXT,
        type TEXT,
        subtype TEXT,
        alignment TEXT,
        armor_class TEXT NOT NULL DEFAULT '10',
        hit_points TEXT NOT NULL DEFAULT '1',
        hit_dice TEXT NOT NULL DEFAULT '1d8',
        speed TEXT NOT NULL DEFAULT '30 ft.',
        strength INTEGER NOT NULL DEFAULT 10,
        dexterity INTEGER NOT NULL DEFAULT 10,
        constitution INTEGER NOT NULL DEFAULT 10,
        intelligence INTEGER NOT NULL DEFAULT 10,
        wisdom INTEGER NOT NULL DEFAULT 10,
        charisma INTEGER NOT NULL DEFAULT 10,
        strength_save INTEGER,
        dexterity_save INTEGER,
        constitution_save INTEGER,
        intelligence_save INTEGER,
        wisdom_save INTEGER,
        charisma_save INTEGER,
        challenge_rating TEXT NOT NULL DEFAULT '1/8',
        experience_points INTEGER NOT NULL DEFAULT 10,
        skills TEXT,
        damage_vulnerabilities TEXT,
        damage_resistances TEXT,
        damage_immunities TEXT,
        condition_immunities TEXT,
        senses TEXT NOT NULL DEFAULT 'passive Perception 10',
        languages TEXT NOT NULL DEFAULT '',
        special_abilities TEXT,
        actions TEXT,
        legendary_actions TEXT,
        description TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT 'MM',
        page INTEGER NOT NULL DEFAULT 1,
        is_custom INTEGER NOT NULL DEFAULT 0,
        version TEXT NOT NULL DEFAULT '1.0'
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monsters_name ON official_monsters(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monsters_cr ON official_monsters(challenge_rating)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monsters_type ON official_monsters(type)');
    
    debugPrint('✅ official_monsters Tabelle erstellt');
  }
  
  /// Erstellt die official_spells Tabelle
  Future<void> _createOfficialSpellsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS official_spells (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 0,
        school TEXT,
        casting_time TEXT,
        range TEXT,
        components TEXT,
        duration TEXT,
        description TEXT NOT NULL DEFAULT '',
        source TEXT NOT NULL DEFAULT 'PHB',
        page INTEGER NOT NULL DEFAULT 1,
        is_custom INTEGER NOT NULL DEFAULT 0,
        version TEXT NOT NULL DEFAULT '1.0'
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_spells_name ON official_spells(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_spells_level ON official_spells(level)');
    
    debugPrint('✅ official_spells Tabelle erstellt');
  }

  /// Erstellt die sounds Tabelle
  Future<void> _createSoundsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sounds (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        sound_type TEXT NOT NULL,
        description TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        category_id TEXT,
        duration INTEGER,
        file_size REAL,
        tags TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sounds_name ON sounds(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sounds_sound_type ON sounds(sound_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sounds_is_favorite ON sounds(is_favorite)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sounds_category_id ON sounds(category_id)');
    
    debugPrint('✅ sounds Tabelle erstellt');
  }

  /// Erstellt die sessions Tabelle
  Future<void> _createSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        id TEXT PRIMARY KEY,
        campaignId TEXT NOT NULL,
        title TEXT NOT NULL,
        inGameTimeInMinutes INTEGER NOT NULL DEFAULT 480,
        liveNotes TEXT DEFAULT '',
        sceneIds TEXT,
        activeSceneId TEXT,
        encounterIds TEXT,
        questProgressIds TEXT,
        characterTrackingIds TEXT,
        linkedSoundIds TEXT,
        ortId TEXT,
        createdAt TEXT NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        FOREIGN KEY (campaignId) REFERENCES campaigns (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_campaign_id ON sessions(campaignId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_created_at ON sessions(createdAt)');

    debugPrint('✅ sessions Tabelle erstellt');
  }

  /// Erstellt die scenes Tabelle
  Future<void> _createScenesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenes (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        scene_type TEXT NOT NULL DEFAULT 'Exploration',
        is_completed INTEGER NOT NULL DEFAULT 0,
        estimated_duration INTEGER,
        complexity TEXT,
        linked_wiki_entry_ids TEXT DEFAULT '[]',
        linked_quest_ids TEXT DEFAULT '[]',
        linked_encounter_id TEXT,
        linked_character_ids TEXT DEFAULT '[]',
        linked_sound_ids TEXT DEFAULT '[]',
        sound_volumes TEXT DEFAULT '{}',
        scene_data TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        ort_id TEXT,
        template_scene_id TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_session_id ON scenes(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_order_index ON scenes(order_index)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_scene_type ON scenes(scene_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_is_completed ON scenes(is_completed)');

    debugPrint('✅ scenes Tabelle erstellt');
  }

  /// Erstellt die encounters Tabelle
  Future<void> _createEncountersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS encounters (
        id TEXT PRIMARY KEY,
        scene_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'planning',
        participant_ids TEXT,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        FOREIGN KEY (scene_id) REFERENCES scenes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_scene_id ON encounters(scene_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_status ON encounters(status)');

    debugPrint('✅ encounters Tabelle erstellt');
  }

  /// Erstellt die encounter_participants Tabelle
  Future<void> _createEncounterParticipantsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS encounter_participants (
        id TEXT PRIMARY KEY,
        encounter_id TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'enemy',
        current_hp INTEGER NOT NULL DEFAULT 0,
        max_hp INTEGER NOT NULL DEFAULT 0,
        conditions TEXT,
        notes TEXT,
        character_id TEXT,
        FOREIGN KEY (encounter_id) REFERENCES encounters (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_encounter_id ON encounter_participants(encounter_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_type ON encounter_participants(type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_character_id ON encounter_participants(character_id)');

    debugPrint('✅ encounter_participants Tabelle erstellt');
  }

  /// Erstellt die session_quest_progress Tabelle
  Future<void> _createSessionQuestProgressTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_quest_progress (
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL,
        questId INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        progress INTEGER NOT NULL DEFAULT 0,
        maxProgress INTEGER NOT NULL DEFAULT 100,
        notes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_session_quest_progress_session_id ON session_quest_progress(sessionId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_session_quest_progress_quest_id ON session_quest_progress(questId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_session_quest_progress_status ON session_quest_progress(status)');

    debugPrint('✅ session_quest_progress Tabelle erstellt');
  }

  /// Erstellt die session_character_tracking Tabelle
  Future<void> _createSessionCharacterTrackingTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_character_tracking (
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL,
        characterId TEXT NOT NULL,
        characterName TEXT NOT NULL,
        isPresent INTEGER NOT NULL DEFAULT 1,
        currentHp INTEGER NOT NULL DEFAULT 0,
        maxHp INTEGER NOT NULL DEFAULT 0,
        tempHp INTEGER NOT NULL DEFAULT 0,
        conditions TEXT,
        notes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_session_character_tracking_session_id ON session_character_tracking(sessionId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_session_character_tracking_character_id ON session_character_tracking(characterId)');

    debugPrint('✅ session_character_tracking Tabelle erstellt');
  }

  /// Erstellt die scene_quest_status Tabelle
  Future<void> _createSceneQuestStatusTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scene_quest_status (
        id TEXT PRIMARY KEY,
        scene_id TEXT NOT NULL,
        quest_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        progress INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (scene_id) REFERENCES scenes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_scene_quest_status_scene_id ON scene_quest_status(scene_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scene_quest_status_quest_id ON scene_quest_status(quest_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scene_quest_status_status ON scene_quest_status(status)');

    debugPrint('✅ scene_quest_status Tabelle erstellt');
  }

  /// Erstellt die quests Tabelle
  Future<void> _createQuestsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS quests (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        quest_type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        campaign_id TEXT,
        location TEXT,
        recommended_level INTEGER,
        estimated_duration_hours REAL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        rewards TEXT,
        involved_npcs TEXT,
        linked_wiki_entry_ids TEXT,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_custom INTEGER NOT NULL DEFAULT 1,
        version TEXT DEFAULT '1.0',
        priority INTEGER NOT NULL DEFAULT 0,
        quest_giver_id TEXT,
        image_url TEXT,
        template_quest_id TEXT
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_quests_campaign_id ON quests(campaign_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quests_status ON quests(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quests_quest_type ON quests(quest_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quests_difficulty ON quests(difficulty)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quests_priority ON quests(priority)');

    debugPrint('✅ quests Tabelle erstellt');
  }

  /// Erstellt die sound_scenes Tabelle
  Future<void> _createSoundScenesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sound_scenes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sound_scenes_name ON sound_scenes(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sound_scenes_is_favorite ON sound_scenes(is_favorite)');

    debugPrint('✅ sound_scenes Tabelle erstellt');
  }

  /// Erstellt die sound_scene_items Tabelle (Junction Table für Sound-Zuordnung)
  Future<void> _createSoundSceneItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sound_scene_items (
        id TEXT PRIMARY KEY,
        sound_scene_id TEXT NOT NULL,
        sound_id TEXT NOT NULL,
        volume REAL NOT NULL DEFAULT 1.0,
        is_looping INTEGER NOT NULL DEFAULT 1,
        fade_in_duration REAL DEFAULT 0.0,
        fade_out_duration REAL DEFAULT 0.0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (sound_scene_id) REFERENCES sound_scenes (id) ON DELETE CASCADE,
        FOREIGN KEY (sound_id) REFERENCES sounds (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sound_scene_items_scene_id ON sound_scene_items(sound_scene_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sound_scene_items_sound_id ON sound_scene_items(sound_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sound_scene_items_sort_order ON sound_scene_items(sort_order)');

    debugPrint('✅ sound_scene_items Tabelle erstellt');
  }
  
  /// Aktualisiert das Datenbankschema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Datenbank-Upgrade von Version $oldVersion auf $newVersion...');
    
    if (oldVersion < 6 && newVersion >= 6) {
      debugPrint('🔄 Füge Bestiarum-Tabellen hinzu (v5 → v6)...');
      await _createCreaturesTable(db);
      await _createOfficialMonstersTable(db);
      await _createOfficialSpellsTable(db);
      debugPrint('✅ Bestiarum-Tabellen erstellt (Version 6)');
    }
    
    if (oldVersion < 7 && newVersion >= 7) {
      debugPrint('🔄 Füge equipment Spalte zu player_characters hinzu (v6 → v7)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
        final hasEquipment = tableInfo.any((column) => column['name'] == 'equipment');
        
        if (!hasEquipment) {
          await db.execute(
            'ALTER TABLE player_characters ADD COLUMN equipment TEXT',
          );
          debugPrint('✅ equipment Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ equipment Spalte existiert bereits');
        }
      } catch (e) {
        debugPrint('⚠️ Konnte equipment Spalte nicht hinzufügen: $e');
      }
    }
    
    if (oldVersion < 8 && newVersion >= 8) {
      debugPrint('🔄 Füge sounds Tabelle hinzu (v7 → v8)...');
      await _createSoundsTable(db);
      debugPrint('✅ sounds Tabelle erstellt (Version 8)');
    }
    
    if (oldVersion < 9 && newVersion >= 9) {
      debugPrint('🔄 Füge Session-Management Tabellen hinzu (v8 → v9)...');
      await _createSessionsTable(db);
      await _createEncountersTable(db);
      await _createEncounterParticipantsTable(db);
      await _createSessionQuestProgressTable(db);
      await _createSessionCharacterTrackingTable(db);
      debugPrint('✅ Session-Management Tabellen erstellt (Version 9)');
    }
    
    if (oldVersion < 10 && newVersion >= 10) {
      debugPrint('🔄 Füge scenes Tabelle hinzu (v9 → v10)...');
      await _createScenesTable(db);
      debugPrint('✅ scenes Tabelle erstellt (Version 10)');
    }
    
    if (oldVersion < 11 && newVersion >= 11) {
      debugPrint('🔄 Füge neue Spalten zu scenes Tabelle hinzu (v10 → v11)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(scenes)');
        final existingColumns = tableInfo.map((column) => column['name'] as String).toSet();
        
        // linked_encounter_id hinzufügen
        if (!existingColumns.contains('linked_encounter_id')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN linked_encounter_id TEXT');
          debugPrint('✅ linked_encounter_id Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ linked_encounter_id Spalte existiert bereits');
        }
        
        // linked_character_ids hinzufügen
        if (!existingColumns.contains('linked_character_ids')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN linked_character_ids TEXT DEFAULT "[]"');
          debugPrint('✅ linked_character_ids Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ linked_character_ids Spalte existiert bereits');
        }
        
        // scene_data hinzufügen
        if (!existingColumns.contains('scene_data')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN scene_data TEXT DEFAULT "{}"');
          debugPrint('✅ scene_data Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ scene_data Spalte existiert bereits');
        }
        
        debugPrint('✅ scenes Tabelle aktualisiert (Version 11)');
      } catch (e) {
        debugPrint('⚠️ Konnte scenes Spalten nicht hinzufügen: $e');
      }
    }
    
    if (oldVersion < 12 && newVersion >= 12) {
      debugPrint('🔄 Füge scene_quest_status Tabelle hinzu (v11 → v12)...');
      await _createSceneQuestStatusTable(db);
      debugPrint('✅ scene_quest_status Tabelle erstellt (Version 12)');
    }
    
    if (oldVersion < 13 && newVersion >= 13) {
      debugPrint('🔄 Füge quests Tabelle hinzu (v12 → v13)...');
      await _createQuestsTable(db);
      debugPrint('✅ quests Tabelle erstellt (Version 13)');
    }
    
    if (oldVersion < 14 && newVersion >= 14) {
      debugPrint('🔄 Füge linked_sound_ids Spalte zu scenes Tabelle hinzu (v13 → v14)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(scenes)');
        final existingColumns = tableInfo.map((column) => column['name'] as String).toSet();
        
        // linked_sound_ids hinzufügen
        if (!existingColumns.contains('linked_sound_ids')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN linked_sound_ids TEXT DEFAULT "[]"');
          debugPrint('✅ linked_sound_ids Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ linked_sound_ids Spalte existiert bereits');
        }
        
        debugPrint('✅ scenes Tabelle aktualisiert (Version 14)');
      } catch (e) {
        debugPrint('⚠️ Konnte linked_sound_ids Spalte nicht hinzufügen: $e');
      }
    }
    
    if (oldVersion < 15 && newVersion >= 15) {
      debugPrint('🔄 Füge saving_throw_proficiencies Spalte zu player_characters hinzu (v14 → v15)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
        final existingColumns = tableInfo.map((column) => column['name'] as String).toSet();
        
        // saving_throw_proficiencies hinzufügen
        if (!existingColumns.contains('saving_throw_proficiencies')) {
          await db.execute('ALTER TABLE player_characters ADD COLUMN saving_throw_proficiencies TEXT DEFAULT "[]"');
          debugPrint('✅ saving_throw_proficiencies Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ saving_throw_proficiencies Spalte existiert bereits');
        }
        
        debugPrint('✅ player_characters Tabelle aktualisiert (Version 15)');
      } catch (e) {
        debugPrint('⚠️ Konnte saving_throw_proficiencies Spalte nicht hinzufügen: $e');
      }
    }
    
    if (oldVersion < 16 && newVersion >= 16) {
      debugPrint('🔄 Füge armor_category Spalte zu items hinzu (v15 → v16)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(items)');
        final existingColumns = tableInfo.map((column) => column['name'] as String).toSet();
        
        // armor_category hinzufügen
        if (!existingColumns.contains('armor_category')) {
          await db.execute('ALTER TABLE items ADD COLUMN armor_category TEXT');
          debugPrint('✅ armor_category Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ armor_category Spalte existiert bereits');
        }
        
        debugPrint('✅ items Tabelle aktualisiert (Version 16)');
      } catch (e) {
        debugPrint('⚠️ Konnte armor_category Spalte nicht hinzufügen: $e');
      }
    }
    
    if (oldVersion < 17 && newVersion >= 17) {
      debugPrint('🔄 Migriere encounters und encounter_participants zu snake_case (v16 → v17)...');
      try {
        // Prüfe ob encounters Tabelle das alte Schema hat
        final encountersInfo = await db.rawQuery('PRAGMA table_info(encounters)');
        final encounterColumns = encountersInfo.map((column) => column['name'] as String).toSet();
        
        // Wenn sessionId existiert, müssen wir migrieren
        if (encounterColumns.contains('sessionId')) {
          debugPrint('🔄 Migriere encounters Tabelle...');
          
          // 1. Erstelle neue Tabelle
          await db.execute('''
            CREATE TABLE IF NOT EXISTS encounters_new (
              id TEXT PRIMARY KEY,
              scene_id TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT,
              status TEXT NOT NULL DEFAULT 'planning',
              participant_ids TEXT,
              created_at TEXT NOT NULL,
              started_at TEXT,
              completed_at TEXT,
              FOREIGN KEY (scene_id) REFERENCES scenes (id) ON DELETE CASCADE
            )
          ''');
          
          // 2. Kopiere Daten (mit Fallback für sessionId -> scene_id)
          await db.execute('''
            INSERT INTO encounters_new (id, scene_id, title, description, status, participant_ids, created_at, started_at, completed_at)
            SELECT id, COALESCE(scene_id, sessionId), title, description, status, COALESCE(participant_ids, participantIds), 
                   COALESCE(created_at, createdAt), COALESCE(started_at, startedAt), COALESCE(completed_at, completedAt)
            FROM encounters
          ''');
          
          // 3. Lösche alte Tabelle
          await db.execute('DROP TABLE encounters');
          
          // 4. Benenne neue Tabelle um
          await db.execute('ALTER TABLE encounters_new RENAME TO encounters');
          
          // 5. Erstelle Indizes
          await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_scene_id ON encounters(scene_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_status ON encounters(status)');
          
          debugPrint('✅ encounters Tabelle migriert');
        }
        
        // Prüfe ob encounter_participants Tabelle das alte Schema hat
        final participantsInfo = await db.rawQuery('PRAGMA table_info(encounter_participants)');
        final participantColumns = participantsInfo.map((column) => column['name'] as String).toSet();
        
        // Wenn encounterId existiert, müssen wir migrieren
        if (participantColumns.contains('encounterId')) {
          debugPrint('🔄 Migriere encounter_participants Tabelle...');
          
          // 1. Erstelle neue Tabelle
          await db.execute('''
            CREATE TABLE IF NOT EXISTS encounter_participants_new (
              id TEXT PRIMARY KEY,
              encounter_id TEXT NOT NULL,
              name TEXT NOT NULL,
              type TEXT NOT NULL DEFAULT 'enemy',
              current_hp INTEGER NOT NULL DEFAULT 0,
              max_hp INTEGER NOT NULL DEFAULT 0,
              conditions TEXT,
              notes TEXT,
              character_id TEXT,
              FOREIGN KEY (encounter_id) REFERENCES encounters (id) ON DELETE CASCADE
            )
          ''');
          
          // 2. Kopiere Daten
          await db.execute('''
            INSERT INTO encounter_participants_new (id, encounter_id, name, type, current_hp, max_hp, conditions, notes, character_id)
            SELECT id, COALESCE(encounter_id, encounterId), name, type, 
                   COALESCE(current_hp, currentHp), COALESCE(max_hp, maxHp), 
                   conditions, notes, COALESCE(character_id, characterId)
            FROM encounter_participants
          ''');
          
          // 3. Lösche alte Tabelle
          await db.execute('DROP TABLE encounter_participants');
          
          // 4. Benenne neue Tabelle um
          await db.execute('ALTER TABLE encounter_participants_new RENAME TO encounter_participants');
          
          // 5. Erstelle Indizes
          await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_encounter_id ON encounter_participants(encounter_id)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_type ON encounter_participants(type)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_character_id ON encounter_participants(character_id)');
          
          debugPrint('✅ encounter_participants Tabelle migriert');
        }
        
        debugPrint('✅ Encounter-Tabellen migriert (Version 17)');
      } catch (e) {
        debugPrint('⚠️ Konnte Encounter-Tabellen nicht migrieren: $e');
      }
    }

    if (oldVersion < 18 && newVersion >= 18) {
      debugPrint('🔄 Füge sound_volumes Spalte zu scenes Tabelle hinzu (v17 → v18)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(scenes)');
        final existingColumns = tableInfo.map((column) => column['name'] as String).toSet();

        if (!existingColumns.contains('sound_volumes')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN sound_volumes TEXT DEFAULT "{}"');
          debugPrint('✅ sound_volumes Spalte hinzugefügt');
        } else {
          debugPrint('ℹ️ sound_volumes Spalte existiert bereits');
        }

        debugPrint('✅ scenes Tabelle aktualisiert (Version 18)');
      } catch (e) {
        debugPrint('⚠️ Konnte sound_volumes Spalte nicht hinzufügen: $e');
      }
    }

    if (oldVersion < 19 && newVersion >= 19) {
      debugPrint('🔄 Füge Wiki- und Verbindungs-Spalten zu orte hinzu (v18 → v19)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(orte)');
        final existingColumns = tableInfo.map((column) => column['name'] as String).toSet();

        if (!existingColumns.contains('linked_wiki_entry_ids')) {
          await db.execute("ALTER TABLE orte ADD COLUMN linked_wiki_entry_ids TEXT");
          debugPrint('✅ linked_wiki_entry_ids Spalte hinzugefügt');
        }
        if (!existingColumns.contains('connected_ort_ids')) {
          await db.execute("ALTER TABLE orte ADD COLUMN connected_ort_ids TEXT");
          debugPrint('✅ connected_ort_ids Spalte hinzugefügt');
        }
        debugPrint('✅ orte Tabelle aktualisiert (Version 19)');
      } catch (e) {
        debugPrint('⚠️ Konnte orte Spalten nicht hinzufügen: $e');
      }
    }

    if (oldVersion < 20 && newVersion >= 20) {
      debugPrint('🔄 Mache session_id in scenes nullable und füge ort_id hinzu (v19 → v20)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(scenes)');
        final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
        final hasOrtId = existingColumns.contains('ort_id');

        await db.execute('ALTER TABLE scenes RENAME TO scenes_old');
        await db.execute('''
          CREATE TABLE scenes (
            id TEXT PRIMARY KEY,
            session_id TEXT,
            order_index INTEGER NOT NULL DEFAULT 0,
            name TEXT NOT NULL,
            description TEXT DEFAULT '',
            scene_type TEXT NOT NULL DEFAULT 'Exploration',
            is_completed INTEGER NOT NULL DEFAULT 0,
            estimated_duration INTEGER,
            complexity TEXT,
            linked_wiki_entry_ids TEXT DEFAULT '[]',
            linked_quest_ids TEXT DEFAULT '[]',
            linked_encounter_id TEXT,
            linked_character_ids TEXT DEFAULT '[]',
            linked_sound_ids TEXT DEFAULT '[]',
            sound_volumes TEXT DEFAULT '{}',
            scene_data TEXT DEFAULT '{}',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            ort_id TEXT,
            FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
          )
        ''');

        final cols = 'id, session_id, order_index, name, description, scene_type, is_completed, '
            'estimated_duration, complexity, linked_wiki_entry_ids, linked_quest_ids, '
            'linked_encounter_id, linked_character_ids, linked_sound_ids, sound_volumes, '
            'scene_data, created_at, updated_at';
        if (hasOrtId) {
          await db.execute('INSERT INTO scenes ($cols, ort_id) SELECT $cols, ort_id FROM scenes_old');
        } else {
          await db.execute('INSERT INTO scenes ($cols) SELECT $cols FROM scenes_old');
        }

        await db.execute('DROP TABLE scenes_old');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_session_id ON scenes(session_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_order_index ON scenes(order_index)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_scene_type ON scenes(scene_type)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_is_completed ON scenes(is_completed)');
        debugPrint('✅ scenes Tabelle migriert (Version 20)');
      } catch (e) {
        debugPrint('⚠️ Konnte scenes Tabelle nicht migrieren: $e');
      }
    }

    if (oldVersion < 21 && newVersion >= 21) {
      debugPrint('🔄 Füge ortId Spalte zu sessions hinzu (v20 → v21)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(sessions)');
        final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
        if (!existingColumns.contains('ortId')) {
          await db.execute('ALTER TABLE sessions ADD COLUMN ortId TEXT');
          debugPrint('✅ ortId Spalte zu sessions hinzugefügt');
        }
        debugPrint('✅ sessions Tabelle aktualisiert (Version 21)');
      } catch (e) {
        debugPrint('⚠️ Konnte ortId zu sessions nicht hinzufügen: $e');
      }
    }

    if (oldVersion < 22 && newVersion >= 22) {
      debugPrint('🔄 Füge verlaufsplan Spalte zu campaigns hinzu (v21 → v22)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(campaigns)');
        final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
        if (!existingColumns.contains('verlaufsplan')) {
          await db.execute('ALTER TABLE campaigns ADD COLUMN verlaufsplan TEXT');
          debugPrint('✅ verlaufsplan Spalte zu campaigns hinzugefügt');
        }
        debugPrint('✅ campaigns Tabelle aktualisiert (Version 22)');
      } catch (e) {
        debugPrint('⚠️ Konnte verlaufsplan zu campaigns nicht hinzufügen: $e');
      }
    }

    if (oldVersion < 23 && newVersion >= 23) {
      debugPrint('🔄 Füge fehlende Spalten zu campaigns hinzu (v22 → v23)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(campaigns)');
        final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();
        if (!existingColumns.contains('last_opened_at')) {
          await db.execute('ALTER TABLE campaigns ADD COLUMN last_opened_at TEXT');
        }
        if (!existingColumns.contains('accent_color')) {
          await db.execute("ALTER TABLE campaigns ADD COLUMN accent_color TEXT DEFAULT '#7c3aed'");
        }
        if (!existingColumns.contains('system')) {
          await db.execute('ALTER TABLE campaigns ADD COLUMN system TEXT');
        }
        if (!existingColumns.contains('is_template')) {
          await db.execute('ALTER TABLE campaigns ADD COLUMN is_template INTEGER NOT NULL DEFAULT 0');
        }
        if (!existingColumns.contains('template_id')) {
          await db.execute('ALTER TABLE campaigns ADD COLUMN template_id TEXT');
        }
        if (!existingColumns.contains('verlaufs_karte_image_path')) {
          await db.execute('ALTER TABLE campaigns ADD COLUMN verlaufs_karte_image_path TEXT');
        }
        if (!existingColumns.contains('karte_image_path')) {
          await db.execute('ALTER TABLE campaigns ADD COLUMN karte_image_path TEXT');
        }
        debugPrint('✅ campaigns Tabelle aktualisiert (Version 23)');
      } catch (e) {
        debugPrint('⚠️ Konnte campaigns Spalten nicht hinzufügen: $e');
      }
    }

    if (oldVersion < 24 && newVersion >= 24) {
      debugPrint('🔄 Mache campaign_id in player_characters nullable (v23 → v24)...');
      try {
        // SQLite kann NOT NULL nicht direkt entfernen → Tabelle neu erstellen
        await db.execute('''
          CREATE TABLE IF NOT EXISTS player_characters_new (
            id TEXT PRIMARY KEY,
            campaign_id TEXT,
            name TEXT NOT NULL,
            player_name TEXT NOT NULL,
            class_name TEXT NOT NULL,
            race_name TEXT NOT NULL,
            level INTEGER NOT NULL DEFAULT 1,
            max_hp INTEGER NOT NULL DEFAULT 10,
            current_hp INTEGER NOT NULL DEFAULT 10,
            armor_class INTEGER NOT NULL DEFAULT 10,
            initiative_bonus INTEGER NOT NULL DEFAULT 0,
            image_path TEXT,
            strength INTEGER NOT NULL DEFAULT 10,
            dexterity INTEGER NOT NULL DEFAULT 10,
            constitution INTEGER NOT NULL DEFAULT 10,
            intelligence INTEGER NOT NULL DEFAULT 10,
            wisdom INTEGER NOT NULL DEFAULT 10,
            charisma INTEGER NOT NULL DEFAULT 10,
            proficient_skills TEXT,
            special_abilities TEXT,
            attacks TEXT,
            attack_list TEXT,
            inventory TEXT,
            equipment TEXT,
            size TEXT DEFAULT 'Medium',
            type TEXT DEFAULT 'Humanoid',
            subtype TEXT,
            alignment TEXT DEFAULT 'Neutral',
            description TEXT,
            gold REAL NOT NULL DEFAULT 0.0,
            silver REAL NOT NULL DEFAULT 0.0,
            copper REAL NOT NULL DEFAULT 0.0,
            source_type TEXT NOT NULL DEFAULT 'custom',
            source_id TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            version TEXT NOT NULL DEFAULT '1.0',
            proficiency_bonus INTEGER NOT NULL DEFAULT 2,
            speed INTEGER NOT NULL DEFAULT 30,
            passive_perception INTEGER NOT NULL DEFAULT 10,
            spell_slots TEXT,
            spell_save_dc INTEGER NOT NULL DEFAULT 0,
            spell_attack_bonus INTEGER NOT NULL DEFAULT 0,
            saving_throw_proficiencies TEXT DEFAULT '[]',
            hit_dice TEXT NOT NULL DEFAULT 'd8',
            hit_dice_count INTEGER NOT NULL DEFAULT 1,
            hit_dice_remaining INTEGER NOT NULL DEFAULT 1,
            player_id TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Prüfe welche Spalten in der alten Tabelle existieren
        final oldCols = (await db.rawQuery('PRAGMA table_info(player_characters)'))
            .map((c) => c['name'] as String)
            .toSet();

        final baseCols = 'id, campaign_id, name, player_name, class_name, race_name, level, '
            'max_hp, current_hp, armor_class, initiative_bonus, image_path, strength, dexterity, '
            'constitution, intelligence, wisdom, charisma, proficient_skills, special_abilities, '
            'attacks, attack_list, inventory, equipment, size, type, subtype, alignment, description, '
            'gold, silver, copper, source_type, source_id, is_favorite, version, proficiency_bonus, '
            'speed, passive_perception, spell_slots, spell_save_dc, spell_attack_bonus, '
            'saving_throw_proficiencies, hit_dice, hit_dice_count, hit_dice_remaining, created_at, updated_at';

        if (oldCols.contains('player_id')) {
          await db.execute(
            'INSERT INTO player_characters_new ($baseCols, player_id) '
            'SELECT $baseCols, player_id FROM player_characters',
          );
        } else {
          await db.execute(
            'INSERT INTO player_characters_new ($baseCols) '
            'SELECT $baseCols FROM player_characters',
          );
        }

        await db.execute('DROP TABLE player_characters');
        await db.execute('ALTER TABLE player_characters_new RENAME TO player_characters');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_campaign_id ON player_characters(campaign_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_name ON player_characters(name)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_level ON player_characters(level)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_class ON player_characters(class_name)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_race ON player_characters(race_name)');
        debugPrint('✅ player_characters Tabelle aktualisiert (Version 24)');
      } catch (e) {
        debugPrint('⚠️ Konnte player_characters nicht migrieren: $e');
      }
    }

    if (oldVersion < 25 && newVersion >= 25) {
      // Migration v20 renamed `scenes` → `scenes_old` then dropped it.
      // SQLite 3.26+ auto-updates child FK references on rename, so
      // encounters.scene_id FK got rewritten to reference `scenes_old`.
      // After `scenes_old` was dropped, every INSERT into encounters fails.
      // Fix: rebuild encounters with the FK pointing to `scenes`.
      try {
        await db.execute('PRAGMA foreign_keys = OFF');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS encounters_repaired (
            id TEXT PRIMARY KEY,
            scene_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL DEFAULT 'planning',
            participant_ids TEXT,
            created_at TEXT NOT NULL,
            started_at TEXT,
            completed_at TEXT,
            FOREIGN KEY (scene_id) REFERENCES scenes (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('INSERT INTO encounters_repaired SELECT * FROM encounters');
        await db.execute('DROP TABLE encounters');
        await db.execute('ALTER TABLE encounters_repaired RENAME TO encounters');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_scene_id ON encounters(scene_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_status ON encounters(status)');

        await db.execute('PRAGMA foreign_keys = ON');
        debugPrint('✅ encounters FK-Referenz repariert (Version 25)');
      } catch (e) {
        await db.execute('PRAGMA foreign_keys = ON');
        debugPrint('⚠️ Konnte encounters nicht reparieren: $e');
      }
    }

    if (oldVersion < 26 && newVersion >= 26) {
      try {
        final ortCols   = (await db.rawQuery('PRAGMA table_info(orte)')).map((c) => c['name'] as String).toSet();
        final sceneCols = (await db.rawQuery('PRAGMA table_info(scenes)')).map((c) => c['name'] as String).toSet();
        final questCols = (await db.rawQuery('PRAGMA table_info(quests)')).map((c) => c['name'] as String).toSet();

        if (!ortCols.contains('is_hidden')) {
          await db.execute('ALTER TABLE orte ADD COLUMN is_hidden INTEGER NOT NULL DEFAULT 0');
        }
        if (!sceneCols.contains('template_scene_id')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN template_scene_id TEXT');
        }
        if (!questCols.contains('template_quest_id')) {
          await db.execute('ALTER TABLE quests ADD COLUMN template_quest_id TEXT');
        }
        debugPrint('✅ Template-Sync-Spalten hinzugefügt (Version 26)');
      } catch (e) {
        debugPrint('⚠️ Migration v26 fehlgeschlagen: $e');
      }
    }
  }

  /// Schließt die Datenbankverbindung
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  /// Setzt die Datenbank zurück
  Future<void> reset() async {
    await close();
    final path = await _getCustomDatabasePath();
    await deleteDatabase(path);
    _database = await _initDatabase();
    debugPrint('✅ Datenbank wurde zurückgesetzt');
  }
  
  /// Löscht die Datenbank-Datei
  Future<void> deleteDatabaseFile() async {
    await close();
    final path = await _getCustomDatabasePath();
    await deleteDatabase(path);
    debugPrint('✅ Datenbank-Datei wurde gelöscht');
  }
  
  /// Führt die Refactoring-Migration manuell aus
  Future<MigrationResult> runRefactoringMigration() async {
    if (_migration == null) {
      _migration = RefactoringMigrationV2(this);
    }
    return await _migration!.migrate();
  }
  
  /// Prüft ob die Refactoring-Migration bereits angewendet wurde
  Future<bool> isRefactoringMigrationApplied() async {
    if (_migration == null) {
      _migration = RefactoringMigrationV2(this);
    }
    return await _migration!.isMigrationApplied();
  }
}