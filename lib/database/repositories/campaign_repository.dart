import '../core/database_connection.dart';
import '../core/database_entity.dart';
import '../entities/campaign_entity.dart';
import 'base_repository.dart';

/// Repository für Campaign-Entitäten
/// Bietet spezialisierte Methoden für Campaign-Operationen
/// 
/// @deprecated Dieses Repository wird durch CampaignModelRepository ersetzt.
/// Bitte zur neuen ModelRepository-Architektur migrieren.
/// Siehe PHASE6_SERVICE_MIGRATION_PLAN.md für Details zur Migration.
@deprecated
class CampaignRepository extends BaseRepository<CampaignEntity> {
  CampaignRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'campaigns';

  @override
  DatabaseEntity<CampaignEntity> get entityFactory => CampaignEntity(
    id: '',
    name: '',
    description: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  /// ===== SPEZIALISIERTE METHODEN FÜR CAMPAIGNS =====

  /// Findet alle aktiven Campaigns
  Future<List<CampaignEntity>> findActiveCampaigns({
    String? orderBy = 'created_at DESC',
  }) async {
    return await findWhere(
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: orderBy,
    );
  }

  /// Findet alle inaktiven Campaigns
  Future<List<CampaignEntity>> findInactiveCampaigns({
    String? orderBy = 'created_at DESC',
  }) async {
    return await findWhere(
      where: 'is_active = ?',
      whereArgs: [0],
      orderBy: orderBy,
    );
  }

  /// Findet Campaigns nach Game Master
  Future<List<CampaignEntity>> findByGameMaster(String gameMaster) async {
    return await findWhere(
      where: 'game_master LIKE ?',
      whereArgs: ['%$gameMaster%'],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Campaigns mit bestimmten Tags
  Future<List<CampaignEntity>> findByTags(List<String> tags) async {
    if (tags.isEmpty) return findAll();
    
    final conditions = tags.map((tag) => 'tags LIKE ?').join(' OR ');
    final args = tags.map((tag) => '%$tag%').toList();
    
    return await findWhere(
      where: conditions,
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Campaigns in einem bestimmten Zeitraum
  Future<List<CampaignEntity>> findByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];
    
    if (startDate != null) {
      conditions.add('start_date >= ?');
      args.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      conditions.add('end_date <= ?');
      args.add(endDate.toIso8601String());
    }
    
    if (conditions.isEmpty) return findAll();
    
    return await findWhere(
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'start_date ASC',
    );
  }

  /// Sucht Campaigns mit erweiterten Kriterien
  Future<List<CampaignEntity>> searchCampaigns({
    String? searchTerm,
    String? gameMaster,
    List<String>? tags,
    bool? isActive,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    int? limit,
    int? offset,
  }) async {
    final conditions = <String>[];
    final args = <dynamic>[];
    
    if (searchTerm != null && searchTerm.isNotEmpty) {
      conditions.add('(name LIKE ? OR description LIKE ?)');
      args.addAll(['%$searchTerm%', '%$searchTerm%']);
    }
    
    if (gameMaster != null && gameMaster.isNotEmpty) {
      conditions.add('game_master LIKE ?');
      args.add('%$gameMaster%');
    }
    
    if (tags != null && tags.isNotEmpty) {
      final tagConditions = tags.map((tag) => 'tags LIKE ?').join(' OR ');
      conditions.add('($tagConditions)');
      args.addAll(tags.map((tag) => '%$tag%'));
    }
    
    if (isActive != null) {
      conditions.add('is_active = ?');
      args.add(isActive ? 1 : 0);
    }
    
    if (startDateFrom != null) {
      conditions.add('start_date >= ?');
      args.add(startDateFrom.toIso8601String());
    }
    
    if (startDateTo != null) {
      conditions.add('start_date <= ?');
      args.add(startDateTo.toIso8601String());
    }
    
    return await findWhere(
      where: conditions.isNotEmpty ? conditions.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// ===== STATISTIK- UND AGGREGATMETHODEN =====

  /// Zählt aktive Campaigns
  Future<int> countActiveCampaigns() async {
    return await count(where: 'is_active = ?', whereArgs: [1]);
  }

  /// Zählt inaktive Campaigns
  Future<int> countInactiveCampaigns() async {
    return await count(where: 'is_active = ?', whereArgs: [0]);
  }

  /// Holt die jüngsten Campaigns
  Future<List<CampaignEntity>> getRecentCampaigns({
    int limit = 5,
    bool onlyActive = false,
  }) async {
    final conditions = onlyActive ? 'is_active = ?' : null;
    final args = onlyActive ? [1] : null;
    
    return await findWhere(
      where: conditions,
      whereArgs: args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  /// Holt Campaigns nach Erstellungsdatum
  Future<List<CampaignEntity>> getCampaignsByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
    
    return await findWhere(
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );
  }

  /// ===== BATCH OPERATIONEN =====

  /// Aktiviert mehrere Campaigns auf einmal
  Future<void> activateCampaigns(List<String> campaignIds) async {
    if (campaignIds.isEmpty) return;
    
    final placeholders = List.filled(campaignIds.length, '?').join(',');
    await executeRaw(
      'UPDATE campaigns SET is_active = 1, updated_at = ? WHERE id IN ($placeholders)',
      [DateTime.now().toIso8601String(), ...campaignIds],
    );
  }

  /// Deaktiviert mehrere Campaigns auf einmal
  Future<void> deactivateCampaigns(List<String> campaignIds) async {
    if (campaignIds.isEmpty) return;
    
    final placeholders = List.filled(campaignIds.length, '?').join(',');
    await executeRaw(
      'UPDATE campaigns SET is_active = 0, updated_at = ? WHERE id IN ($placeholders)',
      [DateTime.now().toIso8601String(), ...campaignIds],
    );
  }

  /// Aktualisiert den Game Master für mehrere Campaigns
  Future<void> updateGameMaster(List<String> campaignIds, String newGameMaster) async {
    if (campaignIds.isEmpty) return;
    
    final placeholders = List.filled(campaignIds.length, '?').join(',');
    await executeRaw(
      'UPDATE campaigns SET game_master = ?, updated_at = ? WHERE id IN ($placeholders)',
      [newGameMaster, DateTime.now().toIso8601String(), ...campaignIds],
    );
  }

  /// ===== UTILITY METHODEN =====

  /// Prüft ob ein Campaign-Name bereits existiert
  Future<bool> nameExists(String name, {String? excludeId}) async {
    final conditions = ['name = ?'];
    final args = [name];
    
    if (excludeId != null) {
      conditions.add('id != ?');
      args.add(excludeId);
    }
    
    final count = await this.count(
      where: conditions.join(' AND '),
      whereArgs: args,
    );
    
    return count > 0;
  }

  /// Holt eine Campaign mit allen zugehörigen Daten (placeholder für zukünftige Implementierung)
  Future<Map<String, dynamic>?> getCampaignWithRelations(String campaignId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) return null;
    
    // Hier könnten zukünftige Relationen geladen werden:
    // - Sessions
    // - Player Characters
    // - Creatures
    // - etc.
    
    return {
      'campaign': campaign,
      'sessionCount': 0, // Placeholder
      'characterCount': 0, // Placeholder
      'lastActivity': campaign.updatedAt,
    };
  }

  /// Holt alle Game Master mit Anzahl ihrer Campaigns
  Future<List<Map<String, dynamic>>> getGameMasterStats() async {
    final results = await rawQuery('''
      SELECT 
        game_master,
        COUNT(*) as campaign_count,
        COUNT(CASE WHEN is_active = 1 THEN 1 END) as active_count
      FROM campaigns 
      WHERE game_master IS NOT NULL AND game_master != ''
      GROUP BY game_master
      ORDER BY campaign_count DESC, active_count DESC
    ''');
    
    return results.map((row) => {
      'gameMaster': row['game_master'] as String,
      'campaignCount': row['campaign_count'] as int,
      'activeCount': row['active_count'] as int,
    }).toList();
  }

  /// Holt statistische Übersicht über Campaigns
  Future<Map<String, dynamic>> getCampaignStatistics() async {
    final totalCampaigns = await count();
    final activeCampaigns = await countActiveCampaigns();
    final inactiveCampaigns = await countInactiveCampaigns();
    
    // Campaigns nach Monat gruppieren
    final monthlyStats = await rawQuery('''
      SELECT 
        strftime('%Y-%m', created_at) as month,
        COUNT(*) as count
      FROM campaigns
      GROUP BY strftime('%Y-%m', created_at)
      ORDER BY month DESC
      LIMIT 12
    ''');
    
    // Top Game Master
    final topGameMasters = await getGameMasterStats();
    
    return {
      'totalCampaigns': totalCampaigns,
      'activeCampaigns': activeCampaigns,
      'inactiveCampaigns': inactiveCampaigns,
      'activationRate': totalCampaigns > 0 ? (activeCampaigns / totalCampaigns * 100) : 0,
      'monthlyStats': monthlyStats,
      'topGameMasters': topGameMasters.take(5).toList(),
    };
  }

  /// Löscht Campaigns sicher (mit Plausibilitätsprüfung)
  Future<bool> safeDelete(String campaignId) async {
    // Prüfen ob Campaign existiert
    final campaign = await findById(campaignId);
    if (campaign == null) return false;
    
    // Hier könnten zukünftige Abhängigkeitsprüfungen stattfinden:
    // - Gibt es aktive Sessions?
    // - Gibt es zugeordnete Charaktere?
    
    // Für jetzt: einfaches Löschen
    await delete(campaignId);
    return true;
  }

  /// Kopiert eine Campaign (creates a duplicate)
  Future<CampaignEntity?> duplicateCampaign(String campaignId, {String? newName}) async {
    final original = await findById(campaignId);
    if (original == null) return null;
    
    final duplicate = CampaignEntity.create(
      name: newName ?? '${original.name} (Copy)',
      description: original.description,
      gameMaster: original.gameMaster,
      imageUrl: original.imageUrl,
      tags: List.from(original.tags),
    );
    
    return await create(duplicate);
  }
}
