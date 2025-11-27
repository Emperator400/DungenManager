class WikiLinkParser {
  /// Regulärer Ausdruck für Wiki-Links [[Page Name]]
  static final RegExp _wikiLinkRegex = RegExp(r'\[\[([^\[\]]+?)\]\]');
  
  /// Parst einen Text und extrahiert alle Wiki-Links
  static List<ParsedWikiLink> parseLinks(String text) {
    final matches = _wikiLinkRegex.allMatches(text);
    return matches.map((match) {
      final linkText = match.group(1)!;
      return ParsedWikiLink(
        originalText: match.group(0)!,
        linkText: linkText,
        displayName: linkText,
      );
    }).toList();
  }
  
  /// Ersetzt Wiki-Links durch klickbare Widgets (für Display)
  static String replaceWithDisplayText(String text) {
    return text.replaceAllMapped(_wikiLinkRegex, (match) {
      final linkText = match.group(1)!;
      return '🔗 $linkText';
    });
  }
  
  /// Prüft ob ein Text Wiki-Links enthält
  static bool hasWikiLinks(String text) {
    return _wikiLinkRegex.hasMatch(text);
  }
  
  /// Extrahiert nur die Link-Texte ohne Formatierung
  static List<String> extractLinkTexts(String text) {
    return parseLinks(text).map((link) => link.linkText).toList();
  }
}

/// Geparster Wiki Link
class ParsedWikiLink {
  final String originalText;  // Originaler Text mit [[...]]
  final String linkText;      // Text innerhalb der Klammern
  final String displayName;    // Angezeigter Name
  
  ParsedWikiLink({
    required this.originalText,
    required this.linkText,
    required this.displayName,
  });
  
  @override
  String toString() {
    return 'ParsedWikiLink(linkText: $linkText, display: $displayName)';
  }
}

/// Erweiterung für String mit Wiki-Link-Funktionalität
extension WikiLinkStringExtension on String {
  /// Prüft ob der String Wiki-Links enthält
  bool get hasWikiLinks => WikiLinkParser.hasWikiLinks(this);
  
  /// Extrahiert alle Wiki-Links aus dem String
  List<ParsedWikiLink> get wikiLinks => WikiLinkParser.parseLinks(this);
  
  /// Extrahiert nur die Link-Texte
  List<String> get wikiLinkTexts => WikiLinkParser.extractLinkTexts(this);
  
  /// Ersetzt Wiki-Links durch Display-Text
  String get withWikiLinkDisplay => WikiLinkParser.replaceWithDisplayText(this);
}
