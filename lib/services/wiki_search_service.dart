import '../models/wiki_entry.dart';
import '../database/database_helper.dart';

/// Service für erweiterte Wiki-Suche mit Highlighting
class WikiSearchService {
  static final WikiSearchService _instance = WikiSearchService._internal();
  factory WikiSearchService() => _instance;
  WikiSearchService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Führt eine Volltextsuche durch
  Future<List<WikiSearchResult>> fullTextSearch(
    String query, {
    WikiEntryType? entryType,
    String? campaignId,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final allEntries = await _dbHelper.getAllWikiEntries();
    final searchTerms = _prepareSearchTerms(query);

    List<WikiSearchResult> results = [];

    for (final entry in allEntries) {
      // Filter nach Typ und Kampagne
      if (entryType != null && entry.entryType != entryType) continue;
      if (campaignId != null && entry.campaignId != campaignId) continue;
      if (tags != null && !_entryContainsAllTags(entry, tags!)) continue;

      // Berechne Relevanz-Score
      final score = _calculateRelevanceScore(entry, searchTerms);
      
      if (score > 0) {
        final highlightedTitle = _highlightText(entry.title, searchTerms);
        final highlightedContent = _highlightText(
          entry.content, 
          searchTerms,
          maxLength: 200
        );
        final highlightedTags = entry.tags
            .where((tag) => tag.isNotEmpty)
            .map((tag) => _highlightText(tag.trim(), searchTerms))
            .toList();

        results.add(WikiSearchResult(
          entry: entry,
          score: score,
          highlightedTitle: highlightedTitle,
          highlightedContent: highlightedContent,
          highlightedTags: highlightedTags,
          matchContext: _extractMatchContext(entry.content, searchTerms),
        ));
      }
    }

    // Sortiere nach Relevanz und paginiere
    results.sort((a, b) => b.score.compareTo(a.score));
    
    final startIndex = offset.clamp(0, results.length);
    final endIndex = (startIndex + limit).clamp(0, results.length);
    
    return results.skip(startIndex).take(endIndex - startIndex).toList();
  }

  /// Bereitet Suchbegriffe für die Suche vor
  List<String> _prepareSearchTerms(String query) {
    final terms = <String>[];
    
    // Extrahiere Anführungszeichen-gruppierte Begriffe
    final quotedTerms = RegExp(r'"([^"]+)"').allMatches(query);
    for (final match in quotedTerms) {
      terms.add(match.group(1)!);
    }
    
    // Entferne Anführungszeichen-Begriffe vom Query
    var remainingQuery = query;
    for (final match in quotedTerms) {
      remainingQuery = remainingQuery.replaceFirst('"${match.group(1)}"', '');
    }
    
    // Teile verbleibenden Query in Wörter
    final remainingTerms = remainingQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .map((term) => term.toLowerCase())
        .toList();
    
    return [...terms, ...remainingTerms];
  }

  /// Berechnet den Relevanz-Score für einen Eintrag
  double _calculateRelevanceScore(WikiEntry entry, List<String> searchTerms) {
    double score = 0;
    
    for (final term in searchTerms) {
      final lowerTerm = term.toLowerCase();
      
      // Titel-Matching (höchste Gewichtung)
      if (entry.title.toLowerCase().contains(lowerTerm)) {
        score += 10.0;
        if (entry.title.toLowerCase() == lowerTerm) {
          score += 20.0; // Exakte Match
        }
      }
      
      // Content-Matching
      final contentLower = entry.content.toLowerCase();
      final contentMatches = _countOccurrences(contentLower, lowerTerm);
      score += contentMatches * 2.0;
      
      // Tag-Matching
      if (entry.tags.any((tag) => tag.toLowerCase().contains(lowerTerm))) {
        score += 5.0;
      }
      
      // Position-basierte Gewichtung
      if (contentLower.contains(lowerTerm)) {
        final firstOccurrence = contentLower.indexOf(lowerTerm);
        if (firstOccurrence < 100) {
          score += 3.0; // Frühe Vorkommen sind wichtiger
        }
      }
    }
    
    // Boost für aktualisierte Einträge
    final daysSinceUpdate = DateTime.now().difference(entry.updatedAt).inDays;
    if (daysSinceUpdate < 7) {
      score += 2.0;
    } else if (daysSinceUpdate < 30) {
      score += 1.0;
    }
    
    // Boost für Tags
    if (entry.tags.isNotEmpty) {
      score += 1.0;
    }
    
    return score;
  }

  /// Zählt Vorkommen eines Strings in einem anderen String
  int _countOccurrences(String text, String pattern) {
    int count = 0;
    int pos = 0;
    
    while ((pos = text.indexOf(pattern, pos)) != -1) {
      count++;
      pos += pattern.length;
    }
    
    return count;
  }

  /// Hebt Text mit Highlight-Markup auf
  String _highlightText(String text, List<String> searchTerms, {int? maxLength}) {
    if (text.isEmpty || searchTerms.isEmpty) return text;
    
    var highlightedText = text;
    
    // Kürze Text wenn nötig
    if (maxLength != null && highlightedText.length > maxLength!) {
      highlightedText = '${highlightedText.substring(0, maxLength!)}...';
    }
    
    // Hebe jeden Suchbegriff hervor
    for (final term in searchTerms) {
      highlightedText = highlightedText.replaceAllMapped(
        RegExp(term, caseSensitive: false),
        (match) => '<<HIGHLIGHT>>${match.group(0)}<<HIGHLIGHT>>',
      );
    }
    
    return highlightedText;
  }

  /// Extrahiert Kontext um Treffer herum
  String _extractMatchContext(String content, List<String> searchTerms, {int contextLength = 150}) {
    if (content.isEmpty || searchTerms.isEmpty) return '';
    
    final contentLower = content.toLowerCase();
    int bestPosition = -1;
    
    // Finde beste Position für Kontext
    for (final term in searchTerms) {
      final termLower = term.toLowerCase();
      final position = contentLower.indexOf(termLower);
      if (position != -1) {
        if (bestPosition == -1 || position < bestPosition) {
          bestPosition = position;
        }
      }
    }
    
    if (bestPosition == -1) return '';
    
    // Extrahiere Kontext um die beste Position
    final start = (bestPosition - contextLength ~/ 2).clamp(0, content.length);
    final end = (bestPosition + contextLength ~/ 2).clamp(0, content.length);
    
    var context = content.substring(start, end);
    if (start > 0) context = '...$context';
    if (end < content.length) context = '$context...';
    
    return _highlightText(context, searchTerms);
  }

  /// Prüft ob ein Eintrag alle Tags enthält
  bool _entryContainsAllTags(WikiEntry entry, List<String> requiredTags) {
    if (requiredTags.isEmpty) return true;
    
    final entryTags = entry.tags
        .map((tag) => tag.trim().toLowerCase())
        .toSet();
    
    return requiredTags.every((requiredTag) => 
        entryTags.any((entryTag) => entryTag.contains(requiredTag.toLowerCase())));
  }

  /// Suchvorschläge basierend auf vorhandenen Einträgen
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    
    final allEntries = await _dbHelper.getAllWikiEntries();
    final suggestions = <String>{};
    
    for (final entry in allEntries) {
      // Titel-Vorschläge
      if (entry.title.toLowerCase().startsWith(query.toLowerCase())) {
        suggestions.add(entry.title);
      }
      
      // Tag-Vorschläge
      final tags = entry.tags.where((tag) => tag.isNotEmpty);
      for (final tag in tags) {
        if (tag.toLowerCase().startsWith(query.toLowerCase())) {
          suggestions.add(tag);
        }
      }
    }
    
    return suggestions.toList()..sort();
  }

  /// Suchverlauf speichern
  Future<void> saveSearchHistory({
    required String query,
    Map<String, dynamic>? filters,
    String? campaignId,
  }) async {
    // TODO: Implementiere Suchverlauf-Speicherung
    // Könnte in einer separaten Tabelle gespeichert werden
  }

  /// Gespeicherte Suchverläufe abrufen
  Future<List<String>> getSearchHistory({String? campaignId}) async {
    // TODO: Implementiere Suchverlauf-Abruf
    return [];
  }
}

/// Suchergebnis mit erweiterten Informationen
class WikiSearchResult {
  final WikiEntry entry;
  final double score;
  final String highlightedTitle;
  final String highlightedContent;
  final List<String> highlightedTags;
  final String matchContext;

  WikiSearchResult({
    required this.entry,
    required this.score,
    required this.highlightedTitle,
    required this.highlightedContent,
    required this.highlightedTags,
    required this.matchContext,
  });

  @override
  String toString() {
    return 'WikiSearchResult(${entry.title}, score: $score)';
  }
}

/// Erweiterte Suchfilter
class WikiSearchFilters {
  final WikiEntryType? entryType;
  final String? campaignId;
  final List<String>? tags;
  final String? dateRange; // TODO: Implementiere Datumsbereich
  final bool onlyWithImages;
  final bool onlyWithChildren;

  WikiSearchFilters({
    this.entryType,
    this.campaignId,
    this.tags,
    this.dateRange,
    this.onlyWithImages = false,
    this.onlyWithChildren = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'entryType': entryType?.toString(),
      'campaignId': campaignId,
      'tags': tags,
      'dateRange': dateRange,
      'onlyWithImages': onlyWithImages,
      'onlyWithChildren': onlyWithChildren,
    };
  }

  factory WikiSearchFilters.fromMap(Map<String, dynamic> map) {
    return WikiSearchFilters(
      entryType: map['entryType'] != null 
          ? WikiEntryType.values.firstWhere((e) => e.toString() == map['entryType'] as String)
          : null,
      campaignId: map['campaignId'] as String?,
      tags: map['tags'] != null ? List<String>.from(map['tags'] as Iterable<dynamic>) : null,
      dateRange: map['dateRange'] as String?,
      onlyWithImages: map['onlyWithImages'] as bool? ?? false,
      onlyWithChildren: map['onlyWithChildren'] as bool? ?? false,
    );
  }

  bool get isActive {
    return entryType != null || 
           campaignId != null || 
           (tags != null && tags!.isNotEmpty) ||
           onlyWithImages ||
           onlyWithChildren ||
           dateRange != null;
  }

  WikiSearchFilters copyWith({
    WikiEntryType? entryType,
    String? campaignId,
    List<String>? tags,
    String? dateRange,
    bool? onlyWithImages,
    bool? onlyWithChildren,
  }) {
    return WikiSearchFilters(
      entryType: entryType ?? this.entryType,
      campaignId: campaignId ?? this.campaignId,
      tags: tags ?? this.tags,
      dateRange: dateRange ?? this.dateRange,
      onlyWithImages: onlyWithImages ?? this.onlyWithImages,
      onlyWithChildren: onlyWithChildren ?? this.onlyWithChildren,
    );
  }
}
