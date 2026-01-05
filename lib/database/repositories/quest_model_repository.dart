import '../core/database_connection.dart';
import '../../models/quest.dart';
import '../../models/quest_reward.dart';
import 'model_repository.dart';

/// Repository für Quest Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Quest Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
/// Es ersetzt das Entity-basierte System.
class QuestModelRepository extends ModelRepository<Quest> {
  QuestModelRepository(DatabaseConnection connection) : super(connection);

  @override
  String get tableName => 'quests';

  @override
  Map<String, dynamic> toDatabaseMap(Quest quest) {
    return quest.toDatabaseMap();
  }

  @override
  Quest fromDatabaseMap(Map<String, dynamic> map) {
    return Quest.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Quests nach Status
  Future<List<Quest>> findByStatus(QuestStatus status) async {
    return await findWhere(
      where: 'status = ?',
      whereArgs: [status.toString().split('.').last],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Quests nach Typ
  Future<List<Quest>> findByType(QuestType questType) async {
    return await findWhere(
      where: 'quest_type = ?',
      whereArgs: [questType.toString().split('.').last],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Quests nach Schwierigkeit
  Future<List<Quest>> findByDifficulty(QuestDifficulty difficulty) async {
    return await findWhere(
      where: 'difficulty = ?',
      whereArgs: [difficulty.toString().split('.').last],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Quests nach Kampagne
  Future<List<Quest>> findByCampaign(String campaignId) async {
    return await findWhere(
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Quests nach Level-Empfehlung
  Future<List<Quest>> findByRecommendedLevel(int level) async {
    return await findWhere(
      where: 'recommended_level = ?',
      whereArgs: [level],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet Quests nach Level-Bereich
  Future<List<Quest>> findByLevelRange(int minLevel, int maxLevel) async {
    return await findWhere(
      where: 'recommended_level BETWEEN ? AND ?',
      whereArgs: [minLevel, maxLevel],
      orderBy: 'recommended_level ASC, title ASC',
    );
  }

  /// Sucht Quests mit komplexen Filtern
  Future<List<Quest>> searchQuests({
    String? searchTerm,
    QuestStatus? status,
    QuestType? questType,
    QuestDifficulty? difficulty,
    String? campaignId,
    String? location,
    int? minLevel,
    int? maxLevel,
    bool? isFavorite,
    List<String>? tags,
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

    if (questType != null) {
      whereConditions.add('quest_type = ?');
      whereArgs.add(questType.toString().split('.').last);
    }

    if (difficulty != null) {
      whereConditions.add('difficulty = ?');
      whereArgs.add(difficulty.toString().split('.').last);
    }

    if (campaignId != null) {
      whereConditions.add('campaign_id = ?');
      whereArgs.add(campaignId);
    }

    if (location != null) {
      whereConditions.add('location LIKE ?');
      whereArgs.add('%$location%');
    }

    if (minLevel != null) {
      whereConditions.add('recommended_level >= ?');
      whereArgs.add(minLevel);
    }

    if (maxLevel != null) {
      whereConditions.add('recommended_level <= ?');
      whereArgs.add(maxLevel);
    }

    if (isFavorite != null) {
      whereConditions.add('is_favorite = ?');
      whereArgs.add(isFavorite ? 1 : 0);
    }

    if (tags != null && tags.isNotEmpty) {
      // Tags als LIKE-Suche implementieren
      final tagConditions = tags.map((tag) => 'tags LIKE ?').join(' OR ');
      whereConditions.add('($tagConditions)');
      whereArgs.addAll(tags.map((tag) => '%$tag%'));
    }

    final whereClause = whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

    return await findWhere(
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC, title ASC',
      limit: limit,
      offset: offset,
    );
  }

  /// Findet favorisierte Quests
  Future<List<Quest>> findFavoriteQuests() async {
    return await findWhere(
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet aktive Quests
  Future<List<Quest>> findActiveQuests() async {
    return await findByStatus(QuestStatus.active);
  }

  /// ===== QUEST-STATISTIKEN =====

  /// Holt umfassende Statistiken über Quests
  Future<Map<String, dynamic>> getQuestStatistics() async {
    // Gesamtzahl der Quests
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
        quest_type,
        COUNT(*) as count
      FROM $tableName
      GROUP BY quest_type
      ORDER BY quest_type
    ''');

    // Schwierigkeits-Verteilung
    final difficultyDistributionResult = await rawQuery('''
      SELECT 
        difficulty,
        COUNT(*) as count
      FROM $tableName
      GROUP BY difficulty
      ORDER BY difficulty
    ''');

    // Favorisierte Quests
    final favoriteCount = await count(where: 'is_favorite = ?', whereArgs: [1]);

    // Durchschnittliches empfohlenes Level
    final avgLevelResult = await rawQuery(
      'SELECT AVG(recommended_level) as avg_level FROM $tableName WHERE recommended_level IS NOT NULL',
    );
    final avgLevel = (avgLevelResult.first['avg_level'] as double?)?.toDouble() ?? 0.0;

    // Quests mit Belohnungen
    final questsRewards = await rawQuery('''
      SELECT COUNT(*) as count
      FROM $tableName
      WHERE rewards IS NOT NULL AND rewards != ''
    ''');

    return {
      'totalQuests': totalCount,
      'statusDistribution': statusDistributionResult,
      'typeDistribution': typeDistributionResult,
      'difficultyDistribution': difficultyDistributionResult,
      'favoriteQuests': favoriteCount,
      'averageRecommendedLevel': avgLevel,
      'questsWithRewards': questsRewards.first['count'] as int? ?? 0,
    };
  }

  /// ===== QUEST-OPERATIONEN =====

  /// Quest-Status ändern
  Future<Quest> updateStatus(String questId, QuestStatus newStatus) async {
    final quest = await findById(questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }

    DateTime? completedAt;
    if (newStatus == QuestStatus.completed && quest.completedAt == null) {
      completedAt = DateTime.now();
    }

    final updatedQuest = quest.copyWith(
      status: newStatus,
      completedAt: completedAt,
      updatedAt: DateTime.now(),
    );
    return await update(updatedQuest);
  }

  /// Favorit-Status umschalten
  Future<Quest> toggleFavorite(String questId) async {
    final quest = await findById(questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }

    final updatedQuest = quest.copyWith(
      isFavorite: !quest.isFavorite,
      updatedAt: DateTime.now(),
    );
    return await update(updatedQuest);
  }

  /// Kampagne zuweisen
  Future<Quest> assignToCampaign(String questId, String campaignId) async {
    final quest = await findById(questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }

    final updatedQuest = quest.copyWith(
      campaignId: campaignId,
      updatedAt: DateTime.now(),
    );
    return await update(updatedQuest);
  }

  /// Location setzen
  Future<Quest> updateLocation(String questId, String location) async {
    final quest = await findById(questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }

    final updatedQuest = quest.copyWith(
      location: location,
      updatedAt: DateTime.now(),
    );
    return await update(updatedQuest);
  }

  /// Empfohlenes Level setzen
  Future<Quest> updateRecommendedLevel(String questId, int? recommendedLevel) async {
    final quest = await findById(questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }

    final updatedQuest = quest.copyWith(
      recommendedLevel: recommendedLevel,
      updatedAt: DateTime.now(),
    );
    return await update(updatedQuest);
  }

  /// Belohnungen aktualisieren
  Future<Quest> updateRewards(String questId, List<QuestReward> rewards) async {
    final quest = await findById(questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }

    final updatedQuest = quest.copyWith(
      rewards: rewards,
      updatedAt: DateTime.now(),
    );
    return await update(updatedQuest);
  }

  /// Tags aktualisieren
  Future<Quest> updateTags(String questId, List<String> tags) async {
    final quest = await findById(questId);
    if (quest == null) {
      throw Exception('Quest not found: $questId');
    }

    final updatedQuest = quest.copyWith(
      tags: tags,
      updatedAt: DateTime.now(),
    );
    return await update(updatedQuest);
  }

  /// ===== ADVANCED SUCHEN =====

  /// Quests nach Titel suchen
  Future<List<Quest>> findByTitle(String title) async {
    return await findWhere(
      where: 'title LIKE ?',
      whereArgs: ['%$title%'],
      orderBy: 'title ASC',
    );
  }

  /// Quests ohne Kampagne finden
  Future<List<Quest>> findQuestsWithoutCampaign() async {
    return await findWhere(
      where: 'campaign_id IS NULL OR campaign_id = ?',
      whereArgs: [''],
      orderBy: 'title ASC',
    );
  }

  /// ===== BATCH OPERATIONEN =====

  /// Mehrere Quests auf einen Status setzen
  Future<List<Quest>> setMultipleQuestsStatus(
    List<String> questIds,
    QuestStatus status,
  ) async {
    final results = <Quest>[];
    
    for (final questId in questIds) {
      try {
        final result = await updateStatus(questId, status);
        results.add(result);
      } catch (e) {
        print('Error setting status for quest $questId: $e');
      }
    }
    
    return results;
  }

  /// Mehrere Quests als Favorit markieren
  Future<List<Quest>> setMultipleAsFavorite(
    List<String> questIds,
    bool isFavorite,
  ) async {
    final results = <Quest>[];
    
    for (final questId in questIds) {
      try {
        final quest = await findById(questId);
        if (quest != null) {
          final updated = quest.copyWith(isFavorite: isFavorite);
          final result = await update(updated);
          results.add(result);
        }
      } catch (e) {
        print('Error setting favorite status for quest $questId: $e');
      }
    }
    
    return results;
  }
}
