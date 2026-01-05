import '../services/uuid_service.dart';
import '../utils/string_list_parser.dart';
import '../utils/model_parsing_helper.dart';

/// Kampagnen-Status
enum CampaignStatus {
  planning,
  active,
  paused,
  completed,
  cancelled,
}

/// Kampagnen-Typ
enum CampaignType {
  homebrew,
  module,
  adventurePath,
  oneShot,
}

/// Kampagnen-Statistiken
class CampaignStats {
  final int totalSessions;
  final int totalQuests;
  final int completedQuests;
  final int totalCharacters;
  final int totalExperienceAwarded;
  final double totalGoldAwarded;
  final Duration totalPlayTime;

  const CampaignStats({
    this.totalSessions = 0,
    this.totalQuests = 0,
    this.completedQuests = 0,
    this.totalCharacters = 0,
    this.totalExperienceAwarded = 0,
    this.totalGoldAwarded = 0.0,
    this.totalPlayTime = Duration.zero,
  });

  factory CampaignStats.fromMap(Map<String, dynamic> map) {
    return CampaignStats(
      totalSessions: ModelParsingHelper.safeInt(map, 'total_sessions', 0),
      totalQuests: ModelParsingHelper.safeInt(map, 'total_quests', 0),
      completedQuests: ModelParsingHelper.safeInt(map, 'completed_quests', 0),
      totalCharacters: ModelParsingHelper.safeInt(map, 'total_characters', 0),
      totalExperienceAwarded: ModelParsingHelper.safeInt(map, 'total_experience_awarded', 0),
      totalGoldAwarded: ModelParsingHelper.safeDouble(map, 'total_gold_awarded', 0.0),
      totalPlayTime: Duration(milliseconds: ModelParsingHelper.safeInt(map, 'total_play_time_ms', 0)),
    );
  }

  factory CampaignStats.fromDatabaseMap(Map<String, dynamic> map) {
    return CampaignStats(
      totalSessions: map['total_sessions'] as int? ?? 0,
      totalQuests: map['total_quests'] as int? ?? 0,
      completedQuests: map['completed_quests'] as int? ?? 0,
      totalCharacters: map['total_characters'] as int? ?? 0,
      totalExperienceAwarded: map['total_experience_awarded'] as int? ?? 0,
      totalGoldAwarded: (map['total_gold_awarded'] as num?)?.toDouble() ?? 0.0,
      totalPlayTime: Duration(milliseconds: map['total_play_time_ms'] as int? ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_sessions': totalSessions,
      'total_quests': totalQuests,
      'completed_quests': completedQuests,
      'total_characters': totalCharacters,
      'total_experience_awarded': totalExperienceAwarded,
      'total_gold_awarded': totalGoldAwarded,
      'total_play_time_ms': totalPlayTime.inMilliseconds,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return toMap();
  }

  CampaignStats copyWith({
    int? totalSessions,
    int? totalQuests,
    int? completedQuests,
    int? totalCharacters,
    int? totalExperienceAwarded,
    double? totalGoldAwarded,
    Duration? totalPlayTime,
  }) {
    return CampaignStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalQuests: totalQuests ?? this.totalQuests,
      completedQuests: completedQuests ?? this.completedQuests,
      totalCharacters: totalCharacters ?? this.totalCharacters,
      totalExperienceAwarded: totalExperienceAwarded ?? this.totalExperienceAwarded,
      totalGoldAwarded: totalGoldAwarded ?? this.totalGoldAwarded,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
    );
  }

  /// Quest-Abschlussrate in Prozent
  double get questCompletionRate {
    if (totalQuests == 0) return 0.0;
    return completedQuests / totalQuests * 100;
  }

  /// Durchschnittliche Erfahrung pro Session
  double get averageExperiencePerSession {
    if (totalSessions == 0) return 0.0;
    return totalExperienceAwarded / totalSessions;
  }

  /// Durchschnittliches Gold pro Session
  double get averageGoldPerSession {
    if (totalSessions == 0) return 0.0;
    return totalGoldAwarded / totalSessions;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampaignStats &&
        other.totalSessions == totalSessions &&
        other.totalQuests == totalQuests &&
        other.completedQuests == completedQuests &&
        other.totalCharacters == totalCharacters &&
        other.totalExperienceAwarded == totalExperienceAwarded &&
        other.totalGoldAwarded == totalGoldAwarded &&
        other.totalPlayTime == totalPlayTime;
  }

  @override
  int get hashCode => Object.hash(
        totalSessions,
        totalQuests,
        completedQuests,
        totalCharacters,
        totalExperienceAwarded,
        totalGoldAwarded,
        totalPlayTime,
      );

  @override
  String toString() {
    return 'CampaignStats(sessions: $totalSessions, quests: $totalQuests/$completedQuests, chars: $totalCharacters)';
  }
}

/// Kampagnen-Einstellungen
class CampaignSettings {
  final int maxPlayerLevel;
  final int startingLevel;
  final String partySize;
  final List<String> availableMonsters;
  final List<String> availableSpells;
  final List<String> availableItems;
  final List<String> availableNpcs;
  final bool allowCustomContent;
  final bool isPublic;
  final String? imageUrl;
  final Map<String, dynamic> customRules;

  const CampaignSettings({
    this.maxPlayerLevel = 20,
    this.startingLevel = 1,
    this.partySize = '4-5',
    this.availableMonsters = const [],
    this.availableSpells = const [],
    this.availableItems = const [],
    this.availableNpcs = const [],
    this.allowCustomContent = true,
    this.isPublic = false,
    this.imageUrl,
    this.customRules = const {},
  });

  factory CampaignSettings.fromMap(Map<String, dynamic> map) {
    return CampaignSettings(
      maxPlayerLevel: ModelParsingHelper.safeInt(map, 'max_player_level', 20),
      startingLevel: ModelParsingHelper.safeInt(map, 'starting_level', 1),
      partySize: ModelParsingHelper.safeString(map, 'party_size', '4-5'),
      availableMonsters: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'available_monsters', null)),
      availableSpells: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'available_spells', null)),
      availableItems: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'available_items', null)),
      availableNpcs: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'available_npcs', null)),
      allowCustomContent: ModelParsingHelper.safeBool(map, 'allow_custom_content', true),
      isPublic: ModelParsingHelper.safeBool(map, 'is_public', false),
      imageUrl: ModelParsingHelper.safeStringOrNull(map, 'image_url', null),
      customRules: _parseCustomRules(ModelParsingHelper.safeStringOrNull(map, 'custom_rules', null)),
    );
  }

  factory CampaignSettings.fromDatabaseMap(Map<String, dynamic> map) {
    return CampaignSettings(
      maxPlayerLevel: map['max_player_level'] as int? ?? 20,
      startingLevel: map['starting_level'] as int? ?? 1,
      partySize: map['party_size'] as String? ?? '4-5',
      availableMonsters: _deserializeStringList(map['available_monsters'] as String?),
      availableSpells: _deserializeStringList(map['available_spells'] as String?),
      availableItems: _deserializeStringList(map['available_items'] as String?),
      availableNpcs: _deserializeStringList(map['available_npcs'] as String?),
      allowCustomContent: ModelParsingHelper.safeBool(map, 'allow_custom_content', true),
      isPublic: ModelParsingHelper.safeBool(map, 'is_public', false),
      imageUrl: map['image_url'] as String?,
      customRules: _parseCustomRules(map['custom_rules'] as String?),
    );
  }

  /// Hilfsmethode zum Deserialisieren einer String-Liste
  static List<String> _deserializeStringList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((s) => s.isNotEmpty).toList();
  }

  /// Hilfsmethode zum Serialisieren einer String-Liste
  static String? _serializeStringList(List<String> list) {
    if (list.isEmpty) return null;
    return list.join(',');
  }

  /// Hilfsmethode zum sicheren Parsen von customRules
  static Map<String, dynamic> _parseCustomRules(String? rulesString) {
    if (rulesString == null || rulesString.isEmpty) {
      return {};
    }
    
    try {
      // Versuche als JSON zu parsen
      if (rulesString.startsWith('{') && rulesString.endsWith('}')) {
        return Map<String, dynamic>.from(
          _parseSimpleJson(rulesString)
        );
      }
      
      // Fallback: leere Map
      return {};
    } catch (e) {
      print('Fehler beim Parsen von customRules: $e');
      return {};
    }
  }

  /// Einfacher JSON-Parser für basic Maps
  static Map<String, dynamic> _parseSimpleJson(String jsonString) {
    final result = <String, dynamic>{};
    
    // Entferne äußere Klammern
    String content = jsonString.trim();
    if (content.startsWith('{') && content.endsWith('}')) {
      content = content.substring(1, content.length - 1).trim();
    }
    
    // Simple key-value parsing
    final pairs = content.split(',');
    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length >= 2) {
        final key = keyValue[0].trim().replaceAll("'", "").replaceAll('"', "").trim();
        final value = keyValue[1].trim().replaceAll("'", "").replaceAll('"', "").trim();
        if (key.isNotEmpty) {
          result[key] = value;
        }
      }
    }
    
    return result;
  }

  /// Hilfsmethode zum sicheren JSON-Encoding
  static String _encodeJson(Map<String, dynamic> data) {
    try {
      return data.map((key, value) {
        if (value == null) return MapEntry(key, 'null');
        if (value is String || value is num || value is bool) {
          return MapEntry(key, value);
        }
        // Komplexe Typen als String speichern
        return MapEntry(key, value.toString());
      }).toString();
    } catch (e) {
      print('Fehler beim JSON-Encoding von customRules: $e');
      return '{}';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'max_player_level': maxPlayerLevel,
      'starting_level': startingLevel,
      'party_size': partySize,
      'available_monsters': availableMonsters.isNotEmpty ? availableMonsters.join(',') : null,
      'available_spells': availableSpells.isNotEmpty ? availableSpells.join(',') : null,
      'available_items': availableItems.isNotEmpty ? availableItems.join(',') : null,
      'available_npcs': availableNpcs.isNotEmpty ? availableNpcs.join(',') : null,
      'allow_custom_content': allowCustomContent ? 1 : 0,
      'is_public': isPublic ? 1 : 0,
      'image_url': imageUrl,
      'custom_rules': customRules.isNotEmpty ? _encodeJson(customRules) : null,
    };
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'max_player_level': maxPlayerLevel,
      'starting_level': startingLevel,
      'party_size': partySize,
      'available_monsters': _serializeStringList(availableMonsters),
      'available_spells': _serializeStringList(availableSpells),
      'available_items': _serializeStringList(availableItems),
      'available_npcs': _serializeStringList(availableNpcs),
      'allow_custom_content': allowCustomContent ? 1 : 0,
      'is_public': isPublic ? 1 : 0,
      'image_url': imageUrl,
      'custom_rules': customRules.isNotEmpty ? _encodeJson(customRules) : null,
    };
  }

  CampaignSettings copyWith({
    int? maxPlayerLevel,
    int? startingLevel,
    String? partySize,
    List<String>? availableMonsters,
    List<String>? availableSpells,
    List<String>? availableItems,
    List<String>? availableNpcs,
    bool? allowCustomContent,
    bool? isPublic,
    String? imageUrl,
    Map<String, dynamic>? customRules,
  }) {
    return CampaignSettings(
      maxPlayerLevel: maxPlayerLevel ?? this.maxPlayerLevel,
      startingLevel: startingLevel ?? this.startingLevel,
      partySize: partySize ?? this.partySize,
      availableMonsters: availableMonsters ?? this.availableMonsters,
      availableSpells: availableSpells ?? this.availableSpells,
      availableItems: availableItems ?? this.availableItems,
      availableNpcs: availableNpcs ?? this.availableNpcs,
      allowCustomContent: allowCustomContent ?? this.allowCustomContent,
      isPublic: isPublic ?? this.isPublic,
      imageUrl: imageUrl ?? this.imageUrl,
      customRules: customRules ?? this.customRules,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampaignSettings &&
        other.maxPlayerLevel == maxPlayerLevel &&
        other.startingLevel == startingLevel &&
        other.partySize == partySize &&
        other.allowCustomContent == allowCustomContent &&
        other.isPublic == isPublic &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => Object.hash(
        maxPlayerLevel,
        startingLevel,
        partySize,
        allowCustomContent,
        isPublic,
        imageUrl,
      );

  @override
  String toString() {
    return 'CampaignSettings(maxLevel: $maxPlayerLevel, startLevel: $startingLevel, partySize: $partySize)';
  }
}

/// Campaign-Model für D&D Kampagnen
/// 
/// Repräsentiert eine vollständige Kampagne mit allen Metadaten,
/// Einstellungen und verknüpften Inhalten. Enthält keine Business-Logik.
class Campaign {
  final String id;
  final String title;
  final String description;
  final CampaignStatus status;
  final CampaignType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? dungeonMasterId;
  final bool isFavorite;
  final List<String> playerCharacterIds;
  final List<String> questIds;
  final List<String> wikiEntryIds;
  final List<String> sessionIds;
  final CampaignSettings settings;
  final CampaignStats stats;

  /// Tabellenname für die Datenbank
  static const String tableName = 'campaigns';

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    this.status = CampaignStatus.planning,
    this.type = CampaignType.homebrew,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.dungeonMasterId,
    this.isFavorite = false,
    this.playerCharacterIds = const [],
    this.questIds = const [],
    this.wikiEntryIds = const [],
    this.sessionIds = const [],
    this.settings = const CampaignSettings(),
    this.stats = const CampaignStats(),
  });

  /// Factory für neue Kampagnen mit automatisch generierter ID
  factory Campaign.create({
    required String title,
    required String description,
    CampaignStatus status = CampaignStatus.planning,
    CampaignType type = CampaignType.homebrew,
    String? dungeonMasterId,
    CampaignSettings? settings,
  }) {
    final now = DateTime.now();
    return Campaign(
      id: UuidService().generateId(),
      title: title,
      description: description,
      status: status,
      type: type,
      createdAt: now,
      updatedAt: now,
      dungeonMasterId: dungeonMasterId,
      settings: settings ?? const CampaignSettings(),
      stats: const CampaignStats(),
    );
  }

  /// Legacy Factory für Abwärtskompatibilität mit alten Parametern
  factory Campaign.legacy({
    required String title,
    required String description,
    List<String>? availableMonsters,
    List<String>? availableSpells,
    List<String>? availableItems,
    List<String>? availableNpcs,
    String? id,
  }) {
    final now = DateTime.now();
    final settings = CampaignSettings(
      availableMonsters: availableMonsters ?? const [],
      availableSpells: availableSpells ?? const [],
      availableItems: availableItems ?? const [],
      availableNpcs: availableNpcs ?? const [],
    );
    
    return Campaign(
      id: id ?? UuidService().generateId(),
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
      settings: settings,
    );
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Legacy)
  factory Campaign.fromMap(Map<String, dynamic> map) {
    try {
      // Parse settings und stats aus JSON-Strings
      final settingsString = ModelParsingHelper.safeStringOrNull(map, 'settings', null);
      final statsString = ModelParsingHelper.safeStringOrNull(map, 'stats', null);
      
      Map<String, dynamic> settingsMap = {};
      Map<String, dynamic> statsMap = {};
      
      if (settingsString != null && settingsString.isNotEmpty) {
        settingsMap = _parseJsonString(settingsString);
      }
      
      if (statsString != null && statsString.isNotEmpty) {
        statsMap = _parseJsonString(statsString);
      }
      
      return Campaign(
        id: ModelParsingHelper.safeId(map, 'id'),
        title: ModelParsingHelper.safeString(map, 'title', ''),
        description: ModelParsingHelper.safeString(map, 'description', ''),
        status: CampaignStatus.values.firstWhere(
          (e) => e.toString() == 'CampaignStatus.${ModelParsingHelper.safeString(map, 'status', 'planning')}',
          orElse: () => CampaignStatus.planning,
        ),
        type: CampaignType.values.firstWhere(
          (e) => e.toString() == 'CampaignType.${ModelParsingHelper.safeString(map, 'type', 'homebrew')}',
          orElse: () => CampaignType.homebrew,
        ),
        createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
        updatedAt: ModelParsingHelper.safeDateTime(map, 'updated_at', DateTime.now()),
        startedAt: ModelParsingHelper.safeDateTimeOrNull(map, 'started_at', null),
        completedAt: ModelParsingHelper.safeDateTimeOrNull(map, 'completed_at', null),
        dungeonMasterId: ModelParsingHelper.safeStringOrNull(map, 'dungeon_master_id', null),
        playerCharacterIds: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'player_character_ids', null)),
        questIds: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'quest_ids', null)),
        wikiEntryIds: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'wiki_entry_ids', null)),
        sessionIds: StringListParser.parseStringList(ModelParsingHelper.safeStringOrNull(map, 'session_ids', null)),
        settings: CampaignSettings.fromMap(settingsMap),
        stats: CampaignStats.fromMap(statsMap),
      );
    } catch (e) {
      print('Fehler beim Parsen der Kampagne: $e');
      // Fallback zu minimal gültiger Kampagne
      return Campaign.create(
        title: ModelParsingHelper.safeString(map, 'title', 'Fehlerhafte Kampagne'),
        description: ModelParsingHelper.safeString(map, 'description', 'Parse-Fehler'),
      );
    }
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Neu)
  factory Campaign.fromDatabaseMap(Map<String, dynamic> map) {
    try {
      // Parse settings und stats aus JSON-Strings
      final settingsString = map['settings'] as String?;
      final statsString = map['stats'] as String?;
      
      Map<String, dynamic> settingsMap = {};
      Map<String, dynamic> statsMap = {};
      
      if (settingsString != null && settingsString.isNotEmpty) {
        settingsMap = _parseJsonString(settingsString);
      }
      
      if (statsString != null && statsString.isNotEmpty) {
        statsMap = _parseJsonString(statsString);
      }
      
      return Campaign(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        status: CampaignStatus.values.firstWhere(
          (e) => e.toString() == 'CampaignStatus.${map['status'] as String? ?? 'planning'}',
          orElse: () => CampaignStatus.planning,
        ),
        type: CampaignType.values.firstWhere(
          (e) => e.toString() == 'CampaignType.${map['type'] as String? ?? 'homebrew'}',
          orElse: () => CampaignType.homebrew,
        ),
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
        startedAt: map['started_at'] != null ? DateTime.tryParse(map['started_at'] as String) : null,
        completedAt: map['completed_at'] != null ? DateTime.tryParse(map['completed_at'] as String) : null,
        dungeonMasterId: map['dungeon_master_id'] as String?,
        isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
        playerCharacterIds: _deserializeStringList(map['player_character_ids'] as String?),
        questIds: _deserializeStringList(map['quest_ids'] as String?),
        wikiEntryIds: _deserializeStringList(map['wiki_entry_ids'] as String?),
        sessionIds: _deserializeStringList(map['session_ids'] as String?),
        settings: CampaignSettings.fromDatabaseMap(settingsMap),
        stats: CampaignStats.fromDatabaseMap(statsMap),
      );
    } catch (e) {
      print('Fehler beim Parsen der Kampagne: $e');
      // Fallback zu minimal gültiger Kampagne
      return Campaign.create(
        title: map['title'] as String? ?? 'Fehlerhafte Kampagne',
        description: map['description'] as String? ?? 'Parse-Fehler',
      );
    }
  }

  /// Hilfsmethode zum Deserialisieren einer String-Liste
  static List<String> _deserializeStringList(String? value) {
    if (value == null || value.isEmpty) return [];
    return value.split(',').where((s) => s.isNotEmpty).toList();
  }

  /// Hilfsmethode zum Serialisieren einer String-Liste
  static String? _serializeStringList(List<String> list) {
    if (list.isEmpty) return null;
    return list.join(',');
  }

  /// Hilfsmethode zum Parsen von JSON-Strings
  static Map<String, dynamic> _parseJsonString(String jsonString) {
    try {
      final result = <String, dynamic>{};
      
      // Entferne äußere Klammern
      String content = jsonString.trim();
      if (content.startsWith('{') && content.endsWith('}')) {
        content = content.substring(1, content.length - 1).trim();
      }
      
      // Simple key-value parsing
      final pairs = content.split(',');
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length >= 2) {
          final key = keyValue[0].trim().replaceAll("'", "").replaceAll('"', "").trim();
          final value = keyValue[1].trim().replaceAll("'", "").replaceAll('"', "").trim();
          if (key.isNotEmpty) {
            // Versuche, Typen zu erkennen
            if (value == 'null') {
              result[key] = null;
            } else if (value == 'true') {
              result[key] = true;
            } else if (value == 'false') {
              result[key] = false;
            } else if (int.tryParse(value) != null) {
              result[key] = int.parse(value);
            } else if (double.tryParse(value) != null) {
              result[key] = double.parse(value);
            } else {
              result[key] = value;
            }
          }
        }
      }
      
      return result;
    } catch (e) {
      print('Fehler beim Parsen des JSON-Strings: $e');
      return {};
    }
  }

  /// Hilfsmethode zum JSON-Encoding von komplexen Objekten
  static String _encodeJson(Map<String, dynamic> data) {
    try {
      return data.map((key, value) {
        if (value == null) return MapEntry(key, 'null');
        if (value is String || value is num || value is bool) {
          return MapEntry(key, value);
        }
        // Komplexe Typen als String speichern
        return MapEntry(key, value.toString());
      }).toString();
    } catch (e) {
      print('Fehler beim JSON-Encoding: $e');
      return '{}';
    }
  }

  /// Konvertiert die Kampagne zu einer Datenbank-Map (Legacy)
  Map<String, dynamic> toMap() {
    return toDatabaseMap();
  }
  
  /// Konvertiert die Kampagne zu einer Datenbank-Map (Neu)
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'dungeon_master_id': dungeonMasterId,
      'is_favorite': isFavorite ? 1 : 0,
      'player_character_ids': _serializeStringList(playerCharacterIds),
      'quest_ids': _serializeStringList(questIds),
      'wiki_entry_ids': _serializeStringList(wikiEntryIds),
      'session_ids': _serializeStringList(sessionIds),
      'settings': _encodeJson(settings.toDatabaseMap()),
      'stats': _encodeJson(stats.toDatabaseMap()),
    };
  }

  /// CopyWith-Methode für unveränderliche Updates
  Campaign copyWith({
    String? id,
    String? title,
    String? description,
    CampaignStatus? status,
    CampaignType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? dungeonMasterId,
    bool? isFavorite,
    List<String>? playerCharacterIds,
    List<String>? questIds,
    List<String>? wikiEntryIds,
    List<String>? sessionIds,
    CampaignSettings? settings,
    CampaignStats? stats,
  }) {
    return Campaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      dungeonMasterId: dungeonMasterId ?? this.dungeonMasterId,
      isFavorite: isFavorite ?? this.isFavorite,
      playerCharacterIds: playerCharacterIds ?? this.playerCharacterIds,
      questIds: questIds ?? this.questIds,
      wikiEntryIds: wikiEntryIds ?? this.wikiEntryIds,
      sessionIds: sessionIds ?? this.sessionIds,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Campaign && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Campaign(id: $id, title: $title, status: $status, type: $type)';
  }

  // ========== BASIS VALIDIERUNGEN ==========
  // Nur grundlegende Datenintegrität - keine Business-Logik

  /// Prüft ob der Titel gültig ist
  bool get hasValidTitle => title.trim().isNotEmpty;

  /// Prüft ob die Beschreibung gültig ist
  bool get hasValidDescription => description.trim().isNotEmpty;

  /// Grundlegende Validierung aller Felder
  bool get isValid => hasValidTitle && hasValidDescription;

  /// Liste aller Validierungsfehler
  List<String> get validationErrors {
    final errors = <String>[];
    if (!hasValidTitle) errors.add('Titel darf nicht leer sein');
    if (!hasValidDescription) errors.add('Beschreibung darf nicht leer sein');
    return errors;
  }

  // ========== COMPATIBILITY GETTERS ==========
  // Für Abwärtskompatibilität mit bestehendem Code

  /// Prüft ob die Kampagne aktiv ist
  bool get isActive => status == CampaignStatus.active;

  /// Prüft ob die Kampagne abgeschlossen ist
  bool get isCompleted => status == CampaignStatus.completed;

  /// Prüft ob die Kampagne Players hat
  bool get hasPlayers => playerCharacterIds.isNotEmpty;

  /// Prüft ob die Kampagne Quests hat
  bool get hasQuests => questIds.isNotEmpty;

  /// Prüft ob die Kampagne Wiki-Einträge hat
  bool get hasWikiEntries => wikiEntryIds.isNotEmpty;

  /// Prüft ob die Kampagne Sessions hat
  bool get hasSessions => sessionIds.isNotEmpty;

  /// Anzahl der Players
  int get playerCount => playerCharacterIds.length;

  /// Anzahl der Quests
  int get questCount => questIds.length;

  /// Anzahl der Wiki-Einträge
  int get wikiEntryCount => wikiEntryIds.length;

  /// Anzahl der Sessions
  int get sessionCount => sessionIds.length;

  /// Lokalisierte Beschreibung für Status
  String get statusDescription {
    switch (status) {
      case CampaignStatus.planning:
        return 'Planung';
      case CampaignStatus.active:
        return 'Aktiv';
      case CampaignStatus.paused:
        return 'Pausiert';
      case CampaignStatus.completed:
        return 'Abgeschlossen';
      case CampaignStatus.cancelled:
        return 'Abgebrochen';
    }
  }

  /// Lokalisierte Beschreibung für Typ
  String get typeDescription {
    switch (type) {
      case CampaignType.homebrew:
        return 'Homebrew';
      case CampaignType.module:
        return 'Module';
      case CampaignType.adventurePath:
        return 'Adventure Path';
      case CampaignType.oneShot:
        return 'One-Shot';
    }
  }

  // Legacy-Felder für Abwärtskompatibilität
  List<String> get availableMonsters => settings.availableMonsters;
  List<String> get availableSpells => settings.availableSpells;
  List<String> get availableItems => settings.availableItems;
  List<String> get availableNpcs => settings.availableNpcs;

  // Legacy-Methode für Tests (Abwärtskompatibilität)
  static List<String> parseStringListForTest(String? value) {
    return StringListParser.parseStringListForTest(value);
  }
}
