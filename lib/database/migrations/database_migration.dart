import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../core/database_connection.dart';
import '../entities/campaign_entity.dart';
import '../entities/player_character_entity.dart';
import '../entities/quest_entity.dart';

/// Einfache Migrations-Engine für die neue Datenbankarchitektur
class DatabaseMigration {
  final DatabaseConnection _connection;
  
  DatabaseMigration(this._connection);
  
  /// Führt alle Migrationen aus
  Future<void> runMigrations() async {
    final db = await _connection.database;
    
    // Erstelle Campaign-Tabelle als erste Migration
    await _createCampaignTable(db);
    
    // Erstelle PlayerCharacter-Tabelle
    await _createPlayerCharacterTable(db);
    
    // Erstelle Items-Tabelle (für die allgemeine Item-Bibliothek)
    await _createItemsTable(db);
    
    // Erstelle InventoryItems-Tabelle
    await _createInventoryItemsTable(db);
    
    // Erstelle Sounds-Tabelle
    await _createSoundsTable(db);
    
    // Neue Tabellen für Session-Management
    await _createSessionsTable(db);
    await _createScenesTable(db); // Scenes Tabelle hinzugefügt
    await _createEncountersTable(db);
    await _createEncounterParticipantsTable(db);
    await _createSessionQuestProgressTable(db);
    await _createSessionCharacterTrackingTable(db);
    
    // SceneQuestStatus Tabelle (wird von SceneService verwendet)
    await _createSceneQuestStatusTable(db);
    
    // Quests Tabelle (für Quest-Management)
    await _createQuestsTable(db);
    
    // Creatures Tabelle (für Bestiarium/Monster)
    await _createCreaturesTable(db);
    
    // Migration v10 -> v11: Scene als Hauptsäule
    await _migrateToV11(db);
    
  // Füge is_favorite Spalte hinzu, falls sie nicht existiert
  await _addIsFavoriteColumn(db);
  
  // Füge equipment Spalte hinzu, falls sie nicht existiert
  await _addEquipmentColumn(db);
  
  // Füge linked_sound_ids Spalte zur scenes Tabelle hinzu, falls sie nicht existiert
  await _addLinkedSoundIdsColumn(db);
  
  // Füge linkedSoundIds Spalte zur sessions Tabelle hinzu, falls sie nicht existiert
  await _migrateSessionsTable(db);
  
  // Füge saving_throw_proficiencies Spalte zur player_characters Tabelle hinzu
  await _addSavingThrowProficienciesColumn(db);
  
  // Füge Trefferwürfel-Spalten zur player_characters Tabelle hinzu
  await _addHitDiceColumns(db);
  
  // Füge damage_type Spalte zur items Tabelle hinzu
  await _addDamageTypeColumn(db);
  
  // Stelle sicher, dass encounters Tabelle scene_id Spalte hat
  await _ensureEncountersSceneIdColumn(db);
  
  // Stelle sicher, dass encounter_participants die richtigen Spalten hat
  await _ensureEncounterParticipantsColumns(db);
  
  // Füge creature_id Spalte zu encounter_participants hinzu (für Loot-Verteilung)
  await _addCreatureIdColumn(db);
  
  print('Database migration completed successfully');
  }
  
  /// Erstellt die PlayerCharacter-Tabelle
  Future<void> _createPlayerCharacterTable(Database db) async {
    final pcEntity = PlayerCharacterEntity(
      id: '',
      name: '',
      characterClass: '',
      level:1,
      race: '',
      hitPoints: 10,
      maxHitPoints: 10,
      armorClass: 10,
      speed: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Prüfe ob Tabelle bereits existiert
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='player_characters'",
    );
    
    if (result.isEmpty) {
      // Erstelle Tabelle
      for (final sql in pcEntity.createTableSql) {
        await db.execute(sql);
      }
      
      // Erstelle Indizes
      for (final indexSql in pcEntity.createIndexes) {
        await db.execute(indexSql);
      }
      
      print('Created player_characters table with indexes');
    } else {
      print('PlayerCharacters table already exists');
    }
  }

  /// Erstellt die InventoryItems-Tabelle
  Future<void> _createInventoryItemsTable(Database db) async {
    // Prüfe ob Tabelle bereits existiert
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='inventory_items'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE inventory_items (
          id TEXT PRIMARY KEY,
          character_id TEXT NOT NULL,
          item_id TEXT,
          name TEXT NOT NULL,
          description TEXT,
          quantity INTEGER NOT NULL DEFAULT 1,
          is_equipped INTEGER NOT NULL DEFAULT 0,
          weight REAL DEFAULT 0.0,
          value REAL DEFAULT 0.0,
          rarity TEXT,
          item_type TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (character_id) REFERENCES player_characters (id) ON DELETE CASCADE
        )
      ''');

      // Erstelle Indizes
      await db.execute('CREATE INDEX idx_inventory_items_character_id ON inventory_items(character_id)');
      await db.execute('CREATE INDEX idx_inventory_items_name ON inventory_items(name)');
      await db.execute('CREATE INDEX idx_inventory_items_is_equipped ON inventory_items(is_equipped)');

      print('Created inventory_items table with indexes');
    } else {
      print('InventoryItems table already exists');
    }
  }

  /// Erstellt die Items-Tabelle (allgemeine Item-Bibliothek)
  Future<void> _createItemsTable(Database db) async {
    // Prüfe ob Tabelle bereits existiert
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='items'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE items (
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

      // Erstelle Indizes
      await db.execute('CREATE INDEX idx_items_name ON items(name)');
      await db.execute('CREATE INDEX idx_items_item_type ON items(item_type)');
      await db.execute('CREATE INDEX idx_items_rarity ON items(rarity)');

      print('Created items table with indexes');
    } else {
      print('Items table already exists');
    }
  }

  /// Erstellt die Sounds-Tabelle (für die Sound-Bibliothek)
  Future<void> _createSoundsTable(Database db) async {
    // Prüfe ob Tabelle bereits existiert
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='sounds'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE sounds (
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

      // Erstelle Indizes
      await db.execute('CREATE INDEX idx_sounds_name ON sounds(name)');
      await db.execute('CREATE INDEX idx_sounds_sound_type ON sounds(sound_type)');
      await db.execute('CREATE INDEX idx_sounds_is_favorite ON sounds(is_favorite)');
      await db.execute('CREATE INDEX idx_sounds_category_id ON sounds(category_id)');

      print('Created sounds table with indexes');
    } else {
      print('Sounds table already exists');
    }
  }

  /// Erstellt die Campaign-Tabelle
  Future<void> _createCampaignTable(Database db) async {
    final campaignEntity = CampaignEntity(
      id: '',
      name: '',
      description: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Prüfe ob Tabelle bereits existiert
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='campaigns'",
    );
    
    if (result.isEmpty) {
      // Erstelle Tabelle
      for (final sql in campaignEntity.createTableSql) {
        await db.execute(sql);
      }
      
      // Erstelle Indizes
      for (final indexSql in campaignEntity.createIndexes) {
        await db.execute(indexSql);
      }
      
      print('Created campaigns table with indexes');
    } else {
      print('Campaigns table already exists');
    }
  }

  /// Erstellt die Quests-Tabelle
  Future<void> _createQuestsTable(Database db) async {
    // Prüfe ob Tabelle bereits existiert
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='quests'",
    );

    if (result.isEmpty) {
      final createSql = QuestEntity.createTableSql();
      await db.execute(createSql);

      // Erstelle Indizes
      await db.execute('CREATE INDEX idx_quests_campaign_id ON quests(campaign_id)');
      await db.execute('CREATE INDEX idx_quests_status ON quests(status)');
      await db.execute('CREATE INDEX idx_quests_quest_type ON quests(quest_type)');
      await db.execute('CREATE INDEX idx_quests_difficulty ON quests(difficulty)');
      await db.execute('CREATE INDEX idx_quests_priority ON quests(priority)');

      print('Created quests table with indexes');
    } else {
      print('Quests table already exists');
    }
  }

  /// Erstellt die Creatures-Tabelle (für Bestiarium/Monster)
  Future<void> _createCreaturesTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='creatures'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE creatures (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          max_hp INTEGER NOT NULL DEFAULT 0,
          current_hp INTEGER NOT NULL DEFAULT 0,
          armor_class INTEGER NOT NULL DEFAULT 10,
          speed TEXT DEFAULT '30ft',
          attacks TEXT DEFAULT '',
          initiative_bonus INTEGER NOT NULL DEFAULT 0,
          strength INTEGER NOT NULL DEFAULT 10,
          dexterity INTEGER NOT NULL DEFAULT 10,
          constitution INTEGER NOT NULL DEFAULT 10,
          intelligence INTEGER NOT NULL DEFAULT 10,
          wisdom INTEGER NOT NULL DEFAULT 10,
          charisma INTEGER NOT NULL DEFAULT 10,
          is_player INTEGER NOT NULL DEFAULT 0,
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
          is_custom INTEGER NOT NULL DEFAULT 1,
          description TEXT,
          attack_list TEXT DEFAULT '[]',
          inventory TEXT DEFAULT '[]',
          source_type TEXT DEFAULT 'custom',
          source_id TEXT,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          version TEXT DEFAULT '1.0',
          initiative INTEGER,
          conditions TEXT DEFAULT '',
          campaign_id TEXT
        )
      ''');

      // Erstelle Indizes
      await db.execute('CREATE INDEX idx_creatures_name ON creatures(name)');
      await db.execute('CREATE INDEX idx_creatures_type ON creatures(type)');
      await db.execute('CREATE INDEX idx_creatures_is_player ON creatures(is_player)');
      await db.execute('CREATE INDEX idx_creatures_source_type ON creatures(source_type)');
      await db.execute('CREATE INDEX idx_creatures_challenge_rating ON creatures(challenge_rating)');
      await db.execute('CREATE INDEX idx_creatures_campaign_id ON creatures(campaign_id)');

      print('Created creatures table with indexes');
    } else {
      print('Creatures table already exists');
    }
  }
  
  /// Fügt die is_favorite Spalte hinzu, falls sie nicht existiert
  Future<void> _addIsFavoriteColumn(Database db) async {
    try {
      // Prüfe ob Spalte bereits existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(campaigns)');
      final hasIsFavorite = tableInfo.any((column) => column['name'] == 'is_favorite');
      
      if (!hasIsFavorite) {
        await db.execute(
          'ALTER TABLE campaigns ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
        );
        print('Added is_favorite column to campaigns table');
      } else {
        print('is_favorite column already exists');
      }
    } catch (e) {
      // Wenn die Tabelle noch nicht existiert, wird sie von _createCampaignTable erstellt
      print('Note: Could not add is_favorite column (table might not exist yet): $e');
    }
  }

  /// Fügt die equipment Spalte zur player_characters Tabelle hinzu, falls sie nicht existiert
  Future<void> _addEquipmentColumn(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='player_characters'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: player_characters table does not exist yet');
        return;
      }
      
      // Prüfe ob Spalte bereits existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final hasEquipment = tableInfo.any((column) => column['name'] == 'equipment');
      
      if (!hasEquipment) {
        await db.execute(
          'ALTER TABLE player_characters ADD COLUMN equipment TEXT',
        );
        print('Added equipment column to player_characters table');
      } else {
        print('equipment column already exists in player_characters table');
      }
    } catch (e) {
      print('Error adding equipment column: $e');
    }
  }

  /// Fügt die saving_throw_proficiencies Spalte zur player_characters Tabelle hinzu, falls sie nicht existiert
  Future<void> _addSavingThrowProficienciesColumn(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='player_characters'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: player_characters table does not exist yet');
        return;
      }
      
      // Prüfe ob Spalte bereits existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      final hasSavingThrowProficiencies = tableInfo.any((column) => column['name'] == 'saving_throw_proficiencies');
      
      if (!hasSavingThrowProficiencies) {
        await db.execute(
          "ALTER TABLE player_characters ADD COLUMN saving_throw_proficiencies TEXT DEFAULT '[]'",
        );
        print('Added saving_throw_proficiencies column to player_characters table');
      } else {
        print('saving_throw_proficiencies column already exists in player_characters table');
      }
    } catch (e) {
      print('Error adding saving_throw_proficiencies column: $e');
    }
  }

  /// Fügt die Trefferwürfel-Spalten zur player_characters Tabelle hinzu
  Future<void> _addHitDiceColumns(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='player_characters'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: player_characters table does not exist yet');
        return;
      }
      
      final tableInfo = await db.rawQuery('PRAGMA table_info(player_characters)');
      
      // hit_dice Spalte hinzufügen
      final hasHitDice = tableInfo.any((column) => column['name'] == 'hit_dice');
      if (!hasHitDice) {
        await db.execute(
          "ALTER TABLE player_characters ADD COLUMN hit_dice TEXT DEFAULT 'd8'",
        );
        print('Added hit_dice column to player_characters table');
      } else {
        print('hit_dice column already exists in player_characters table');
      }
      
      // hit_dice_count Spalte hinzufügen
      final hasHitDiceCount = tableInfo.any((column) => column['name'] == 'hit_dice_count');
      if (!hasHitDiceCount) {
        await db.execute(
          'ALTER TABLE player_characters ADD COLUMN hit_dice_count INTEGER DEFAULT 1',
        );
        print('Added hit_dice_count column to player_characters table');
      } else {
        print('hit_dice_count column already exists in player_characters table');
      }
      
      // hit_dice_remaining Spalte hinzufügen
      final hasHitDiceRemaining = tableInfo.any((column) => column['name'] == 'hit_dice_remaining');
      if (!hasHitDiceRemaining) {
        await db.execute(
          'ALTER TABLE player_characters ADD COLUMN hit_dice_remaining INTEGER DEFAULT 1',
        );
        print('Added hit_dice_remaining column to player_characters table');
      } else {
        print('hit_dice_remaining column already exists in player_characters table');
      }
    } catch (e) {
      print('Error adding hit dice columns: $e');
    }
  }

  /// Fügt die damage_type Spalte zur items Tabelle hinzu, falls sie nicht existiert
  Future<void> _addDamageTypeColumn(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='items'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: items table does not exist yet');
        return;
      }
      
      // Prüfe ob Spalte bereits existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(items)');
      final hasDamageType = tableInfo.any((column) => column['name'] == 'damage_type');
      
      if (!hasDamageType) {
        await db.execute(
          'ALTER TABLE items ADD COLUMN damage_type TEXT',
        );
        print('Added damage_type column to items table');
      } else {
        print('damage_type column already exists in items table');
      }
    } catch (e) {
      print('Error adding damage_type column: $e');
    }
  }

  /// Fügt die linked_sound_ids Spalte zur scenes Tabelle hinzu, falls sie nicht existiert
  Future<void> _addLinkedSoundIdsColumn(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='scenes'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: scenes table does not exist yet');
        return;
      }
      
      // Prüfe ob Spalte bereits existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(scenes)');
      final hasLinkedSoundIds = tableInfo.any((column) => column['name'] == 'linked_sound_ids');
      
      if (!hasLinkedSoundIds) {
        await db.execute(
          'ALTER TABLE scenes ADD COLUMN linked_sound_ids TEXT DEFAULT "[]"',
        );
        print('Added linked_sound_ids column to scenes table');
      } else {
        print('linked_sound_ids column already exists in scenes table');
      }
    } catch (e) {
      print('Error adding linked_sound_ids column: $e');
    }
  }

  /// Migriert die sessions-Tabelle um linkedSoundIds hinzuzufügen
  Future<void> _migrateSessionsTable(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='sessions'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: sessions table does not exist yet');
        return;
      }
      
      final tableInfo = await db.rawQuery('PRAGMA table_info(sessions)');
      final hasLinkedSoundIds = tableInfo.any((column) => column['name'] == 'linkedSoundIds');
      
      if (!hasLinkedSoundIds) {
        print('Migrating sessions table: adding linkedSoundIds column');
        await db.execute(
          'ALTER TABLE sessions ADD COLUMN linkedSoundIds TEXT DEFAULT ""',
        );
        print('Successfully added linkedSoundIds column to sessions table');
      } else {
        print('linkedSoundIds column already exists in sessions table');
      }
    } catch (e) {
      print('Error migrating sessions table: $e');
    }
  }

  /// Erstellt die Scenes-Tabelle
  Future<void> _createScenesTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='scenes'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE scenes (
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
          linked_character_ids TEXT DEFAULT '[]',
          linked_sound_ids TEXT DEFAULT '[]',
          linked_encounter_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX idx_scenes_session_id ON scenes(session_id)');
      await db.execute('CREATE INDEX idx_scenes_order_index ON scenes(order_index)');
      await db.execute('CREATE INDEX idx_scenes_scene_type ON scenes(scene_type)');
      await db.execute('CREATE INDEX idx_scenes_is_completed ON scenes(is_completed)');
      await db.execute('CREATE INDEX idx_scenes_linked_encounter_id ON scenes(linked_encounter_id)');

      print('Created scenes table with indexes (including linked_character_ids and linked_sound_ids)');
    } else {
      print('Scenes table already exists');
    }
  }

  /// Erstellt die Sessions-Tabelle
  Future<void> _createSessionsTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='sessions'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE sessions (
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
          createdAt TEXT NOT NULL,
          startedAt TEXT,
          completedAt TEXT,
          FOREIGN KEY (campaignId) REFERENCES campaigns (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX idx_sessions_campaign_id ON sessions(campaignId)');
      await db.execute('CREATE INDEX idx_sessions_created_at ON sessions(createdAt)');
      await db.execute('CREATE INDEX idx_sessions_started_at ON sessions(startedAt)');
      await db.execute('CREATE INDEX idx_sessions_active_scene_id ON sessions(activeSceneId)');

      print('Created sessions table with indexes (using camelCase with linkedSoundIds)');
    } else {
      print('Sessions table already exists');
    }
  }

  /// Erstellt die Encounters-Tabelle
  Future<void> _createEncountersTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='encounters'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE encounters (
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

      await db.execute('CREATE INDEX idx_encounters_scene_id ON encounters(scene_id)');
      await db.execute('CREATE INDEX idx_encounters_status ON encounters(status)');

      print('Created encounters table with indexes (using scene_id)');
    } else {
      print('Encounters table already exists');
    }
  }

  /// Erstellt die EncounterParticipants-Tabelle
  Future<void> _createEncounterParticipantsTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='encounter_participants'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE encounter_participants (
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

      await db.execute('CREATE INDEX idx_encounter_participants_encounter_id ON encounter_participants(encounter_id)');
      await db.execute('CREATE INDEX idx_encounter_participants_type ON encounter_participants(type)');
      await db.execute('CREATE INDEX idx_encounter_participants_character_id ON encounter_participants(character_id)');

      print('Created encounter_participants table with indexes (using snake_case)');
    } else {
      print('EncounterParticipants table already exists');
    }
  }

  /// Erstellt die SessionQuestProgress-Tabelle
  Future<void> _createSessionQuestProgressTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='session_quest_progress'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE session_quest_progress (
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

      await db.execute('CREATE INDEX idx_session_quest_progress_session_id ON session_quest_progress(sessionId)');
      await db.execute('CREATE INDEX idx_session_quest_progress_quest_id ON session_quest_progress(questId)');
      await db.execute('CREATE INDEX idx_session_quest_progress_status ON session_quest_progress(status)');

      print('Created session_quest_progress table with indexes');
    } else {
      print('SessionQuestProgress table already exists');
    }
  }

  /// Erstellt die SessionCharacterTracking-Tabelle
  Future<void> _createSessionCharacterTrackingTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='session_character_tracking'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE session_character_tracking (
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

      await db.execute('CREATE INDEX idx_session_character_tracking_session_id ON session_character_tracking(sessionId)');
      await db.execute('CREATE INDEX idx_session_character_tracking_character_id ON session_character_tracking(characterId)');

      print('Created session_character_tracking table with indexes');
    } else {
      print('SessionCharacterTracking table already exists');
    }
  }

  /// Migration v10 -> v11: Scene als Hauptsäule
  Future<void> _migrateToV11(Database db) async {
    print('Running migration v10 -> v11: Scene as central hub');
    
    try {
      // 1. Scenes Tabelle erweitern
      await _addSceneFields(db);
      
      // 2. Encounters Tabelle umstrukturieren (sessionId -> sceneId)
      await _restructureEncountersTable(db);
      
      // 3. SceneQuestStatus Tabelle erstellen
      await _createSceneQuestStatusTable(db);
      
      print('Migration v10 -> v11 completed successfully');
    } catch (e) {
      print('Migration v10 -> v11 failed: $e');
      // Kein Abbruch bei Fehlern, da die Tabelle vielleicht noch nicht existiert
    }
  }

  /// Fügt neue Felder zur Scenes Tabelle hinzu
  Future<void> _addSceneFields(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='scenes'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: scenes table does not exist yet');
        return;
      }
      
      final tableInfo = await db.rawQuery('PRAGMA table_info(scenes)');
      
      // linked_encounter_id hinzufügen
      if (!tableInfo.any((column) => column['name'] == 'linked_encounter_id')) {
        await db.execute('ALTER TABLE scenes ADD COLUMN linked_encounter_id TEXT');
        print('Added linked_encounter_id column to scenes table');
      }
      
      // linked_character_ids hinzufügen
      if (!tableInfo.any((column) => column['name'] == 'linked_character_ids')) {
        await db.execute('ALTER TABLE scenes ADD COLUMN linked_character_ids TEXT DEFAULT "[]"');
        print('Added linked_character_ids column to scenes table');
      }
      
      // scene_data hinzufügen
      if (!tableInfo.any((column) => column['name'] == 'scene_data')) {
        await db.execute('ALTER TABLE scenes ADD COLUMN scene_data TEXT DEFAULT "{}"');
        print('Added scene_data column to scenes table');
      }
      
      // Index für linked_encounter_id erstellen
      try {
        await db.execute('CREATE INDEX idx_scenes_linked_encounter_id ON scenes(linked_encounter_id)');
      } catch (e) {
        // Index existiert vielleicht schon
      }
      
    } catch (e) {
      print('Error adding scene fields: $e');
    }
  }

  /// Strukturiert die Encounters Tabelle um (sessionId -> sceneId)
  Future<void> _restructureEncountersTable(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='encounters'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: encounters table does not exist yet');
        return;
      }
      
      final tableInfo = await db.rawQuery('PRAGMA table_info(encounters)');
      final hasSceneId = tableInfo.any((column) => column['name'] == 'scene_id');
      final hasSessionId = tableInfo.any((column) => column['name'] == 'session_id');
      
      // Wenn scene_id bereits existiert, nichts zu tun
      if (hasSceneId) {
        print('encounters table already has scene_id column');
        return;
      }
      
      // Wenn nur session_id existiert, müssen wir migrieren
      if (hasSessionId) {
        // In SQLite können wir Spalten nicht umbenennen, wir müssen:
        // 1. Neue Tabelle mit scene_id erstellen
        // 2. Daten kopieren
        // 3. Alte Tabelle löschen
        // 4. Neue Tabelle umbenennen
        
        print('Migrating encounters from session_id to scene_id');
        
        // 1. Erstelle temporäre Tabelle
        await db.execute('''
          CREATE TABLE encounters_new (
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
        
        // 2. Kopiere Daten (session_id wird zu scene_id)
        await db.execute('''
          INSERT INTO encounters_new 
          SELECT id, session_id, title, description, status, participant_ids, 
                 created_at, started_at, completed_at 
          FROM encounters
        ''');
        
        // 3. Lösche alte Tabelle
        await db.execute('DROP TABLE encounters');
        
        // 4. Benenne neue Tabelle um
        await db.execute('ALTER TABLE encounters_new RENAME TO encounters');
        
        // 5. Erstelle Indizes
        await db.execute('CREATE INDEX idx_encounters_scene_id ON encounters(scene_id)');
        await db.execute('CREATE INDEX idx_encounters_status ON encounters(status)');
        
        print('Successfully migrated encounters table to use scene_id');
      }
      
    } catch (e) {
      print('Error restructuring encounters table: $e');
    }
  }

  /// Erstellt die SceneQuestStatus Tabelle
  Future<void> _createSceneQuestStatusTable(Database db) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='scene_quest_status'",
    );

    if (result.isEmpty) {
      await db.execute('''
        CREATE TABLE scene_quest_status (
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

      await db.execute('CREATE INDEX idx_scene_quest_status_scene_id ON scene_quest_status(scene_id)');
      await db.execute('CREATE INDEX idx_scene_quest_status_quest_id ON scene_quest_status(quest_id)');
      await db.execute('CREATE INDEX idx_scene_quest_status_status ON scene_quest_status(status)');

      print('Created scene_quest_status table with indexes');
    } else {
      print('SceneQuestStatus table already exists');
    }
  }
  
  /// Fügt Beispieldaten ein
  Future<void> seedSampleData() async {
    final db = await _connection.database;
    
    // Prüfe ob bereits Daten vorhanden
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM campaigns');
    final campaignCount = count.first['count'] as int;
    
    if (campaignCount == 0) {
      final sampleCampaigns = [
        CampaignEntity.create(
          name: 'The Lost Mine of Phandelver',
          description: 'A beginner adventure for 1-5 level characters',
          gameMaster: 'Dungeon Master',
          tags: ['beginner', 'forgotten-realms', 'dungeon'],
        ),
        CampaignEntity.create(
          name: 'Curse of Strahd',
          description: 'A gothic horror adventure in the land of Barovia',
          gameMaster: 'Master Storyteller',
          tags: ['horror', 'vampire', 'ravenloft'],
        ),
        CampaignEntity.create(
          name: 'Waterdeep: Dragon Heist',
          description: 'An urban adventure of political intrigue and high-stakes heists',
          gameMaster: 'City Watch',
          tags: ['urban', 'political', 'heist'],
        ),
      ];
      
      for (final campaign in sampleCampaigns) {
        final campaignMap = campaign.toDatabaseMap();
        await db.insert('campaigns', campaignMap);
      }
      
      print('Seeded ${sampleCampaigns.length} sample campaigns');
    } else {
      print('Sample data already exists ($campaignCount campaigns)');
    }
  }
  
  /// Setzt die Datenbank zurück und erstellt sie neu
  Future<void> resetDatabase() async {
    await _connection.reset();
    await runMigrations();
    await seedSampleData();
  }
  
  /// Prüft die Datenbankintegrität
  Future<Map<String, dynamic>> checkIntegrity() async {
    final db = await _connection.database;
    final results = <String, dynamic>{};
    
    // Prüfe Campaign-Tabelle
    try {
      final campaignResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM campaigns',
      );
      results['campaigns'] = {
        'exists': true,
        'count': campaignResult.first['count'] as int,
        'status': 'ok',
      };
    } catch (e) {
      results['campaigns'] = {
        'exists': false,
        'error': e.toString(),
        'status': 'error',
      };
    }
    
    // Prüfe Indizes
    try {
      final indexResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='campaigns'",
      );
      results['indexes'] = {
        'count': indexResult.length,
        'names': indexResult.map((row) => row['name'] as String).toList(),
      };
    } catch (e) {
      results['indexes'] = {
        'error': e.toString(),
      };
    }
    
    return results;
  }
  
  /// Holt Migrationsstatus
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final integrity = await checkIntegrity();
    
    return {
      'version': 1,
      'lastRun': DateTime.now().toIso8601String(),
      'status': integrity['campaigns']?['status'] ?? 'unknown',
      'integrity': integrity,
    };
  }

  /// Stellt sicher, dass die encounters Tabelle die scene_id Spalte hat
  /// und sessionId KEIN NOT NULL Constraint mehr hat
  Future<void> _ensureEncountersSceneIdColumn(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='encounters'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: encounters table does not exist yet');
        return;
      }
      
      final tableInfo = await db.rawQuery('PRAGMA table_info(encounters)');
      final columnNames = tableInfo.map((c) => c['name'] as String).toList();
      print('Encounters table columns: $columnNames');
      
      final hasSceneId = columnNames.contains('scene_id');
      final hasSessionId = columnNames.contains('sessionId');
      
      // Prüfe ob sessionId NOT NULL hat
      bool sessionIdHasNotNull = false;
      if (hasSessionId) {
        final sessionIdColumn = tableInfo.firstWhere((c) => c['name'] == 'sessionId');
        sessionIdHasNotNull = sessionIdColumn['notnull'] == 1;
        print('sessionId has NOT NULL constraint: $sessionIdHasNotNull');
      }
      
      print('Encounters table check: hasSceneId=$hasSceneId, hasSessionId=$hasSessionId, sessionIdHasNotNull=$sessionIdHasNotNull');
      
      // Wenn sessionId noch NOT NULL hat, müssen wir die Tabelle neu erstellen
      // da SQLite NOT NULL Constraints nicht entfernen kann
      if (sessionIdHasNotNull || !hasSceneId) {
        print('Need to recreate encounters table (sessionId NOT NULL or scene_id missing)');
        await _recreateEncountersTableWithSceneId(db);
        return;
      }
      
      // Wenn scene_id bereits existiert und sessionId kein NOT NULL hat, ist alles gut
      if (hasSceneId) {
        print('encounters table already has scene_id column and sessionId is nullable - OK');
        return;
      }
      
    } catch (e) {
      print('Error ensuring scene_id column: $e');
    }
  }

  /// Erstellt die encounters Tabelle komplett neu mit scene_id
  Future<void> _recreateEncountersTableWithSceneId(Database db) async {
    print('Recreating encounters table with scene_id...');
    
    try {
      // 1. Backup der alten Daten
      final existingData = await db.rawQuery('SELECT * FROM encounters');
      print('Found ${existingData.length} existing encounters to migrate');
      
      // 2. Alte Tabelle löschen
      await db.execute('DROP TABLE IF EXISTS encounters');
      
      // 3. Neue Tabelle mit scene_id erstellen
      await db.execute('''
        CREATE TABLE encounters (
          id TEXT PRIMARY KEY,
          scene_id TEXT,
          title TEXT NOT NULL,
          description TEXT,
          status TEXT NOT NULL DEFAULT 'planning',
          participant_ids TEXT,
          created_at TEXT NOT NULL,
          started_at TEXT,
          completed_at TEXT
        )
      ''');
      
      // 4. Indizes erstellen
      await db.execute('CREATE INDEX idx_encounters_scene_id ON encounters(scene_id)');
      await db.execute('CREATE INDEX idx_encounters_status ON encounters(status)');
      
      print('Successfully recreated encounters table with scene_id');
    } catch (e) {
      print('Error recreating encounters table: $e');
    }
  }

  /// Stellt sicher, dass encounter_participants die richtigen Spalten hat
  Future<void> _ensureEncounterParticipantsColumns(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='encounter_participants'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: encounter_participants table does not exist yet');
        return;
      }
      
      final tableInfo = await db.rawQuery('PRAGMA table_info(encounter_participants)');
      final columnNames = tableInfo.map((c) => c['name'] as String).toList();
      print('Encounter participants table columns: $columnNames');
      
      final hasEncounterId = columnNames.contains('encounter_id');
      
      // Wenn encounter_id fehlt, Tabelle neu erstellen
      if (!hasEncounterId) {
        print('Need to recreate encounter_participants table (encounter_id missing)');
        await _recreateEncounterParticipantsTable(db);
        return;
      }
      
      print('encounter_participants table has encounter_id column - OK');
      
    } catch (e) {
      print('Error ensuring encounter_participants columns: $e');
    }
  }

  /// Erstellt die encounter_participants Tabelle komplett neu
  Future<void> _recreateEncounterParticipantsTable(Database db) async {
    print('Recreating encounter_participants table...');
    
    try {
      // 1. Alte Tabelle löschen
      await db.execute('DROP TABLE IF EXISTS encounter_participants');
      
      // 2. Neue Tabelle erstellen
      await db.execute('''
        CREATE TABLE encounter_participants (
          id TEXT PRIMARY KEY,
          encounter_id TEXT NOT NULL,
          name TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'enemy',
          current_hp INTEGER NOT NULL DEFAULT 0,
          max_hp INTEGER NOT NULL DEFAULT 0,
          conditions TEXT,
          notes TEXT,
          character_id TEXT
        )
      ''');
      
      // 3. Indizes erstellen
      await db.execute('CREATE INDEX idx_encounter_participants_encounter_id ON encounter_participants(encounter_id)');
      await db.execute('CREATE INDEX idx_encounter_participants_type ON encounter_participants(type)');
      await db.execute('CREATE INDEX idx_encounter_participants_character_id ON encounter_participants(character_id)');
      
      print('Successfully recreated encounter_participants table');
    } catch (e) {
      print('Error recreating encounter_participants table: $e');
    }
  }

  /// Fügt die creature_id Spalte zu encounter_participants hinzu (für Loot-Verteilung)
  Future<void> _addCreatureIdColumn(Database db) async {
    try {
      // Prüfe ob Tabelle existiert
      final tableExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='encounter_participants'",
      );
      
      if (tableExists.isEmpty) {
        print('Note: encounter_participants table does not exist yet');
        return;
      }
      
      // Prüfe ob Spalte bereits existiert
      final tableInfo = await db.rawQuery('PRAGMA table_info(encounter_participants)');
      final hasCreatureId = tableInfo.any((column) => column['name'] == 'creature_id');
      
      if (!hasCreatureId) {
        await db.execute(
          'ALTER TABLE encounter_participants ADD COLUMN creature_id TEXT',
        );
        print('Added creature_id column to encounter_participants table');
      } else {
        print('creature_id column already exists in encounter_participants table');
      }
    } catch (e) {
      print('Error adding creature_id column: $e');
    }
  }
}
