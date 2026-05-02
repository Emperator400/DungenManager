import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../theme/app_theme.dart';

/// Search Delegate für Wiki-Einträge mit Filter-Unterstützung
class WikiSearchDelegate extends SearchDelegate<WikiEntry?> {
  final List<WikiEntry> allEntries;
  final WikiEntryType? selectedType;
  final Set<String> selectedTags;

  WikiSearchDelegate({
    required this.allEntries,
    this.selectedType,
    this.selectedTags = const {},
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (selectedType != null || selectedTags.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            close(context, null);
            // Signal zum Zurücksetzen der Filter übergebnis
            showResults(context);
          },
          tooltip: 'Suche verlassen',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Zurück',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final C = context.appColors;
    final results = _getFilteredEntries();

    if (results.isEmpty) {
      return _buildNoResults(C);
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return _buildResultTile(context, entry, C);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final C = context.appColors;
    final suggestions = _getSuggestions();

    if (suggestions.isEmpty) {
      return _buildNoSuggestions(C);
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final entry = suggestions[index];
        return _buildSuggestionTile(context, entry, C);
      },
    );
  }

  List<WikiEntry> _getFilteredEntries() {
    var filtered = allEntries;

    // Text-Filter anwenden
    if (query.isNotEmpty) {
      filtered = filtered.where((entry) {
        final titleMatch = entry.title.toLowerCase().contains(query.toLowerCase());
        final contentMatch = entry.content.toLowerCase().contains(query.toLowerCase());
        final tagMatch = entry.tags.any((tag) =>
            tag.toLowerCase().contains(query.toLowerCase()));
        return titleMatch || contentMatch || tagMatch;
      }).toList();
    }

    // Typ-Filter anwenden
    if (selectedType != null) {
      filtered = filtered.where((entry) => entry.entryType == selectedType).toList();
    }

    // Tag-Filter anwenden
    if (selectedTags.isNotEmpty) {
      filtered = filtered.where((entry) {
        return selectedTags.every((selectedTag) =>
            entry.tags.contains(selectedTag));
      }).toList();
    }

    // Sortieren: Zuerst nach Typ, dann nach Titel
    filtered.sort((a, b) {
      if (a.entryType != b.entryType) {
        return a.entryType.index.compareTo(b.entryType.index);
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return filtered;
  }

  List<WikiEntry> _getSuggestions() {
    if (query.isEmpty) return [];

    final suggestions = _getFilteredEntries();

    // Nur Top 5 Vorschläge zeigen
    return suggestions.take(5).toList();
  }

  Widget _buildResultTile(BuildContext context, WikiEntry entry, AppColorsExtension C) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTypeColor(entry, C).withValues(alpha: 0.1),
        child: Icon(
          _getTypeIcon(entry),
          color: _getTypeColor(entry, C),
          size: 20,
        ),
      ),
      title: Text(
        entry.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_getTypeDisplayName(entry.entryType)),
          if (entry.hasTags) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: entry.tags.take(3).map((tag) => Chip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 10),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],
        ],
      ),
      trailing: entry.hasLocation
          ? Icon(Icons.location_on, color: C.textMid)
          : null,
      onTap: () => close(context, entry),
    );
  }

  Widget _buildSuggestionTile(BuildContext context, WikiEntry entry, AppColorsExtension C) {
    return ListTile(
      leading: Icon(
        _getTypeIcon(entry),
        color: _getTypeColor(entry, C),
        size: 20,
      ),
      title: Text(entry.title),
      subtitle: Text(_getTypeDisplayName(entry.entryType)),
      onTap: () {
        query = entry.title;
        showResults(context);
      },
    );
  }

  Widget _buildNoResults(AppColorsExtension C) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: C.textSoft,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Ergebnisse gefunden',
            style: TextStyle(
              fontSize: 18,
              color: C.textMid,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            query.isEmpty
                ? 'Versuche es mit anderen Filtern'
                : 'Versuche andere Suchbegriffe',
            style: TextStyle(
              fontSize: 14,
              color: C.textSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuggestions(AppColorsExtension C) {
    if (query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Tippe um Wiki-Einträge zu suchen...',
          style: TextStyle(color: C.textMid),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Keine Vorschläge gefunden',
        style: TextStyle(color: C.textMid),
      ),
    );
  }

  IconData _getTypeIcon(WikiEntry entry) {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.location_on;
      case WikiEntryType.Faction:
        return Icons.group;
      case WikiEntryType.Magic:
        return Icons.auto_awesome;
      case WikiEntryType.History:
        return Icons.history;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Quest:
        return Icons.task;
      case WikiEntryType.Creature:
        return Icons.pets;
      case WikiEntryType.Lore:
        return Icons.menu_book;
    }
  }

  Color _getTypeColor(WikiEntry entry, AppColorsExtension C) {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return C.accent;
      case WikiEntryType.Place:
        return C.green;
      case WikiEntryType.Faction:
        return C.amber;
      case WikiEntryType.Magic:
        return C.accent;
      case WikiEntryType.History:
        return C.accent;
      case WikiEntryType.Item:
        return C.green;
      case WikiEntryType.Quest:
        return C.red;
      case WikiEntryType.Creature:
        return C.red;
      case WikiEntryType.Lore:
        return C.accent;
    }
  }

  String _getTypeDisplayName(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return 'NPC';
      case WikiEntryType.Place:
        return 'Ort';
      case WikiEntryType.Faction:
        return 'Fraktion';
      case WikiEntryType.Magic:
        return 'Magie';
      case WikiEntryType.History:
        return 'Geschichte';
      case WikiEntryType.Item:
        return 'Gegenstand';
      case WikiEntryType.Quest:
        return 'Quest';
      case WikiEntryType.Creature:
        return 'Kreatur';
      case WikiEntryType.Lore:
        return 'Lore';
    }
  }

  @override
  void showResults(BuildContext context) {
    super.showResults(context);
  }

  @override
  void showSuggestions(BuildContext context) {
    super.showSuggestions(context);
  }
}
