import '../utils/model_parsing_helper.dart';

/// Typen von Quest-Belohnungen
enum QuestRewardType {
  item,
  gold,
  experience,
  wikiEntry,
  custom
}

/// Repräsentiert eine Belohnung für eine Quest
class QuestReward {
  final String id;
  final QuestRewardType type;
  final String name;
  final String? description;
  final int? quantity;
  final String? itemId;         // Verknüpfung zu Item-Modell
  final String? wikiEntryId;    // Verknüpfung zu Wiki-Eintrag
  final int? goldAmount;
  final int? experiencePoints;

  const QuestReward({
    required this.id,
    required this.type,
    required this.name,
    this.description,
    this.quantity,
    this.itemId,
    this.wikiEntryId,
    this.goldAmount,
    this.experiencePoints,
  });

  /// Konvertierung für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString(),
      'name': name,
      'description': description,
      'quantity': quantity,
      'item_id': itemId,
      'wiki_entry_id': wikiEntryId,
      'gold_amount': goldAmount,
      'experience_points': experiencePoints,
    };
  }

  /// Erstellung aus Datenbank
  factory QuestReward.fromMap(Map<String, dynamic> map) {
    return QuestReward(
      id: ModelParsingHelper.safeId(map, 'id'),
      type: QuestRewardType.values.firstWhere(
        (e) => e.toString() == 'QuestRewardType.${ModelParsingHelper.safeString(map, 'type', 'item')}',
        orElse: () => QuestRewardType.item,
      ),
      name: ModelParsingHelper.safeString(map, 'name', ''),
      description: ModelParsingHelper.safeStringOrNull(map, 'description', null),
      quantity: ModelParsingHelper.safeIntOrNull(map, 'quantity', null),
      itemId: ModelParsingHelper.safeStringOrNull(map, 'item_id', null),
      wikiEntryId: ModelParsingHelper.safeStringOrNull(map, 'wiki_entry_id', null),
      goldAmount: ModelParsingHelper.safeIntOrNull(map, 'gold_amount', null),
      experiencePoints: ModelParsingHelper.safeIntOrNull(map, 'experience_points', null),
    );
  }

  @override
  String toString() {
    return 'QuestReward(id: $id, type: $type, name: $name)';
  }
}
