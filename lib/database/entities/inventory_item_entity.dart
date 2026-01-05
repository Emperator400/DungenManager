import 'base_entity.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';

/// InventoryItem Entity für die neue Datenbankarchitektur
/// Implementiert BaseEntity für konsistente Struktur und Typ-Sicherheit
class InventoryItemEntity extends BaseEntity {
  // Core Felder
  String _id;
  final String characterId;
  final String itemId; // Referenz zum Item
  final String name; // Name des Items
  final String? description; // Beschreibung des Items
  final int quantity;
  final bool isEquipped;
  final EquipSlot? equipSlot;

  // Erweiterte Felder für Entity
  final int? currentDurability; // Aktuelle Haltbarkeit des Items im Inventar
  final String? customNotes; // Spieler-Notizen zum Item
  final bool isFavorite; // Ob das Item im Inventar favorisiert ist
  final DateTime? acquiredAt; // Wann das Item erworben wurde
  final String? sourceType; // Wie das Item erworben wurde (purchase, loot, craft, etc.)

  // Konstruktor
  InventoryItemEntity({
    required String id,
    required this.characterId,
    required this.itemId,
    required this.name,
    this.description,
    this.quantity = 1,
    this.isEquipped = false,
    this.equipSlot,
    this.currentDurability,
    this.customNotes,
    this.isFavorite = false,
    this.acquiredAt,
    this.sourceType,
  }) : _id = id;

  /// Factory für Datenbank-Erstellung
  factory InventoryItemEntity.fromMap(Map<String, dynamic> map) {
    return InventoryItemEntity(
      id: map['id'] as String,
      characterId: map['character_id'] as String,
      itemId: map['item_id'] as String,
      name: map['name'] as String? ?? 'Unbekanntes Item',
      description: map['description'] as String?,
      quantity: map['quantity'] as int,
      isEquipped: (map['is_equipped'] as int) ==1,
      equipSlot: map['equip_slot'] != null 
          ? EquipSlotSerialization.fromJson(map['equip_slot'].toString())
          : null,
      currentDurability: map['current_durability'] as int?,
      customNotes: map['custom_notes'] as String?,
      isFavorite: (map['is_favorite'] as int?) ==1,
      acquiredAt: map['acquired_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['acquired_at'] as int)
          : null,
      sourceType: map['source_type'] as String?,
    );
  }

  /// Factory von InventoryItem Model
  factory InventoryItemEntity.fromModel(InventoryItem inventoryItem, {
    int? currentDurability,
    String? customNotes,
    bool? isFavorite,
    DateTime? acquiredAt,
    String? sourceType,
  }) {
    return InventoryItemEntity(
      id: inventoryItem.id,
      characterId: inventoryItem.characterId,
      itemId: inventoryItem.itemId,
      name: inventoryItem.name,
      description: inventoryItem.description,
      quantity: inventoryItem.quantity,
      isEquipped: inventoryItem.isEquipped,
      equipSlot: inventoryItem.equipSlot,
      currentDurability: currentDurability,
      customNotes: customNotes,
      isFavorite: isFavorite ?? false,
      acquiredAt: acquiredAt,
      sourceType: sourceType,
    );
  }

  /// ID Getter aus BaseEntity
  @override
  String get id => _id;
  
  /// ID Setter aus BaseEntity
  @override
  set id(String value) => _id = value;
  
  /// Metadata Getter aus BaseEntity
  @override
  Map<String, dynamic> get metadata => {
    'entityType': 'InventoryItem',
    'tableName': tableName,
    'characterId': characterId,
    'itemId': itemId,
    'isEquipped': isEquipped,
    'sourceType': sourceType,
  };
  
  /// Validierung Getter aus BaseEntity
  @override
  bool get isValid {
    return characterId.isNotEmpty && 
           itemId.isNotEmpty &&
           quantity >= 0;
  }
  
  /// Validation Errors Getter aus BaseEntity
  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (characterId.isEmpty) errors.add('Character ID darf nicht leer sein');
    if (itemId.isEmpty) errors.add('Item ID darf nicht leer sein');
    if (quantity < 0) errors.add('Menge darf nicht negativ sein');
    return errors;
  }

  /// Konvertierung zu Map für Datenbank
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character_id': characterId,
      'item_id': itemId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'is_equipped': isEquipped ?1 : 0,
      'equip_slot': equipSlot?.toJson(),
      'current_durability': currentDurability,
      'custom_notes': customNotes,
      'is_favorite': isFavorite ?1 : 0,
      'acquired_at': acquiredAt?.millisecondsSinceEpoch,
      'source_type': sourceType,
    };
  }

  /// Konvertierung zurück zum InventoryItem Model
  InventoryItem toModel() {
    return InventoryItem(
      id: id,
      characterId: characterId,
      itemId: itemId,
      name: name,
      description: description,
      quantity: quantity,
      isEquipped: isEquipped,
      equipSlot: equipSlot,
    );
  }

  /// Kopie mit geänderten Werten erstellen
  InventoryItemEntity copyWith({
    String? id,
    String? characterId,
    String? itemId,
    String? name,
    String? description,
    int? quantity,
    bool? isEquipped,
    EquipSlot? equipSlot,
    int? currentDurability,
    String? customNotes,
    bool? isFavorite,
    DateTime? acquiredAt,
    String? sourceType,
  }) {
    return InventoryItemEntity(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      isEquipped: isEquipped ?? this.isEquipped,
      equipSlot: equipSlot ?? this.equipSlot,
      currentDurability: currentDurability ?? this.currentDurability,
      customNotes: customNotes ?? this.customNotes,
      isFavorite: isFavorite ?? this.isFavorite,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      sourceType: sourceType ?? this.sourceType,
    );
  }

  /// Datenbank-Tabellenname
  static const String tableName = 'inventory_items';

  /// Erstelle Tabelle SQL
  static String createTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        character_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        quantity INTEGER NOT NULL DEFAULT 1,
        is_equipped INTEGER DEFAULT 0,
        equip_slot TEXT,
        current_durability INTEGER,
        custom_notes TEXT,
        is_favorite INTEGER DEFAULT 0,
        acquired_at INTEGER,
        source_type TEXT
      )
    ''';
  }

  @override
  String toString() {
    return 'InventoryItemEntity(id: $id, characterId: $characterId, itemId: $itemId, quantity: $quantity, equipped: $isEquipped)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItemEntity &&
           other.id == id &&
           other.characterId == characterId &&
           other.itemId == itemId &&
           other.quantity == quantity;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           characterId.hashCode ^
           itemId.hashCode ^
           quantity.hashCode;
  }
}
