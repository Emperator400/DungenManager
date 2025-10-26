import 'item.dart';

enum EquipSlot {
  // Waffen
  mainHand,      // Haupthand (Schwert, Axt, etc.)
  offHand,       // Nebenhand (Schild, Dolch, Zweitwaffe)
  ranged,        // Fernkampfwaffe (Bogen, Armbrust)
  
  // Spell-Slots (neu)
  spellActive,      // Aktiver Spell (wie "gezogene Waffe")
  cantripReady,     // Cantrip-Slot (immer verfügbar)
  spellPrepared1, spellPrepared2, spellPrepared3, spellPrepared4, // Vorbereitete Spells
  
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
      case EquipSlot.spellActive:
        return 'Aktiver Zauber';
      case EquipSlot.cantripReady:
        return 'Cantrip';
      case EquipSlot.spellPrepared1:
      case EquipSlot.spellPrepared2:
      case EquipSlot.spellPrepared3:
      case EquipSlot.spellPrepared4:
        return 'Vorbereiteter Zauber';
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
      case EquipSlot.spellActive:
        return '✨';
      case EquipSlot.cantripReady:
        return '🌟';
      case EquipSlot.spellPrepared1:
      case EquipSlot.spellPrepared2:
      case EquipSlot.spellPrepared3:
      case EquipSlot.spellPrepared4:
        return '📖';
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
        return [ItemType.Weapon, ItemType.Armor, ItemType.Shield]; // Schild oder Zweithand-Waffe
      case EquipSlot.ranged:
        return [ItemType.Weapon];
      case EquipSlot.spellActive:
      case EquipSlot.cantripReady:
      case EquipSlot.spellPrepared1:
      case EquipSlot.spellPrepared2:
      case EquipSlot.spellPrepared3:
      case EquipSlot.spellPrepared4:
        return [ItemType.SPELL_WEAPON];
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
