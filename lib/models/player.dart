import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

class Player {
  final String id;
  final String name;
  final String color;
  final String? avatarPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String get tableName => 'players';

  const Player({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.avatarPath,
    this.notes,
  });

  factory Player.create({
    required String name,
    String color = '#6B6B66',
    String? avatarPath,
    String? notes,
  }) {
    final now = DateTime.now();
    return Player(
      id: UuidService().generateId(),
      name: name,
      color: color,
      avatarPath: avatarPath,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toDatabaseMap() => {
        'id': id,
        'name': name,
        'color': color,
        'avatar_path': avatarPath,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Player.fromDatabaseMap(Map<String, dynamic> map) => Player(
        id: ModelParsingHelper.safeId(map, 'id'),
        name: ModelParsingHelper.safeString(map, 'name', 'Unbekannt'),
        color: ModelParsingHelper.safeString(map, 'color', '#6B6B66'),
        avatarPath: ModelParsingHelper.safeStringOrNull(map, 'avatar_path', null),
        notes: ModelParsingHelper.safeStringOrNull(map, 'notes', null),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      );

  Player copyWith({
    String? id,
    String? name,
    String? color,
    String? avatarPath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Player(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        avatarPath: avatarPath ?? this.avatarPath,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Player && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, name: $name)';
}
