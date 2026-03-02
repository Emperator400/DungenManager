import 'inventory_item.dart';

/// Equipment-Slot-Typen für Ausrüstung
enum EquipmentSlot {
  helmet,
  armor,
  shield,
  weaponPrimary,
  weaponSecondary,
  gloves,
  boots,
  ring1,
  ring2,
  amulet,
  cloak,
}

/// Erweiterte Equipment-Klasse mit Item-Daten
class EquippedItem {
  final EquipmentSlot slot;
  final DisplayInventoryItem? item;
  
  const EquippedItem({
    required this.slot,
    this.item,
  });
  
  /// Gibt die InventoryItem-ID zurück oder null
  String? get inventoryItemId => item?.inventoryItem.id;
  
  /// Gibt den Item-Namen zurück
  String get itemName => item?.item.name ?? 'Kein Gegenstand';
  
  /// Gibt zurück ob der Slot belegt ist
  bool get isEquipped => item != null;
  
  /// Erstellt eine Kopie mit neuem Item
  EquippedItem copyWith({DisplayInventoryItem? item}) {
    return EquippedItem(
      slot: slot,
      item: item,
    );
  }
}

/// Verwaltet die gesamte Ausrüstung eines Charakters
class Equipment {
  final Map<EquipmentSlot, EquippedItem> _slots;
  
  const Equipment({
    Map<EquipmentSlot, EquippedItem>? slots,
  }) : _slots = slots ?? const {
    EquipmentSlot.helmet: EquippedItem(slot: EquipmentSlot.helmet),
    EquipmentSlot.armor: EquippedItem(slot: EquipmentSlot.armor),
    EquipmentSlot.shield: EquippedItem(slot: EquipmentSlot.shield),
    EquipmentSlot.weaponPrimary: EquippedItem(slot: EquipmentSlot.weaponPrimary),
    EquipmentSlot.weaponSecondary: EquippedItem(slot: EquipmentSlot.weaponSecondary),
    EquipmentSlot.gloves: EquippedItem(slot: EquipmentSlot.gloves),
    EquipmentSlot.boots: EquippedItem(slot: EquipmentSlot.boots),
    EquipmentSlot.ring1: EquippedItem(slot: EquipmentSlot.ring1),
    EquipmentSlot.ring2: EquippedItem(slot: EquipmentSlot.ring2),
    EquipmentSlot.amulet: EquippedItem(slot: EquipmentSlot.amulet),
    EquipmentSlot.cloak: EquippedItem(slot: EquipmentSlot.cloak),
  };

  /// Leere Ausrüstung
  factory Equipment.empty() {
    return const Equipment();
  }
  
  /// Konvertiert von Map (für Datenbank-Speicherung)
  factory Equipment.fromMap(Map<String, String> map) {
    final slots = <EquipmentSlot, EquippedItem>{};
    
    for (final slot in EquipmentSlot.values) {
      final itemId = map[slot.name];
      final item = itemId != null 
          ? EquippedItem(slot: slot, item: null) // Placeholder, wird später geladen
          : EquippedItem(slot: slot);
      
      slots[slot] = item;
    }
    
    return Equipment(slots: slots);
  }
  
  /// Gibt das Item für einen Slot zurück
  EquippedItem? getItem(EquipmentSlot slot) {
    return _slots[slot];
  }
  
  /// Rüstet ein Item in einem Slot aus
  Equipment equip(EquipmentSlot slot, DisplayInventoryItem item) {
    final newSlots = Map<EquipmentSlot, EquippedItem>.from(_slots);
    newSlots[slot] = EquippedItem(slot: slot, item: item);
    return Equipment(slots: newSlots);
  }
  
  /// Legt ein Item ab (entfernt es aus dem Slot)
  Equipment unequip(EquipmentSlot slot) {
    final newSlots = Map<EquipmentSlot, EquippedItem>.from(_slots);
    newSlots[slot] = EquippedItem(slot: slot);
    return Equipment(slots: newSlots);
  }
  
  /// Tauscht ein Item gegen ein anderes
  Equipment swap(EquipmentSlot slot, DisplayInventoryItem newItem) {
    final newSlots = Map<EquipmentSlot, EquippedItem>.from(_slots);
    newSlots[slot] = EquippedItem(slot: slot, item: newItem);
    return Equipment(slots: newSlots);
  }
  
  /// Prüft ob ein Item bereits ausgerüstet ist
  bool isItemEquipped(String inventoryItemId) {
    for (final equipped in _slots.values) {
      if (equipped.inventoryItemId == inventoryItemId) {
        return true;
      }
    }
    return false;
  }
  
  /// Findet den Slot in dem ein Item ausgerüstet ist
  EquipmentSlot? findSlotForItem(String inventoryItemId) {
    for (final entry in _slots.entries) {
      if (entry.value.inventoryItemId == inventoryItemId) {
        return entry.key;
      }
    }
    return null;
  }
  
  /// Gibt alle ausgerüsteten Items zurück
  List<EquippedItem> getEquippedItems() {
    return _slots.values.where((e) => e.isEquipped).toList();
  }
  
  /// Konvertiert zu Map (für Datenbank-Speicherung)
  Map<String, String> toMap() {
    final map = <String, String>{};
    for (final entry in _slots.entries) {
      if (entry.value.inventoryItemId != null) {
        map[entry.key.name] = entry.value.inventoryItemId!;
      }
    }
    return map;
  }
  
  /// Serialisiert als JSON-String
  String toJson() {
    final map = toMap();
    // Als einfache Map serialisieren
    return map.toString();
  }
  
  /// Prüft ob ein Item-Typ für einen Slot geeignet ist
  /// FLEXIBEL: Erlaubt alle Item-Typen in allen Slots
  /// Helden können auch "normale" Gegenstände überall tragen
  static bool canEquip(EquipmentSlot slot) {
    // Immer true zurückgeben - flexibles System
    // Helden können beliebige Gegenstände in jedem Slot tragen
    return true;
  }
  
  /// Gibt einen Anzeigename für einen Slot zurück
  static String getSlotName(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return 'Helm';
      case EquipmentSlot.armor:
        return 'Rüstung';
      case EquipmentSlot.shield:
        return 'Schild';
      case EquipmentSlot.weaponPrimary:
        return 'Hauptwaffe';
      case EquipmentSlot.weaponSecondary:
        return 'Nebenwaffe';
      case EquipmentSlot.gloves:
        return 'Handschuhe';
      case EquipmentSlot.boots:
        return 'Stiefel';
      case EquipmentSlot.ring1:
      case EquipmentSlot.ring2:
        return 'Ring';
      case EquipmentSlot.amulet:
        return 'Amulett';
      case EquipmentSlot.cloak:
        return 'Umhang';
    }
  }
  
  /// Gibt eine Beschreibung für einen Slot zurück
  static String getSlotDescription(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return 'Kopfschutz für deinen Charakter';
      case EquipmentSlot.armor:
        return 'Körperrüstung';
      case EquipmentSlot.shield:
        return 'Zusätzlichen Schutz im Kampf';
      case EquipmentSlot.weaponPrimary:
        return 'Deine Hauptwaffe für Angriffe';
      case EquipmentSlot.weaponSecondary:
        return 'Zweitwaffe für zusätzliche Optionen';
      case EquipmentSlot.gloves:
        return 'Schutz für die Hände';
      case EquipmentSlot.boots:
        return 'Schutz und Komfort für die Füße';
      case EquipmentSlot.ring1:
      case EquipmentSlot.ring2:
        return 'Magischer Ring mit Effekten';
      case EquipmentSlot.amulet:
        return 'Magisches Amulett mit Effekten';
      case EquipmentSlot.cloak:
        return 'Umhang mit Schutz- oder Bonuseffekten';
    }
  }
}
