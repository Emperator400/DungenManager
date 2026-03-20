// lib/models/sound_scene.dart
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';
import 'sound_scene_item.dart';

/// Sound Scene Type für die Klassifizierung von Sound-Szenen
enum SoundSceneType { Ambiente, Effekte, Mixed }

class SoundScene {
  final String id;
  final String name;
  final String description;
  final bool isFavorite;
  final List<SoundSceneItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  SoundScene({
    String? id,
    required this.name,
    this.description = '',
    this.isFavorite = false,
    List<SoundSceneItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidService().generateId(),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this SoundScene with updated values
  SoundScene copyWith({
    String? id,
    String? name,
    String? description,
    bool? isFavorite,
    List<SoundSceneItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SoundScene(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      items: items ?? List<SoundSceneItem>.from(this.items),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Konvertiert zu Datenbank-Map (ohne Items, diese werden separat gespeichert)
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Erstellt aus Datenbank-Map (ohne Items)
  factory SoundScene.fromDatabaseMap(Map<String, dynamic> map) {
    return SoundScene(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbenannte Szene'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      isFavorite: ModelParsingHelper.safeBool(map, 'is_favorite', false),
      createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
      updatedAt: ModelParsingHelper.safeDateTime(map, 'updated_at', DateTime.now()),
    );
  }

  /// Erstellt aus Datenbank-Map mit Items
  factory SoundScene.fromDatabaseMapWithItems(
    Map<String, dynamic> map,
    List<SoundSceneItem> items,
  ) {
    return SoundScene(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbenannte Szene'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      isFavorite: ModelParsingHelper.safeBool(map, 'is_favorite', false),
      items: items,
      createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
      updatedAt: ModelParsingHelper.safeDateTime(map, 'updated_at', DateTime.now()),
    );
  }

  /// Legacy-Methode für Abwärtskompatibilität
  Map<String, dynamic> toMap() => toDatabaseMap();
  
  /// Legacy-Methode für Abwärtskompatibilität
  factory SoundScene.fromMap(Map<String, dynamic> map) => SoundScene.fromDatabaseMap(map);

  /// Anzahl der Sounds in dieser Szene
  int get soundCount => items.length;

  /// Typ der Szene (für Abwärtskompatibilität)
  SoundSceneType get type {
    if (items.isEmpty) return SoundSceneType.Mixed;
    // Bestimmt den Typ basierend auf den Sounds
    return SoundSceneType.Mixed;
  }

  /// Szenen-ID (Alias für id, für Abwärtskompatibilität)
  String get sceneId => id;

  /// Prüft ob die Szene Sounds enthält
  bool get hasSounds => items.isNotEmpty;

  /// Findet ein Item anhand der Sound-ID
  SoundSceneItem? findItemBySoundId(String soundId) {
    try {
      return items.firstWhere((item) => item.soundId == soundId);
    } catch (_) {
      return null;
    }
  }

  /// Validierung
  bool get isValid {
    return name.isNotEmpty;
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
    return 'SoundScene(id: $id, name: $name, items: ${items.length})';
  }
}