import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';
import '../../theme/dnd_icons.dart';

class ItemColorHelper {
  // Item-Typen Farben (AppColors-basiert)
  static Color getItemTypeColor(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return AppColors.typQuest;           // Rot für Waffen
      case ItemType.Armor:
        return AppColors.typNpc;             // Blau für Rüstung
      case ItemType.Shield:
        return AppColors.typKreatur;         // Grau für Schilde
      case ItemType.AdventuringGear:
        return AppColors.typOrt;             // Grün für Ausrüstung
      case ItemType.Treasure:
        return AppColors.typFraktion;        // Amber für Schätze
      case ItemType.MagicItem:
        return AppColors.typLore;            // Lila für magische Items
      case ItemType.SPELL_WEAPON:
        return AppColors.typLore;            // Lila für Zauber
      case ItemType.Consumable:
        return AppColors.typWildnis;         // Amber für Verbrauchbares
      case ItemType.Tool:
        return AppColors.typGebaeude;        // Blau für Werkzeuge
      case ItemType.Material:
        return AppColors.typGegenstand;      // Dunkelgrün für Materialien
      case ItemType.Component:
        return AppColors.typGeschichte;      // Blau für Komponenten
      case ItemType.Scroll:
        return AppColors.typNpc;             // Blau für Schriftrollen
      case ItemType.Potion:
        return AppColors.typOrt;             // Grün für Tränke
      case ItemType.Currency:
        return AppColors.typFraktion;        // Amber für Währung
    }
  }

  // D&D Icons für Item-Typen (neues System)
  static IconData getItemTypeIcon(ItemType type) {
    return DnDIcons.getItemIcon(type.toString());
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

  // Rarity Farben
  static Color getRarityColor(String rarity) {
    return _getRarityColorFromString(rarity);
  }

  static Color _getRarityColorFromString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return AppColors.typFraktion;    // Amber/Gold für Legendary
      case 'very rare':
        return AppColors.typLore;        // Lila für Very Rare
      case 'rare':
        return AppColors.typNpc;         // Blau für Rare
      case 'uncommon':
        return AppColors.typOrt;         // Grün für Uncommon
      case 'common':
      default:
        return AppColors.typKreatur;     // Grau für Common
    }
  }

  // Rarity Rahmenfarben
  static Color getRarityBorderColor(String rarity) {
    final baseColor = getRarityColor(rarity);
    return baseColor.withValues(alpha: 0.7);
  }

  // Haltbarkeitsfarbe
  static Color getDurabilityColor(double percentage) {
    if (percentage > 0.6) {
      return AppColors.typOrt;         // Grün für gut
    } else if (percentage > 0.3) {
      return AppColors.typFraktion;    // Amber für mittel
    } else {
      return AppColors.typQuest;       // Rot für schlecht
    }
  }

  // Mystische Glow-Effekte für besondere Items
  static BoxShadow getItemGlow(ItemType type, String rarity) {
    final color = getRarityColor(rarity);
    final intensity = _getGlowIntensity(rarity);

    return BoxShadow(
      color: color.withValues(alpha: intensity),
      blurRadius: 8.0,
      spreadRadius: intensity > 0.3 ? 2.0 : 1.0,
    );
  }

  // Helper für Glow-Intensität basierend auf Rarity
  static double _getGlowIntensity(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 0.6;
      case 'very rare':
        return 0.4;
      case 'rare':
        return 0.3;
      case 'uncommon':
        return 0.2;
      case 'common':
      default:
        return 0.1;
    }
  }

  // Klassen-spezifische Farben für Character Items
  static Color getClassSpecificColor(String? characterClass, ItemType itemType) {
    if (characterClass == null) return getItemTypeColor(itemType);

    switch (characterClass) {
      case 'Magier':
      case 'Hexenmeister':
        return AppColors.typLore;         // Lila für magische Klassen
      case 'Kleriker':
      case 'Paladin':
        return AppColors.typFraktion;     // Amber für heilige Klassen
      case 'Druide':
        return AppColors.typOrt;          // Grün für Naturklassen
      case 'Schurke':
        return AppColors.typKreatur;      // Grau für Schattenklassen
      case 'Krieger':
      case 'Barbar':
      case 'Todesritter':
        return AppColors.typQuest;        // Rot für Kampfklassen
      default:
        return getItemTypeColor(itemType);
    }
  }

  // Erweiterte Item-Styling
  static Decoration getItemDecoration({
    required ItemType itemType,
    required String rarity,
    String? characterClass,
    bool isSelected = false,
  }) {
    final baseColor = getClassSpecificColor(characterClass, itemType);
    final rarityColor = getRarityColor(rarity);
    final borderColor = getRarityBorderColor(rarity);
    final glow = getItemGlow(itemType, rarity);

    return BoxDecoration(
      color: baseColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(
        color: isSelected ? rarityColor : borderColor,
        width: isSelected ? 3.0 : 2.0,
      ),
      boxShadow: isSelected ? [glow] : null,
    );
  }

  // Text-Styling
  static TextStyle getItemTextStyle({
    required String rarity,
    bool isSelected = false,
  }) {
    final rarityColor = getRarityColor(rarity);

    return TextStyle(
      color: isSelected ? rarityColor : AppColors.darkTextMid,
      fontSize: isSelected ? 16 : 14,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      shadows: isSelected
          ? [
              Shadow(
                color: rarityColor.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }
}
