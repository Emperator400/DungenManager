// lib/models/scene.dart
import 'dart:convert';
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

/// Scene Type für die Klassifizierung von Szenen
enum SceneType {
  Introduction,
  Exploration,
  Combat,
  Social,
  Puzzle,
  Climax,
  Resolution,
}

/// Komplexitäts-Level für Szenen
enum Complexity {
  Easy,
  Medium,
  Hard,
  Legendary,
}

class Scene {
  final String id;
  final String sessionId;
  int orderIndex;
  String name; // Umbenannt von title für Konsistenz
  String description;
  SceneType sceneType;
  bool isCompleted;
  Duration? estimatedDuration;
  Complexity? complexity;
  List<String> linkedWikiEntryIds;
  List<String> linkedQuestIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Scene({
    String? id,
    required this.sessionId,
    required this.orderIndex,
    this.name = "Neue Szene",
    this.description = "",
    this.sceneType = SceneType.Exploration,
    this.isCompleted = false,
    this.estimatedDuration,
    this.complexity,
    List<String>? linkedWikiEntryIds,
    List<String>? linkedQuestIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? UuidService().generateId(),
        linkedWikiEntryIds = linkedWikiEntryIds ?? [],
        linkedQuestIds = linkedQuestIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this Scene with updated values
  Scene copyWith({
    String? id,
    String? sessionId,
    int? orderIndex,
    String? name,
    String? description,
    SceneType? sceneType,
    bool? isCompleted,
    Duration? estimatedDuration,
    Complexity? complexity,
    List<String>? linkedWikiEntryIds,
    List<String>? linkedQuestIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Scene(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      orderIndex: orderIndex ?? this.orderIndex,
      name: name ?? this.name,
      description: description ?? this.description,
      sceneType: sceneType ?? this.sceneType,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      complexity: complexity ?? this.complexity,
      linkedWikiEntryIds: linkedWikiEntryIds ?? this.linkedWikiEntryIds,
      linkedQuestIds: linkedQuestIds ?? this.linkedQuestIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'orderIndex': orderIndex,
      'name': name,
      'description': description,
      'sceneType': sceneType.name,
      'isCompleted': isCompleted ? 1 : 0,
      'estimatedDuration': estimatedDuration?.inMilliseconds,
      'complexity': complexity?.name,
      'linkedWikiEntryIds': jsonEncode(linkedWikiEntryIds),
      'linkedQuestIds': jsonEncode(linkedQuestIds),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Scene.fromMap(Map<String, dynamic> map) {
    try {
      return Scene(
        id: ModelParsingHelper.safeId(map, 'id'),
        sessionId: ModelParsingHelper.safeString(map, 'sessionId', ''),
        orderIndex: ModelParsingHelper.safeInt(map, 'orderIndex', 0),
        name: ModelParsingHelper.safeString(map, 'name', ModelParsingHelper.safeString(map, 'title', "Unbenannte Szene")),
        description: ModelParsingHelper.safeString(map, 'description', ''),
        sceneType: SceneType.values.firstWhere(
          (e) => e.name == ModelParsingHelper.safeString(map, 'sceneType', 'Exploration'),
          orElse: () => SceneType.Exploration,
        ),
        isCompleted: ModelParsingHelper.safeBool(map, 'isCompleted', false),
        estimatedDuration: ModelParsingHelper.safeIntOrNull(map, 'estimatedDuration', null) != null
            ? Duration(milliseconds: ModelParsingHelper.safeInt(map, 'estimatedDuration', 0))
            : null,
        complexity: ModelParsingHelper.safeStringOrNull(map, 'complexity', null) != null
            ? Complexity.values.firstWhere(
                (e) => e.name == ModelParsingHelper.safeString(map, 'complexity', 'Easy'),
              )
            : null,
        linkedWikiEntryIds: _parseStringList(map['linkedWikiEntryIds']),
        linkedQuestIds: _parseStringList(map['linkedQuestIds']),
        createdAt: ModelParsingHelper.safeDateTime(map, 'createdAt', DateTime.now()),
        updatedAt: ModelParsingHelper.safeDateTime(map, 'updatedAt', DateTime.now()),
      );
    } catch (e) {
      // Fallback bei Parsing-Fehlern
      return Scene(
        sessionId: ModelParsingHelper.safeString(map, 'sessionId', ''),
        orderIndex: ModelParsingHelper.safeInt(map, 'orderIndex', 0),
        name: ModelParsingHelper.safeString(map, 'name', "Fehlerhafte Szene"),
      );
    }
  }

  /// Gets the display name for the scene type
  String get sceneTypeDisplayName {
    switch (sceneType) {
      case SceneType.Introduction:
        return 'Einführung';
      case SceneType.Exploration:
        return 'Erforschung';
      case SceneType.Combat:
        return 'Kampf';
      case SceneType.Social:
        return 'Sozial';
      case SceneType.Puzzle:
        return 'Rätsel';
      case SceneType.Climax:
        return 'Höhepunkt';
      case SceneType.Resolution:
        return 'Auflösung';
    }
  }

  /// Gets the display name for complexity
  String get complexityDisplayName {
    if (complexity == null) return 'Unbekannt';
    switch (complexity!) {
      case Complexity.Easy:
        return 'Einfach';
      case Complexity.Medium:
        return 'Mittel';
      case Complexity.Hard:
        return 'Schwer';
      case Complexity.Legendary:
        return 'Legendär';
    }
  }

  /// Validates the scene model
  bool get isValid {
    return name.isNotEmpty && sessionId.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scene && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Scene(id: $id, name: $name, type: $sceneType, completed: $isCompleted)';
  }

  /// Hilfsmethode zum sicheren Parsen von String-Listen
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        // Fallback: Komma-getrennte Zeichenkette
        return data.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } catch (e) {
        // Fallback bei JSON-Fehlern: Komma-getrennte Zeichenkette
        return data.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }
    
    return [];
  }
}
