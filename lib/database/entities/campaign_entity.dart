import '../core/database_entity.dart';
import 'base_entity.dart';
import '../../models/campaign.dart';

/// Campaign-Entität für die neue Datenbankarchitektur
/// Implementiert DatabaseEntity für Campaign-Tabellen
class CampaignEntity extends BaseEntity implements DatabaseEntity<CampaignEntity> {
  String id;
  String name;
  String description;
  String? gameMaster;
  DateTime? startDate;
  DateTime? endDate;
  String? imageUrl;
  List<String> tags;
  bool isActive;
  bool isFavorite;
  Map<String, dynamic> settings;
  DateTime createdAt;
  DateTime updatedAt;

  CampaignEntity({
    required this.id,
    required this.name,
    required this.description,
    this.gameMaster,
    this.startDate,
    this.endDate,
    this.imageUrl,
    this.tags = const [],
    this.isActive = false,
    this.isFavorite = false,
    this.settings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  String get tableName => 'campaigns';

  @override
  String get primaryKeyField => 'id';

  @override
  List<String> get databaseFields => [
    'id',
    'name',
    'description',
    'game_master',
    'start_date',
    'end_date',
    'image_url',
    'tags',
    'is_active',
    'is_favorite',
    'settings',
    'created_at',
    'updated_at',
  ];

  @override
  List<String> get createTableSql => [
    '''
    CREATE TABLE campaigns (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      game_master TEXT,
      start_date TEXT,
      end_date TEXT,
      image_url TEXT,
      tags TEXT,
      is_active INTEGER NOT NULL DEFAULT 0,
      is_favorite INTEGER NOT NULL DEFAULT 0,
      settings TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    ''',
  ];

  @override
  List<String> get createIndexes => [
    'CREATE INDEX idx_campaigns_name ON campaigns(name)',
    'CREATE INDEX idx_campaigns_game_master ON campaigns(game_master)',
    'CREATE INDEX idx_campaigns_is_active ON campaigns(is_active)',
    'CREATE INDEX idx_campaigns_created_at ON campaigns(created_at)',
  ];

  @override
  Map<String, dynamic> toDatabaseMap() {
    return convertToSnakeCase({
      'id': id,
      'name': name,
      'description': description,
      'gameMaster': gameMaster,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'tags': tags.join(','),
      'isActive': isActive ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'settings': _encodeSettings(settings),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  @override
  CampaignEntity fromDatabaseMap(Map<String, dynamic> map) {
    final camelCaseMap = convertToCamelCase(map);
    
    return CampaignEntity(
      id: camelCaseMap['id'] as String,
      name: camelCaseMap['name'] as String,
      description: camelCaseMap['description'] as String,
      gameMaster: camelCaseMap['gameMaster'] as String?,
      startDate: camelCaseMap['startDate'] != null 
          ? DateTime.parse(camelCaseMap['startDate'] as String)
          : null,
      endDate: camelCaseMap['endDate'] != null 
          ? DateTime.parse(camelCaseMap['endDate'] as String)
          : null,
      imageUrl: camelCaseMap['imageUrl'] as String?,
      tags: _parseTags(camelCaseMap['tags'] as String?),
      isActive: (camelCaseMap['isActive'] as int?) == 1,
      isFavorite: (camelCaseMap['isFavorite'] as int?) == 1,
      settings: _decodeSettings(camelCaseMap['settings'] as String?),
      createdAt: DateTime.parse(camelCaseMap['createdAt'] as String),
      updatedAt: DateTime.parse(camelCaseMap['updatedAt'] as String),
    );
  }

  @override
  bool get isValid {
    final errors = validationErrors;
    return errors.isEmpty;
  }

  @override
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (name.trim().isEmpty) {
      errors.add('Campaign name cannot be empty');
    }
    
    if (name.length > 100) {
      errors.add('Campaign name too long (max 100 characters)');
    }
    
    if (description.trim().isEmpty) {
      errors.add('Campaign description cannot be empty');
    }
    
    if (description.length > 1000) {
      errors.add('Campaign description too long (max 1000 characters)');
    }
    
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      errors.add('Start date cannot be after end date');
    }
    
    if (tags.length > 10) {
      errors.add('Too many tags (max 10)');
    }
    
    for (final tag in tags) {
      if (tag.length > 20) {
        errors.add('Tag too long: $tag (max 20 characters)');
      }
    }
    
    return errors;
  }

  @override
  Map<String, dynamic> get metadata => {
    'tableName': tableName,
    'recordCount': 1, // Would be set by repository
    'tags': tags,
    'isActive': isActive,
    'hasImage': imageUrl != null && imageUrl!.isNotEmpty,
    'dateRange': startDate != null && endDate != null 
        ? '${startDate!.toIso8601String()} - ${endDate!.toIso8601String()}'
        : null,
  };

  @override
  CampaignEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? gameMaster,
    DateTime? startDate,
    DateTime? endDate,
    String? imageUrl,
    List<String>? tags,
    bool? isActive,
    bool? isFavorite,
    Map<String, dynamic>? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampaignEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameMaster: gameMaster ?? this.gameMaster,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      isFavorite: isFavorite ?? this.isFavorite,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CampaignEntity(id: $id, name: $name, gameMaster: $gameMaster, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampaignEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Implementierung der abstrakten Methoden von DatabaseEntity
  @override
  String toSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
        .toLowerCase();
  }
  
  @override
  String toCamelCase(String snakeCase) {
    final parts = snakeCase.split('_');
    if (parts.length == 1) return parts.first;
    
    return parts.first + parts
        .skip(1)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1))
        .join('');
  }
  
  @override
  Map<String, dynamic> convertToSnakeCase(Map<String, dynamic> camelCaseMap) {
    final snakeCaseMap = <String, dynamic>{};
    
    for (final entry in camelCaseMap.entries) {
      final snakeKey = toSnakeCase(entry.key);
      snakeCaseMap[snakeKey] = entry.value;
    }
    
    return snakeCaseMap;
  }
  
  @override
  Map<String, dynamic> convertToCamelCase(Map<String, dynamic> snakeCaseMap) {
    final camelCaseMap = <String, dynamic>{};
    
    for (final entry in snakeCaseMap.entries) {
      final camelKey = toCamelCase(entry.key);
      camelCaseMap[camelKey] = entry.value;
    }
    
    return camelCaseMap;
  }

  // Helper methods for data conversion

  String _encodeSettings(Map<String, dynamic> settings) {
    try {
      // Simple JSON encoding - in production you'd use dart:convert
      return settings.entries
          .map((e) => '${e.key}:${e.value}')
          .join('|');
    } catch (e) {
      return '';
    }
  }

  Map<String, dynamic> _decodeSettings(String? encoded) {
    if (encoded == null || encoded.isEmpty) return {};
    
    try {
      final Map<String, dynamic> settings = {};
      final pairs = encoded.split('|');
      
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          settings[parts[0]] = parts[1];
        }
      }
      
      return settings;
    } catch (e) {
      return {};
    }
  }

  List<String> _parseTags(String? tagsString) {
    if (tagsString == null || tagsString.trim().isEmpty) {
      return [];
    }
    
    return tagsString
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  /// Convenience factory for creating new campaigns
  factory CampaignEntity.create({
    required String name,
    required String description,
    String? gameMaster,
    String? imageUrl,
    List<String> tags = const [],
  }) {
    final now = DateTime.now();
    
    return CampaignEntity(
      id: _generateId(),
      name: name.trim(),
      description: description.trim(),
      gameMaster: gameMaster?.trim(),
      startDate: now,
      imageUrl: imageUrl?.trim(),
      tags: tags,
      isActive: true,
      settings: {},
      createdAt: now,
      updatedAt: now,
    );
  }

  static String _generateId() {
    // Simple ID generation - in production use UUID service
    return 'camp_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Marks campaign as active/inactive
  CampaignEntity setActive(bool active) {
    return copyWith(
      isActive: active,
      updatedAt: DateTime.now(),
    );
  }

  /// Adds a tag to the campaign
  CampaignEntity addTag(String tag) {
    final cleanTag = tag.trim().toLowerCase();
    if (cleanTag.isEmpty || tags.contains(cleanTag)) {
      return this;
    }
    
    return copyWith(
      tags: [...tags, cleanTag],
      updatedAt: DateTime.now(),
    );
  }

  /// Removes a tag from the campaign
  CampaignEntity removeTag(String tag) {
    final cleanTag = tag.trim().toLowerCase();
    if (!tags.contains(cleanTag)) {
      return this;
    }
    
    return copyWith(
      tags: tags.where((t) => t != cleanTag).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Converts CampaignEntity to Campaign model
  Campaign toModel() {
    // Convert entity settings to CampaignSettings
    final campaignSettings = CampaignSettings(
      maxPlayerLevel: (settings['maxPlayerLevel'] as int?) ?? 20,
      startingLevel: (settings['startingLevel'] as int?) ?? 1,
      partySize: (settings['partySize'] as String?) ?? '4-5',
      availableMonsters: (settings['availableMonsters'] as String?)?.split(',') ?? [],
      availableSpells: (settings['availableSpells'] as String?)?.split(',') ?? [],
      availableItems: (settings['availableItems'] as String?)?.split(',') ?? [],
      availableNpcs: (settings['availableNpcs'] as String?)?.split(',') ?? [],
      allowCustomContent: (settings['allowCustomContent'] as bool?) ?? true,
      isPublic: (settings['isPublic'] as bool?) ?? false,
      imageUrl: imageUrl,
      customRules: (settings['customRules'] as Map<String, dynamic>?) ?? {},
    );

    return Campaign(
      id: id,
      title: name,
      description: description,
      status: isActive ? CampaignStatus.active : CampaignStatus.planning,
      type: CampaignType.homebrew,
      createdAt: createdAt,
      updatedAt: updatedAt,
      startedAt: startDate,
      completedAt: endDate,
      dungeonMasterId: gameMaster,
      isFavorite: isFavorite,
      playerCharacterIds: [], // Would be loaded separately
      questIds: [], // Would be loaded separately
      wikiEntryIds: [], // Would be loaded separately
      sessionIds: [], // Would be loaded separately
      settings: campaignSettings,
      stats: const CampaignStats(), // Would be calculated separately
    );
  }

  /// Creates CampaignEntity from Campaign model
  factory CampaignEntity.fromModel(Campaign campaign) {
    // Convert CampaignSettings to entity settings map
    final entitySettings = <String, dynamic>{
      'maxPlayerLevel': campaign.settings.maxPlayerLevel,
      'startingLevel': campaign.settings.startingLevel,
      'partySize': campaign.settings.partySize,
      'availableMonsters': campaign.settings.availableMonsters.join(','),
      'availableSpells': campaign.settings.availableSpells.join(','),
      'availableItems': campaign.settings.availableItems.join(','),
      'availableNpcs': campaign.settings.availableNpcs.join(','),
      'allowCustomContent': campaign.settings.allowCustomContent,
      'isPublic': campaign.settings.isPublic,
      'customRules': campaign.settings.customRules,
    };

    return CampaignEntity(
      id: campaign.id,
      name: campaign.title,
      description: campaign.description,
      gameMaster: campaign.dungeonMasterId,
      startDate: campaign.startedAt,
      endDate: campaign.completedAt,
      imageUrl: campaign.settings.imageUrl,
      tags: [], // Campaign model doesn't have tags
      isActive: campaign.status == CampaignStatus.active,
      isFavorite: campaign.isFavorite,
      settings: entitySettings,
      createdAt: campaign.createdAt,
      updatedAt: campaign.updatedAt,
    );
  }
}
