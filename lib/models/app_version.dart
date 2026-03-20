/// Modell für App-Versionen und Update-Informationen
class AppVersion {
  final String version;
  final String? buildNumber;
  final String tagName;
  final String releaseNotes;
  final String downloadUrl;
  final DateTime publishedAt;
  final bool isPrerelease;

  const AppVersion({
    required this.version,
    this.buildNumber,
    required this.tagName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.publishedAt,
    this.isPrerelease = false,
  });

  /// Parst die Version aus einem Tag-Namen (z.B. "v1.2.3" -> "1.2.3")
  static String parseVersionFromTag(String tagName) {
    return tagName.startsWith('v') ? tagName.substring(1) : tagName;
  }

  /// Vergleicht zwei Versionen im Semantic Versioning Format
  /// Returns:
  /// - negativen Wert wenn [other] neuer ist
  /// - 0 wenn gleich
  /// - positiven Wert wenn [this] neuer ist
  int compareTo(AppVersion other) {
    final thisParts = version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final otherParts = other.version.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Mit Nullen auffüllen um gleiche Länge zu haben
    while (thisParts.length < 3) thisParts.add(0);
    while (otherParts.length < 3) otherParts.add(0);

    for (int i = 0; i < 3; i++) {
      if (thisParts[i] != otherParts[i]) {
        return thisParts[i].compareTo(otherParts[i]);
      }
    }
    return 0;
  }

  /// Prüft ob diese Version älter ist als eine andere
  bool isOlderThan(AppVersion other) {
    return compareTo(other) < 0;
  }

  /// Prüft ob diese Version neuer ist als eine andere
  bool isNewerThan(AppVersion other) {
    return compareTo(other) > 0;
  }

  /// Formatierte Version für die Anzeige
  String get displayVersion => 'v$version';

  /// Formatiertes Veröffentlichungsdatum
  String get formattedDate {
    return '${publishedAt.day}.${publishedAt.month}.${publishedAt.year}';
  }

  /// Kopiert das Objekt mit optional neuen Werten
  AppVersion copyWith({
    String? version,
    String? buildNumber,
    String? tagName,
    String? releaseNotes,
    String? downloadUrl,
    DateTime? publishedAt,
    bool? isPrerelease,
  }) {
    return AppVersion(
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      tagName: tagName ?? this.tagName,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      isPrerelease: isPrerelease ?? this.isPrerelease,
    );
  }

  @override
  String toString() {
    return 'AppVersion(version: $version, tagName: $tagName, downloadUrl: $downloadUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppVersion &&
        other.version == version &&
        other.tagName == tagName;
  }

  @override
  int get hashCode => version.hashCode ^ tagName.hashCode;
}