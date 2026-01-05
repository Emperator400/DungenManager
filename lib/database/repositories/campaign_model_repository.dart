import '../core/database_connection.dart';
import '../../models/campaign.dart';
import 'model_repository.dart';

/// Repository für Campaign Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Campaign Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class CampaignModelRepository extends ModelRepository<Campaign> {
  CampaignModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => Campaign.tableName;

  @override
  Map<String, dynamic> toDatabaseMap(Campaign campaign) {
    return campaign.toDatabaseMap();
  }

  @override
  Campaign fromDatabaseMap(Map<String, dynamic> map) {
    return Campaign.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Kampagnen nach Status
  Future<List<Campaign>> findByStatus(CampaignStatus status) async {
    return await findWhere(
      where: 'status = ?',
      whereArgs: [status.toString().split('.').last],
      orderBy: 'title ASC',
    );
  }

  /// Findet Kampagnen nach Typ
  Future<List<Campaign>> findByType(CampaignType type) async {
    return await findWhere(
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'title ASC',
    );
  }

  /// Findet Kampagnen nach Dungeon Master
  Future<List<Campaign>> findByDungeonMaster(String dungeonMasterId) async {
    return await findWhere(
      where: 'dungeon_master_id = ?',
      whereArgs: [dungeonMasterId],
      orderBy: 'title ASC',
    );
  }

  /// Sucht Kampagnen mit komplexen Filtern
  Future<List<Campaign>> searchCampaigns({
    String? searchTerm,
    CampaignStatus? status,
    CampaignType? type,
    String? dungeonMasterId,
    bool? isPublic,
    int? limit,
    int? offset,
  }) async {
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(title LIKE ? OR description LIKE ?)');
      whereArgs.addAll(['%$searchTerm%', '%$searchTerm%']);
    }

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status.toString().split('.').last);
    }

    if (type != null) {
      whereConditions.add('type = ?');
      whereArgs.add(type.toString().split('.').last);
    }

    if (dungeonMasterId != null) {
      whereConditions.add('dungeon_master_id = ?');
      whereArgs.add(dungeonMasterId);
    }

    if (isPublic != null) {
      // is_public ist in settings gespeichert - müssen JSON parsen
      // Für einfache Suche verwenden wir einen anderen Ansatz
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'updated_at DESC, title ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// Findet aktive Kampagnen
  Future<List<Campaign>> findActiveCampaigns() async {
    return await findByStatus(CampaignStatus.active);
  }

  /// Findet aktive oder geplante Kampagnen
  Future<List<Campaign>> findPlanningOrActiveCampaigns() async {
    return await findWhere(
      where: 'status IN (?, ?)',
      whereArgs: [
        CampaignStatus.planning.toString().split('.').last,
        CampaignStatus.active.toString().split('.').last,
      ],
      orderBy: 'updated_at DESC',
    );
  }

  /// ===== KAMPAGNEN-STATISTIKEN =====

  /// Holt umfassende Statistiken über Kampagnen
  Future<Map<String, dynamic>> getCampaignStatistics() async {
    // Gesamtzahl der Kampagnen
    final totalCount = await count();
    
    // Status-Verteilung
    final statusDistributionResult = await rawQuery('''
      SELECT 
        status,
        COUNT(*) as count
      FROM $tableName
      GROUP BY status
      ORDER BY status
    ''');
    
    // Typ-Verteilung
    final typeDistributionResult = await rawQuery('''
      SELECT 
        type,
        COUNT(*) as count
      FROM $tableName
      GROUP BY type
      ORDER BY type
    ''');

    // Kampagnen mit Sessions
    final campaignsWithSessions = await rawQuery('''
      SELECT COUNT(*) as count
      FROM $tableName
      WHERE session_ids IS NOT NULL AND session_ids != ''
    ''');

    // Durchschnittliche Anzahl an Sessions pro Kampagne
    final avgSessionsResult = await rawQuery('''
      SELECT AVG(
        CASE 
          WHEN session_ids IS NULL OR session_ids = '' THEN 0
          ELSE LENGTH(session_ids) - LENGTH(REPLACE(session_ids, ',', '')) + 1
        END
      ) as avg_sessions
      FROM $tableName
    ''');
    final avgSessions = (avgSessionsResult.first['avg_sessions'] as double?)?.toDouble() ?? 0.0;

    return {
      'totalCampaigns': totalCount,
      'statusDistribution': statusDistributionResult,
      'typeDistribution': typeDistributionResult,
      'campaignsWithSessions': campaignsWithSessions.first['count'] as int? ?? 0,
      'averageSessionsPerCampaign': avgSessions,
    };
  }

  /// ===== KAMPAGNEN-OPERATIONEN =====

  /// Kampagnen-Status ändern
  Future<Campaign> updateStatus(String campaignId, CampaignStatus newStatus) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    final updatedCampaign = campaign.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    
    // Setze startedAt oder completedAt basierend auf Status
    if (newStatus == CampaignStatus.active && campaign.startedAt == null) {
      return await update(updatedCampaign.copyWith(startedAt: DateTime.now()));
    } else if (newStatus == CampaignStatus.completed) {
      return await update(updatedCampaign.copyWith(completedAt: DateTime.now()));
    }
    
    return await update(updatedCampaign);
  }

  /// Dungeon Master ändern
  Future<Campaign> updateDungeonMaster(String campaignId, String newDungeonMasterId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    final updatedCampaign = campaign.copyWith(
      dungeonMasterId: newDungeonMasterId,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Player zu Kampagne hinzufügen
  Future<Campaign> addPlayerCharacter(String campaignId, String playerId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    if (campaign.playerCharacterIds.contains(playerId)) {
      return campaign; // Bereits vorhanden
    }

    final updatedPlayerIds = List<String>.from(campaign.playerCharacterIds)..add(playerId);
    final updatedCampaign = campaign.copyWith(
      playerCharacterIds: updatedPlayerIds,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Player aus Kampagne entfernen
  Future<Campaign> removePlayerCharacter(String campaignId, String playerId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    final updatedPlayerIds = campaign.playerCharacterIds.where((id) => id != playerId).toList();
    final updatedCampaign = campaign.copyWith(
      playerCharacterIds: updatedPlayerIds,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Quest zu Kampagne hinzufügen
  Future<Campaign> addQuest(String campaignId, String questId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    if (campaign.questIds.contains(questId)) {
      return campaign;
    }

    final updatedQuestIds = List<String>.from(campaign.questIds)..add(questId);
    final updatedCampaign = campaign.copyWith(
      questIds: updatedQuestIds,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Quest aus Kampagne entfernen
  Future<Campaign> removeQuest(String campaignId, String questId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    final updatedQuestIds = campaign.questIds.where((id) => id != questId).toList();
    final updatedCampaign = campaign.copyWith(
      questIds: updatedQuestIds,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Session zu Kampagne hinzufügen
  Future<Campaign> addSession(String campaignId, String sessionId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    if (campaign.sessionIds.contains(sessionId)) {
      return campaign;
    }

    final updatedSessionIds = List<String>.from(campaign.sessionIds)..add(sessionId);
    final updatedCampaign = campaign.copyWith(
      sessionIds: updatedSessionIds,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Wiki-Entry zu Kampagne hinzufügen
  Future<Campaign> addWikiEntry(String campaignId, String wikiEntryId) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    if (campaign.wikiEntryIds.contains(wikiEntryId)) {
      return campaign;
    }

    final updatedWikiEntryIds = List<String>.from(campaign.wikiEntryIds)..add(wikiEntryId);
    final updatedCampaign = campaign.copyWith(
      wikiEntryIds: updatedWikiEntryIds,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Einstellungen aktualisieren
  Future<Campaign> updateSettings(String campaignId, CampaignSettings newSettings) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    final updatedCampaign = campaign.copyWith(
      settings: newSettings,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// Statistiken aktualisieren
  Future<Campaign> updateStats(String campaignId, CampaignStats newStats) async {
    final campaign = await findById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found: $campaignId');
    }

    final updatedCampaign = campaign.copyWith(
      stats: newStats,
      updatedAt: DateTime.now(),
    );
    return await update(updatedCampaign);
  }

  /// ===== ADVANCED SUCHEN =====

  /// Kampagnen nach Titel suchen
  Future<List<Campaign>> findByTitle(String title) async {
    return await findWhere(
      where: 'title LIKE ?',
      whereArgs: ['%$title%'],
      orderBy: 'title ASC',
    );
  }

  /// Kampagnen ohne Players finden
  Future<List<Campaign>> findCampaignsWithoutPlayers() async {
    return await findWhere(
      where: 'player_character_ids IS NULL OR player_character_ids = ?',
      whereArgs: [''],
      orderBy: 'title ASC',
    );
  }

  /// Kampagnen nach Anzahl der Players sortieren
  Future<List<Campaign>> findCampaignsSortedByPlayerCount({bool descending = true}) async {
    final allCampaigns = await findAll();
    final sortedCampaigns = List<Campaign>.from(allCampaigns);
    sortedCampaigns.sort((a, b) {
      final comparison = a.playerCharacterIds.length.compareTo(b.playerCharacterIds.length);
      return descending ? -comparison : comparison;
    });
    return sortedCampaigns;
  }

  /// ===== BATCH OPERATIONEN =====

  /// Mehrere Kampagnen auf einen Status setzen
  Future<List<Campaign>> setMultipleCampaignsStatus(
    List<String> campaignIds,
    CampaignStatus status,
  ) async {
    final results = <Campaign>[];
    
    for (final campaignId in campaignIds) {
      try {
        final result = await updateStatus(campaignId, status);
        results.add(result);
      } catch (e) {
        print('Error setting status for campaign $campaignId: $e');
      }
    }
    
    return results;
  }
}
