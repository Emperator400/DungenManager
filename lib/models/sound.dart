// lib/models/sound.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();
enum SoundType { Ambiente, Effekt }

class Sound {
  final String id;
  final String name;
  final String filePath;
  final SoundType soundType;
  final String description; // NEUES FELD

  Sound({
    String? id,
    required this.name,
    required this.filePath,
    required this.soundType,
    this.description = '', // NEU im Konstruktor
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'soundType': soundType.toString(),
      'description': description, // NEU
    };
  }

  factory Sound.fromMap(Map<String, dynamic> map) {
    return Sound(
      id: map['id'],
      name: map['name'],
      filePath: map['filePath'],
      soundType: SoundType.values.firstWhere((e) => e.toString() == map['soundType']),
      description: map['description'] ?? '', // NEU
    );
  }
}