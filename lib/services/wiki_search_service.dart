// lib/services/wiki_search_service.dart
import 'dart:async';
import '../models/wiki_entry.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import 'exceptions/service_exceptions.dart';

/// Service für erweiterte Wiki-Suche mit Highlighting
/// 
/// Bietet Volltextsuche, Relevanz-Scoring und Suchvorschläge.
/// Verwendet Repository-Architektur und spezifische Exceptions.
class WikiSearchService {
  final WikiEntryModelRepository _wikiRepository;

  WikiSearchService({
    WikiEntryModelRepository? wikiRepository,
  }) : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance);

  /// Führt eine Volltextsuche durch
  Future<ServiceResult<List<WikiSearchResult>>> fullTextSearch(
    String query, {
    WikiEntryType? entryType,
    String? campaignId,
    List<String>? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    return performServiceOperation('fullTextSearch', () async {
      if (query.trim().isEmpty) {
        throw ValidationException(
          'Suchbegriff darf nicht leer sein',
          operation: 'fullTextSearch',
        );
      }

      final allEntries = await _wikiRepository.findAll();
      final searchTerms = _prepareSearchTerms(query);

      List<WikiSearchResult> results = [];

      for (final entry in allEntries) {
        // Filter nach Typ und Kampagne
        if (entryType != null && entry.entryType != entryType) continue;
        if (campaignId != null && entry.campaignId != campaignId) continue;
        if (tags != null && !_entryContainsAllTags(entry, tags)) continue;

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
      
      final int startIndex = offset.clamp(0, results.length);
      final int endIndex = (startIndex + limit).clamp(0, results.length);
      
      return results.skip(startIndex).take(endIndex - startIndex).toList();
    });
  }

  /// Sucht mit erweiterten Filtern
  Future<List<WikiSearchResult>> searchWithFilters(
    String query,
    WikiSearchFilters filters, {
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await fullTextSearch(
      query,
      entryType: filters.entryType,
      campaignId: filters.campaignId,
      tags: filters.tags,
      limit: limit,
      offset: offset,
    );
    return result.data ?? [];
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
    
    String highlightedText = text;
    
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
    final int start = (bestPosition - contextLength ~/ 2).clamp(0, content.length);
    final int end = (bestPosition + contextLength ~/ 2).clamp(0, content.length);
    
    String context = content.substring(start, end);
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
    if (query.length < 2) {
      throw ValidationException(
        'Suchbegriff muss mindestens 2 Zeichen lang sein',
        operation: 'getSearchSuggestions',
      );
    }
    
    final allEntries = await _wikiRepository.findAll();
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

  /// Beliebte Suchbegriffe abrufen
  Future<List<String>> getPopularSearchTerms({int limit = 10}) async {
    final allEntries = await _wikiRepository.findAll();
    final termFrequency = <String, int>{};
    
    // Extrahiere Wörter aus Titeln und Tags
    for (final entry in allEntries) {
      final titleWords = entry.title
          .split(RegExp(r'\s+'))
          .where((word) => word.length > 2);
      
      for (final word in titleWords) {
        termFrequency[word.toLowerCase()] = 
            (termFrequency[word.toLowerCase()] ?? 0) + 2; // Titel-Wörter zählen doppelt
      }
      
      for (final tag in entry.tags) {
        if (tag.length > 2) {
          termFrequency[tag.toLowerCase()] = 
                (termFrequency[tag.toLowerCase()] ?? 0) + 1;
        }
      }
    }
    
    // Sortiere nach Häufigkeit
    final sortedTerms = termFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTerms
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  /// Suchverlauf speichern
  Future<void> saveSearchHistory({
    required String query,
    WikiSearchFilters? filters,
    String? campaignId,
  }) async {
    // TODO: Implementiere Suchverlauf-Speicherung in separater Tabelle
    // Könnte in einer search_history Tabelle gespeichert werden
    // Für jetzt als Platzhalter implementiert
  }

  /// Gespeicherte Suchverläufe abrufen
  Future<List<SearchHistoryEntry>> getSearchHistory({
    String? campaignId,
    int limit = 20,
  }) async {
    // TODO: Implementiere Suchverlauf-Abruf aus Datenbank
    // Für jetzt leere Liste zurückgeben
    return [];
  }

  /// Bereinigt Suchverlauf
  Future<void> clearSearchHistory({String? campaignId}) async {
    // TODO: Implementiere Suchverlauf-Bereinigung
  }

  /// Suche nach ähnlichen Einträgen
  Future<List<WikiEntry>> findSimilarEntries(
    String entryId, {
    int limit = 5,
  }) async {
    final entry = await _wikiRepository.findById(entryId);
    if (entry == null) {
      throw ResourceNotFoundException.forId(
        'WikiEntry',
        entryId,
        operation: 'findSimilarEntries',
      );
    }

    final allEntries = await _wikiRepository.findAll();
    final similarEntries = <WikiEntry, double>{};

    // Berechne Ähnlichkeit basierend auf Titeln und Tags
    for (final otherEntry in allEntries) {
      if (otherEntry.id == entryId) continue;

      double similarity = 0;

      // Titel-Ähnlichkeit
      final titleSimilarity = _calculateStringSimilarity(entry.title, otherEntry.title);
      similarity += titleSimilarity * 0.4;

      // Tag-Ähnlichkeit
      final tagSimilarity = _calculateTagSimilarity(entry.tags, otherEntry.tags);
      similarity += tagSimilarity * 0.3;

      // Content-Ähnlichkeit (vereinfacht)
      final contentSimilarity = _calculateStringSimilarity(
        entry.content.substring(0, 200), 
        otherEntry.content.substring(0, 200)
      );
      similarity += contentSimilarity * 0.3;

      if (similarity > 0.2) { // Mindest-Schwelle
        similarEntries[otherEntry] = similarity;
      }
    }

    // Sortiere nach Ähnlichkeit und begrenze Ergebnis
    final sortedSimilar = similarEntries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSimilar
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  /// Berechnet String-Ähnlichkeit (vereinfacht)
  double _calculateStringSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final s1Lower = s1.toLowerCase();
    final s2Lower = s2.toLowerCase();
    
    int matches = 0;
    int totalLength = s1Lower.length + s2Lower.length;
    
    // Einfache Wort-basierte Ähnlichkeit
    final words1 = s1Lower.split(RegExp(r'\s+'));
    final words2 = s2Lower.split(RegExp(r'\s+'));
    
    for (final word1 in words1) {
      if (words2.any((word2) => word2.contains(word1) || word1.contains(word2))) {
        matches += word1.length;
      }
    }
    
    return matches / totalLength;
  }

  /// Berechnet Tag-Ähnlichkeit
  double _calculateTagSimilarity(List<String> tags1, List<String> tags2) {
    if (tags1.isEmpty && tags2.isEmpty) return 1.0;
    if (tags1.isEmpty || tags2.isEmpty) return 0.0;

    final set1 = tags1.map((tag) => tag.toLowerCase()).toSet();
    final set2 = tags2.map((tag) => tag.toLowerCase()).toSet();
    
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    
    return union == 0 ? 0.0 : intersection / union;
  }

  // ========== STATISCHE HELPER METHODEN ==========

  /// Formatiert Suchergebnis für Anzeige
  static String formatSearchResult(WikiSearchResult result) {
    final buffer = StringBuffer();
    buffer.writeln('WikiSearchResult:');
    buffer.writeln('  Titel: ${result.highlightedTitle}');
    buffer.writeln('  Score: ${result.score.toStringAsFixed(2)}');
    buffer.writeln('  Typ: ${result.entry.entryType}');
    buffer.writeln('  Kontext: ${result.matchContext}');
    
    if (result.highlightedTags.isNotEmpty) {
      buffer.writeln('  Tags: ${result.highlightedTags.join(', ')}');
    }
    
    return buffer.toString();
  }

  /// Prüft ob Suchbegriff gültig ist
  static bool isValidSearchQuery(String query) {
    return query.trim().length >= 2 && 
           query.trim().length <= 100 &&
           !RegExp(r'[<>]').hasMatch(query);
  }

  /// Extrahiert Suchbegriffe aus Query
  static List<String> extractSearchTerms(String query) {
    final service = WikiSearchService();
    return service._prepareSearchTerms(query);
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

  Map<String, dynamic> toMap() {
    return {
      'entry': entry.toMap(),
      'score': score,
      'highlightedTitle': highlightedTitle,
      'highlightedContent': highlightedContent,
      'highlightedTags': highlightedTags,
      'matchContext': matchContext,
    };
  }

  factory WikiSearchResult.fromMap(Map<String, dynamic> map) {
    return WikiSearchResult(
      entry: WikiEntry.fromMap(map['entry'] as Map<String, dynamic>),
      score: (map['score'] as num).toDouble(),
      highlightedTitle: map['highlightedTitle'] as String,
      highlightedContent: map['highlightedContent'] as String,
      highlightedTags: List<String>.from(map['highlightedTags'] as Iterable<dynamic>),
      matchContext: map['matchContext'] as String,
    );
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

  @override
  String toString() {
    final parts = <String>[];
    if (entryType != null) parts.add('type: $entryType');
    if (campaignId != null) parts.add('campaign: $campaignId');
    if (tags != null && tags!.isNotEmpty) parts.add('tags: $tags');
    if (onlyWithImages) parts.add('images: true');
    if (onlyWithChildren) parts.add('children: true');
    if (dateRange != null) parts.add('dateRange: $dateRange');
    
    return 'WikiSearchFilters(${parts.join(', ')})';
  }
}

/// Eintrag im Suchverlauf
class SearchHistoryEntry {
  final String id;
  final String query;
  final WikiSearchFilters? filters;
  final String? campaignId;
  final DateTime createdAt;
  final int resultCount;

  SearchHistoryEntry({
    required this.id,
    required this.query,
    this.filters,
    this.campaignId,
    required this.createdAt,
    required this.resultCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'filters': filters?.toMap(),
      'campaignId': campaignId,
      'createdAt': createdAt.toIso8601String(),
      'resultCount': resultCount,
    };
  }

  factory SearchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SearchHistoryEntry(
      id: map['id'] as String,
      query: map['query'] as String,
      filters: map['filters'] != null 
          ? WikiSearchFilters.fromMap(map['filters'] as Map<String, dynamic>)
          : null,
      campaignId: map['campaignId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      resultCount: map['resultCount'] as int,
    );
  }
}
