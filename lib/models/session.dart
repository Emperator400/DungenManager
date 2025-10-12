// lib/models/session.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

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
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaignId': campaignId,
      'title': title,
      'inGameTimeInMinutes': inGameTimeInMinutes,
      // HIER WIRD ES ZUR MAP HINZUGEFÜGT
      'liveNotes': liveNotes,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      campaignId: map['campaignId'],
      title: map['title'],
      inGameTimeInMinutes: map['inGameTimeInMinutes'] ?? 480,
      // HIER WIRD ES AUS DER MAP GELESEN
      liveNotes: map['liveNotes'] ?? "",
    );
  }
}