import 'base_entity.dart';
import '../../models/sound.dart';

/// Sound Entity für die neue Datenbankarchitektur
/// Implementiert BaseEntity für konsistente Struktur und Typ-Sicherheit
class SoundEntity extends BaseEntity {
  // Core Felder
  String _id;
  final String name;
  final String filePath;
  final SoundType soundType;
  final String description;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final Duration? duration;
  final double? fileSize; // in MB
  final String? tags; // Comma-separated tags
  
  // Erweiterte Entity-Felder
  final String sourceType; // 'custom', 'official', 'import'
  final String? sourceId; // Referenz zur Original-Quelle
  final bool isCustom;
  final String version;
  final int priority; // Sortierung für Sound-Listen
  final bool isPublic; // Sichtbarkeit für andere Spieler
  final String? imageUrl; // Cover-Bild für den Sound
  final String? authorId; // Ersteller des Sounds

  // Sound-spezifische Felder
  final bool isLoopable; // Kann der Sound geloopt werden?
  final double? volume; // Standard-Lautstärke (0.0 - 2.0)
  final double? fadeIn; // Fade-In Dauer in Sekunden
  final double? fadeOut; // Fade-Out Dauer in Sekunden
  final int? playCount; // Anzahl der Wiedergaben
  final String? category; // 'music', 'effect', 'ambient', 'voice'

  // Audio-Technische Felder (zusätzlich zum Modell)
  final String? format; // 'mp3', 'wav', 'ogg', etc.
  final int? bitrate; // in kbps
  final int? sampleRate; // in Hz
  final int? channels; // 1 für mono, 2 für stereo

  // Konstruktor
  SoundEntity({
    required String id,
    required this.name,
    required this.filePath,
    required this.soundType,
    this.description = '',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.duration,
    this.fileSize,
    this.tags,
    this.sourceType = 'custom',
    this.sourceId,
    this.isCustom = true,
    this.version = '1.0',
    this.priority = 0,
    this.isPublic = false,
    this.imageUrl,
    this.authorId,
    this.isLoopable = false,
    this.volume,
    this.fadeIn,
    this.fadeOut,
    this.playCount = 0,
    this.category,
    this.format,
    this.bitrate,
    this.sampleRate,
    this.channels,
  }) : _id = id;

  /// Factory für Datenbank-Erstellung
  factory SoundEntity.fromMap(Map<String, dynamic> map) {
    return SoundEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      soundType: _parseSoundType(map['sound_type'] as String?),
      description: map['description'] as String? ?? '',
      isFavorite: (map['is_favorite'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      categoryId: map['category_id'] as String?,
      duration: map['duration_ms'] != null 
          ? Duration(milliseconds: map['duration_ms'] as int)
          : null,
      fileSize: (map['file_size'] as num?)?.toDouble(),
      tags: map['tags'] as String?,
      sourceType: map['source_type'] as String? ?? 'custom',
      sourceId: map['source_id'] as String?,
      isCustom: (map['is_custom'] as int?) == 1,
      version: map['version'] as String? ?? '1.0',
      priority: map['priority'] as int? ?? 0,
      isPublic: (map['is_public'] as int?) == 1,
      imageUrl: map['image_url'] as String?,
      authorId: map['author_id'] as String?,
      isLoopable: (map['is_loopable'] as int?) == 1,
      volume: (map['volume'] as num?)?.toDouble(),
      fadeIn: (map['fade_in'] as num?)?.toDouble(),
      fadeOut: (map['fade_out'] as num?)?.toDouble(),
      playCount: map['play_count'] as int? ?? 0,
      category: map['category'] as String?,
      format: map['format'] as String?,
      bitrate: map['bitrate'] as int?,
      sampleRate: map['sample_rate'] as int?,
      channels: map['channels'] as int?,
    );
  }

  /// Factory von Sound Model
  factory SoundEntity.fromModel(Sound sound, {
    String? sourceType,
    String? sourceId,
    bool? isCustom,
    String? version,
    int? priority,
    bool? isPublic,
    String? imageUrl,
    String? authorId,
    bool? isLoopable,
    double? volume,
    double? fadeIn,
    double? fadeOut,
    int? playCount,
    String? category,
    String? format,
    int? bitrate,
    int? sampleRate,
    int? channels,
  }) {
    return SoundEntity(
      id: sound.id,
      name: sound.name,
      filePath: sound.filePath,
      soundType: sound.soundType,
      description: sound.description,
      isFavorite: sound.isFavorite,
      createdAt: sound.createdAt,
      updatedAt: sound.updatedAt,
      categoryId: sound.categoryId,
      duration: sound.duration,
      fileSize: sound.fileSize,
      tags: sound.tags,
      sourceType: sourceType ?? 'custom',
      sourceId: sourceId,
      isCustom: isCustom ?? true,
      version: version ?? '1.0',
      priority: priority ?? 0,
      isPublic: isPublic ?? false,
      imageUrl: imageUrl,
      authorId: authorId,
      isLoopable: isLoopable ?? false,
      volume: volume ?? 1.0,
      fadeIn: fadeIn,
      fadeOut: fadeOut,
      playCount: playCount ?? 0,
      category: category,
      format: format,
      bitrate: bitrate,
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  /// Hilfsmethoden zum Parsen der Enums
  static SoundType _parseSoundType(String? typeString) {
    if (typeString == null) return SoundType.Ambiente;
    
    try {
      return SoundType.values.firstWhere(
        (type) => type.name == typeString,
        orElse: () => SoundType.Ambiente,
      );
    } catch (e) {
      return SoundType.Ambiente;
    }
  }

  /// ID Getter aus BaseEntity
  @override
  String get id => _id;
  
  /// ID Setter aus BaseEntity
  @override
  set id(String value) => _id = value;
  
  /// Metadata Getter aus BaseEntity
  @override
  Map<String, dynamic> get metadata => {
    'entityType': 'Sound',
    'tableName': tableName,
    'soundType': soundType.name,
    'categoryId': categoryId,
    'sourceType': sourceType,
    'priority': priority,
    'isPublic': isPublic,
    'category': category,
    'duration': duration?.inMilliseconds,
  };
  
  /// Validierung Getter aus BaseEntity
  @override
  bool get isValid {
    return name.isNotEmpty && 
           filePath.isNotEmpty &&
           (priority >= -1000 && priority <= 1000) &&
           (volume == null || (volume! >= 0.0 && volume! <= 2.0)) &&
           (playCount != null && playCount! >= 0) &&
           (duration == null || duration!.inMilliseconds >= 0);
  }
  
  /// Validation Errors Getter aus BaseEntity
  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (name.isEmpty) errors.add('Name darf nicht leer sein');
    if (filePath.isEmpty) errors.add('Dateipfad darf nicht leer sein');
    if (name.length > 100) errors.add('Name darf nicht länger als 100 Zeichen sein');
    if (priority < -1000 || priority > 1000) {
      errors.add('Priorität muss zwischen -1000 und 1000 liegen');
    }
    if (volume != null && (volume! < 0.0 || volume! > 2.0)) {
      errors.add('Volume muss zwischen 0.0 und 2.0 liegen');
    }
    if (playCount != null && playCount! < 0) {
      errors.add('Play Count muss nicht negativ sein');
    }
    if (duration != null && duration!.inMilliseconds < 0) {
      errors.add('Duration muss positiv sein');
    }
    if (fadeIn != null && fadeIn! < 0) {
      errors.add('Fade-In muss nicht negativ sein');
    }
    if (fadeOut != null && fadeOut! < 0) {
      errors.add('Fade-Out muss nicht negativ sein');
    }
    return errors;
  }

  /// Konvertierung zu Map für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'sound_type': soundType.name,
      'description': description,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'category_id': categoryId,
      'duration_ms': duration?.inMilliseconds,
      'file_size': fileSize,
      'tags': tags,
      'source_type': sourceType,
      'source_id': sourceId,
      'is_custom': isCustom ? 1 : 0,
      'version': version,
      'priority': priority,
      'is_public': isPublic ? 1 : 0,
      'image_url': imageUrl,
      'author_id': authorId,
      'is_loopable': isLoopable ? 1 : 0,
      'volume': volume,
      'fade_in': fadeIn,
      'fade_out': fadeOut,
      'play_count': playCount,
      'category': category,
      'format': format,
      'bitrate': bitrate,
      'sample_rate': sampleRate,
      'channels': channels,
    };
  }

  /// Konvertierung zurück zum Sound Model
  Sound toModel() {
    return Sound(
      id: id,
      name: name,
      filePath: filePath,
      soundType: soundType,
      description: description,
      isFavorite: isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
      categoryId: categoryId,
      duration: duration,
      fileSize: fileSize,
      tags: tags,
    );
  }

  /// Kopie mit geänderten Werten erstellen
  SoundEntity copyWith({
    String? id,
    String? name,
    String? filePath,
    SoundType? soundType,
    String? description,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryId,
    Duration? duration,
    double? fileSize,
    String? tags,
    String? sourceType,
    String? sourceId,
    bool? isCustom,
    String? version,
    int? priority,
    bool? isPublic,
    String? imageUrl,
    String? authorId,
    bool? isLoopable,
    double? volume,
    double? fadeIn,
    double? fadeOut,
    int? playCount,
    String? category,
    String? format,
    int? bitrate,
    int? sampleRate,
    int? channels,
  }) {
    return SoundEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      soundType: soundType ?? this.soundType,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      tags: tags ?? this.tags,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isCustom: isCustom ?? this.isCustom,
      version: version ?? this.version,
      priority: priority ?? this.priority,
      isPublic: isPublic ?? this.isPublic,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      isLoopable: isLoopable ?? this.isLoopable,
      volume: volume ?? this.volume,
      fadeIn: fadeIn ?? this.fadeIn,
      fadeOut: fadeOut ?? this.fadeOut,
      playCount: playCount ?? this.playCount,
      category: category ?? this.category,
      format: format ?? this.format,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
    );
  }

  /// Datenbank-Tabellenname
  static const String tableName = 'sounds';

  /// Erstelle Tabelle SQL
  static String createTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        sound_type TEXT NOT NULL,
        description TEXT,
        is_favorite INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        category_id TEXT,
        duration_ms INTEGER,
        file_size REAL,
        tags TEXT,
        source_type TEXT DEFAULT 'custom',
        source_id TEXT,
        is_custom INTEGER DEFAULT 1,
        version TEXT DEFAULT '1.0',
        priority INTEGER DEFAULT 0,
        is_public INTEGER DEFAULT 0,
        image_url TEXT,
        author_id TEXT,
        is_loopable INTEGER DEFAULT 0,
        volume REAL,
        fade_in REAL,
        fade_out REAL,
        play_count INTEGER DEFAULT 0,
        category TEXT,
        format TEXT,
        bitrate INTEGER,
        sample_rate INTEGER,
        channels INTEGER
      )
    ''';
  }

  @override
  String toString() {
    return 'SoundEntity(id: $id, name: $name, type: $soundType, duration: ${duration?.inSeconds ?? 0}s)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundEntity &&
           other.id == id &&
           other.name == name &&
           other.soundType == soundType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           name.hashCode ^
           soundType.hashCode;
  }
}
