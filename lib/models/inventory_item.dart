import 'item.dart';
import 'equip_slot.dart';
import '../utils/model_parsing_helper.dart';

class InventoryItem {
  final String id;
  final String ownerId;
  final String itemId; // Referenz zum Item
  final int quantity;
  final bool isEquipped;
  final EquipSlot? equipSlot;

  const InventoryItem({
    required this.id,
    required this.ownerId,
    required this.itemId,
    this.quantity = 1,
    this.isEquipped = false,
    this.equipSlot,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'item_id': itemId,
      'quantity': quantity,
      'is_equipped': isEquipped,
      'equip_slot': equipSlot?.toJson(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    final equipSlot = EquipSlotSerialization.fromJson(map['equip_slot']?.toString());

    return InventoryItem(
      id: ModelParsingHelper.safeId(map, 'id'),
      ownerId: ModelParsingHelper.safeString(map, 'owner_id', ''),
      itemId: ModelParsingHelper.safeString(map, 'item_id', ''),
      quantity: ModelParsingHelper.safeInt(map, 'quantity', 1),
      isEquipped: ModelParsingHelper.safeBool(map, 'is_equipped', false),
      equipSlot: equipSlot,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? ownerId,
    String? itemId,
    int? quantity,
    bool? isEquipped,
    EquipSlot? equipSlot,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      isEquipped: isEquipped ?? this.isEquipped,
      equipSlot: equipSlot ?? this.equipSlot,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InventoryItem(id: $id, itemId: $itemId, quantity: $quantity)';
}

class DisplayInventoryItem {
  final InventoryItem inventoryItem;
  final Item item;
  final int? currentDurability;

  const DisplayInventoryItem({
    required this.inventoryItem, 
    required this.item, 
    this.currentDurability,
  });

  Map<String, dynamic> toMap() {
    return {
      'inventoryItem': inventoryItem.toMap(),
      'item': item.toMap(),
      'currentDurability': currentDurability,
    };
  }

  factory DisplayInventoryItem.fromMap(Map<String, dynamic> map) {
    return DisplayInventoryItem(
      inventoryItem: InventoryItem.fromMap(map['inventoryItem'] as Map<String, dynamic>),
      item: Item.fromMap(map['item'] as Map<String, dynamic>),
      currentDurability: map['currentDurability'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DisplayInventoryItem && other.inventoryItem.id == inventoryItem.id;
  }

  @override
  int get hashCode => inventoryItem.id.hashCode;

  @override
  String toString() => 'DisplayInventoryItem(itemId: ${item.id}, quantity: ${inventoryItem.quantity})';
}
