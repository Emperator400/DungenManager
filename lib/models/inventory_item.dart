// lib/models/inventory_item.dart
import 'package:uuid/uuid.dart';
import 'item.dart'; // NEU: Importiert unser neues Item-Modell

var uuid = const Uuid();

class InventoryItem {
  final String id;
  final String ownerId;
  // GEÄNDERT: von wikiEntryId zu itemId
  final String itemId;
  final int quantity;

  InventoryItem({
    String? id,
    required this.ownerId,
    required this.itemId,
    this.quantity = 1,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'itemId': itemId,
      'quantity': quantity,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      ownerId: map['ownerId'],
      itemId: map['itemId'],
      quantity: map['quantity'] ?? 1,
    );
  }
}

// NEU: Die Helfer-Klasse für die Anzeige wird auch angepasst
class DisplayInventoryItem {
  final InventoryItem inventoryItem; // Enthält die Menge
  final Item item; // Enthält Name, Beschreibung, alle Details

  DisplayInventoryItem({required this.inventoryItem, required this.item});
}