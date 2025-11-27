// lib/models/scene_sound_link.dart
import '../services/uuid_service.dart';
import 'sound.dart';
import '../utils/model_parsing_helper.dart';

class SceneSoundLink {
  final String id;
  final String sceneId;
  final String soundId;
  double volume; // Lautstärke von 0.0 bis 1.0

  SceneSoundLink({
    String? id,
    required this.sceneId,
    required this.soundId,
    this.volume = 0.8, // Standard-Lautstärke 80%
  }) : id = id ?? UuidService().generateId();
    
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scene_id': sceneId,
      'sound_id': soundId,
      'volume': volume,
    };
  }

  factory SceneSoundLink.fromMap(Map<String, dynamic> map) {
    return SceneSoundLink(
      id: ModelParsingHelper.safeId(map, 'id'),
      sceneId: ModelParsingHelper.safeString(map, 'scene_id', ''),
      soundId: ModelParsingHelper.safeString(map, 'sound_id', ''),
      volume: ModelParsingHelper.safeDouble(map, 'volume', 0.8),
    );
  }
}

class DisplaySceneSound {
  final SceneSoundLink link; // Enthält die Lautstärke
  final Sound sound;         // Enthält Name, Pfad, Typ

  DisplaySceneSound({required this.link, required this.sound});
}
