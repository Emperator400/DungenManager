import 'dart:convert';

// Message-Typen Server → Client
const String msgFullState       = 'full_state';
const String msgHpUpdate        = 'hp_update';
const String msgConditionUpdate = 'condition_update';
const String msgInitiativeUpdate= 'initiative_update';
const String msgMapUpdate       = 'map_update';
const String msgFeedMessage     = 'feed_message';
const String msgRoomStarted     = 'room_started';
const String msgRoomEnded       = 'room_ended';
const String msgJoinConfirmed   = 'join_confirmed';
const String msgJoinError       = 'join_error';
const String msgCharVisibility  = 'char_visibility';

// Message-Typen Client → Server
const String msgJoin            = 'join';
const String msgPing            = 'ping';

class CompanionMessage {
  final String type;
  final Map<String, dynamic> data;

  const CompanionMessage({required this.type, this.data = const {}});

  factory CompanionMessage.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return CompanionMessage(
      type: map['type'] as String,
      data: (map['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  String toJson() => jsonEncode({'type': type, 'data': data});

  // ── Helpers zum Erstellen häufiger Nachrichten ────────────────────────────

  static CompanionMessage hpUpdate(String characterId, int hp) =>
      CompanionMessage(type: msgHpUpdate, data: {'characterId': characterId, 'hp': hp});

  static CompanionMessage conditionUpdate(String characterId, List<String> conditions) =>
      CompanionMessage(
          type: msgConditionUpdate,
          data: {'characterId': characterId, 'conditions': conditions});

  static CompanionMessage initiativeUpdate(String characterId, int? initiative) =>
      CompanionMessage(
          type: msgInitiativeUpdate,
          data: {'characterId': characterId, 'initiative': initiative});

  static CompanionMessage charVisibility(String characterId, bool visible) =>
      CompanionMessage(
          type: msgCharVisibility,
          data: {'characterId': characterId, 'isVisible': visible});

  static CompanionMessage feedMsg(String text, {String feedType = 'message'}) =>
      CompanionMessage(type: msgFeedMessage, data: {'text': text, 'feedType': feedType});

  static CompanionMessage roomEnded() =>
      CompanionMessage(type: msgRoomEnded);

  static CompanionMessage roomStarted() =>
      CompanionMessage(type: msgRoomStarted);
}
