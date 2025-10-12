// lib/models/scene.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class Scene {
  final String id;
  final String sessionId;
  int orderIndex;
  String title;
  String description;
  List<String> linkedWikiEntryIds;
  List<String> linkedQuestIds;

  Scene({
    String? id,
    required this.sessionId,
    required this.orderIndex,
    this.title = "Neue Szene",
    this.description = "",
    List<String>? linkedWikiEntryIds,
    List<String>? linkedQuestIds,
  })  : id = id ?? uuid.v4(),
        linkedWikiEntryIds = linkedWikiEntryIds ?? [],
        linkedQuestIds = linkedQuestIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'orderIndex': orderIndex,
      'title': title,
      'description': description,
      'linkedWikiEntryIds': jsonEncode(linkedWikiEntryIds),
      'linkedQuestIds': jsonEncode(linkedQuestIds),
    };
  }

  factory Scene.fromMap(Map<String, dynamic> map) {
    return Scene(
      id: map['id'],
      sessionId: map['sessionId'],
      orderIndex: map['orderIndex'],
      title: map['title'],
      description: map['description'],
      linkedWikiEntryIds: List<String>.from(jsonDecode(map['linkedWikiEntryIds'])),
      linkedQuestIds: List<String>.from(jsonDecode(map['linkedQuestIds'])),
    );
  }
}