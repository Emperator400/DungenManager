import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../core/database_connection.dart';
import '../entities/campaign_entity.dart';
import '../entities/player_character_entity.dart';

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
    
    // Füge is_favorite Spalte hinzu, falls sie nicht existiert
    await _addIsFavoriteColumn(db);
    
    // Füge equipment Spalte hinzu, falls sie nicht existiert
    await _addEquipmentColumn(db);
    
    print('Database migration completed successfully');
  }
  
  /// Erstellt die PlayerCharacter-Tabelle
  Future<void> _createPlayerCharacterTable(Database db) async {
    final pcEntity = PlayerCharacterEntity(
      id: '',
      name: '',
      characterClass: '',
      level: 1,
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
}