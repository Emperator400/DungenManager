// lib/models/wiki_hierarchy.dart
import 'wiki_entry.dart';

/// Klasse zur Verwaltung von Wiki-Eintrags-Hierarchien
class WikiHierarchy {
  final Map<String, WikiEntry> _entries = {};
  final Map<String, List<String>> _parentChildMap = {};
  final List<WikiEntry> _roots = [];

  /// Gibt alle Root-Einträge zurück
  List<WikiEntry> get roots => List.unmodifiable(_roots);

  /// Fügt einen Root-Eintrag hinzu
  void addRoot(WikiEntry entry) {
    _entries[entry.id] = entry;
    if (!_roots.contains(entry)) {
      _roots.add(entry);
    }
  }

  /// Fügt einen Kind-Eintrag hinzu
  void addChild(String parentId, WikiEntry child) {
    _entries[child.id] = child;
    
    if (_parentChildMap.containsKey(parentId)) {
      _parentChildMap[parentId]!.add(child.id);
    } else {
      _parentChildMap[parentId] = [child.id];
    }
  }

  /// Gibt alle Kinder eines Eintrags zurück
  List<WikiEntry> getChildren(String parentId) {
    final childIds = _parentChildMap[parentId] ?? [];
    return childIds
        .map((id) => _entries[id])
        .where((entry) => entry != null)
        .cast<WikiEntry>()
        .toList();
  }

  /// Prüft, ob ein Eintrag Kinder hat
  bool hasChildren(String parentId) {
    final children = _parentChildMap[parentId];
    return children != null && children.isNotEmpty;
  }

  /// Erkennt Zyklen in der Hierarchie
  List<String> detectCycles() {
    final visited = <String>{};
    final recursionStack = <String>{};
    final cycles = <String>{};

    for (final entryId in _entries.keys) {
      if (!visited.contains(entryId)) {
        _detectCyclesUtil(
          entryId,
          visited,
          recursionStack,
          cycles,
        );
      }
    }

    return cycles.toList();
  }

  void _detectCyclesUtil(
    String entryId,
    Set<String> visited,
    Set<String> recursionStack,
    Set<String> cycles,
  ) {
    visited.add(entryId);
    recursionStack.add(entryId);

    final children = _parentChildMap[entryId] ?? [];
    for (final childId in children) {
      if (!visited.contains(childId)) {
        _detectCyclesUtil(childId, visited, recursionStack, cycles);
      } else if (recursionStack.contains(childId)) {
        // Zyklus detected
        cycles.add(entryId);
        cycles.add(childId);
      }
    }

    recursionStack.remove(entryId);
  }

  /// Gibt die flache Hierarchie zurück
  List<WikiEntry> getFlattenedHierarchy() {
    final result = <WikiEntry>[];
    final visited = <String>{};

    for (final root in _roots) {
      _flattenHierarchy(root, visited, result);
    }

    return result;
  }

  void _flattenHierarchy(
    WikiEntry entry,
    Set<String> visited,
    List<WikiEntry> result,
  ) {
    if (visited.contains(entry.id)) {
      return;
    }

    visited.add(entry.id);
    result.add(entry);

    final children = getChildren(entry.id);
    for (final child in children) {
      _flattenHierarchy(child, visited, result);
    }
  }
}
