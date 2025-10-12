// lib/models/sound_scene.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

// NEU: Ein Enum für den Szenen-Typ
enum SoundSceneType { Ambiente, Effekte }

class SoundScene {
  final String id;
  final String name;
  final SoundSceneType type; // NEUES FELD

  SoundScene({
    String? id,
    required this.name,
    required this.type, // NEU im Konstruktor
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(), // NEU
    };
  }

  factory SoundScene.fromMap(Map<String, dynamic> map) {
    return SoundScene(
      id: map['id'],
      name: map['name'],
      // NEU: Lese den Typ aus der Datenbank
      type: SoundSceneType.values.firstWhere((e) => e.toString() == map['type'], orElse: () => SoundSceneType.Ambiente),
    );
  }
}