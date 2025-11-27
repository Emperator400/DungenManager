// lib/models/sound.dart
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

enum SoundType { Ambiente, Effekt }

class Sound {
  final String id;
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

  Sound({
    String? id,
    required this.name,
    required this.filePath,
    required this.soundType,
    this.description = '',
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.categoryId,
    this.duration,
    this.fileSize,
    this.tags,
  }) : id = id ?? UuidService().generateId(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this Sound with updated values
  Sound copyWith({
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
  }) {
    return Sound(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      soundType: soundType ?? this.soundType,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      categoryId: categoryId ?? this.categoryId,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      tags: tags ?? this.tags,
    );
  }

  /// Converts Sound to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'sound_type': soundType.name,
      'description': description,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'category_id': categoryId,
      'duration': duration?.inMilliseconds,
      'file_size': fileSize,
      'tags': tags,
    };
  }

  /// Creates Sound from Map from database
  factory Sound.fromMap(Map<String, dynamic> map) {
    return Sound(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbekannter Sound'),
      filePath: ModelParsingHelper.safeString(map, 'file_path', ''),
      soundType: SoundType.values.firstWhere(
        (e) => e.name == ModelParsingHelper.safeString(map, 'sound_type', 'Ambiente'),
        orElse: () => SoundType.Ambiente,
      ),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      isFavorite: ModelParsingHelper.safeBool(map, 'is_favorite', false),
      createdAt: ModelParsingHelper.safeDateTime(map, 'created_at', DateTime.now()),
      updatedAt: ModelParsingHelper.safeDateTime(map, 'updated_at', DateTime.now()),
      categoryId: ModelParsingHelper.safeStringOrNull(map, 'category_id', null),
      duration: ModelParsingHelper.safeIntOrNull(map, 'duration', null) != null 
          ? Duration(milliseconds: ModelParsingHelper.safeInt(map, 'duration', 0)) 
          : null,
      fileSize: ModelParsingHelper.safeDouble(map, 'file_size', 0.0),
      tags: ModelParsingHelper.safeStringOrNull(map, 'tags', null),
    );
  }

  /// Gets the display name for the sound type
  String get soundTypeDisplayName {
    switch (soundType) {
      case SoundType.Ambiente:
        return 'Ambiente';
      case SoundType.Effekt:
        return 'Effekt';
    }
  }

  /// Gets the file extension from the file path
  String get fileExtension {
    return filePath.split('.').last.toLowerCase();
  }

  /// Checks if the file is a valid audio format
  bool get isValidAudioFormat {
    final validFormats = ['mp3', 'wav', 'ogg', 'm4a', 'flac'];
    return validFormats.contains(fileExtension);
  }

  /// Gets formatted duration as string
  String get formattedDuration {
    if (duration == null) return 'Unbekannt';
    
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Gets formatted file size as string
  String get formattedFileSize {
    if (fileSize == null) return 'Unbekannt';
    
    if (fileSize! < 1.0) {
      return '${(fileSize! * 1024).toStringAsFixed(0)} KB';
    } else {
      return '${fileSize!.toStringAsFixed(1)} MB';
    }
  }

  /// Gets list of tags from comma-separated string
  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  /// Validates the sound model
  bool get isValid {
    return name.isNotEmpty && 
           filePath.isNotEmpty && 
           isValidAudioFormat;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sound && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Sound(id: $id, name: $name, type: $soundType, filePath: $filePath)';
  }
}
