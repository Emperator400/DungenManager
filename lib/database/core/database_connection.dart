import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
  
  /// Datenbank-Instanz
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  /// Initialisiert die Datenbankverbindung
  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'dnd_helper_v2.db');
    
    _migration = RefactoringMigrationV2(this);
    
    final db = await openDatabase(
      path,
      version: 5, // Aktualisiert auf Version 5 - character_id statt owner_id
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // Stelle sicher, dass die items Tabelle immer existiert
    await _ensureItemsTableExists(db);
    
    return db;
  }
  
  /// Erstellt die Tabellen bei der ersten Installation
  Future<void> _onCreate(Database db, int version) async {
    print('📦 Erstelle Datenbank-Tabellen...');
    
    // Erstelle alle Tabellen
    await _createAllTables(db);
    
    print('✅ Alle Datenbank-Tabellen erstellt');
  }
  
  /// Erstellt alle Tabellen der Datenbank
  Future<void> _createAllTables(Database db) async {
    await _createCampaignsTable(db);
    await _createPlayerCharactersTable(db);
    await _createInventoryItemsTable(db);
    await _createItemsTable(db);
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
    
    // Indizes für campaigns
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
    
    // Indizes für player_characters
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
    
    // Indizes für inventory_items
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_items_character_id ON inventory_items(character_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_items_name ON inventory_items(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inventory_items_is_equipped ON inventory_items(is_equipped)');
    
    print('✅ inventory_items Tabelle erstellt');
  }
  
  /// Erstellt die items Tabelle (allgemeine Item-Bibliothek)
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
    
    // Indizes für items
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_name ON items(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_item_type ON items(item_type)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_items_rarity ON items(rarity)');
    
    print('✅ items Tabelle erstellt');
  }
  
  /// Aktualisiert das Datenbankschema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Datenbank-Upgrade von Version $oldVersion auf $newVersion...');
    
    // Führt Migrationen basierend auf der Version
    if (oldVersion < 2 && newVersion >= 2) {
      print('🔄 Starte API Refactoring Migration (v1 → v2)...');
      
      // Führe die RefactoringMigrationV2 aus
      final migration = RefactoringMigrationV2(this);
      final result = await migration.migrate();
      
      print(result.toString());
      
      if (!result.success) {
        throw Exception('Migration fehlgeschlagen: ${result.error}');
      }
      
      // Füge is_favorite Spalte hinzu, falls sie noch nicht existiert
      try {
        final tableInfo = await db.rawQuery('PRAGMA table_info(campaigns)');
        final hasIsFavorite = tableInfo.any((column) => column['name'] == 'is_favorite');
        
        if (!hasIsFavorite) {
          await db.execute(
            'ALTER TABLE campaigns ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0',
          );
          print('✅ is_favorite Spalte hinzugefügt');
        } else {
          print('ℹ️ is_favorite Spalte existiert bereits');
        }
      } catch (e) {
        print('⚠️ Konnte is_favorite Spalte nicht hinzufügen: $e');
      }
    }
    
    // Erstelle items Tabelle falls sie noch nicht existiert (für bestehende Datenbanken)
    await _ensureItemsTableExists(db);
    
    // Migration zu Version 5: Vollständiger Reset
    if (oldVersion < 5 && newVersion >= 5) {
      print('🔄 Starte vollständigen Reset (v4 → v5)...');
      
      // Lösche alle alten Tabellen
      await db.execute('DROP TABLE IF EXISTS inventory_items');
      await db.execute('DROP TABLE IF EXISTS player_characters');
      await db.execute('DROP TABLE IF EXISTS campaigns');
      await db.execute('DROP TABLE IF EXISTS items');
      
      // Erstelle alle Tabellen neu mit korrektem Schema
      await _createAllTables(db);
      
      print('✅ Alle Tabellen neu erstellt mit korrektem Schema (Version 5)');
    }
  }
  
  /// Stellt sicher, dass die items Tabelle existiert
  Future<void> _ensureItemsTableExists(Database db) async {
    try {
      // Prüfe ob Tabelle bereits existiert
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='items'",
      );
      
      if (result.isEmpty) {
        print('📦 Erstelle items Tabelle (nachträglich)...');
        
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
        
        // Indizes für items
        await db.execute('CREATE INDEX idx_items_name ON items(name)');
        await db.execute('CREATE INDEX idx_items_item_type ON items(item_type)');
        await db.execute('CREATE INDEX idx_items_rarity ON items(rarity)');
        
        print('✅ items Tabelle erstellt');
      } else {
        print('ℹ️ items Tabelle existiert bereits');
      }
    } catch (e) {
      print('⚠️ Fehler beim Erstellen der items Tabelle: $e');
    }
  }
  
  /// Schließt die Datenbankverbindung
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
  
  /// Setzt die Datenbank zurück (nur für Entwicklung)
  Future<void> reset() async {
    await close();
    final path = join(await getDatabasesPath(), 'dnd_helper_v2.db');
    await deleteDatabase(path);
    _database = await _initDatabase();
    print('✅ Datenbank wurde zurückgesetzt');
  }
  
  /// Löscht die Datenbank-Datei komplett (für Schema-Änderungen)
  Future<void> deleteDatabaseFile() async {
    await close();
    final path = join(await getDatabasesPath(), 'dnd_helper_v2.db');
    await deleteDatabase(path);
    print('✅ Datenbank-Datei wurde gelöscht');
  }
  
  /// Führt die Refactoring-Migration manuell aus (für Entwicklung/Tests)
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
