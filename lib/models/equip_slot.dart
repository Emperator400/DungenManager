import 'item.dart';

enum EquipSlot {
  // Waffen
  mainHand,      // Haupthand (Schwert, Axt, etc.)
  offHand,       // Nebenhand (Schild, Dolch, Zweitwaffe)
  ranged,        // Fernkampfwaffe (Bogen, Armbrust)
  
  // Rüstung
  head,          // Helm
  chest,         // Brustpanzer/Rüstung
  hands,         // Handschuhe
  feet,          // Stiefel
  cloak,         // Umhang
  
  // Accessoires
  ring1, ring2,  // Ringe
  amulet,        // Amulett/Halskette
  belt,          // Gürtel
}

extension EquipSlotExtension on EquipSlot {
  String get displayName {
    switch (this) {
      case EquipSlot.mainHand:
        return 'Haupthand';
      case EquipSlot.offHand:
        return 'Nebenhand';
      case EquipSlot.ranged:
        return 'Fernkampf';
      case EquipSlot.head:
        return 'Kopf';
      case EquipSlot.chest:
        return 'Brust';
      case EquipSlot.hands:
        return 'Hände';
      case EquipSlot.feet:
        return 'Füße';
      case EquipSlot.cloak:
        return 'Umhang';
      case EquipSlot.ring1:
      case EquipSlot.ring2:
        return 'Ring';
      case EquipSlot.amulet:
        return 'Amulett';
      case EquipSlot.belt:
        return 'Gürtel';
    }
  }

  String get iconName {
    switch (this) {
      case EquipSlot.mainHand:
        return '⚔️';
      case EquipSlot.offHand:
        return '🛡️';
      case EquipSlot.ranged:
        return '🏹';
      case EquipSlot.head:
        return '👑';
      case EquipSlot.chest:
        return '🦺';
      case EquipSlot.hands:
        return '🧤';
      case EquipSlot.feet:
        return '👢';
      case EquipSlot.cloak:
        return '🧥';
      case EquipSlot.ring1:
      case EquipSlot.ring2:
        return '💍';
      case EquipSlot.amulet:
        return '📿';
      case EquipSlot.belt:
        return '🧵';
    }
  }

  List<ItemType> get allowedItemTypes {
    switch (this) {
      case EquipSlot.mainHand:
        return [ItemType.Weapon];
      case EquipSlot.offHand:
        return [ItemType.Weapon, ItemType.Armor]; // Schild oder Zweithand-Waffe
      case EquipSlot.ranged:
        return [ItemType.Weapon];
      case EquipSlot.head:
        return [ItemType.Armor];
      case EquipSlot.chest:
        return [ItemType.Armor];
      case EquipSlot.hands:
        return [ItemType.Armor];
      case EquipSlot.feet:
        return [ItemType.Armor];
      case EquipSlot.cloak:
        return [ItemType.Armor];
      case EquipSlot.ring1:
      case EquipSlot.ring2:
        return [ItemType.MagicItem, ItemType.Treasure];
      case EquipSlot.amulet:
        return [ItemType.MagicItem, ItemType.Treasure];
      case EquipSlot.belt:
        return [ItemType.Armor, ItemType.AdventuringGear];
    }
  }
}
