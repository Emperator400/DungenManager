// lib/models/inventory_item.dart
import 'package:uuid/uuid.dart';
import 'item.dart'; // NEU: Importiert unser neues Item-Modell
import 'equip_slot.dart'; // NEU: Import für Ausrüstungs-Slots

var uuid = const Uuid();

class InventoryItem {
  final String id;
  final String ownerId;
  // GEÄNDERT: von wikiEntryId zu itemId
  final String itemId;
  final int quantity;
  
  // NEU: Ausrüstungs-Felder
  final bool isEquipped;
  final EquipSlot? equipSlot;

  InventoryItem({
    String? id,
    required this.ownerId,
    required this.itemId,
    this.quantity = 1,
    this.isEquipped = false,
    this.equipSlot,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'itemId': itemId,
      'quantity': quantity,
      'isEquipped': isEquipped ? 1 : 0,
      'equipSlot': equipSlot?.toString(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    EquipSlot? equipSlot;
    if (map['equipSlot'] != null) {
      equipSlot = EquipSlot.values.firstWhere(
        (slot) => slot.toString() == map['equipSlot'],
        orElse: () => throw ArgumentError('Invalid EquipSlot: ${map['equipSlot']}'),
      );
    }

    return InventoryItem(
      id: map['id'],
      ownerId: map['ownerId'],
      itemId: map['itemId'],
      quantity: map['quantity'] ?? 1,
      isEquipped: map['isEquipped'] == 1,
      equipSlot: equipSlot,
    );
  }
}

// NEU: Die Helfer-Klasse für die Anzeige wird auch angepasst
class DisplayInventoryItem {
  final InventoryItem inventoryItem; // Enthält die Menge und Ausrüstungs-Status
  final Item item; // Enthält Name, Beschreibung, alle Details
  final int? currentDurability; // Aktuelle Haltbarkeit (nur wenn hasDurability = true)

  DisplayInventoryItem({
    required this.inventoryItem, 
    required this.item, 
    this.currentDurability,
  });
}
