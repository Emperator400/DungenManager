// Dart Core
import 'dart:convert';

// Eigene Projekte
import '../models/quest.dart';
import '../models/quest_reward.dart' as qr;
import '../utils/string_list_parser.dart';

/// Service für die Datenverarbeitung von Quest-Objekten
class QuestDataService {
  /// Parst Quest-Typ sicher aus verschiedenen Datenformaten
  static QuestType parseQuestType(dynamic value) {
    if (value == null) return QuestType.side;
    
    if (value is QuestType) return value;
    if (value is String) {
      return QuestType.values.firstWhere(
        (e) => e.toString() == value,
        orElse: () => QuestType.side,
      );
    }
    return QuestType.side;
  }

  /// Parst Quest-Schwierigkeit sicher aus verschiedenen Datenformaten
  static QuestDifficulty parseDifficulty(dynamic value) {
    if (value == null) return QuestDifficulty.medium;
    
    if (value is QuestDifficulty) return value;
    if (value is String) {
      return QuestDifficulty.values.firstWhere(
        (e) => e.toString() == value,
        orElse: () => QuestDifficulty.medium,
      );
    }
    return QuestDifficulty.medium;
  }

  /// Parst Quest-Belohnungen sicher aus verschiedenen Datenformaten
  static List<qr.QuestReward> parseRewards(dynamic rewardsData) {
    if (rewardsData == null) return <qr.QuestReward>[];
    
    try {
      if (rewardsData is String) {
        // Neues Format: JSON-String
        if (rewardsData.isEmpty) return <qr.QuestReward>[];
        
        final decoded = jsonDecode(rewardsData);
        if (decoded is List) {
          return decoded
              .where((rewardMap) => rewardMap != null && rewardMap is Map<String, dynamic>)
              .map((rewardMap) => qr.QuestReward.fromMap(rewardMap as Map<String, dynamic>))
              .where((reward) => reward != null)
              .cast<qr.QuestReward>()
              .toList();
        }
      } else if (rewardsData is List) {
        // Altes Format: direkte Liste
        return rewardsData
            .where((rewardMap) => rewardMap != null && rewardMap is Map<String, dynamic>)
            .map((rewardMap) => qr.QuestReward.fromMap(rewardMap as Map<String, dynamic>))
            .where((reward) => reward != null)
            .cast<qr.QuestReward>()
            .toList();
      }
    } catch (e) {
      print('Fehler bei der Verarbeitung der Quest-Belohnungen: $e');
      
      // Fallback: Altes String-basiertes Format
      if (rewardsData is String) {
        final oldRewards = rewardsData.split(',');
        final List<qr.QuestReward> result = [];
        for (final String reward in oldRewards) {
          if (reward.isNotEmpty) {
            final String trimmedReward = reward.trim();
            result.add(qr.QuestReward(
              id: trimmedReward,
              type: qr.QuestRewardType.custom,
              name: trimmedReward,
            ));
          }
        }
        return result;
      }
    }
    
    return <qr.QuestReward>[];
  }

  /// Serialisiert Quest-Belohnungen für Datenbank-Speicherung
  static String serializeRewards(List<qr.QuestReward> rewards) {
    if (rewards.isEmpty) return '';
    
    try {
      return jsonEncode(rewards.map((reward) => reward.toMap()).toList());
    } catch (e) {
      print('Fehler bei der Serialisierung der Quest-Belohnungen: $e');
      return '';
    }
  }

  /// Parst String-Listen sicher aus verschiedenen Datenformaten
  static List<String> parseStringList(dynamic value) => 
      StringListParser.parseStringList(value is String ? value : null);

  /// Serialisiert String-Listen für Datenbank-Speicherung
  static String serializeStringList(List<String> list) => list.join(',');

  /// Sichere Konvertierung von dynamischen Werten mit Standardwerten
  static int safeInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int safeIntOrNull(dynamic value, int? defaultValue) {
    final int fallback = defaultValue ?? 0;
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static String safeStringOrNull(dynamic value, String? defaultValue) {
    if (value == null) {
      return defaultValue ?? '';
    }
    final converted = value.toString();
    if (converted.isEmpty) {
      return defaultValue ?? '';
    }
    return converted;
  }

  static bool safeBool(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return defaultValue;
  }
}
