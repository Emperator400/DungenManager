/// Einfacher Markdown-Parser für Basic Wiki Content
class MarkdownParser {
  /// Konvertiert einfachen Markdown-Text zu Flutter Widgets
  static List<String> parseToPlainText(String markdownText) {
    final lines = markdownText.split('\n');
    final parsedLines = <String>[];
    
    for (final line in lines) {
      parsedLines.add(_parseLine(line));
    }
    
    return parsedLines;
  }
  
  /// Parst eine einzelne Zeile mit Basic Markdown
  static String _parseLine(String line) {
    var parsedLine = line;
    
    // Bold (**text**)
    parsedLine = parsedLine.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => match.group(1) ?? '',
    );
    
    // Italic (*text*)
    parsedLine = parsedLine.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => match.group(1) ?? '',
    );
    
    // Headers (# Header)
    if (parsedLine.startsWith('# ')) {
      parsedLine = parsedLine.substring(2);
    } else if (parsedLine.startsWith('## ')) {
      parsedLine = parsedLine.substring(3);
    } else if (parsedLine.startsWith('### ')) {
      parsedLine = parsedLine.substring(4);
    }
    
    // Lists (- item)
    if (parsedLine.startsWith('- ')) {
      parsedLine = '• ${parsedLine.substring(2)}';
    }
    
    // Links [text](url)
    parsedLine = parsedLine.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (match) => match.group(1) ?? '',
    );
    
    return parsedLine;
  }
  
  /// Extrahiert reinen Text ohne Markdown-Syntax
  static String extractPlainText(String markdownText) {
    var plainText = markdownText;
    
    // Entferne bold markers
    plainText = plainText.replaceAll(RegExp(r'\*\*'), '');
    plainText = plainText.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => match.group(1) ?? '',
    );
    
    // Entferne italic markers
    plainText = plainText.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => match.group(1) ?? '',
    );
    
    // Entferne header markers
    plainText = plainText.replaceAll(RegExp(r'^#{1,6}\s*'), '');
    
    // Entferne list markers
    plainText = plainText.replaceAllMapped(
      RegExp(r'^\s*[-*+]\s*'),
      (match) => match.input?.substring(match.group(0)!.length) ?? '',
    );
    
    // Entferne links (behalte nur text)
    plainText = plainText.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );
    
    // Bereinige mehrfache Leerzeichen
    plainText = plainText.replaceAll(RegExp(r'\s+'), ' ');
    
    return plainText.trim();
  }
}

/// Erweiterung für String mit Markdown-Unterstützung
extension MarkdownStringExtension on String {
  /// Prüft ob der Text Markdown-Formatierung enthält
  bool get hasMarkdown {
    return contains(RegExp(r'\*\*|\*|#{1,6}|^\s*[-*+]|\[.*\]\(.*\)'));
  }
  
  /// Konvertiert zu Plain-Text
  String toPlainText() => MarkdownParser.extractPlainText(this);
}
