// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/quest.dart';
import '../models/quest_reward.dart';
import '../database/database_helper.dart';
import '../services/quest_helper_service.dart';
import 'exceptions/service_exceptions.dart';

/// Service für Quest-Bibliothek Business-Logik
/// 
/// Dieser Service kapselt alle Geschäftslogik für die Quest-Bibliothek
/// und bietet eine saubere API für die UI-Schicht.
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
class QuestLibraryService {
  final DatabaseHelper _databaseHelper;

  QuestLibraryService({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ========== CRUD OPERATIONS ==========

  /// Lädt alle Quests aus der Datenbank
  Future<ServiceResult<List<Quest>>> getAllQuests() async =>
      performServiceOperation('getAllQuests', () async =>
          await _databaseHelper.getAllQuests());

  /// Erstellt eine neue Quest
  Future<ServiceResult<Quest>> createQuest({
    required String title,
    required String description,
    required QuestType questType,
    required QuestDifficulty difficulty,
    String? location,
    int? recommendedLevel,
    double? estimatedDurationHours,
    List<String> tags = const [],
    List<String> involvedNpcs = const [],
    List<QuestReward> rewards = const [],
    bool isFavorite = false,
  }) async {
    return performServiceOperation('createQuest', () async {
      // Validierung
      if (title.trim().isEmpty) {
        throw ValidationException(
          'Titel darf nicht leer sein',
          operation: 'createQuest',
        );
      }

      if (description.trim().isEmpty) {
        throw ValidationException(
          'Beschreibung darf nicht leer sein',
          operation: 'createQuest',
        );
      }

      if (recommendedLevel != null && recommendedLevel < 1) {
        throw ValidationException(
          'Empfohlenes Level muss mindestens 1 sein',
          operation: 'createQuest',
        );
      }

      if (estimatedDurationHours != null && estimatedDurationHours < 0) {
        throw ValidationException(
          'Geschätzte Dauer darf nicht negativ sein',
          operation: 'createQuest',
        );
      }

      final quest = Quest(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        description: description,
        questType: questType,
        difficulty: difficulty,
        location: location,
        recommendedLevel: recommendedLevel,
        estimatedDurationHours: estimatedDurationHours,
        tags: tags,
        involvedNpcs: involvedNpcs,
        rewards: rewards,
        isFavorite: isFavorite,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdId = await _databaseHelper.insertQuest(quest);
      return quest.copyWith(id: createdId);
    });
  }

  /// Aktualisiert eine existierende Quest
  Future<ServiceResult<Quest>> updateQuest(Quest quest) async {
    return performServiceOperation('updateQuest', () async {
      // Prüfe ob Quest existiert
      final existingQuests = await getAllQuests();
      if (!existingQuests.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden der Quests',
          operation: 'updateQuest',
        );
      }

      final exists = existingQuests.data!.any((q) => q.id == quest.id);
      if (!exists) {
        throw ResourceNotFoundException.forId(
          'Quest',
          quest.id.toString(),
          operation: 'updateQuest',
        );
      }

      // Validierung
      if (quest.title.trim().isEmpty) {
        throw ValidationException(
          'Titel darf nicht leer sein',
          operation: 'updateQuest',
        );
      }

      if (quest.description.trim().isEmpty) {
        throw ValidationException(
          'Beschreibung darf nicht leer sein',
          operation: 'updateQuest',
        );
      }

      final updatedQuest = quest.copyWith(updatedAt: DateTime.now());
      await _databaseHelper.updateQuest(updatedQuest);
      return updatedQuest;
    });
  }

  /// Löscht eine Quest
  Future<ServiceResult<void>> deleteQuest(String questId) async {
    return performServiceOperation('deleteQuest', () async {
      // Prüfe ob Quest existiert
      final existingQuests = await getAllQuests();
      if (!existingQuests.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden der Quests',
          operation: 'deleteQuest',
        );
      }

      final exists = existingQuests.data!.any((q) => q.id.toString() == questId);
      if (!exists) {
        throw ResourceNotFoundException.forId(
          'Quest',
          questId,
          operation: 'deleteQuest',
        );
      }

      await _databaseHelper.deleteQuest(questId);
    });
  }

  // ========== SEARCH & FILTER OPERATIONS ==========

  /// Sucht Quests nach verschiedenen Kriterien
  Future<ServiceResult<List<Quest>>> searchQuests({
    String? query,
    QuestType? type,
    QuestDifficulty? difficulty,
    Set<String>? tags,
    bool? favoritesOnly,
    int? minLevel,
    int? maxLevel,
    String? location,
  }) async {
    return performServiceOperation('searchQuests', () async {
      final allQuestsResult = await getAllQuests();
      if (!allQuestsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Quests',
          operation: 'searchQuests',
        );
      }

      return allQuestsResult.data!.where((quest) {
        // Suchtext filtern
        if (query != null && query.isNotEmpty) {
          final queryLower = query.toLowerCase();
          final titleMatch = quest.title.toLowerCase().contains(queryLower);
          final descriptionMatch = quest.description.toLowerCase().contains(queryLower);
          final tagMatch = quest.tags.any((tag) => 
              tag.toLowerCase().contains(queryLower));
          final locationMatch = quest.location != null && 
              quest.location!.toLowerCase().contains(queryLower);
          final npcMatch = quest.involvedNpcs.isNotEmpty && 
              quest.involvedNpcs.any((npc) => npc.toLowerCase().contains(queryLower));
          final rewardMatch = quest.rewards.isNotEmpty && 
              quest.rewards.any((reward) => reward.name.toLowerCase().contains(queryLower));
          
          if (!(titleMatch || descriptionMatch || 
                tagMatch || locationMatch || npcMatch || rewardMatch)) {
            return false;
          }
        }

        // Typ filtern
        if (type != null && quest.questType != type) {
          return false;
        }

        // Schwierigkeit filtern
        if (difficulty != null && quest.difficulty != difficulty) {
          return false;
        }

        // Tags filtern
        if (tags != null && tags.isNotEmpty) {
          final hasAllRequiredTags = tags.every((requiredTag) => 
              quest.tags.contains(requiredTag));
          if (!hasAllRequiredTags) return false;
        }

        // Favoriten filtern
        if (favoritesOnly == true && !quest.isFavorite) {
          return false;
        }

        // Level-Bereich filtern
        if (minLevel != null && quest.recommendedLevel != null && 
            quest.recommendedLevel! < minLevel) {
          return false;
        }
        if (maxLevel != null && quest.recommendedLevel != null && 
            quest.recommendedLevel! > maxLevel) {
          return false;
        }

        // Location filtern
        if (location != null && location.isNotEmpty && 
            quest.location != null && 
            !quest.location!.toLowerCase().contains(location.toLowerCase())) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  // ========== BUSINESS LOGIC OPERATIONS ==========

  /// Toggle Favoriten-Status einer Quest
  Future<ServiceResult<Quest>> toggleQuestFavorite(String questId) async {
    return performServiceOperation('toggleQuestFavorite', () async {
      final allQuestsResult = await getAllQuests();
      if (!allQuestsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden der Quests',
          operation: 'toggleQuestFavorite',
        );
      }

      final quest = allQuestsResult.data!.firstWhere(
        (q) => q.id.toString() == questId,
        orElse: () => throw ResourceNotFoundException.forId(
          'Quest',
          questId,
          operation: 'toggleQuestFavorite',
        ),
      );

      final updatedQuest = QuestHelperService.toggleFavorite(quest);
      await _databaseHelper.updateQuest(updatedQuest);
      return updatedQuest;
    });
  }

  // ========== UTILITY OPERATIONS ==========

  /// Sortiert Quests nach verschiedenen Kriterien
  List<Quest> sortQuests(
    List<Quest> quests, {
    QuestSortOption sortBy = QuestSortOption.alphabetical,
    bool ascending = true,
  }) {
    final sortedQuests = List<Quest>.from(quests);

    switch (sortBy) {
      case QuestSortOption.alphabetical:
        sortedQuests.sort((a, b) => 
            a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case QuestSortOption.type:
        sortedQuests.sort((a, b) => 
            a.questType.index.compareTo(b.questType.index));
        break;
      case QuestSortOption.difficulty:
        sortedQuests.sort((a, b) => 
            a.difficulty.index.compareTo(b.difficulty.index));
        break;
      case QuestSortOption.level:
        sortedQuests.sort((a, b) {
          if (a.recommendedLevel == null && b.recommendedLevel == null) return 0;
          if (a.recommendedLevel == null) return 1;
          if (b.recommendedLevel == null) return -1;
          return a.recommendedLevel!.compareTo(b.recommendedLevel!);
        });
        break;
      case QuestSortOption.duration:
        sortedQuests.sort((a, b) {
          if (a.estimatedDurationHours == null && b.estimatedDurationHours == null) return 0;
          if (a.estimatedDurationHours == null) return 1;
          if (b.estimatedDurationHours == null) return -1;
          return a.estimatedDurationHours!.compareTo(b.estimatedDurationHours!);
        });
        break;
      case QuestSortOption.created:
        sortedQuests.sort((a, b) => 
            a.createdAt.compareTo(b.createdAt));
        break;
      case QuestSortOption.updated:
        sortedQuests.sort((a, b) => 
            a.updatedAt.compareTo(b.updatedAt));
        break;
    }

    if (!ascending) {
      return sortedQuests.reversed.toList();
    }

    return sortedQuests;
  }

  /// Gibt alle verfügbaren Tags aus den Quests zurück
  Future<ServiceResult<Set<String>>> getAllAvailableTags() async {
    return performServiceOperation('getAllAvailableTags', () async {
      final questsResult = await getAllQuests();
      if (!questsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden der Quests',
          operation: 'getAllAvailableTags',
        );
      }

      final allTags = <String>{};
      for (final quest in questsResult.data!) {
        allTags.addAll(quest.tags);
      }
      return allTags;
    });
  }

  /// Gibt Quest-Statistiken zurück
  Future<ServiceResult<QuestStatistics>> getQuestStatistics() async {
    return performServiceOperation('getQuestStatistics', () async {
      final questsResult = await getAllQuests();
      if (!questsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden der Quests',
          operation: 'getQuestStatistics',
        );
      }

      final quests = questsResult.data!;
      
      final mainQuests = quests.where((q) => q.questType == QuestType.main).length;
      final sideQuests = quests.where((q) => q.questType == QuestType.side).length;
      final personalQuests = quests.where((q) => q.questType == QuestType.personal).length;
      final factionQuests = quests.where((q) => q.questType == QuestType.faction).length;
      
      final favorites = quests.where((q) => q.isFavorite).length;
      final withLocation = quests.where((q) => q.location != null && q.location!.isNotEmpty).length;
      final withLevel = quests.where((q) => q.recommendedLevel != null).length;
      
      final allTags = <String>{};
      for (final quest in quests) {
        allTags.addAll(quest.tags);
      }
      
      return QuestStatistics(
        totalQuests: quests.length,
        mainQuests: mainQuests,
        sideQuests: sideQuests,
        personalQuests: personalQuests,
        factionQuests: factionQuests,
        favorites: favorites,
        withLocation: withLocation,
        withLevel: withLevel,
        totalTags: allTags.length,
        availableTags: allTags,
      );
    });
  }

  // ========== STATIC HELPER METHODS ==========

  /// Prüft ob eine Quest bestimmte Tags hat
  static bool hasTags(Quest quest, Set<String> requiredTags) =>
      requiredTags.isEmpty || requiredTags.every((tag) => quest.tags.contains(tag));

  /// Prüft ob eine Quest im Level-Bereich liegt
  static bool isInLevelRange(Quest quest, int? minLevel, int? maxLevel) {
    if (quest.recommendedLevel == null) return true;
    
    final level = quest.recommendedLevel!;
    if (minLevel != null && level < minLevel) return false;
    if (maxLevel != null && level > maxLevel) return false;
    
    return true;
  }

  /// Prüft ob eine Quest eine Location hat
  static bool hasLocation(Quest quest) =>
      quest.location != null && quest.location!.isNotEmpty;

  /// Prüft ob eine Quest ein Level hat
  static bool hasRecommendedLevel(Quest quest) =>
      quest.recommendedLevel != null;

  /// Prüft ob eine Quest NPCs involviert
  static bool hasInvolvedNpcs(Quest quest) =>
      quest.involvedNpcs.isNotEmpty;

  /// Prüft ob eine Quest Belohnungen hat
  static bool hasRewards(Quest quest) =>
      quest.rewards.isNotEmpty;

  /// Prüft ob eine Quest eine geschätzte Dauer hat
  static bool hasEstimatedDuration(Quest quest) =>
      quest.estimatedDurationHours != null;

  /// Formatiert Quest für Anzeige
  static String formatQuest(Quest quest) {
    final buffer = StringBuffer();
    buffer.writeln('Quest: ${quest.title}');
    buffer.writeln('  Type: ${quest.questType}');
    buffer.writeln('  Difficulty: ${quest.difficulty}');
    buffer.writeln('  Tags: ${quest.tags.join(', ')}');
    buffer.writeln('  Location: ${quest.location ?? 'Keine Location'}');
    buffer.writeln('  Level: ${quest.recommendedLevel ?? 'Kein Level'}');
    buffer.writeln('  Duration: ${quest.estimatedDurationHours != null ? '${quest.estimatedDurationHours}h' : 'Unbekannt'}');
    buffer.writeln('  Created: ${quest.createdAt}');
    buffer.writeln('  Updated: ${quest.updatedAt}');
    buffer.writeln('  Is Favorite: ${quest.isFavorite}');
    
    if (hasInvolvedNpcs(quest)) {
      buffer.writeln('  NPCs: ${quest.involvedNpcs.join(', ')}');
    }
    
    if (hasRewards(quest)) {
      buffer.writeln('  Rewards: ${quest.rewards.length}');
    }
    
    return buffer.toString();
  }
}

/// Sortieroptionen für Quests
enum QuestSortOption {
  alphabetical,
  type,
  difficulty,
  level,
  duration,
  created,
  updated,
}

/// Quest-Statistiken
class QuestStatistics {
  final int totalQuests;
  final int mainQuests;
  final int sideQuests;
  final int personalQuests;
  final int factionQuests;
  final int favorites;
  final int withLocation;
  final int withLevel;
  final int totalTags;
  final Set<String> availableTags;

  const QuestStatistics({
    required this.totalQuests,
    required this.mainQuests,
    required this.sideQuests,
    required this.personalQuests,
    required this.factionQuests,
    required this.favorites,
    required this.withLocation,
    required this.withLevel,
    required this.totalTags,
    required this.availableTags,
  });

  @override
  String toString() =>
      'QuestStatistics('
      'total: $totalQuests, '
      'main: $mainQuests, '
      'side: $sideQuests, '
      'personal: $personalQuests, '
      'faction: $factionQuests, '
      'favorites: $favorites, '
      'withLocation: $withLocation, '
      'withLevel: $withLevel, '
      'totalTags: $totalTags'
      ')';
}
