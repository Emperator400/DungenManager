// lib/models/campaign.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class Campaign {
  final String id;
  final String title;
  final String description;
  final List<String> availableMonsters; // IDs der verfügbaren Monster
  final List<String> availableSpells;   // IDs der verfügbaren Zauber
  final List<String> availableItems;    // IDs der verfügbaren Gegenstände
  final List<String> availableNpcs;      // IDs der verfügbaren NPCs

  Campaign({
    String? id,
    required this.title,
    required this.description,
    this.availableMonsters = const [],
    this.availableSpells = const [],
    this.availableItems = const [],
    this.availableNpcs = const [],
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'available_monsters': availableMonsters.isNotEmpty ? availableMonsters.join(',') : null,
      'available_spells': availableSpells.isNotEmpty ? availableSpells.join(',') : null,
      'available_items': availableItems.isNotEmpty ? availableItems.join(',') : null,
      'available_npcs': availableNpcs.isNotEmpty ? availableNpcs.join(',') : null,
    };
  }

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      availableMonsters: _parseStringList(map['available_monsters']),
      availableSpells: _parseStringList(map['available_spells']),
      availableItems: _parseStringList(map['available_items']),
      availableNpcs: _parseStringList(map['available_npcs']),
    );
  }

  static List<String> _parseStringList(String? value) {
    if (value == null || value.trim().isEmpty) {
      return [];
    }
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  // Öffentliche Methode für Tests
  static List<String> parseStringListForTest(String? value) {
    return _parseStringList(value);
  }


  // Methode zum Hinzufügen von offiziellen Daten zur Kampagne
  Campaign copyWith({
    String? title,
    String? description,
    List<String>? availableMonsters,
    List<String>? availableSpells,
    List<String>? availableItems,
    List<String>? availableNpcs,
  }) {
    return Campaign(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      availableMonsters: availableMonsters ?? this.availableMonsters,
      availableSpells: availableSpells ?? this.availableSpells,
      availableItems: availableItems ?? this.availableItems,
      availableNpcs: availableNpcs ?? this.availableNpcs,
    );
  }
}
