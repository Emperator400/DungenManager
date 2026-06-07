import '../services/uuid_service.dart';

class MapLayer {
  final String id;
  final String campaignId;
  final String? ortId; // null = Weltkarte-Layer
  final String name;
  final String? imagePath;
  final bool isVisible;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const String tableName = 'map_layers';

  const MapLayer({
    required this.id,
    required this.campaignId,
    this.ortId,
    required this.name,
    this.imagePath,
    this.isVisible = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MapLayer.create({
    required String campaignId,
    String? ortId,
    required String name,
    String? imagePath,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return MapLayer(
      id: UuidService().generateId(),
      campaignId: campaignId,
      ortId: ortId,
      name: name,
      imagePath: imagePath,
      isVisible: true,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory MapLayer.fromDatabaseMap(Map<String, dynamic> map) => MapLayer(
        id: map['id'] as String,
        campaignId: map['campaign_id'] as String,
        ortId: map['ort_id'] as String?,
        name: map['name'] as String? ?? '',
        imagePath: map['image_path'] as String?,
        isVisible: (map['is_visible'] as int? ?? 1) == 1,
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toDatabaseMap() => {
        'id': id,
        'campaign_id': campaignId,
        'ort_id': ortId,
        'name': name,
        'image_path': imagePath,
        'is_visible': isVisible ? 1 : 0,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  MapLayer copyWith({
    String? id,
    String? campaignId,
    Object? ortId = _sentinel,
    String? name,
    Object? imagePath = _sentinel,
    bool? isVisible,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MapLayer(
        id: id ?? this.id,
        campaignId: campaignId ?? this.campaignId,
        ortId: ortId == _sentinel ? this.ortId : ortId as String?,
        name: name ?? this.name,
        imagePath: imagePath == _sentinel ? this.imagePath : imagePath as String?,
        isVisible: isVisible ?? this.isVisible,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MapLayer && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
