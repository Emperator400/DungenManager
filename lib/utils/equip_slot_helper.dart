import '../models/item.dart';
import '../models/equip_slot.dart';

class EquipSlotHelper {
  static String getDisplayName(EquipSlot slot) {
    switch (slot) {
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

  static String getIconName(EquipSlot slot) {
    switch (slot) {
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

  static List<ItemType> getAllowedItemTypes(EquipSlot slot) {
    switch (slot) {
      case EquipSlot.mainHand:
        return [ItemType.Weapon];
      case EquipSlot.offHand:
        return [ItemType.Weapon, ItemType.Armor, ItemType.Shield];
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
