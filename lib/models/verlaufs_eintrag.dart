import 'dart:convert';

import '../services/uuid_service.dart';

enum VerlaufsEintragType { ort, quest, ereignis }

extension VerlaufsEintragTypeLabel on VerlaufsEintragType {
  String get label {
    switch (this) {
      case VerlaufsEintragType.ort:       return 'Ort';
      case VerlaufsEintragType.quest:     return 'Quest';
      case VerlaufsEintragType.ereignis:  return 'Ereignis';
    }
  }
}

class VerlaufsEintrag {
  final String id;
  final VerlaufsEintragType type;
  final String? refId;
  final String label;
  final String? note;
  final bool isDone;

  /// Notiz für den Übergang von diesem Schritt zum nächsten
  /// (z.B. "3-tägiger Marsch durch den Wald")
  final String? connectionNote;

  /// IDs anderer VerlaufsEinträge, auf die dieser zeigt (gerichteter Graph)
  final List<String> connections;

  const VerlaufsEintrag({
    required this.id,
    required this.type,
    this.refId,
    required this.label,
    this.note,
    this.isDone = false,
    this.connectionNote,
    this.connections = const [],
  });

  factory VerlaufsEintrag.create({
    required VerlaufsEintragType type,
    String? refId,
    required String label,
    String? note,
  }) =>
      VerlaufsEintrag(
        id: UuidService().generateId(),
        type: type,
        refId: refId,
        label: label,
        note: note,
      );

  factory VerlaufsEintrag.fromMap(Map<String, dynamic> map) => VerlaufsEintrag(
        id: map['id'] as String,
        type: VerlaufsEintragType.values.firstWhere(
          (e) => e.name == (map['type'] as String? ?? 'ereignis'),
          orElse: () => VerlaufsEintragType.ereignis,
        ),
        refId: map['refId'] as String?,
        label: map['label'] as String? ?? '',
        note: map['note'] as String?,
        isDone: (map['isDone'] as bool?) ?? false,
        connectionNote: map['connectionNote'] as String?,
        connections: (map['connections'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        if (refId != null) 'refId': refId,
        'label': label,
        if (note != null && note!.isNotEmpty) 'note': note,
        'isDone': isDone,
        if (connectionNote != null && connectionNote!.isNotEmpty) 'connectionNote': connectionNote,
        if (connections.isNotEmpty) 'connections': connections,
      };

  VerlaufsEintrag copyWith({
    String? label,
    String? note,
    bool? isDone,
    VerlaufsEintragType? type,
    Object? refId = _sentinel,
    Object? connectionNote = _sentinel,
    List<String>? connections,
  }) =>
      VerlaufsEintrag(
        id: id,
        type: type ?? this.type,
        refId: refId == _sentinel ? this.refId : refId as String?,
        label: label ?? this.label,
        note: note ?? this.note,
        isDone: isDone ?? this.isDone,
        connectionNote: connectionNote == _sentinel
            ? this.connectionNote
            : connectionNote as String?,
        connections: connections ?? List<String>.from(this.connections),
      );

  static const Object _sentinel = Object();

  // ── Serialisierung der Liste ──────────────────────────────────────────────

  static List<VerlaufsEintrag> listFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => VerlaufsEintrag.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<VerlaufsEintrag> list) =>
      jsonEncode(list.map((e) => e.toMap()).toList());
}
