import 'base_entity.dart';
import '../../models/quest.dart';
import '../../models/quest_reward.dart';

/// Quest Entity für die neue Datenbankarchitektur
/// Implementiert BaseEntity für konsistente Struktur und Typ-Sicherheit
class QuestEntity extends BaseEntity {
  // Core Felder
  String _id;
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
  
  // Listen als JSON-Strings für Datenbank
  final String? tags;
  final String? rewards;
  final String? involvedNpcs;
  final String? linkedWikiEntryIds;

  // Erweiterte Entity-Felder
  final String sourceType; // 'custom', 'official', 'campaign'
  final String? sourceId; // Referenz zur Original-Quelle
  final bool isCustom;
  final String version;
  final int priority; // Sortierung für Quest-Listen
  final String? questGiverId; // NPC/Character der die Quest gab
  final String? imageUrl; // Bild für die Quest

  // Konstruktor
  QuestEntity({
    required String id,
    required this.title,
    required this.description,
    required this.status,
    required this.questType,
    required this.difficulty,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.campaignId,
    this.location,
    this.recommendedLevel,
    this.estimatedDurationHours,
    this.isFavorite = false,
    this.tags,
    this.rewards,
    this.involvedNpcs,
    this.linkedWikiEntryIds,
    this.sourceType = 'custom',
    this.sourceId,
    this.isCustom = true,
    this.version = '1.0',
    this.priority = 0,
    this.questGiverId,
    this.imageUrl,
  }) : _id = id;

  /// Factory für Datenbank-Erstellung
  factory QuestEntity.fromMap(Map<String, dynamic> map) {
    return QuestEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      status: _parseQuestStatus(map['status'] as String?),
      questType: _parseQuestType(map['quest_type'] as String?),
      difficulty: _parseQuestDifficulty(map['difficulty'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      campaignId: map['campaign_id'] as String?,
      location: map['location'] as String?,
      recommendedLevel: map['recommended_level'] as int?,
      estimatedDurationHours: (map['estimated_duration_hours'] as num?)?.toDouble(),
      isFavorite: (map['is_favorite'] as int?) == 1,
      tags: map['tags'] as String?,
      rewards: map['rewards'] as String?,
      involvedNpcs: map['involved_npcs'] as String?,
      linkedWikiEntryIds: map['linked_wiki_entry_ids'] as String?,
      sourceType: map['source_type'] as String? ?? 'custom',
      sourceId: map['source_id'] as String?,
      isCustom: (map['is_custom'] as int?) == 1,
      version: map['version'] as String? ?? '1.0',
      priority: map['priority'] as int? ?? 0,
      questGiverId: map['quest_giver_id'] as String?,
      imageUrl: map['image_url'] as String?,
    );
  }

  /// Factory von Quest Model
  factory QuestEntity.fromModel(Quest quest, {
    String? sourceType,
    String? sourceId,
    bool? isCustom,
    String? version,
    int? priority,
    String? questGiverId,
    String? imageUrl,
  }) {
    return QuestEntity(
      id: quest.id.toString(),
      title: quest.title,
      description: quest.description,
      status: quest.status,
      questType: quest.questType,
      difficulty: quest.difficulty,
      createdAt: quest.createdAt,
      updatedAt: quest.updatedAt,
      completedAt: quest.completedAt,
      campaignId: quest.campaignId,
      location: quest.location,
      recommendedLevel: quest.recommendedLevel,
      estimatedDurationHours: quest.estimatedDurationHours,
      isFavorite: quest.isFavorite,
      tags: _serializeStringList(quest.tags),
      rewards: _serializeRewards(quest.rewards),
      involvedNpcs: _serializeStringList(quest.involvedNpcs),
      linkedWikiEntryIds: _serializeStringList(quest.linkedWikiEntryIds),
      sourceType: sourceType ?? 'custom',
      sourceId: sourceId,
      isCustom: isCustom ?? true,
      version: version ?? '1.0',
      priority: priority ?? 0,
      questGiverId: questGiverId,
      imageUrl: imageUrl,
    );
  }

  /// Hilfsmethoden zum Parsen der Enums
  static QuestStatus _parseQuestStatus(String? statusString) {
    if (statusString == null) return QuestStatus.active;
    
    try {
      return QuestStatus.values.firstWhere(
        (status) => status.toString() == 'QuestStatus.$statusString',
        orElse: () => QuestStatus.active,
      );
    } catch (e) {
      return QuestStatus.active;
    }
  }

  static QuestType _parseQuestType(String? typeString) {
    if (typeString == null) return QuestType.side;
    
    try {
      return QuestType.values.firstWhere(
        (type) => type.toString() == 'QuestType.$typeString',
        orElse: () => QuestType.side,
      );
    } catch (e) {
      return QuestType.side;
    }
  }

  static QuestDifficulty _parseQuestDifficulty(String? difficultyString) {
    if (difficultyString == null) return QuestDifficulty.medium;
    
    try {
      return QuestDifficulty.values.firstWhere(
        (difficulty) => difficulty.toString() == 'QuestDifficulty.$difficultyString',
        orElse: () => QuestDifficulty.medium,
      );
    } catch (e) {
      return QuestDifficulty.medium;
    }
  }

  /// Hilfsmethoden zur Serialisierung
  static String? _serializeStringList(List<String> list) {
    if (list.isEmpty) return null;
    return list.map((item) => item.replaceAll('"', '\\"')).join(',');
  }

  static String? _serializeRewards(List<QuestReward> rewards) {
    if (rewards.isEmpty) return null;
    return rewards.map((reward) => reward.toString()).join('|');
  }

  /// Hilfsmethoden zur Deserialisierung
  static List<String> _parseStringList(String? serialized) {
    if (serialized == null || serialized.isEmpty) return [];
    
    try {
      return serialized.split(',').map((item) {
        return item.replaceAll('\\"', '"').trim();
      }).where((item) => item.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  static List<QuestReward> _parseRewards(String? serialized) {
    if (serialized == null || serialized.isEmpty) return [];
    
    try {
      return serialized.split('|').where((item) => item.isNotEmpty).map((item) {
        // Einfache Parsing-Logik für QuestReward
        final parts = item.split(':');
        if (parts.length >= 2) {
          return QuestReward(
            id: DateTime.now().millisecondsSinceEpoch.toString() + parts.length.toString(),
            type: _parseRewardType(parts[0]),
            name: parts[1],
            description: parts.length > 2 ? parts[2] : null,
            goldAmount: parts.length > 3 ? int.tryParse(parts[3]) : null,
            experiencePoints: parts.length > 4 ? int.tryParse(parts[4]) : null,
            itemId: parts.length > 5 ? parts[5] : null,
            quantity: parts.length > 6 ? int.tryParse(parts[6]) : null,
          );
        }
        return QuestReward(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: QuestRewardType.gold,
          name: item,
          description: item,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static QuestRewardType _parseRewardType(String typeString) {
    try {
      return QuestRewardType.values.firstWhere(
        (type) => type.toString() == 'QuestRewardType.$typeString',
        orElse: () => QuestRewardType.gold,
      );
    } catch (e) {
      return QuestRewardType.gold;
    }
  }

  /// ID Getter aus BaseEntity
  @override
  String get id => _id;
  
  /// ID Setter aus BaseEntity
  @override
  set id(String value) => _id = value;
  
  /// Metadata Getter aus BaseEntity
  @override
  Map<String, dynamic> get metadata => {
    'entityType': 'Quest',
    'tableName': tableName,
    'status': status.toString(),
    'questType': questType.toString(),
    'difficulty': difficulty.toString(),
    'campaignId': campaignId,
    'sourceType': sourceType,
    'priority': priority,
  };
  
  /// Validierung Getter aus BaseEntity
  @override
  bool get isValid {
    return title.isNotEmpty && 
           description.isNotEmpty &&
           (recommendedLevel == null || (recommendedLevel! >= 1 && recommendedLevel! <= 20)) &&
           (estimatedDurationHours == null || (estimatedDurationHours! > 0 && estimatedDurationHours! <= 1000));
  }
  
  /// Validation Errors Getter aus BaseEntity
  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (title.isEmpty) errors.add('Titel darf nicht leer sein');
    if (description.isEmpty) errors.add('Beschreibung darf nicht leer sein');
    if (recommendedLevel != null && (recommendedLevel! < 1 || recommendedLevel! > 20)) {
      errors.add('Level muss zwischen 1 und 20 liegen');
    }
    if (estimatedDurationHours != null && (estimatedDurationHours! <= 0 || estimatedDurationHours! > 1000)) {
      errors.add('Dauer muss positiv und <= 1000 Stunden sein');
    }
    return errors;
  }

  /// Konvertierung zu Map für Datenbank
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
      'is_favorite': isFavorite ? 1 : 0,
      'tags': tags,
      'rewards': rewards,
      'involved_npcs': involvedNpcs,
      'linked_wiki_entry_ids': linkedWikiEntryIds,
      'source_type': sourceType,
      'source_id': sourceId,
      'is_custom': isCustom ? 1 : 0,
      'version': version,
      'priority': priority,
      'quest_giver_id': questGiverId,
      'image_url': imageUrl,
    };
  }

  /// Konvertierung zurück zum Quest Model
  Quest toModel() {
    return Quest(
      id: int.tryParse(id) ?? 0,
      title: title,
      description: description,
      status: status,
      questType: questType,
      difficulty: difficulty,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      campaignId: campaignId,
      location: location,
      recommendedLevel: recommendedLevel,
      estimatedDurationHours: estimatedDurationHours,
      isFavorite: isFavorite,
      tags: _parseStringList(tags),
      rewards: _parseRewards(rewards),
      involvedNpcs: _parseStringList(involvedNpcs),
      linkedWikiEntryIds: _parseStringList(linkedWikiEntryIds),
    );
  }

  /// Kopie mit geänderten Werten erstellen
  QuestEntity copyWith({
    String? id,
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
    String? tags,
    String? rewards,
    String? involvedNpcs,
    String? linkedWikiEntryIds,
    String? sourceType,
    String? sourceId,
    bool? isCustom,
    String? version,
    int? priority,
    String? questGiverId,
    String? imageUrl,
  }) {
    return QuestEntity(
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
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isCustom: isCustom ?? this.isCustom,
      version: version ?? this.version,
      priority: priority ?? this.priority,
      questGiverId: questGiverId ?? this.questGiverId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Datenbank-Tabellenname
  static const String tableName = 'quests';

  /// Erstelle Tabelle SQL
  static String createTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        quest_type TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        campaign_id TEXT,
        location TEXT,
        recommended_level INTEGER,
        estimated_duration_hours REAL,
        is_favorite INTEGER DEFAULT 0,
        tags TEXT,
        rewards TEXT,
        involved_npcs TEXT,
        linked_wiki_entry_ids TEXT,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_custom INTEGER DEFAULT 1,
        version TEXT DEFAULT '1.0',
        priority INTEGER DEFAULT 0,
        quest_giver_id TEXT,
        image_url TEXT
      )
    ''';
  }

  @override
  String toString() {
    return 'QuestEntity(id: $id, title: $title, status: $status, type: $questType, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestEntity &&
           other.id == id &&
           other.title == title &&
           other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           title.hashCode ^
           status.hashCode;
  }
}
