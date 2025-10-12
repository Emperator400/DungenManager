// lib/models/sound.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

enum SoundType { Ambiente, Effekt }

class Sound {
  final String id;
  final String name;
  final String filePath; // Der Pfad zur kopierten Audio-Datei
  final SoundType soundType;

  Sound({
    String? id,
    required this.name,
    required this.filePath,
    required this.soundType,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'soundType': soundType.toString(),
    };
  }

  factory Sound.fromMap(Map<String, dynamic> map) {
    return Sound(
      id: map['id'],
      name: map['name'],
      filePath: map['filePath'],
      soundType: SoundType.values.firstWhere((e) => e.toString() == map['soundType']),
    );
  }
}