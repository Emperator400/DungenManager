// lib/models/sound_scene_item.dart
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

/// Repräsentiert einen Sound in einer SoundScene mit seinen Einstellungen
class SoundSceneItem {
  final String id;
  final String soundSceneId;
  final String soundId;
  final double volume; // 0.0 bis 1.0
  final bool isLooping;
  final double fadeInDuration; // in Sekunden
  final double fadeOutDuration; // in Sekunden
  final int sortOrder;
  final DateTime createdAt;

  SoundSceneItem({
    String? id,
    required this.soundSceneId,
    required this.soundId,
    this.volume = 1.0,
    this.isLooping = true,
    this.fadeInDuration = 0.0,
    this.fadeOutDuration = 0.0,
    this.sortOrder = 0,
    DateTime? createdAt,
  })  : id = id ?? UuidService().generateId(),
        createdAt = createdAt ?? DateTime.now();

  /// Creates a copy with updated values
  SoundSceneItem copyWith({
    String? id,
    String? soundSceneId,
    String? soundId,
    double? volume,
    bool? isLooping,
    double? fadeInDuration,
    double? fadeOutDuration,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return SoundSceneItem(
      id: id ?? this.id,
      soundSceneId: soundSceneId ?? this.soundSceneId,
      soundId: soundId ?? this.soundId,
      volume: volume ?? this.volume,
      isLooping: isLooping ?? this.isLooping,
      fadeInDuration: fadeInDuration ?? this.fadeInDuration,
      fadeOutDuration: fadeOutDuration ?? this.fadeOutDuration,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Konvertiert zu Datenbank-Map
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'sound_scene_id': soundSceneId,
      'sound_id': soundId,
      'volume': volume,
      'is_looping': isLooping ? 1 : 0,
      'fade_in_duration': fadeInDuration,
      'fade_out_duration': fadeOutDuration,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Erstellt aus Datenbank-Map
  factory SoundSceneItem.fromDatabaseMap(Map<String, dynamic> map) {
    return SoundSceneItem(
      id: ModelParsingHelper.safeId(map, 'id'),
      soundSceneId: ModelParsingHelper.safeString(map, 'sound_scene_id', ''),
      soundId: ModelParsingHelper.safeString(map, 'sound_id', ''),
      volume: ModelParsingHelper.safeDouble(map, 'volume', 1.0),
      isLooping: ModelParsingHelper.safeBool(map, 'is_looping', true),
      fadeInDuration: ModelParsingHelper.safeDouble(map, 'fade_in_duration', 0.0),
      fadeOutDuration: ModelParsingHelper.safeDouble(map, 'fade_out_duration', 0.0),
      sortOrder: ModelParsingHelper.safeInt(map, 'sort_order', 0),
      createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
    );
  }

  /// Validierung
  bool get isValid {
    return soundSceneId.isNotEmpty && 
           soundId.isNotEmpty && 
           volume >= 0.0 && 
           volume <= 1.0;
  }

  /// Formatierte Lautstärke als Prozent
  String get formattedVolume => '${(volume * 100).toStringAsFixed(0)}%';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundSceneItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SoundSceneItem(id: $id, soundId: $soundId, volume: $volume, looping: $isLooping)';
  }
}