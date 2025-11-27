import '../services/quest_data_service.dart';
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';
import 'quest_reward.dart';

/// Quest-Model für D&D Kampagnen
/// 
/// Repräsentiert eine einzelne Quest mit allen Metadaten und Belohnungen.
/// Enthält keine Business-Logik - nur Datenstrukturen und Basis-Validierung.
class Quest {
  final int id;
  final String title;
  final String description;
  final QuestStatus status;
  final QuestType questType;
  final QuestDifficulty difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? campaignId;
  final String? location;
  final int? recommendedLevel;
  final double? estimatedDurationHours;
  final bool isFavorite;
  final List<String> tags;
  final List<QuestReward> rewards;
  final List<String> involvedNpcs;
  final List<String> linkedWikiEntryIds;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    this.status = QuestStatus.active,
    this.questType = QuestType.side,
    this.difficulty = QuestDifficulty.medium,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.campaignId,
    this.location,
    this.recommendedLevel,
    this.estimatedDurationHours,
    this.isFavorite = false,
    this.tags = const [],
    this.rewards = const [],
    this.involvedNpcs = const [],
    this.linkedWikiEntryIds = const [],
  });

  /// Factory für neue Quests mit automatisch generierter ID
  factory Quest.create({
    required String title,
    required String description,
    QuestStatus status = QuestStatus.active,
    QuestType questType = QuestType.side,
    QuestDifficulty difficulty = QuestDifficulty.medium,
    String? campaignId,
    String? location,
    int? recommendedLevel,
    double? estimatedDurationHours,
    bool isFavorite = false,
    List<String> tags = const [],
    List<QuestReward> rewards = const [],
    List<String> involvedNpcs = const [],
    List<String> linkedWikiEntryIds = const [],
  }) {
    final now = DateTime.now();
    return Quest(
      id: UuidService().generateId().hashCode.abs(),
      title: title,
      description: description,
      status: status,
      questType: questType,
      difficulty: difficulty,
      createdAt: now,
      updatedAt: now,
      campaignId: campaignId,
      location: location,
      recommendedLevel: recommendedLevel,
      estimatedDurationHours: estimatedDurationHours,
      isFavorite: isFavorite,
      tags: tags,
      rewards: rewards,
      involvedNpcs: involvedNpcs,
      linkedWikiEntryIds: linkedWikiEntryIds,
    );
  }

  /// Factory für Datenbank-Map mit sicherem Parsing
  factory Quest.fromMap(Map<String, dynamic> map) {
    try {
      return Quest(
        id: QuestDataService.safeInt(map['id'], 0),
        title: QuestDataService.safeString(map['title'], ''),
        description: QuestDataService.safeString(map['description'], ''),
        status: QuestStatus.values.firstWhere(
          (e) => e.toString() == map['status'],
          orElse: () => QuestStatus.active,
        ),
        questType: QuestDataService.parseQuestType(map['quest_type']),
        difficulty: QuestDataService.parseDifficulty(map['difficulty']),
        createdAt: DateTime.tryParse(ModelParsingHelper.safeString(map, 'created_at', '')) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(ModelParsingHelper.safeString(map, 'updated_at', '')) ?? DateTime.now(),
        completedAt: ModelParsingHelper.safeStringOrNull(map, 'completed_at', null) != null 
            ? DateTime.tryParse(ModelParsingHelper.safeString(map, 'completed_at', '')) 
            : null,
        campaignId: QuestDataService.safeStringOrNull(map['campaign_id'], ''),
        location: QuestDataService.safeStringOrNull(map['location'], ''),
        recommendedLevel: QuestDataService.safeIntOrNull(map['recommended_level'], null),
        estimatedDurationHours: ModelParsingHelper.safeDouble(map, 'estimated_duration_hours', 0.0),
        isFavorite: QuestDataService.safeBool(map['is_favorite'], false),
        tags: QuestDataService.parseStringList(map['tags']),
        rewards: QuestDataService.parseRewards(map['rewards']),
        involvedNpcs: QuestDataService.parseStringList(map['involved_npcs']),
        linkedWikiEntryIds: QuestDataService.parseStringList(map['linked_wiki_entry_ids']),
      );
    } catch (e) {
      print('Fehler beim Parsen der Quest: $e');
      // Fallback zu minimal gültiger Quest
      return Quest.create(
        title: QuestDataService.safeString(map['title'], 'Fehlerhafte Quest'),
        description: QuestDataService.safeString(map['description'], 'Parse-Fehler'),
      );
    }
  }

  /// Konvertiert das Quest zu einer Datenbank-Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString(),
      'quest_type': questType.toString(),
      'difficulty': difficulty.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'campaign_id': campaignId,
      'location': location,
      'recommended_level': recommendedLevel,
      'estimated_duration_hours': estimatedDurationHours,
      'is_favorite': isFavorite,
      'tags': QuestDataService.serializeStringList(tags),
      'rewards': QuestDataService.serializeRewards(rewards),
      'involved_npcs': QuestDataService.serializeStringList(involvedNpcs),
      'linked_wiki_entry_ids': QuestDataService.serializeStringList(linkedWikiEntryIds),
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  Quest copyWith({
    int? id,
    String? title,
    String? description,
    QuestStatus? status,
    QuestType? questType,
    QuestDifficulty? difficulty,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? campaignId,
    String? location,
    int? recommendedLevel,
    double? estimatedDurationHours,
    bool? isFavorite,
    List<String>? tags,
    List<QuestReward>? rewards,
    List<String>? involvedNpcs,
    List<String>? linkedWikiEntryIds,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      questType: questType ?? this.questType,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      campaignId: campaignId ?? this.campaignId,
      location: location ?? this.location,
      recommendedLevel: recommendedLevel ?? this.recommendedLevel,
      estimatedDurationHours: estimatedDurationHours ?? this.estimatedDurationHours,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      rewards: rewards ?? this.rewards,
      involvedNpcs: involvedNpcs ?? this.involvedNpcs,
      linkedWikiEntryIds: linkedWikiEntryIds ?? this.linkedWikiEntryIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Quest(id: $id, title: $title, status: $status, type: $questType)';
  }

  // ========== BASIS VALIDIERUNGEN ==========
  // Nur grundlegende Datenintegrität - keine Business-Logik

  /// Prüft ob der Titel gültig ist
  bool get hasValidTitle => title.trim().isNotEmpty;

  /// Prüft ob die Beschreibung gültig ist
  bool get hasValidDescription => description.trim().isNotEmpty;

  /// Prüft ob das Level im gültigen Bereich ist
  bool get hasValidLevel => recommendedLevel == null || 
      (recommendedLevel! >= 1 && recommendedLevel! <= 20);

  /// Prüft ob die Dauer gültig ist
  bool get hasValidDuration => estimatedDurationHours == null || 
      (estimatedDurationHours! > 0 && estimatedDurationHours! <= 1000);

  /// Grundlegende Validierung aller Felder
  bool get isValid {
    return hasValidTitle && 
           hasValidDescription && 
           hasValidLevel && 
           hasValidDuration;
  }

  /// Liste aller Validierungsfehler
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (!hasValidTitle) errors.add('Titel darf nicht leer sein');
    if (!hasValidDescription) errors.add('Beschreibung darf nicht leer sein');
    if (!hasValidLevel) errors.add('Level muss zwischen 1 und 20 liegen');
    if (!hasValidDuration) errors.add('Dauer muss positiv und <= 1000 Stunden sein');
    
    return errors;
  }

  // ========== COMPATIBILITY GETTERS ==========
  // Für Abwärtskompatibilität mit bestehendem Code

  /// Alias für description (wird in Legacy-Code verwendet)
  String get goal => description;

  /// Prüft ob Belohnungen vorhanden sind
  bool get hasRewards => rewards.isNotEmpty;

  /// Prüft ob NPCs vorhanden sind
  bool get hasNpcs => involvedNpcs.isNotEmpty;

  /// Prüft ob Location vorhanden ist
  bool get hasLocation => location != null && location!.isNotEmpty;

  /// Prüft ob Level-Empfehlung vorhanden ist
  bool get hasLevelRecommendation => recommendedLevel != null;

  /// Prüft ob Dauer-Schätzung vorhanden ist
  bool get hasDurationEstimate => estimatedDurationHours != null;

  /// NPCs als kommagetrennten String
  String get npcsString => involvedNpcs.join(', ');

  /// Gesamtbetrag an Gold aus allen Belohnungen
  int get totalGoldAmount {
    return rewards
        .where((reward) => reward.goldAmount != null)
        .fold(0, (sum, reward) => sum + reward.goldAmount!);
  }

  /// Gesamt-EP aus allen Belohnungen
  int get totalXP {
    return rewards
        .where((reward) => reward.experiencePoints != null)
        .fold(0, (sum, reward) => sum + reward.experiencePoints!);
  }

  /// Lokalisierte Beschreibung für Quest-Typ
  String get questTypeDescription {
    switch (questType) {
      case QuestType.main:
        return 'Hauptquest';
      case QuestType.side:
        return 'Nebenquest';
      case QuestType.personal:
        return 'Persönliche Quest';
      case QuestType.faction:
        return 'Fraktions-Quest';
    }
  }

  /// Lokalisierte Beschreibung für Schwierigkeit
  String get difficultyDescription {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 'Leicht';
      case QuestDifficulty.medium:
        return 'Mittel';
      case QuestDifficulty.hard:
        return 'Schwer';
      case QuestDifficulty.deadly:
        return 'Tödlich';
      case QuestDifficulty.epic:
        return 'Episch';
      case QuestDifficulty.legendary:
        return 'Legendär';
    }
  }

  /// Prüft ob Tags vorhanden sind
  bool get hasTags => tags.isNotEmpty;

  /// Tags als kommagetrennten String
  String get tagsString => tags.join(', ');

  /// Prüft ob Wiki-Links vorhanden sind
  bool get hasWikiLinks => linkedWikiEntryIds.isNotEmpty;
}

/// Enum für Quest-Status
enum QuestStatus {
  active,
  completed,
  failed,
  abandoned,
  onHold,
}

/// Enum für Quest-Typen
enum QuestType {
  main,
  side,
  personal,
  faction,
}

/// Enum für Quest-Schwierigkeiten
enum QuestDifficulty {
  easy,
  medium,
  hard,
  deadly,
  epic,
  legendary,
}
