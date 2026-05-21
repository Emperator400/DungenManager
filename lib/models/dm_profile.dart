import '../utils/model_parsing_helper.dart';

class DmProfile {
  static const String fixedId = 'dm_profile';
  static String get tableName => 'dm_profile';

  final String id;
  final String dmName;
  final String? bio;
  final String? avatarPath;
  final String? favoriteSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DmProfile({
    required this.id,
    required this.dmName,
    required this.createdAt,
    required this.updatedAt,
    this.bio,
    this.avatarPath,
    this.favoriteSystem,
  });

  factory DmProfile.empty() {
    final now = DateTime.now();
    return DmProfile(
      id: fixedId,
      dmName: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toDatabaseMap() => {
        'id': id,
        'dm_name': dmName,
        'bio': bio,
        'avatar_path': avatarPath,
        'favorite_system': favoriteSystem,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DmProfile.fromDatabaseMap(Map<String, dynamic> map) => DmProfile(
        id: ModelParsingHelper.safeId(map, 'id'),
        dmName: ModelParsingHelper.safeString(map, 'dm_name', ''),
        bio: ModelParsingHelper.safeStringOrNull(map, 'bio', null),
        avatarPath: ModelParsingHelper.safeStringOrNull(map, 'avatar_path', null),
        favoriteSystem: ModelParsingHelper.safeStringOrNull(map, 'favorite_system', null),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      );

  DmProfile copyWith({
    String? dmName,
    String? bio,
    Object? avatarPath = _sentinel,
    String? favoriteSystem,
    DateTime? updatedAt,
  }) =>
      DmProfile(
        id: id,
        dmName: dmName ?? this.dmName,
        bio: bio ?? this.bio,
        avatarPath: avatarPath == _sentinel ? this.avatarPath : avatarPath as String?,
        favoriteSystem: favoriteSystem ?? this.favoriteSystem,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

const Object _sentinel = Object();
