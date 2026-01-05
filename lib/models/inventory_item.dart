import 'item.dart';
import 'equip_slot.dart';
import '../utils/model_parsing_helper.dart';

class InventoryItem {
  final String id;
  final String characterId; // Geändert von ownerId zu characterId
  final String itemId; // Referenz zum Item
  final String name; // Name des Items für direkten Zugriff
  final String? description; // Beschreibung des Items für direkten Zugriff
  final int quantity;
  final bool isEquipped;
  final EquipSlot? equipSlot;

  const InventoryItem({
    required this.id,
    required this.characterId, // Geändert von ownerId zu characterId
    required this.itemId,
    this.name = 'Unbekanntes Item', // Name ist jetzt optional mit Default
    this.description,
    this.quantity =1,
    this.isEquipped = false,
    this.equipSlot,
  });

  /// Konvertiert InventoryItem zu Datenbank-Map (Legacy)
  Map<String, dynamic> toMap() {
    return toDatabaseMap();
  }

  /// Konvertiert InventoryItem zu Datenbank-Map (Neu)
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'character_id': characterId, // Geändert von owner_id zu character_id
      'item_id': itemId,
      'name': name, // Name in Datenbank speichern
      'description': description, // Beschreibung in Datenbank speichern
      'quantity': quantity,
      'is_equipped': isEquipped ?1 : 0, // Boolean zu int konvertieren für SQLite
      'equip_slot': equipSlot?.toJson(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Factory für Datenbank-Map (Legacy)
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem.fromDatabaseMap(map);
  }

  /// Factory für Datenbank-Map (Neu)
  factory InventoryItem.fromDatabaseMap(Map<String, dynamic> map) {
    final equipSlot = EquipSlotSerialization.fromJson(map['equip_slot']?.toString());

    return InventoryItem(
      id: ModelParsingHelper.safeId(map, 'id'),
      characterId: ModelParsingHelper.safeString(map, 'character_id', ''), // Geändert von owner_id zu character_id
      itemId: ModelParsingHelper.safeString(map, 'item_id', ''),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbekanntes Item'), // Name aus Datenbank lesen
      description: map['description'] as String?, // Beschreibung aus Datenbank lesen
      quantity: ModelParsingHelper.safeInt(map, 'quantity',1),
      isEquipped: ModelParsingHelper.safeBool(map, 'is_equipped', false),
      equipSlot: equipSlot,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? characterId, // Geändert von ownerId zu characterId
    String? itemId,
    String? name,
    String? description,
    int? quantity,
    bool? isEquipped,
    EquipSlot? equipSlot,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId, // Geändert von ownerId zu characterId
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
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
