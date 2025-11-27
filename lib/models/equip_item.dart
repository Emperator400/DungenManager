import 'equip_slot.dart';
import '../utils/model_parsing_helper.dart';

class EquippedItem {
  final String id;
  final String ownerId; // creature_id oder player_character_id
  final String itemId; // Referenz zum Item
  final EquipSlot equipSlot;
  final DateTime equippedAt;
  final int? currentDurability; // Aktuelle Haltbarkeit wenn das Item Haltbarkeit hat

  const EquippedItem({
    required this.id,
    required this.ownerId,
    required this.itemId,
    required this.equipSlot,
    required this.equippedAt,
    this.currentDurability,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'item_id': itemId,
      'equip_slot': equipSlot.toString(),
      'equipped_at': equippedAt.toIso8601String(),
      'current_durability': currentDurability,
    };
  }

  factory EquippedItem.fromMap(Map<String, dynamic> map) {
    return EquippedItem(
      id: ModelParsingHelper.safeId(map, 'id'),
      ownerId: ModelParsingHelper.safeString(map, 'owner_id', ''),
      itemId: ModelParsingHelper.safeString(map, 'item_id', ''),
      equipSlot: EquipSlot.values.firstWhere(
        (e) => e.toString() == ModelParsingHelper.safeString(map, 'equip_slot', ''),
        orElse: () => EquipSlot.head, // Fallback
      ),
      equippedAt: DateTime.tryParse(ModelParsingHelper.safeString(map, 'equipped_at', '')) ?? DateTime.now(),
      currentDurability: ModelParsingHelper.safeIntOrNull(map, 'current_durability', null),
    );
  }

  EquippedItem copyWith({
    String? id,
    String? ownerId,
    String? itemId,
    EquipSlot? equipSlot,
    DateTime? equippedAt,
    int? currentDurability,
  }) {
    return EquippedItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      itemId: itemId ?? this.itemId,
      equipSlot: equipSlot ?? this.equipSlot,
      equippedAt: equippedAt ?? this.equippedAt,
      currentDurability: currentDurability ?? this.currentDurability,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquippedItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EquippedItem(id: $id, itemId: $itemId, slot: $equipSlot)';
}

class EquipBonus {
  final String description;
  final int? strengthBonus;
  final int? dexterityBonus;
  final int? constitutionBonus;
  final int? intelligenceBonus;
  final int? wisdomBonus;
  final int? charismaBonus;
  final int? armorClassBonus;
  final int? attackBonus;
  final int? damageBonus;
  final int? savingThrowBonus;

  const EquipBonus({
    required this.description,
    this.strengthBonus,
    this.dexterityBonus,
    this.constitutionBonus,
    this.intelligenceBonus,
    this.wisdomBonus,
    this.charismaBonus,
    this.armorClassBonus,
    this.attackBonus,
    this.damageBonus,
    this.savingThrowBonus,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'strength_bonus': strengthBonus,
      'dexterity_bonus': dexterityBonus,
      'constitution_bonus': constitutionBonus,
      'intelligence_bonus': intelligenceBonus,
      'wisdom_bonus': wisdomBonus,
      'charisma_bonus': charismaBonus,
      'armor_class_bonus': armorClassBonus,
      'attack_bonus': attackBonus,
      'damage_bonus': damageBonus,
      'saving_throw_bonus': savingThrowBonus,
    };
  }

  factory EquipBonus.fromMap(Map<String, dynamic> map) {
    return EquipBonus(
      description: ModelParsingHelper.safeString(map, 'description', ''),
      strengthBonus: ModelParsingHelper.safeIntOrNull(map, 'strength_bonus', null),
      dexterityBonus: ModelParsingHelper.safeIntOrNull(map, 'dexterity_bonus', null),
      constitutionBonus: ModelParsingHelper.safeIntOrNull(map, 'constitution_bonus', null),
      intelligenceBonus: ModelParsingHelper.safeIntOrNull(map, 'intelligence_bonus', null),
      wisdomBonus: ModelParsingHelper.safeIntOrNull(map, 'wisdom_bonus', null),
      charismaBonus: ModelParsingHelper.safeIntOrNull(map, 'charisma_bonus', null),
      armorClassBonus: ModelParsingHelper.safeIntOrNull(map, 'armor_class_bonus', null),
      attackBonus: ModelParsingHelper.safeIntOrNull(map, 'attack_bonus', null),
      damageBonus: ModelParsingHelper.safeIntOrNull(map, 'damage_bonus', null),
      savingThrowBonus: ModelParsingHelper.safeIntOrNull(map, 'saving_throw_bonus', null),
    );
  }

  EquipBonus copyWith({
    String? description,
    int? strengthBonus,
    int? dexterityBonus,
    int? constitutionBonus,
    int? intelligenceBonus,
    int? wisdomBonus,
    int? charismaBonus,
    int? armorClassBonus,
    int? attackBonus,
    int? damageBonus,
    int? savingThrowBonus,
  }) {
    return EquipBonus(
      description: description ?? this.description,
      strengthBonus: strengthBonus ?? this.strengthBonus,
      dexterityBonus: dexterityBonus ?? this.dexterityBonus,
      constitutionBonus: constitutionBonus ?? this.constitutionBonus,
      intelligenceBonus: intelligenceBonus ?? this.intelligenceBonus,
      wisdomBonus: wisdomBonus ?? this.wisdomBonus,
      charismaBonus: charismaBonus ?? this.charismaBonus,
      armorClassBonus: armorClassBonus ?? this.armorClassBonus,
      attackBonus: attackBonus ?? this.attackBonus,
      damageBonus: damageBonus ?? this.damageBonus,
      savingThrowBonus: savingThrowBonus ?? this.savingThrowBonus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquipBonus && other.description == description;
  }

  @override
  int get hashCode => description.hashCode;

  @override
  String toString() => 'EquipBonus(description: $description)';
}
