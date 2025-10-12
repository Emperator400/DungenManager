// lib/models/sound_scene.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class SoundScene {
  final String id;
  final String name;

  SoundScene({
    String? id,
    required this.name,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return { 'id': id, 'name': name };
  }

  factory SoundScene.fromMap(Map<String, dynamic> map) {
    return SoundScene(id: map['id'], name: map['name']);
  }
}