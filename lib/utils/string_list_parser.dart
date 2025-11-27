class StringListParser {
  /// Parst einen kommagetrennten String zu einer Liste von Strings
  static List<String> parseStringList(String? value) {
    if (value == null || value.trim().isEmpty) {
      return [];
    }
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Konvertiert eine Liste von Strings zu einem kommagetrennten String
  static String stringListToString(List<String> list) {
    if (list.isEmpty) return '';
    return list.join(',');
  }

  /// Öffentliche Methode für Tests (Legacy-Kompatibilität)
  static List<String> parseStringListForTest(String? value) {
    return parseStringList(value);
  }
}
