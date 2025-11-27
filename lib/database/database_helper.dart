// lib/database/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/campaign.dart';
import '../models/campaign_quest.dart';
import '../models/creature.dart';
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../models/player_character.dart';
import '../models/quest.dart';
import '../models/scene.dart';
import '../models/session.dart';
import '../models/sound.dart';
import '../models/wiki_entry.dart';
import '../models/official_monster.dart';
import '../models/official_spell.dart';

final _uuid = const Uuid();


class DatabaseHelper {
  static const _databaseName = "dnd_helper.db";
  static const _databaseVersion = 31; // Erhöhte Version für finale Migration

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade);
  }

  // --- Datenbank-Struktur (Erstellen & Upgraden) ---
  Future<void> _onCreate(Database db, int version) async => await _createTables(db, version);

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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
      
      // Performance-Indizes für die neuen Felder
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
        await db.execute('CREATE INDEX idx_players_campaign ON player_characters(campaign_id)');
      } catch (e) {
        // Index existiert bereits
      }
    }
    
    // NEU: Migration für Version 21: imageUrl und Spell-Felder für Items
    if (oldVersion < 21) {
      // imageUrl Spalte zur items Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE items ADD COLUMN imageUrl TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Spell-spezifische Spalten zur items Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE items ADD COLUMN spellId TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN isSpell INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN spellLevel INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN spellSchool TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN isCantrip INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN maxCastsPerDay INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE items ADD COLUMN requiresConcentration INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
    }
    
    // NEU: Migration für Version 22: attack_list und inventory Spalten für player_characters und creatures
    if (oldVersion < 22) {
      // attack_list Spalte zur player_characters Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN attack_list TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // inventory Spalte zur player_characters Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE player_characters ADD COLUMN inventory TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // attack_list Spalte zur creatures Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN attack_list TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // inventory Spalte zur creatures Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE creatures ADD COLUMN inventory TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
    }
    
    // NEU: Migration für Version 23: WikiEntry Erweiterung für Kartenintegration und Tags
    if (oldVersion < 23) {
      // Neue Felder zur wiki_entries Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN locationData TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN tags TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN createdAt INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN updatedAt INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN campaignId TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Performance-Indizes für neue Felder
      try {
        await db.execute('CREATE INDEX idx_wiki_entries_type ON wiki_entries(entryType)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_wiki_entries_campaign ON wiki_entries(campaignId)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_wiki_entries_updated ON wiki_entries(updatedAt DESC)');
      } catch (e) {
        // Index existiert bereits
      }
      
      // Bestehende Einträge mit Default-Werten aktualisieren
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'wiki_entries',
        {
          'createdAt': now,
          'updatedAt': now,
          'tags': '', // Leerer String für keine Tags
        },
        where: 'createdAt IS NULL OR updatedAt IS NULL',
      );
    }
    
    // NEU: Migration für Version 24: WikiEntry Erweiterung für Metadaten und hierarchische Strukturen
    if (oldVersion < 24) {
      // Neue Metadaten-Felder zur wiki_entries Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN imageUrl TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN createdBy TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN parentId TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN childIds TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN isMarkdown INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Performance-Indizes für neue Felder
      try {
        await db.execute('CREATE INDEX idx_wiki_entries_parent ON wiki_entries(parentId)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_wiki_entries_created_by ON wiki_entries(createdBy)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_wiki_entries_image ON wiki_entries(imageUrl)');
      } catch (e) {
        // Index existiert bereits
      }
    }
    
    // NEU: Migration für Version 25: Wiki Links und Cross-References
    if (oldVersion < 25) {
      // Wiki Links Tabelle erstellen
      try {
        await db.execute('''
          CREATE TABLE wiki_links (
            id TEXT PRIMARY KEY,
            source_entry_id TEXT NOT NULL,
            target_entry_id TEXT NOT NULL,
            link_type TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            created_by TEXT
          )
        ''');
      } catch (e) {
        // Tabelle existiert bereits
      }
      
      // Performance-Indizes für Wiki Links
      try {
        await db.execute('CREATE INDEX idx_wiki_links_source ON wiki_links(source_entry_id)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_wiki_links_target ON wiki_links(target_entry_id)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_wiki_links_type ON wiki_links(link_type)');
      } catch (e) {
        // Index existiert bereits
      }
    }
    
    // NEU: Migration für Version 26: Wiki Favoriten-Funktion
    if (oldVersion < 26) {
      // Favoriten-Feld zur wiki_entries Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE wiki_entries ADD COLUMN isFavorite INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Performance-Index für Favoriten
      try {
        await db.execute('CREATE INDEX idx_wiki_entries_favorite ON wiki_entries(isFavorite)');
      } catch (e) {
        // Index existiert bereits
      }
    }
    
    // NEU: Migration für Version 27: Quest-Erweiterung für verbessertes Quest-Management
    if (oldVersion < 27) {
      // Neue Felder zur quests Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN quest_type TEXT DEFAULT \'side\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN difficulty TEXT DEFAULT \'medium\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN recommended_level INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN estimated_duration_hours INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN tags TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN rewards TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN location TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN involved_npcs TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN is_favorite INTEGER DEFAULT 0');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN created_at INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN updated_at INTEGER');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN linked_wiki_entry_ids TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE quests ADD COLUMN campaign_id TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Performance-Indizes für neue Quest-Felder
      try {
        await db.execute('CREATE INDEX idx_quests_type ON quests(quest_type)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_quests_difficulty ON quests(difficulty)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_quests_favorite ON quests(is_favorite)');
      } catch (e) {
        // Index existiert bereits
      }
      
      try {
        await db.execute('CREATE INDEX idx_quests_level ON quests(recommended_level)');
      } catch (e) {
        // Index existiert bereits
      }
      
      // Bestehende Quests mit Default-Werten aktualisieren
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'quests',
        {
          'created_at': now,
          'updated_at': now,
          'tags': '', // Leerer String für keine Tags
          'rewards': '', // Leerer String für keine Belohnungen
          'involved_npcs': '', // Leerer String für keine NPCs
        },
        where: 'created_at IS NULL OR updated_at IS NULL',
      );
    }
    
    // NEU: Migration für Version 28: Alte campaignId Spalte in player_characters umbenennen
    if (oldVersion < 28) {
      try {
        await db.execute('ALTER TABLE player_characters RENAME COLUMN campaignId TO campaign_id');
      } catch (e) {
        // Spalte existiert bereits oder wurde bereits umbenannt
      }
    }
    
    // NEU: Migration für Version 29: Campaign Schema Update
    if (oldVersion < 29) {
      // Neue Spalten zur campaigns Tabelle hinzufügen
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN status TEXT NOT NULL DEFAULT \'planning\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN type TEXT NOT NULL DEFAULT \'homebrew\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN created_at TEXT NOT NULL DEFAULT \'\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN updated_at TEXT NOT NULL DEFAULT \'\'');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN started_at TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN completed_at TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN dungeon_master_id TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN player_character_ids TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN quest_ids TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN wiki_entry_ids TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN session_ids TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN settings TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      try {
        await db.execute('ALTER TABLE campaigns ADD COLUMN stats TEXT');
      } catch (e) {
        // Spalte existiert bereits
      }
      
      // Bestehende Kampagnen mit Default-Werten aktualisieren
      final now = DateTime.now().toIso8601String();
      await db.update(
        'campaigns',
        {
          'status': 'planning',
          'type': 'homebrew',
          'created_at': now,
          'updated_at': now,
          'settings': '{"max_player_level":20,"starting_level":1,"party_size":"4-5","available_monsters":"","available_spells":"","available_items":"","available_npcs":"","allow_custom_content":1,"is_public":0,"image_url":null,"custom_rules":""}',
          'stats': '{"total_sessions":0,"total_quests":0,"completed_quests":0,"total_characters":0,"total_experience_awarded":0,"total_gold_awarded":0.0,"total_play_time_ms":0}',
        },
        where: 'created_at = \'\' OR updated_at = \'\'',
      );
    }
    
    // Alte Migrationen für Version 17 und darunter
    if (oldVersion < 17) {
      // Alte Migrationen für Version 17 und darunter
      await _migrateToVersion17(db);
    }
  }
  
  // Alte Migration für Version 17
  Future<void> _migrateToVersion17(Database db) async {
    // Hier könnten alte Migrationen für Version 17 implementiert werden
    // Aktuell nicht benötigt, da wir direkt auf Version 18 migrieren
  }

  // Diese eine Methode erstellt den GESAMTEN, AKTUELLEN Zustand der Datenbank
  Future<void> _createTables(Database db, int version) async {

      await db.execute('''
      CREATE TABLE player_characters (
        id TEXT PRIMARY KEY, campaign_id TEXT NOT NULL, name TEXT NOT NULL, playerName TEXT NOT NULL, 
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
        version TEXT DEFAULT '1.0',
        -- NEU: Strukturierte Listen für Version 22
        attack_list TEXT,
        inventory TEXT
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
        imageUrl TEXT,
        damage TEXT,
        properties TEXT,
        acFormula TEXT,
        strengthRequirement INTEGER,
        stealthDisadvantage INTEGER,
        rarity TEXT,
        requiresAttunement INTEGER,
        hasDurability INTEGER DEFAULT 0,
        maxDurability INTEGER,
        isRepairable INTEGER DEFAULT 0,
        spellId TEXT,
        isSpell INTEGER DEFAULT 0,
        spellLevel INTEGER,
        spellSchool TEXT,
        isCantrip INTEGER DEFAULT 0,
        maxCastsPerDay INTEGER,
        requiresConcentration INTEGER DEFAULT 0
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
        status TEXT NOT NULL DEFAULT 'planning',
        type TEXT NOT NULL DEFAULT 'homebrew',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT,
        dungeon_master_id TEXT,
        player_character_ids TEXT,
        quest_ids TEXT,
        wiki_entry_ids TEXT,
        session_ids TEXT,
        settings TEXT,
        stats TEXT,
        -- Legacy fields for backward compatibility
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
        version TEXT DEFAULT '1.0',
        -- NEU: Strukturierte Listen für Version 22
        attack_list TEXT,
        inventory TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE wiki_entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        entryType TEXT NOT NULL,
        locationData TEXT,
        tags TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        campaignId TEXT,
        imageUrl TEXT,
        createdBy TEXT,
        parentId TEXT,
        childIds TEXT,
        isMarkdown INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0
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
      CREATE TABLE wiki_links (
        id TEXT PRIMARY KEY,
        source_entry_id TEXT NOT NULL,
        target_entry_id TEXT NOT NULL,
        link_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        created_by TEXT
      )
    ''');
     await db.execute('''
      CREATE TABLE quests (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        goal TEXT NOT NULL,
        quest_type TEXT NOT NULL DEFAULT 'side',
        difficulty TEXT NOT NULL DEFAULT 'medium',
        recommended_level INTEGER,
        estimated_duration_hours INTEGER,
        tags TEXT,
        rewards TEXT,
        location TEXT,
        involved_npcs TEXT,
        linked_wiki_entry_ids TEXT,
        campaign_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
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
    
    // Performance-Indizes für WikiEntries
    await db.execute('CREATE INDEX idx_wiki_entries_favorite ON wiki_entries(isFavorite)');
    await db.execute('CREATE INDEX idx_wiki_entries_type ON wiki_entries(entryType)');
    await db.execute('CREATE INDEX idx_wiki_entries_campaign ON wiki_entries(campaignId)');
    await db.execute('CREATE INDEX idx_wiki_entries_updated ON wiki_entries(updatedAt DESC)');
    await db.execute('CREATE INDEX idx_wiki_entries_parent ON wiki_entries(parentId)');
    await db.execute('CREATE INDEX idx_wiki_entries_created_by ON wiki_entries(createdBy)');
    await db.execute('CREATE INDEX idx_wiki_entries_image ON wiki_entries(imageUrl)');
  }

  // --- Campaign CRUD ---
  Future<int> insertCampaign(Campaign campaign) async => await (await database).insert('campaigns', campaign.toMap());
  Future<List<Campaign>> getAllCampaigns() async {
    final maps = await (await database).query('campaigns', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Campaign.fromMap(maps[i]));
  }
  Future<int> updateCampaign(Campaign campaign) async => await (await database).update('campaigns', campaign.toMap(), where: 'id = ?', whereArgs: [campaign.id]);
  Future<void> deleteCampaign(String campaignId) async => await (await database).delete('campaigns', where: 'id = ?', whereArgs: [campaignId]);
  Future<void> deleteCampaignAndAssociatedData(String campaignId) async {
    final db = await instance.database;
    // Beginnen eine "Transaktion", um sicherzustellen, dass alles oder nichts gelöscht wird
    await db.transaction((txn) async {
      // 1. Finde alle Sessions, die zur Kampagne gehören
      final sessions = await txn.query('sessions', where: 'campaignId = ? OR campaignId = ?', whereArgs: [campaignId, campaignId]);
      for (var session in sessions) {
        // 2. Lösche alle Szenen, die zu jeder Session gehören
        await txn.delete('scenes', where: 'sessionId = ?', whereArgs: [session['id']]);
      }
      // 3. Lösche alle Sessions der Kampagne
      await txn.delete('sessions', where: 'campaignId = ? OR campaignId = ?', whereArgs: [campaignId, campaignId]);

      // 4. Finde alle Helden der Kampagne
      final playerCharacters = await txn.query('player_characters', where: 'campaign_id = ?', whereArgs: [campaignId]);
      for (var pc in playerCharacters) {
        // 5. Lösche das gesamte Inventar für jeden Helden
        await txn.delete('inventory_items', where: 'ownerId = ?', whereArgs: [pc['id']]);
      }
      // 6. Lösche alle Helden der Kampagne
      await txn.delete('player_characters', where: 'campaign_id = ?', whereArgs: [campaignId]);

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
    final maps = await (await database).query('player_characters', where: 'campaign_id = ? OR campaignId = ?', whereArgs: [campaignId, campaignId], orderBy: 'name ASC');
    return List.generate(maps.length, (i) => PlayerCharacter.fromMap(maps[i]));
  }
  
  /// NEU: Gibt alle Player Characters aus allen Kampagnen zurück
  Future<List<PlayerCharacter>> getAllPlayerCharacters() async {
    final maps = await (await database).query('player_characters', orderBy: 'name ASC');
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
      attackList: original.attackList,
      inventory: original.inventory,
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
  
  Future<Creature?> getCreatureById(String id) async {
    final maps = await (await database).query('creatures', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Creature.fromMap(maps.first);
    return null;
  }
  
  Future<int> updateCreature(Creature creature) async => await (await database).update('creatures', creature.toMap(), where: 'id = ?', whereArgs: [creature.id]);
  Future<int> deleteCreature(String id) async => await (await database).delete('creatures', where: 'id = ?', whereArgs: [id]);
  
  // NEU: Creature Favoriten-Management
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
  
  Future<List<Creature>> getFavoriteCreatures() async {
    final maps = await (await database).query(
      'creatures',
      where: 'is_favorite = 1',
      orderBy: 'name ASC',
    );
    return List.generate(maps.length, (i) => Creature.fromMap(maps[i]));
  }
  
  // NEU: Creature Duplizieren
  Future<String> duplicateCreature(String id) async {
    final original = await getCreatureById(id);
    if (original == null) throw Exception('Creature nicht gefunden: $id');
    
    // Neue ID und Name generieren
    final newId = _uuid.v4();
    final newName = '${original.name} (Kopie)';
    
    // Kopie erstellen
    final copy = Creature(
      id: newId,
      name: newName,
      maxHp: original.maxHp,
      armorClass: original.armorClass,
      speed: original.speed,
      attacks: original.attacks,
      initiativeBonus: original.initiativeBonus,
      strength: original.strength,
      dexterity: original.dexterity,
      constitution: original.constitution,
      intelligence: original.intelligence,
      wisdom: original.wisdom,
      charisma: original.charisma,
      isPlayer: original.isPlayer,
      gold: original.gold,
      silver: original.silver,
      copper: original.copper,
      officialMonsterId: original.officialMonsterId,
      officialSpellIds: original.officialSpellIds,
      officialItemIds: original.officialItemIds,
      size: original.size,
      type: original.type,
      subtype: original.subtype,
      alignment: original.alignment,
      challengeRating: original.challengeRating,
      specialAbilities: original.specialAbilities,
      legendaryActions: original.legendaryActions,
      isCustom: true, // Kopien sind immer custom
      description: original.description,
      sourceType: 'custom',
      sourceId: null,
      isFavorite: false, // Kopien sind nicht favorisiert
      version: '1.0',
      attackList: original.attackList,
      inventory: original.inventory,
    );
    
    await insertCreature(copy);
    return newId;
  }

  // --- Item CRUD ---
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

  // --- Inventory CRUD ---
  Future<int> insertInventoryItem(InventoryItem inventoryItem) async => await (await database).insert('inventory_items', inventoryItem.toMap());
  Future<List<InventoryItem>> getInventoryForOwner(String ownerId) async {
    final maps = await (await database).query('inventory_items', where: 'ownerId = ? OR ownerId = ?', whereArgs: [ownerId, ownerId], orderBy: 'isEquipped DESC, itemId ASC');
    return List.generate(maps.length, (i) => InventoryItem.fromMap(maps[i]));
  }
  Future<int> updateInventoryItem(InventoryItem inventoryItem) async => await (await database).update('inventory_items', inventoryItem.toMap(), where: 'id = ?', whereArgs: [inventoryItem.id]);
  Future<int> deleteInventoryItem(String id) async => await (await database).delete('inventory_items', where: 'id = ?', whereArgs: [id]);
  Future<void> deleteInventoryForOwner(String ownerId) async => await (await database).delete('inventory_items', where: 'ownerId = ?', whereArgs: [ownerId]);

  // --- Quest CRUD ---
  Future<int> insertQuest(Quest quest) async => await (await database).insert('quests', quest.toMap());
  Future<List<Quest>> getAllQuests() async {
    final maps = await (await database).query('quests', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }
  Future<List<Quest>> getQuestsForCampaign(String campaignId) async {
    final maps = await (await database).query('quests', where: 'campaign_id = ?', whereArgs: [campaignId], orderBy: 'title ASC');
    return List.generate(maps.length, (i) => Quest.fromMap(maps[i]));
  }
  Future<Quest?> getQuestById(String id) async {
    final maps = await (await database).query('quests', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Quest.fromMap(maps.first);
    return null;
  }
  Future<int> updateQuest(Quest quest) async => await (await database).update('quests', quest.toMap(), where: 'id = ?', whereArgs: [quest.id]);
  Future<int> deleteQuest(String id) async => await (await database).delete('quests', where: 'id = ?', whereArgs: [id]);

  // --- Wiki Entry CRUD ---
  Future<int> insertWikiEntry(WikiEntry wikiEntry) async => await (await database).insert('wiki_entries', wikiEntry.toMap());
  Future<List<WikiEntry>> getAllWikiEntries() async {
    final maps = await (await database).query('wiki_entries', orderBy: 'title ASC');
    return List.generate(maps.length, (i) => WikiEntry.fromMap(maps[i]));
  }
  Future<List<WikiEntry>> getWikiEntriesForCampaign(String campaignId) async {
    final maps = await (await database).query('wiki_entries', where: 'campaignId = ?', whereArgs: [campaignId], orderBy: 'title ASC');
    return List.generate(maps.length, (i) => WikiEntry.fromMap(maps[i]));
  }
  Future<WikiEntry?> getWikiEntryById(String id) async {
    final maps = await (await database).query('wiki_entries', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return WikiEntry.fromMap(maps.first);
    return null;
  }
  Future<int> updateWikiEntry(WikiEntry wikiEntry) async => await (await database).update('wiki_entries', wikiEntry.toMap(), where: 'id = ?', whereArgs: [wikiEntry.id]);
  Future<int> deleteWikiEntry(String id) async => await (await database).delete('wiki_entries', where: 'id = ?', whereArgs: [id]);

  // --- Sound CRUD ---
  Future<int> insertSound(Sound sound) async => await (await database).insert('sounds', sound.toMap());
  Future<List<Sound>> getAllSounds() async {
    final maps = await (await database).query('sounds', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Sound.fromMap(maps[i]));
  }
  Future<Sound?> getSoundById(String id) async {
    final maps = await (await database).query('sounds', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Sound.fromMap(maps.first);
    return null;
  }
  Future<int> updateSound(Sound sound) async => await (await database).update('sounds', sound.toMap(), where: 'id = ?', whereArgs: [sound.id]);
  Future<int> deleteSound(String id) async => await (await database).delete('sounds', where: 'id = ?', whereArgs: [id]);

  // --- Campaign Quest CRUD ---
  Future<int> insertCampaignQuest(CampaignQuest campaignQuest) async => await (await database).insert('campaign_quests', campaignQuest.toMap());
  Future<List<CampaignQuest>> getCampaignQuestsForCampaign(String campaignId) async {
    final maps = await (await database).query('campaign_quests', where: 'campaignId = ?', whereArgs: [campaignId]);
    return List.generate(maps.length, (i) => CampaignQuest.fromDbMap(maps[i]));
  }
  Future<int> updateCampaignQuest(CampaignQuest campaignQuest) async => await (await database).update('campaign_quests', campaignQuest.toMap());
  Future<int> deleteCampaignQuest(String campaignId, String questId) async => await (await database).delete('campaign_quests', where: 'campaignId = ? AND questId = ?', whereArgs: [campaignId, questId]);

  // --- Scene Sound Link CRUD ---
  Future<int> insertSceneSoundLink(Map<String, dynamic> sceneSoundLink) async =>
      await (await database).insert('scene_sound_links', sceneSoundLink);

  // Scene Sound Links CRUD operations
  Future<List<Map<String, dynamic>>> getAllSceneSoundLinks() async {
    return await (await database).query('scene_sound_links');
  }

  Future<int> deleteSceneSoundLink(String linkId) async {
    return await (await database).delete(
      'scene_sound_links',
      where: 'id = ?',
      whereArgs: [linkId],
    );
  }

  // --- Offizielle D&D-Daten CRUD Methoden ---
  
  /// Holt alle offiziellen Monster aus der Datenbank
  Future<List<OfficialMonster>> getAllOfficialMonsters({int? limit}) async {
    final maps = await (await database).query(
      'official_monsters', 
      orderBy: 'name ASC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => OfficialMonster.fromMap(maps[i]));
  }
  
  /// Holt alle offiziellen Zauber aus der Datenbank
  Future<List<OfficialSpell>> getAllOfficialSpells({int? limit}) async {
    final maps = await (await database).query(
      'official_spells', 
      orderBy: 'name ASC',
      limit: limit,
    );
    return List.generate(maps.length, (i) => OfficialSpell.fromMap(maps[i] as Map<String, dynamic>));
  }
  
  /// Löscht alle offiziellen Daten aus einer bestimmten Tabelle
  Future<void> clearOfficialData([String? tableName]) async {
    final db = await database;
    if (tableName != null) {
      await db.delete(tableName);
      print('Offizielle Daten aus Tabelle $tableName wurden gelöscht.');
    } else {
      final tables = ['official_monsters', 'official_spells', 'official_classes', 'official_races', 'official_items', 'official_locations'];
      
      for (final table in tables) {
        await db.delete(table);
      }
      print('Alle offiziellen Daten aus Tabellen $tables wurden gelöscht.');
    }
  }
  
  /// Fügt ein offizielles Monster in die Datenbank ein
  Future<int> insertOfficialMonster(OfficialMonster monster) async {
    return await (await database).insert('official_monsters', monster.toMap());
  }
  
  /// Fügt einen offiziellen Zauber in die Datenbank ein
  Future<int> insertOfficialSpell(Map<String, dynamic> spellData) async {
    return await (await database).insert('official_spells', spellData);
  }
  
  /// Fügt eine offizielle Klasse in die Datenbank ein
  Future<int> insertOfficialClass(Map<String, dynamic> classData) async {
    return await (await database).insert('official_classes', classData);
  }
  
  /// Fügt eine offizielle Rasse in die Datenbank ein
  Future<int> insertOfficialRace(Map<String, dynamic> raceData) async {
    return await (await database).insert('official_races', raceData);
  }
  
  /// Fügt ein offizielles Item in die Datenbank ein
  Future<int> insertOfficialItem(Map<String, dynamic> itemData) async {
    return await (await database).insert('official_items', itemData);
  }
  
  /// Fügt einen offiziellen Ort in die Datenbank ein
  Future<int> insertOfficialLocation(Map<String, dynamic> locationData) async {
    return await (await database).insert('official_locations', locationData);
  }
  
  /// Holt die Anzahl der Datensätze in einer offiziellen Tabelle
  Future<int> getOfficialDataCount(String tableName) async {
    final result = await (await database).rawQuery('SELECT COUNT(*) FROM $tableName');
    return result.first['COUNT(*)'] as int;
  }
  
  /// Holt die neueste Version aus einer offiziellen Tabelle
  Future<String?> getLatestVersion(String tableName) async {
    final result = await (await database).rawQuery(
      'SELECT version FROM $tableName ORDER BY created_at DESC LIMIT 1'
    );
    return result.isNotEmpty ? result.first['version'] as String : null;
  }
  
  /// Holt Inventardaten für einen bestimmten Owner zur Anzeige im Encounter Setup
  Future<List<Map<String, dynamic>>> getDisplayInventoryForOwner(String ownerId) async {
    final db = await database;
    
    // Hole alle Inventar-Items für den Owner
    final inventoryItems = await db.query(
      'inventory_items',
      where: 'ownerId = ?',
      whereArgs: [ownerId],
    );
    
    final displayItems = <Map<String, dynamic>>[];
    
    for (final inventoryItem in inventoryItems) {
      // Hole das entsprechende Item für jedes Inventar-Item
      final itemResult = await db.query(
        'items',
        where: 'id = ?',
        whereArgs: [inventoryItem['itemId']],
      );
      
      if (itemResult.isNotEmpty) {
        final item = itemResult.first;
        displayItems.add({
          'id': inventoryItem['id'],
          'itemId': item['id'],
          'name': item['name'],
          'description': item['description'],
          'itemType': item['itemType'],
          'quantity': inventoryItem['quantity'],
          'isEquipped': inventoryItem['isEquipped'] ?? 0,
          'equipSlot': inventoryItem['equipSlot'],
          'weight': item['weight'],
          'cost': item['cost'],
          'imageUrl': item['imageUrl'],
          'damage': item['damage'],
          'properties': item['properties'],
          'rarity': item['rarity'],
          'requiresAttunement': item['requiresAttunement'],
        });
      }
    }
    
    return displayItems;
  }

  // --- Hilfsmethoden ---
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // --- Datenbank-Reset für Entwicklung ---
  Future<void> resetDatabase() async {
    await closeDatabase();
    final dbPath = join(await getDatabasesPath(), _databaseName);
    await deleteDatabase(dbPath);
    print("Datenbank zurückgesetzt: $dbPath");
  }
}
