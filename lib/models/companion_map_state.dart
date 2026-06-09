class MapLayerEntry {
  final String id;
  final String name;
  final String? imagePath;
  final bool isVisible;

  const MapLayerEntry({
    required this.id,
    required this.name,
    this.imagePath,
    required this.isVisible,
  });
}

class MapToken {
  final String id;
  final double x; // normalized 0.0–1.0 fraction of image width
  final double y; // normalized 0.0–1.0 fraction of image height
  final String label;
  final String color; // Hex
  final double size;     // grid-cell radius multiplier, default 1.0
  final String? imageUrl; // relative server URL e.g. /img/<ort_id>, null = no image

  const MapToken({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
    required this.color,
    this.size = 1.0,
    this.imageUrl,
  });

  factory MapToken.fromMap(Map<String, dynamic> map) => MapToken(
        id: map['id'] as String? ?? '',
        x: (map['x'] as num?)?.toDouble() ?? 0.0,
        y: (map['y'] as num?)?.toDouble() ?? 0.0,
        label: map['label'] as String? ?? '',
        color: map['color'] as String? ?? '#7c3aed',
        size: (map['size'] as num?)?.toDouble() ?? 1.0,
        imageUrl: map['imageUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'x': x,
        'y': y,
        'label': label,
        'color': color,
        'size': size,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  MapToken copyWith({double? x, double? y, String? label, String? color, double? size, String? imageUrl}) => MapToken(
        id: id,
        x: x ?? this.x,
        y: y ?? this.y,
        label: label ?? this.label,
        color: color ?? this.color,
        size: size ?? this.size,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

class CompanionMapState {
  final String? imageStoragePath;
  final bool fogOfWar;
  final List<int> revealedCells; // Grid-Indizes
  final List<MapToken> tokens;
  final int gridColumns;
  final int gridRows;

  const CompanionMapState({
    this.imageStoragePath,
    this.fogOfWar = true,
    this.revealedCells = const [],
    this.tokens = const [],
    this.gridColumns = 20,
    this.gridRows = 20,
  });

  factory CompanionMapState.fromMap(Map<String, dynamic> map) => CompanionMapState(
        imageStoragePath: map['imageStoragePath'] as String?,
        fogOfWar: map['fogOfWar'] as bool? ?? true,
        revealedCells: List<int>.from(map['revealedCells'] as List? ?? []),
        tokens: (map['tokens'] as List? ?? [])
            .map((t) => MapToken.fromMap(t as Map<String, dynamic>))
            .toList(),
        gridColumns: map['gridColumns'] as int? ?? 20,
        gridRows: map['gridRows'] as int? ?? 20,
      );

  Map<String, dynamic> toMap() => {
        'imageStoragePath': imageStoragePath,
        'fogOfWar': fogOfWar,
        'revealedCells': revealedCells,
        'tokens': tokens.map((t) => t.toMap()).toList(),
        'gridColumns': gridColumns,
        'gridRows': gridRows,
      };

  CompanionMapState copyWith({
    String? imageStoragePath,
    bool? fogOfWar,
    List<int>? revealedCells,
    List<MapToken>? tokens,
    int? gridColumns,
    int? gridRows,
  }) =>
      CompanionMapState(
        imageStoragePath: imageStoragePath ?? this.imageStoragePath,
        fogOfWar: fogOfWar ?? this.fogOfWar,
        revealedCells: revealedCells ?? this.revealedCells,
        tokens: tokens ?? this.tokens,
        gridColumns: gridColumns ?? this.gridColumns,
        gridRows: gridRows ?? this.gridRows,
      );

  int get totalCells => gridColumns * gridRows;
  bool isCellRevealed(int index) => !fogOfWar || revealedCells.contains(index);
}
