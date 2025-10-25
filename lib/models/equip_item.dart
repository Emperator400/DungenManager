// lib/models/equip_item.dart
import 'equip_slot.dart';
import 'item.dart';

class EquippedItem {
  final String id;
  final String ownerId; // creature_id oder player_character_id
  final String itemId; // Referenz zum Item
  final EquipSlot equipSlot;
  final DateTime equippedAt;
  final int? currentDurability; // Aktuelle Haltbarkeit wenn das Item Haltbarkeit hat

  EquippedItem({
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
      id: map['id'],
      ownerId: map['owner_id'],
      itemId: map['item_id'],
      equipSlot: EquipSlot.values.firstWhere((e) => e.toString() == map['equip_slot']),
      equippedAt: DateTime.parse(map['equipped_at']),
      currentDurability: map['current_durability'],
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

  EquipBonus({
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

  Map<String, int?> toMap() {
    return {
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

  String getBonusSummary() {
    final bonuses = <String>[];
    
    if (strengthBonus != null && strengthBonus! != 0) bonuses.add('ST ${strengthBonus! > 0 ? "+$strengthBonus" : strengthBonus}');
    if (dexterityBonus != null && dexterityBonus! != 0) bonuses.add('GE ${dexterityBonus! > 0 ? "+$dexterityBonus" : dexterityBonus}');
    if (constitutionBonus != null && constitutionBonus! != 0) bonuses.add('KO ${constitutionBonus! > 0 ? "+$constitutionBonus" : constitutionBonus}');
    if (intelligenceBonus != null && intelligenceBonus! != 0) bonuses.add('IN ${intelligenceBonus! > 0 ? "+$intelligenceBonus" : intelligenceBonus}');
    if (wisdomBonus != null && wisdomBonus! != 0) bonuses.add('WE ${wisdomBonus! > 0 ? "+$wisdomBonus" : wisdomBonus}');
    if (charismaBonus != null && charismaBonus! != 0) bonuses.add('CH ${charismaBonus! > 0 ? "+$charismaBonus" : charismaBonus}');
    if (armorClassBonus != null && armorClassBonus! != 0) bonuses.add('RK ${armorClassBonus! > 0 ? "+$armorClassBonus" : armorClassBonus}');
    if (attackBonus != null && attackBonus! != 0) bonuses.add('Angriff ${attackBonus! > 0 ? "+$attackBonus" : attackBonus}');
    if (damageBonus != null && damageBonus! != 0) bonuses.add('Schaden ${damageBonus! > 0 ? "+$damageBonus" : damageBonus}');
    if (savingThrowBonus != null && savingThrowBonus! != 0) bonuses.add('Rettungswürfe ${savingThrowBonus! > 0 ? "+$savingThrowBonus" : savingThrowBonus}');
    
    return bonuses.isNotEmpty ? bonuses.join(', ') : 'Keine Boni';
  }
}
