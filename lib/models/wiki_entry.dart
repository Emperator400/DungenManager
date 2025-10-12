// lib/models/wiki_entry.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

enum WikiEntryType { Person, Place, Lore }

class WikiEntry {
  final String id;
  final String title;
  final String content;
  final WikiEntryType entryType;

  // Das 'isPlayerCharacter'-Feld wurde entfernt
  WikiEntry({
    String? id,
    required this.title,
    required this.content,
    required this.entryType,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'entryType': entryType.toString(),
    };
  }

  factory WikiEntry.fromMap(Map<String, dynamic> map) {
    return WikiEntry(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      entryType: WikiEntryType.values.firstWhere((e) => e.toString() == map['entryType']),
    );
  }
}