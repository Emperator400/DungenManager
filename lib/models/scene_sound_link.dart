// lib/models/scene_sound_link.dart
import 'package:uuid/uuid.dart';
import 'sound.dart';

var uuid = const Uuid();

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
  }) : id = id ?? uuid.v4();
    
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sceneId': sceneId,
      'soundId': soundId,
      'volume': volume,
    };
  }

  factory SceneSoundLink.fromMap(Map<String, dynamic> map) {
    return SceneSoundLink(
      id: map['id'],
      sceneId: map['sceneId'],
      soundId: map['soundId'],
      volume: map['volume'],
    );
  }
}

class DisplaySceneSound {
  final SceneSoundLink link; // Enthält die Lautstärke
  final Sound sound;         // Enthält Name, Pfad, Typ

  DisplaySceneSound({required this.link, required this.sound});
}