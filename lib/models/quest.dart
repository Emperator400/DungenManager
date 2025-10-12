// lib/models/quest.dart

import 'package:uuid/uuid.dart';

var uuid = const Uuid();

// Dies repräsentiert eine Quest-Schablone in unserer globalen Bibliothek
class Quest {
  final String id;
  final String title;
  final String description; // Die Grundidee oder der "Hook"
  final String goal; // Was ist das Ziel der Quest?

  Quest({
    String? id,
    required this.title,
    required this.description,
    required this.goal,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'goal': goal,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      goal: map['goal'],
    );
  }
}

// Dieses Enum repräsentiert den Status einer Quest *innerhalb* einer Kampagne
enum QuestStatus {
  verfuegbar, // Available
  aktiv,      // Active
  abgeschlossen,// Completed
  gescheitert,  // Failed
}

class CampaignQuest {
  final Quest quest;
  final QuestStatus status;
  final String? notes;

  CampaignQuest({
    required this.quest,
    required this.status,
    this.notes,
  });
}