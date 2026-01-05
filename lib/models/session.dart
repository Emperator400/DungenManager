// lib/models/session.dart
import '../services/uuid_service.dart';
import '../utils/model_parsing_helper.dart';

class Session {
  final String id;
  final String campaignId;
  final String title;
  final int inGameTimeInMinutes;
  
  // HIER IST DAS FEHLENDE FELD
  final String liveNotes;

  Session({
    String? id,
    required this.campaignId,
    required this.title,
    this.inGameTimeInMinutes = 480,
    // HIER WIRD ES IM KONSTRUKTOR HINZUGEFÜGT
    this.liveNotes = "", 
  }) : id = id ?? UuidService().generateId();

  /// Konvertiert das Session zu einer Datenbank-Map (Legacy)
  Map<String, dynamic> toMap() {
    return toDatabaseMap();
  }

  /// Konvertiert das Session zu einer Datenbank-Map (Neu)
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'campaignId': campaignId,
      'title': title,
      'inGameTimeInMinutes': inGameTimeInMinutes,
      // HIER WIRD ES ZUR MAP HINZUGEFÜGT
      'liveNotes': liveNotes,
    };
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Legacy)
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map mit sicherem Parsing (Neu)
  factory Session.fromDatabaseMap(Map<String, dynamic> map) {
    return Session(
      id: ModelParsingHelper.safeId(map, 'id'),
      campaignId: ModelParsingHelper.safeString(map, 'campaignId', ''),
      title: ModelParsingHelper.safeString(map, 'title', 'Unbenannte Session'),
      inGameTimeInMinutes: ModelParsingHelper.safeInt(map, 'inGameTimeInMinutes', 480),
      // HIER WIRD ES AUS DER MAP GELESEN
      liveNotes: ModelParsingHelper.safeString(map, 'liveNotes', ''),
    );
  }
}
