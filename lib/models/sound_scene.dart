// lib/models/sound_scene.dart
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

/// Sound Scene Type für die Klassifizierung von Sound-Szenen
enum SoundSceneType { Ambiente, Effekte }

class SoundScene {
  final String id;
  final String name;
  final SoundSceneType type;
  final String sceneId; // Verknüpfung zur Scene
  final DateTime createdAt;
  final DateTime updatedAt;

  SoundScene({
    String? id,
    required this.name,
    required this.type,
    required this.sceneId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidService().generateId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this SoundScene with updated values
  SoundScene copyWith({
    String? id,
    String? name,
    SoundSceneType? type,
    String? sceneId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoundScene(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      sceneId: sceneId ?? this.sceneId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'sceneId': sceneId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SoundScene.fromMap(Map<String, dynamic> map) {
    return SoundScene(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbenannte Sound Scene'),
      type: SoundSceneType.values.firstWhere(
        (e) => e.name == ModelParsingHelper.safeString(map, 'type', 'Ambiente'),
        orElse: () => SoundSceneType.Ambiente,
      ),
      sceneId: ModelParsingHelper.safeString(map, 'sceneId', ''),
      createdAt: DateTime.fromMillisecondsSinceEpoch(ModelParsingHelper.safeInt(map, 'createdAt', 0)),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(ModelParsingHelper.safeInt(map, 'updatedAt', 0)),
    );
  }

  /// Gets the display name for the sound scene type
  String get typeDisplayName {
    switch (type) {
      case SoundSceneType.Ambiente:
        return 'Ambiente';
      case SoundSceneType.Effekte:
        return 'Effekte';
    }
  }

  /// Validates the sound scene model
  bool get isValid {
    return name.isNotEmpty && sceneId.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundScene && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SoundScene(id: $id, name: $name, type: $type, sceneId: $sceneId)';
  }
}
