import 'package:flutter/material.dart';
import '../../models/quest.dart';
import 'enhanced_quest_card_widget.dart';
import '../../theme/dnd_theme.dart';

class QuestSearchDelegate extends SearchDelegate<Quest?> {
  final List<Quest> allQuests;
  final QuestType? selectedType;
  final QuestDifficulty? selectedDifficulty;
  final Set<String> selectedTags;
  final bool showFavoritesOnly;

  QuestSearchDelegate({
    required this.allQuests,
    this.selectedType,
    this.selectedDifficulty,
    this.selectedTags = const {},
    this.showFavoritesOnly = false,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
        tooltip: 'Suche löschen',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
      tooltip: 'Zurück',
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _performSearch();
    
    if (results.isEmpty) {
      return _buildEmptyState('Keine Quests gefunden');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final quest = results[index];
        return EnhancedQuestCardWidget(
          quest: quest,
          onTap: () {
            close(context, quest);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }

    final suggestions = _performSearch();
    
    if (suggestions.isEmpty) {
      return _buildEmptyState('Keine Vorschläge gefunden');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final quest = suggestions[index];
        return EnhancedQuestCardWidget(
          quest: quest,
          onTap: () {
            close(context, quest);
          },
        );
      },
    );
  }

  List<Quest> _performSearch() {
    if (query.isEmpty && 
        selectedType == null && 
        selectedDifficulty == null && 
        selectedTags.isEmpty && 
        !showFavoritesOnly) {
      return allQuests;
    }

    var filteredQuests = allQuests.where((quest) {
      // Suchtext filtern
      final queryLower = query.toLowerCase();
      final titleMatch = quest.title.toLowerCase().contains(queryLower);
      final descriptionMatch = quest.description.toLowerCase().contains(queryLower);
      final goalMatch = quest.description.toLowerCase().contains(queryLower);
      final tagMatch = quest.tags.any((tag) => 
          tag.toLowerCase().contains(queryLower));
      final locationMatch = quest.hasLocation && 
          quest.location!.toLowerCase().contains(queryLower);
      final npcMatch = quest.hasNpcs && 
          quest.involvedNpcs.any((npc) => npc.toLowerCase().contains(queryLower));
      final rewardMatch = quest.hasRewards && 
          quest.rewards.any((reward) => reward.name.toLowerCase().contains(queryLower));
      
      final searchMatch = query.isEmpty || 
          titleMatch || descriptionMatch || goalMatch || 
          tagMatch || locationMatch || npcMatch || rewardMatch;

      if (!searchMatch) return false;

      // Typ filtern
      if (selectedType != null && quest.questType != selectedType) {
        return false;
      }

      // Schwierigkeit filtern
      if (selectedDifficulty != null && quest.difficulty != selectedDifficulty) {
        return false;
      }

      // Tags filtern
      if (selectedTags.isNotEmpty) {
        final hasAllRequiredTags = selectedTags.every((requiredTag) => 
            quest.tags.contains(requiredTag));
        if (!hasAllRequiredTags) return false;
      }

      // Favoriten filtern
      if (showFavoritesOnly && !quest.isFavorite) {
        return false;
      }

      return true;
    }).toList();

    // Sortieren: Relevanz für Suchergebnisse, sonst alphabetisch
    if (query.isNotEmpty) {
      filteredQuests.sort((a, b) {
        final queryLower = query.toLowerCase();
        
        // Exakte Titel-Matches zuerst
        final aTitleExact = a.title.toLowerCase() == queryLower;
        final bTitleExact = b.title.toLowerCase() == queryLower;
        if (aTitleExact && !bTitleExact) return -1;
        if (!aTitleExact && bTitleExact) return 1;
        
        // Titel-Anfangs-Matches zweitens
        final aTitleStart = a.title.toLowerCase().startsWith(queryLower);
        final bTitleStart = b.title.toLowerCase().startsWith(queryLower);
        if (aTitleStart && !bTitleStart) return -1;
        if (!aTitleStart && bTitleStart) return 1;
        
        // Alphabetisch als letztes Kriterium
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    } else {
      // Alphabetisch sortieren wenn keine Suche
      filteredQuests.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    return filteredQuests;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Versuche andere Suchbegriffe oder filtere die Ergebnisse',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    // Hier könnten kürzliche Suchen gespeichert werden
    // Für jetzt zeigen wir ein paar hilfreiche Vorschläge
    
    final suggestions = _getHelpfulSuggestions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Vorschläge',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...suggestions.map((suggestion) => ListTile(
          leading: Icon(
            suggestion['icon'] as IconData,
            color: DnDTheme.mysticalPurple,
          ),
          title: Text(suggestion['title'] as String),
          subtitle: suggestion['subtitle'] != null 
              ? Text(suggestion['subtitle'] as String)
              : null,
          onTap: () {
            query = suggestion['title'] as String;
            showResults(context);
          },
        )),
      ],
    );
  }

  List<Map<String, dynamic>> _getHelpfulSuggestions() {
    final suggestions = <Map<String, dynamic>>[];
    
    // Favoriten Quests vorschlagen
    final favoriteQuests = allQuests.where((q) => q.isFavorite).take(3);
    for (final quest in favoriteQuests) {
      suggestions.add({
        'title': quest.title,
        'subtitle': '${_getQuestTypeDisplayName(quest.questType)} • ${_getQuestDifficultyDisplayName(quest.difficulty)}',
        'icon': _getQuestTypeIcon(quest.questType),
      });
    }
    
    // Hauptquests vorschlagen
    final mainQuests = allQuests
        .where((q) => q.questType == QuestType.main && !q.isFavorite)
        .take(2);
    for (final quest in mainQuests) {
      suggestions.add({
        'title': quest.title,
        'subtitle': '${_getQuestTypeDisplayName(quest.questType)} • ${_getQuestDifficultyDisplayName(quest.difficulty)}',
        'icon': _getQuestTypeIcon(quest.questType),
      });
    }
    
    // Beliebte Tags vorschlagen
    final allTags = <String>{};
    for (final quest in allQuests) {
      allTags.addAll(quest.tags);
    }
    
    final popularTags = allTags.take(3);
    for (final tag in popularTags) {
      suggestions.add({
        'title': tag,
        'subtitle': 'Tag durchsuchen',
        'icon': Icons.tag,
      });
    }
    
    return suggestions;
  }

  IconData _getQuestTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.main:
        return Icons.flag;
      case QuestType.side:
        return Icons.explore;
      case QuestType.personal:
        return Icons.person;
      case QuestType.faction:
        return Icons.group;
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: DnDTheme.stoneGrey,
        foregroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DnDTheme.slateGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }

  String _getQuestTypeDisplayName(QuestType type) {
    switch (type) {
      case QuestType.main:
        return 'Hauptquest';
      case QuestType.side:
        return 'Nebenquest';
      case QuestType.personal:
        return 'Persönlich';
      case QuestType.faction:
        return 'Fraktions-Quest';
    }
  }

  String _getQuestDifficultyDisplayName(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 'Leicht';
      case QuestDifficulty.medium:
        return 'Mittel';
      case QuestDifficulty.hard:
        return 'Schwer';
      case QuestDifficulty.deadly:
        return 'Tödlich';
      case QuestDifficulty.epic:
        return 'Episch';
      case QuestDifficulty.legendary:
        return 'Legendär';
    }
  }

  @override
  String get searchFieldLabel => 'Quests durchsuchen...';
}
