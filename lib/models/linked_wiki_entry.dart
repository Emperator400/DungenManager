// lib/models/linked_wiki_entry.dart
import 'wiki_entry.dart';
import 'wiki_link.dart';

/// Klasse, die einen Wiki-Link mit dem zugehörigen Ziel-Eintrag kombiniert
class LinkedWikiEntry {
  final WikiLink link;
  final WikiEntry targetEntry;

  const LinkedWikiEntry({
    required this.link,
    required this.targetEntry,
  });

  /// Erstellt LinkedWikiEntry aus Map-Daten (für Datenbank-Kompatibilität)
  factory LinkedWikiEntry.fromMap(Map<String, dynamic> map) {
    final linkData = map['link'] as Map;
    final targetData = map['targetEntry'] as Map;
    return LinkedWikiEntry(
      link: WikiLink.fromMap(Map<String, dynamic>.from(linkData)),
      targetEntry: WikiEntry.fromMap(Map<String, dynamic>.from(targetData)),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LinkedWikiEntry &&
        other.link == link &&
        other.targetEntry == targetEntry;
  }

  @override
  int get hashCode {
    return link.hashCode ^ targetEntry.hashCode;
  }

  @override
  String toString() {
    return 'LinkedWikiEntry(target: ${targetEntry.title}, type: ${link.linkType})';
  }
}
