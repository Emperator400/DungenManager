import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../migrations/refactoring_migration_v2.dart';
import '../migrations/database_migration.dart';

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
  
  /// Datenbank-Instanz
  Future<Database> get database async {
    print('🔌 [DatabaseConnection] database getter aufgerufen');
    if (_database != null) {
      print('✅ [DatabaseConnection] Datenbank bereits initialisiert');
      return _database!;
    }
    print('⏳ [DatabaseConnection] Initialisiere Datenbank...');
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Initialisiert die Datenbankverbindung
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'dnd_helper_v2.db');
    print('📁 [DatabaseConnection] Datenbank-Pfad: $path');
    
    _migration = RefactoringMigrationV2(this);
    
    final db = await openDatabase(
      path,
      version: 11,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      singleInstance: true,
    );
    
    // TEMPORÄR DEAKTIVIERT - Verursacht Freeze
    print('⚠️ [DatabaseConnection] Migrationen vorübergehend deaktiviert');
    // await _runDatabaseMigrations(db);
    
    return db;
  }
  
  /// Erstellt die Tabellen bei der ersten Installation
  Future<void> _onCreate(Database db, int version) async {
    print('📦 Erstelle Datenbank-Tabellen...');
    
    await _createAllTables(db);
    
    print('✅ Alle Datenbank-Tabellen erstellt');
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
    
    print('✅ wiki_entries Tabelle erstellt');
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
        player_character_ids TEXT,
        quest_ids TEXT,
        wiki_entry_ids TEXT,
        session_ids TEXT,
        settings TEXT,
        stats TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_campaigns_title ON campaigns(title)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_campaigns_dungeon_master ON campaigns(dungeon_master_id)');
    
    print('✅ campaigns Tabelle erstellt');
  }
  
  /// Erstellt die player_characters Tabelle
  Future<void> _createPlayerCharactersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_characters (
        id TEXT PRIMARY KEY,
        campaign_id TEXT NOT NULL,
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
        size TEXT NOT NULL DEFAULT 'Medium',
        type TEXT NOT NULL DEFAULT 'Humanoid',
        subtype TEXT,
        alignment TEXT NOT NULL DEFAULT 'Neutral',
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (campaign_id) REFERENCES campaigns (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_campaign_id ON player_characters(campaign_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_name ON player_characters(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_level ON player_characters(level)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_class ON player_characters(class_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_player_characters_race ON player_characters(race_name)');
    
    print('✅ player_characters Tabelle erstellt');
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
    
    print('✅ inventory_items Tabelle erstellt');
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
    
    print('✅ items Tabelle erstellt');
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
    
    print('✅ creatures Tabelle erstellt');
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
    
    print('✅ official_monsters Tabelle erstellt');
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
    
    print('✅ official_spells Tabelle erstellt');
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
    
    print('✅ sounds Tabelle erstellt');
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
        createdAt TEXT NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        FOREIGN KEY (campaignId) REFERENCES campaigns (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_campaign_id ON sessions(campaignId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sessions_created_at ON sessions(createdAt)');

    print('✅ sessions Tabelle erstellt');
  }

  /// Erstellt die scenes Tabelle
  Future<void> _createScenesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scenes (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
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
        scene_data TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_session_id ON scenes(session_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_order_index ON scenes(order_index)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_scene_type ON scenes(scene_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_scenes_is_completed ON scenes(is_completed)');

    print('✅ scenes Tabelle erstellt');
  }

  /// Erstellt die encounters Tabelle
  Future<void> _createEncountersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS encounters (
        id TEXT PRIMARY KEY,
        sessionId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT NOT NULL DEFAULT 'planning',
        participantIds TEXT,
        createdAt TEXT NOT NULL,
        startedAt TEXT,
        completedAt TEXT,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_session_id ON encounters(sessionId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounters_status ON encounters(status)');

    print('✅ encounters Tabelle erstellt');
  }

  /// Erstellt die encounter_participants Tabelle
  Future<void> _createEncounterParticipantsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS encounter_participants (
        id TEXT PRIMARY KEY,
        encounterId TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'enemy',
        currentHp INTEGER NOT NULL DEFAULT 0,
        maxHp INTEGER NOT NULL DEFAULT 0,
        conditions TEXT,
        notes TEXT,
        characterId TEXT,
        FOREIGN KEY (encounterId) REFERENCES encounters (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_encounter_id ON encounter_participants(encounterId)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_encounter_participants_type ON encounter_participants(type)');

    print('✅ encounter_participants Tabelle erstellt');
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

    print('✅ session_quest_progress Tabelle erstellt');
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

    print('✅ session_character_tracking Tabelle erstellt');
  }
  
  /// Aktualisiert das Datenbankschema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Datenbank-Upgrade von Version $oldVersion auf $newVersion...');
    
    if (oldVersion < 6 && newVersion >= 6) {
      print('🔄 Füge Bestiarum-Tabellen hinzu (v5 → v6)...');
      await _createCreaturesTable(db);
      await _createOfficialMonstersTable(db);
      await _createOfficialSpellsTable(db);
      print('✅ Bestiarum-Tabellen erstellt (Version 6)');
    }
    
    if (oldVersion < 7 && newVersion >= 7) {
      print('🔄 Füge equipment Spalte zu player_characters hinzu (v6 → v7)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
        final hasEquipment = tableInfo.any((column) => column['name'] == 'equipment');
        
        if (!hasEquipment) {
          await db.execute(
            'ALTER TABLE player_characters ADD COLUMN equipment TEXT',
          );
          print('✅ equipment Spalte hinzugefügt');
        } else {
          print('ℹ️ equipment Spalte existiert bereits');
        }
      } catch (e) {
        print('⚠️ Konnte equipment Spalte nicht hinzufügen: $e');
      }
    }
    
    if (oldVersion < 8 && newVersion >= 8) {
      print('🔄 Füge sounds Tabelle hinzu (v7 → v8)...');
      await _createSoundsTable(db);
      print('✅ sounds Tabelle erstellt (Version 8)');
    }
    
    if (oldVersion < 9 && newVersion >= 9) {
      print('🔄 Füge Session-Management Tabellen hinzu (v8 → v9)...');
      await _createSessionsTable(db);
      await _createEncountersTable(db);
      await _createEncounterParticipantsTable(db);
      await _createSessionQuestProgressTable(db);
      await _createSessionCharacterTrackingTable(db);
      print('✅ Session-Management Tabellen erstellt (Version 9)');
    }
    
    if (oldVersion < 10 && newVersion >= 10) {
      print('🔄 Füge scenes Tabelle hinzu (v9 → v10)...');
      await _createScenesTable(db);
      print('✅ scenes Tabelle erstellt (Version 10)');
    }
    
    if (oldVersion < 11 && newVersion >= 11) {
      print('🔄 Füge neue Spalten zu scenes Tabelle hinzu (v10 → v11)...');
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(scenes)');
        final existingColumns = tableInfo.map((column) => column['name'] as String).toSet();
        
        // linked_encounter_id hinzufügen
        if (!existingColumns.contains('linked_encounter_id')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN linked_encounter_id TEXT');
          print('✅ linked_encounter_id Spalte hinzugefügt');
        } else {
          print('ℹ️ linked_encounter_id Spalte existiert bereits');
        }
        
        // linked_character_ids hinzufügen
        if (!existingColumns.contains('linked_character_ids')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN linked_character_ids TEXT DEFAULT "[]"');
          print('✅ linked_character_ids Spalte hinzugefügt');
        } else {
          print('ℹ️ linked_character_ids Spalte existiert bereits');
        }
        
        // scene_data hinzufügen
        if (!existingColumns.contains('scene_data')) {
          await db.execute('ALTER TABLE scenes ADD COLUMN scene_data TEXT DEFAULT "{}"');
          print('✅ scene_data Spalte hinzugefügt');
        } else {
          print('ℹ️ scene_data Spalte existiert bereits');
        }
        
        print('✅ scenes Tabelle aktualisiert (Version 11)');
      } catch (e) {
        print('⚠️ Konnte scenes Spalten nicht hinzufügen: $e');
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
    final path = join(await getDatabasesPath(), 'dnd_helper_v2.db');
    await deleteDatabase(path);
    _database = await _initDatabase();
    print('✅ Datenbank wurde zurückgesetzt');
  }
  
  /// Führt Datenbank-Migrationen aus
  Future<void> _runDatabaseMigrations(Database db) async {
    try {
      final migration = DatabaseMigration(this);
      await migration.runMigrations();
      print('✅ Datenbank-Migrationen erfolgreich ausgeführt');
    } catch (e) {
      print('⚠️ Fehler bei Datenbank-Migrationen: $e');
    }
  }
  
  /// Löscht die Datenbank-Datei
  Future<void> deleteDatabaseFile() async {
    await close();
    final path = join(await getDatabasesPath(), 'dnd_helper_v2.db');
    await deleteDatabase(path);
    print('✅ Datenbank-Datei wurde gelöscht');
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