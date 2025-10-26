import 'package:flutter/material.dart';
import '../../models/item.dart';

class ItemColorHelper {
  // Dunkle Farben für Item-Typen
  static Color getItemTypeColor(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Colors.red.shade800;
      case ItemType.Armor:
        return Colors.blue.shade800;
      case ItemType.Shield:
        return Colors.cyan.shade800;
      case ItemType.AdventuringGear:
        return Colors.green.shade800;
      case ItemType.Treasure:
        return Colors.amber.shade800;
      case ItemType.MagicItem:
        return Colors.purple.shade800;
      case ItemType.SPELL_WEAPON:
        return Colors.deepPurple.shade800;
      case ItemType.Consumable:
        return Colors.orange.shade800;
      case ItemType.Tool:
        return Colors.brown.shade800;
      case ItemType.Material:
        return Colors.grey.shade700;
      case ItemType.Component:
        return Colors.teal.shade800;
      case ItemType.Scroll:
        return Colors.indigo.shade800;
      case ItemType.Potion:
        return Colors.pink.shade800;
      case ItemType.Currency:
        return Colors.yellow.shade800;
    }
  }

  // Icons für Item-Typen
  static IconData getItemTypeIcon(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Icons.gavel;
      case ItemType.Armor:
        return Icons.security;
      case ItemType.Shield:
        return Icons.shield;
      case ItemType.AdventuringGear:
        return Icons.backpack;
      case ItemType.Treasure:
        return Icons.monetization_on;
      case ItemType.MagicItem:
        return Icons.auto_awesome;
      case ItemType.SPELL_WEAPON:
        return Icons.flourescent;
      case ItemType.Consumable:
        return Icons.restaurant;
      case ItemType.Tool:
        return Icons.build;
      case ItemType.Material:
        return Icons.category;
      case ItemType.Component:
        return Icons.science;
      case ItemType.Scroll:
        return Icons.description;
      case ItemType.Potion:
        return Icons.local_drink;
      case ItemType.Currency:
        return Icons.attach_money;
    }
  }

  // Display-Namen für Item-Typen
  static String getItemTypeDisplayName(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return 'Waffe';
      case ItemType.Armor:
        return 'Rüstung';
      case ItemType.Shield:
        return 'Schild';
      case ItemType.AdventuringGear:
        return 'Ausrüstung';
      case ItemType.Treasure:
        return 'Schatz';
      case ItemType.MagicItem:
        return 'Magisches Item';
      case ItemType.SPELL_WEAPON:
        return 'Zauber';
      case ItemType.Consumable:
        return 'Verbrauchbar';
      case ItemType.Tool:
        return 'Werkzeug';
      case ItemType.Material:
        return 'Material';
      case ItemType.Component:
        return 'Komponente';
      case ItemType.Scroll:
        return 'Schriftrolle';
      case ItemType.Potion:
        return 'Trank';
      case ItemType.Currency:
        return 'Währung';
    }
  }

  // Farben für Rarity (dunkle Varianten)
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey.shade600;
      case 'uncommon':
        return Colors.green.shade700;
      case 'rare':
        return Colors.blue.shade700;
      case 'very rare':
        return Colors.purple.shade700;
      case 'legendary':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  // Rarity-Rahmenfarbe
  static Color getRarityBorderColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey.shade400;
      case 'uncommon':
        return Colors.green.shade400;
      case 'rare':
        return Colors.blue.shade400;
      case 'very rare':
        return Colors.purple.shade400;
      case 'legendary':
        return Colors.orange.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // Haltbarkeitsfarbe basierend auf Prozentsatz
  static Color getDurabilityColor(double percentage) {
    if (percentage > 0.6) {
      return Colors.green.shade600;
    } else if (percentage > 0.3) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
    }
  }
}
