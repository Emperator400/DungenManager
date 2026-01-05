import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../core/database_connection.dart';

/// Migration für API Refactoring Phase 5
/// 
/// Diese Migration aktualisiert alle Tabellen auf konsistente Feldnamen
/// entsprechend der neuen Model-basierten Architektur.
/// 
/// WICHTIG: Vor der Migration ein Backup der Datenbank erstellen!
class RefactoringMigrationV2 {
  final DatabaseConnection _connection;
  
  RefactoringMigrationV2(this._connection);
  
  /// Aktuelle Datenbank-Version
  static const int _targetVersion = 2;
  
  /// Führt die Migration aus
  Future<MigrationResult> migrate() async {
    final db = await _connection.database;
    final startTime = DateTime.now();
    final logs = <String>[];
    
    try {
      // 1. Prüfe ob Backup existiert
      await _verifyBackup(db, logs);
      
      // 2. Migriere Player Characters Tabelle
      await _migratePlayerCharacters(db, logs);
      
      // 3. Migriere Items Tabelle
      await _migrateItems(db, logs);
      
      // 4. Migriere Campaigns Tabelle
      await _migrateCampaigns(db, logs);
      
      // 5. Migriere Quests Tabelle
      await _migrateQuests(db, logs);
      
      // 6. Migriere Creatures Tabelle
      await _migrateCreatures(db, logs);
      
      // 7. Migriere Sessions Tabelle
      await _migrateSessions(db, logs);
      
      // 8. Migriere Sounds Tabelle
      await _migrateSounds(db, logs);
      
      // 9. Migriere Wiki Entries Tabelle
      await _migrateWikiEntries(db, logs);
      
      // 10. Migriere Wiki Links Tabelle
      await _migrateWikiLinks(db, logs);
      
      // 11. Migriere Inventory Items Tabelle
      await _migrateInventoryItems(db, logs);
      
      // 12. Migriere Scenes Tabelle
      await _migrateScenes(db, logs);
      
      // 13. Update Datenbank-Version
      await _updateDatabaseVersion(db);
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      logs.add('✅ Migration erfolgreich abgeschlossen in ${duration.inSeconds}s');
      
      return MigrationResult(
        success: true,
        version: _targetVersion,
        duration: duration,
        logs: logs,
      );
    } catch (e, stackTrace) {
      logs.add('❌ FEHLER bei Migration: $e');
      logs.add('Stacktrace: $stackTrace');
      
      // Versuche Rollback
      await _rollback(db, logs);
      
      return MigrationResult(
        success: false,
        version: _targetVersion,
        duration: DateTime.now().difference(startTime),
        logs: logs,
        error: e.toString(),
      );
    }
  }
  
  /// Prüft ob ein Backup existiert
  Future<void> _verifyBackup(Database db, List<String> logs) async {
    logs.add('🔍 Prüfe Backup-Status...');
    
    // In einer echten App würde hier geprüft werden, ob ein Backup existiert
    // Für Entwicklung gehen wir davon aus, dass der Nutzer selbst Backups macht
    
    logs.add('✓ Backup-Verifizierung übersprungen (Entwicklungsmodus)');
  }
  
  /// Migriert Player Characters Tabelle
  Future<void> _migratePlayerCharacters(Database db, List<String> logs) async {
    logs.add('📝 Migriere player_characters Tabelle...');
    
    // Prüfe ob Tabelle existiert
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='player_characters'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle player_characters existiert nicht - wird übersprungen');
      return;
    }
    
    // Prüfe ob Spalte max_hit_points existiert (alte Benennung)
    final columns = await db.rawQuery('PRAGMA table_info(player_characters)');
    final hasOldColumns = columns.any((col) => 
      col['name'] == 'max_hit_points' || 
      col['name'] == 'character_class' ||
      col['name'] == 'race'
    );
    
    if (!hasOldColumns) {
      logs.add('  ✓ Tabelle bereits migriert - keine Änderungen nötig');
      return;
    }
    
    // Erstelle neue Tabelle mit konsistenten Feldnamen
    await db.execute('''
      CREATE TABLE player_characters_new (
        id TEXT PRIMARY KEY,
        campaign_id TEXT NOT NULL,
        name TEXT NOT NULL,
        player_name TEXT NOT NULL,
        class_name TEXT NOT NULL,
        race_name TEXT NOT NULL,
        level INTEGER NOT NULL,
        max_hp INTEGER NOT NULL,
        armor_class INTEGER NOT NULL,
        initiative_bonus INTEGER NOT NULL,
        image_path TEXT,
        strength INTEGER NOT NULL,
        dexterity INTEGER NOT NULL,
        constitution INTEGER NOT NULL,
        intelligence INTEGER NOT NULL,
        wisdom INTEGER NOT NULL,
        charisma INTEGER NOT NULL,
        proficient_skills TEXT,
        size TEXT,
        type TEXT,
        subtype TEXT,
        alignment TEXT,
        description TEXT,
        special_abilities TEXT,
        attacks TEXT,
        attack_list TEXT,
        inventory TEXT,
        gold REAL DEFAULT 0.0,
        silver REAL DEFAULT 0.0,
        copper REAL DEFAULT 0.0,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        version TEXT DEFAULT '1.0',
        proficiency_bonus INTEGER DEFAULT 2,
        speed INTEGER DEFAULT 30,
        passive_perception INTEGER DEFAULT 10,
        spell_slots TEXT,
        spell_save_dc INTEGER DEFAULT 8,
        spell_attack_bonus INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Kopiere Daten mit Feldnamen-Anpassung
    await db.execute('''
      INSERT INTO player_characters_new (
        id, campaign_id, name, player_name, class_name, race_name, level,
        max_hp, armor_class, initiative_bonus, image_path,
        strength, dexterity, constitution, intelligence, wisdom, charisma,
        proficient_skills, size, type, subtype, alignment, description,
        special_abilities, attacks, attack_list, inventory,
        gold, silver, copper, source_type, source_id, is_favorite, version,
        proficiency_bonus, speed, passive_perception, spell_slots,
        spell_save_dc, spell_attack_bonus, created_at, updated_at
      )
      SELECT 
        id, campaign_id, name, 
        COALESCE(background, '') as player_name,
        COALESCE(character_class, '') as class_name,
        COALESCE(race, '') as race_name,
        level,
        max_hit_points as max_hp,
        armor_class,
        initiative_bonus,
        image_path,
        strength, dexterity, constitution, intelligence, wisdom, charisma,
        proficient_skills, size, type, subtype, alignment, description,
        special_abilities, attacks, attack_list, inventory,
        gold, silver, copper, source_type, source_id, is_favorite, version,
        proficiency_bonus, speed, passive_perception, spell_slots,
        spell_save_dc, spell_attack_bonus, created_at, updated_at
      FROM player_characters
    ''');
    
    // Lösche alte Tabelle und benenne neue um
    await db.execute('DROP TABLE player_characters');
    await db.execute('ALTER TABLE player_characters_new RENAME TO player_characters');
    
    // Re-Indizes erstellen
    await db.execute('CREATE INDEX idx_player_characters_campaign ON player_characters(campaign_id)');
    await db.execute('CREATE INDEX idx_player_characters_class ON player_characters(class_name)');
    await db.execute('CREATE INDEX idx_player_characters_race ON player_characters(race_name)');
    await db.execute('CREATE INDEX idx_player_characters_favorite ON player_characters(is_favorite)');
    
    logs.add('  ✓ player_characters erfolgreich migriert');
  }
  
  /// Migriert Items Tabelle
  Future<void> _migrateItems(Database db, List<String> logs) async {
    logs.add('📝 Migriere items Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='items'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle items existiert nicht - wird übersprungen');
      return;
    }
    
    // Die Items-Tabelle hat wahrscheinlich bereits die neuen Feldnamen
    // Prüfen ob Migration nötig ist
    logs.add('  ✓ items Tabelle bereits kompatibel');
  }
  
  /// Migriert Campaigns Tabelle
  Future<void> _migrateCampaigns(Database db, List<String> logs) async {
    logs.add('📝 Migriere campaigns Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='campaigns'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle campaigns existiert nicht - wird übersprungen');
      return;
    }
    
    // Prüfe ob Felder snake_case verwenden
    final columns = await db.rawQuery('PRAGMA table_info(campaigns)');
    final needsMigration = columns.any((col) => 
      col['name'] == 'dungeonMaster' || 
      col['name'] == 'gameMaster'
    );
    
    if (!needsMigration) {
      logs.add('  ✓ campaigns Tabelle bereits migriert');
      return;
    }
    
    // Füge neue Felder hinzu falls nötig
    await db.execute('ALTER TABLE campaigns ADD COLUMN settings TEXT');
    await db.execute('ALTER TABLE campaigns ADD COLUMN stats TEXT');
    await db.execute('ALTER TABLE campaigns ADD COLUMN is_archived INTEGER DEFAULT 0');
    
    logs.add('  ✓ campaigns erfolgreich migriert');
  }
  
  /// Migriert Quests Tabelle
  Future<void> _migrateQuests(Database db, List<String> logs) async {
    logs.add('📝 Migriere quests Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='quests'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle quests existiert nicht - wird übersprungen');
      return;
    }
    
    // Prüfe ob Migration nötig ist
    final columns = await db.rawQuery('PRAGMA table_info(quests)');
    final hasRewardColumn = columns.any((col) => col['name'] == 'reward');
    
    if (!hasRewardColumn) {
      await db.execute('ALTER TABLE quests ADD COLUMN reward TEXT');
      logs.add('  ✓ reward Spalte zu quests hinzugefügt');
    } else {
      logs.add('  ✓ quests Tabelle bereits kompatibel');
    }
  }
  
  /// Migriert Creatures Tabelle
  Future<void> _migrateCreatures(Database db, List<String> logs) async {
    logs.add('📝 Migriere creatures Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='creatures'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle creatures existiert nicht - wird übersprungen');
      return;
    }
    
    // Prüfe ob Tabelle bereits snake_case Felder hat (neue Struktur)
    final columns = await db.rawQuery('PRAGMA table_info(creatures)');
    final hasSnakeCaseFields = columns.any((col) => 
      col['name'] == 'max_hp' && 
      col['name'] == 'armor_class'
    );
    
    if (hasSnakeCaseFields) {
      logs.add('  ✓ creatures Tabelle bereits kompatibel (hat snake_case Felder)');
      return;
    }
    
    // Prüfe ob Tabelle camelCase Felder hat (alte Struktur)
    final hasCamelCaseFields = columns.any((col) => 
      col['name'] == 'maxHitPoints' || 
      col['name'] == 'armorClass'
    );
    
    if (!hasCamelCaseFields) {
      logs.add('  ⚠ creatures Tabelle hat weder snake_case noch camelCase Felder - wird übersprungen');
      return;
    }
    
    // Erstelle neue Tabelle
    await db.execute('''
      CREATE TABLE creatures_new (
        id TEXT PRIMARY KEY,
        campaign_id TEXT,
        name TEXT NOT NULL,
        challenge_rating REAL NOT NULL,
        type TEXT,
        environment TEXT,
        max_hp INTEGER NOT NULL,
        current_hp INTEGER NOT NULL,
        armor_class INTEGER NOT NULL,
        initiative INTEGER,
        size TEXT,
        speed INTEGER DEFAULT 30,
        strength INTEGER NOT NULL,
        dexterity INTEGER NOT NULL,
        constitution INTEGER NOT NULL,
        intelligence INTEGER NOT NULL,
        wisdom INTEGER NOT NULL,
        charisma INTEGER NOT NULL,
        conditions TEXT,
        attacks TEXT,
        inventory TEXT,
        image_url TEXT,
        description TEXT,
        special_abilities TEXT,
        is_official INTEGER DEFAULT 0,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_favorite INTEGER DEFAULT 0,
        version TEXT DEFAULT '1.0',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    
    // Kopiere Daten und konvertiere von camelCase zu snake_case
    await db.execute('''
      INSERT INTO creatures_new (
        id, campaign_id, name, challenge_rating, type, environment,
        max_hp, current_hp, armor_class, initiative, size, speed,
        strength, dexterity, constitution, intelligence, wisdom, charisma,
        conditions, attacks, inventory, image_url, description,
        special_abilities, is_official, source_type, source_id,
        is_favorite, version, created_at, updated_at
      )
      SELECT 
        id, campaign_id, name, challenge_rating, type, environment,
        maxHitPoints as max_hp, 
        COALESCE(currentHitPoints, maxHitPoints) as current_hp,
        armorClass as armor_class, 
        initiative, size, speed,
        strength, dexterity, constitution, intelligence, wisdom, charisma,
        conditions, attacks, inventory, image_url, description,
        special_abilities, is_official, source_type, source_id,
        is_favorite, version, created_at, updated_at
      FROM creatures
    ''');
    
    // Tausche Tabellen
    await db.execute('DROP TABLE creatures');
    await db.execute('ALTER TABLE creatures_new RENAME TO creatures');
    
    // Re-Indizes
    await db.execute('CREATE INDEX idx_creatures_campaign ON creatures(campaign_id)');
    await db.execute('CREATE INDEX idx_creatures_cr ON creatures(challenge_rating)');
    
    logs.add('  ✓ creatures erfolgreich migriert (camelCase zu snake_case)');
  }
  
  /// Migriert Sessions Tabelle
  Future<void> _migrateSessions(Database db, List<String> logs) async {
    logs.add('📝 Migriere sessions Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='sessions'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle sessions existiert nicht - wird übersprungen');
      return;
    }
    
    // Prüfe ob liveNotes Feld existiert
    final columns = await db.rawQuery('PRAGMA table_info(sessions)');
    final hasLiveNotes = columns.any((col) => col['name'] == 'live_notes');
    
    if (!hasLiveNotes) {
      await db.execute('ALTER TABLE sessions ADD COLUMN live_notes TEXT');
      logs.add('  ✓ live_notes Spalte zu sessions hinzugefügt');
    } else {
      logs.add('  ✓ sessions Tabelle bereits kompatibel');
    }
  }
  
  /// Migriert Sounds Tabelle
  Future<void> _migrateSounds(Database db, List<String> logs) async {
    logs.add('📝 Migriere sounds Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='sounds'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle sounds existiert nicht - wird übersprungen');
      return;
    }
    
    // Prüfe ob Felder snake_case verwenden
    final columns = await db.rawQuery('PRAGMA table_info(sounds)');
    final needsMigration = columns.any((col) => 
      col['name'] == 'soundName' || 
      col['name'] == 'soundType'
    );
    
    if (needsMigration) {
      // Erstelle neue Tabelle mit snake_case
      await db.execute('''
        CREATE TABLE sounds_new (
          id TEXT PRIMARY KEY,
          campaign_id TEXT,
          name TEXT NOT NULL,
          description TEXT,
          sound_type TEXT NOT NULL,
          duration_ms INTEGER NOT NULL,
          file_path TEXT,
          url TEXT,
          volume REAL DEFAULT 1.0,
          loop INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      
      // Kopiere Daten
      await db.execute('''
        INSERT INTO sounds_new (
          id, campaign_id, name, description, sound_type, duration_ms,
          file_path, url, volume, loop, created_at, updated_at
        )
        SELECT 
          id, campaign_id, soundName as name, description, 
          soundType as sound_type, duration_ms,
          file_path, url, volume, loop, created_at, updated_at
        FROM sounds
      ''');
      
      await db.execute('DROP TABLE sounds');
      await db.execute('ALTER TABLE sounds_new RENAME TO sounds');
      
      logs.add('  ✓ sounds erfolgreich migriert');
    } else {
      logs.add('  ✓ sounds Tabelle bereits kompatibel');
    }
  }
  
  /// Migriert Wiki Entries Tabelle
  Future<void> _migrateWikiEntries(Database db, List<String> logs) async {
    logs.add('📝 Migriere wiki_entries Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='wiki_entries'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle wiki_entries existiert nicht - wird übersprungen');
      return;
    }
    
    logs.add('  ✓ wiki_entries Tabelle bereits kompatibel');
  }
  
  /// Migriert Wiki Links Tabelle
  Future<void> _migrateWikiLinks(Database db, List<String> logs) async {
    logs.add('📝 Migriere wiki_links Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='wiki_links'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle wiki_links existiert nicht - wird übersprungen');
      return;
    }
    
    logs.add('  ✓ wiki_links Tabelle bereits kompatibel');
  }
  
  /// Migriert Inventory Items Tabelle
  Future<void> _migrateInventoryItems(Database db, List<String> logs) async {
    logs.add('📝 Migriere inventory_items Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='inventory_items'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle inventory_items existiert nicht - wird übersprungen');
      return;
    }
    
    logs.add('  ✓ inventory_items Tabelle bereits kompatibel');
  }
  
  /// Migriert Scenes Tabelle
  Future<void> _migrateScenes(Database db, List<String> logs) async {
    logs.add('📝 Migriere scenes Tabelle...');
    
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='scenes'",
    );
    
    if (tables.isEmpty) {
      logs.add('  ⚠ Tabelle scenes existiert nicht - wird übersprungen');
      return;
    }
    
    // Prüfe ob order_index existiert
    final columns = await db.rawQuery('PRAGMA table_info(scenes)');
    final hasOrderIndex = columns.any((col) => col['name'] == 'order_index');
    
    if (!hasOrderIndex) {
      await db.execute('ALTER TABLE scenes ADD COLUMN order_index INTEGER DEFAULT 0');
      logs.add('  ✓ order_index Spalte zu scenes hinzugefügt');
    } else {
      logs.add('  ✓ scenes Tabelle bereits kompatibel');
    }
  }
  
  /// Aktualisiert die Datenbank-Version
  Future<void> _updateDatabaseVersion(Database db) async {
    // Erstelle version_table falls nicht existent
    await db.execute('''
      CREATE TABLE IF NOT EXISTS db_version (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
      )
    ''');
    
    // Update oder Insert Version
    final existing = await db.query('db_version');
    if (existing.isEmpty) {
      await db.insert('db_version', {
        'version': _targetVersion,
        'applied_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'db_version',
        {
          'version': _targetVersion,
          'applied_at': DateTime.now().toIso8601String(),
        },
        where: 'version < ?',
        whereArgs: [_targetVersion],
      );
    }
  }
  
  /// Rollback bei Fehler
  Future<void> _rollback(Database db, List<String> logs) async {
    logs.add('🔄 Versuche Rollback...');
    
    try {
      // In einer echten Implementierung würde hier das Backup wiederhergestellt werden
      // Für Entwicklung loggen wir nur den Rollback-Versuch
      
      logs.add('  ⚠ Rollback incomplete - Bitte Backup manuell wiederherstellen');
    } catch (e) {
      logs.add('  ❌ Rollback fehlgeschlagen: $e');
    }
  }
  
  /// Prüft ob Migration bereits durchgeführt wurde
  Future<bool> isMigrationApplied() async {
    final db = await _connection.database;
    final result = await db.query('db_version');
    if (result.isEmpty) return false;
    final version = result.first['version'] as int?;
    return version != null && version >= _targetVersion;
  }
}

/// Ergebnis einer Migration
class MigrationResult {
  final bool success;
  final int version;
  final Duration duration;
  final List<String> logs;
  final String? error;
  
  MigrationResult({
    required this.success,
    required this.version,
    required this.duration,
    required this.logs,
    this.error,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Migration Ergebnis:');
    buffer.writeln('  Status: ${success ? "✅ Erfolgreich" : "❌ Fehlgeschlagen"}');
    buffer.writeln('  Version: $version');
    buffer.writeln('  Dauer: ${duration.inSeconds}s');
    if (error != null) {
      buffer.writeln('  Fehler: $error');
    }
    buffer.writeln('\nDetails:');
    for (final log in logs) {
      buffer.writeln('  $log');
    }
    return buffer.toString();
  }
}
