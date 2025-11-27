import 'dart:convert';
import '../utils/model_parsing_helper.dart';

/// Repräsentiert einen geografischen Ort auf einer Karte für zukünftige Kartenintegration
class MapLocation {
  final double latitude;
  final double longitude;
  final String mapId; // z.B. "faerun", "eberron", "custom_campaign_1"
  final int? zoomLevel;
  final String? markerType; // "city", "dungeon", "npc", "event", "place"

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.mapId,
    this.zoomLevel,
    this.markerType,
  });

  /// Konvertiert zu Map für SQLite-Datenbank-Speicherung
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'mapId': mapId,
      'zoomLevel': zoomLevel,
      'markerType': markerType,
    };
  }

  /// Erstellt MapLocation aus Map für SQLite-Datenbank
  factory MapLocation.fromMap(Map<String, dynamic> map) {
    return MapLocation(
      latitude: ModelParsingHelper.safeDouble(map, 'latitude', 0.0),
      longitude: ModelParsingHelper.safeDouble(map, 'longitude', 0.0),
      mapId: ModelParsingHelper.safeString(map, 'mapId', 'unknown'),
      zoomLevel: ModelParsingHelper.safeIntOrNull(map, 'zoomLevel', null),
      markerType: ModelParsingHelper.safeStringOrNull(map, 'markerType', null),
    );
  }

  /// Konvertiert zu JSON String für Datenbank
  String toJsonString() => jsonEncode(toMap());

  /// Erstellt aus JSON String aus Datenbank
  factory MapLocation.fromJsonString(String jsonString) {
    return MapLocation.fromMap(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Erstellt eine Kopie mit aktualisierten Werten
  MapLocation copyWith({
    double? latitude,
    double? longitude,
    String? mapId,
    int? zoomLevel,
    String? markerType,
  }) {
    return MapLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mapId: mapId ?? this.mapId,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      markerType: markerType ?? this.markerType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.mapId == mapId &&
        other.zoomLevel == zoomLevel &&
        other.markerType == markerType;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^
        longitude.hashCode ^
        mapId.hashCode ^
        zoomLevel.hashCode ^
        markerType.hashCode;
  }

  @override
  String toString() {
    return 'MapLocation(latitude: $latitude, longitude: $longitude, mapId: $mapId, zoomLevel: $zoomLevel, markerType: $markerType)';
  }
}

// Legacy Extension für Abwärtskompatibilität
extension MapLocationExtension on MapLocation {
  /// Legacy-Methode für JSON-Kompatibilität
  /// @deprecated Verwende stattdessen toMap()
  Map<String, dynamic> toJson() => toMap();

  /// Legacy-Methode für JSON-Kompatibilität  
  /// @deprecated Verwende stattdessen MapLocation.fromMap()
  MapLocation fromJson(Map<String, dynamic> json) => MapLocation.fromMap(json);
}
