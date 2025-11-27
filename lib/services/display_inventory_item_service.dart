import 'dart:convert';
import '../models/inventory_item.dart';
import '../models/item.dart';

/// Service für DisplayInventoryItem JSON-Operationen
class DisplayInventoryItemService {
  /// Konvertiert DisplayInventoryItem zu Map
  static Map<String, dynamic> toMap(DisplayInventoryItem displayItem) => {
    'inventoryItem': displayItem.inventoryItem.toMap(),
    'item': displayItem.item.toMap(),
    'currentDurability': displayItem.currentDurability,
  };

  /// Stellt DisplayInventoryItem aus Map wieder her
  static DisplayInventoryItem fromMap(Map<String, dynamic> map) => DisplayInventoryItem(
    inventoryItem: InventoryItem.fromMap(map['inventoryItem'] as Map<String, dynamic>),
    item: Item.fromMap(map['item'] as Map<String, dynamic>),
    currentDurability: map['currentDurability'] as int?,
  );

  /// Konvertiert DisplayInventoryItem zu JSON
  static String toJson(DisplayInventoryItem displayItem) => jsonEncode(toMap(displayItem));

  /// Stellt DisplayInventoryItem aus JSON wieder her
  static DisplayInventoryItem fromJson(String json) => fromMap(jsonDecode(json) as Map<String, dynamic>);
}
