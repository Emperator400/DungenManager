import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../theme/dnd_theme.dart';
import '../../theme/dnd_icons.dart';

class ItemColorHelper {
  // D&D Item-Typen Farben (ersetzen die alten Farben)
  static Color getItemTypeColor(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return DnDTheme.deepRed;           // Blutrot für Waffen
      case ItemType.Armor:
        return DnDTheme.arcaneBlue;         // Arkanes Blau für Rüstung
      case ItemType.Shield:
        return DnDTheme.slateGrey;          // Schiefergrau für Schilde
      case ItemType.AdventuringGear:
        return DnDTheme.emeraldGreen;       // Smaragdgrün für Ausrüstung
      case ItemType.Treasure:
        return DnDTheme.ancientGold;         // Altes Gold für Schätze
      case ItemType.MagicItem:
        return DnDTheme.mysticalPurple;      // Mystisches Lila für magische Items
      case ItemType.SPELL_WEAPON:
        return DnDTheme.mysticalPurple;      // Mystisches Lila für Zauber
      case ItemType.Consumable:
        return DnDTheme.warningOrange;        // Warnungsorange für Verbrauchbares
      case ItemType.Tool:
        return DnDTheme.stoneGrey;          // Steingrau für Werkzeuge
      case ItemType.Material:
        return DnDTheme.charcoalGrey;        // Holzkohle für Materialien
      case ItemType.Component:
        return DnDTheme.infoBlue;           // Info-Blau für Komponenten
      case ItemType.Scroll:
        return DnDTheme.arcaneBlue;         // Arkanes Blau für Schriftrollen
      case ItemType.Potion:
        return DnDTheme.emeraldGreen;       // Smaragdgrün für Tränke
      case ItemType.Currency:
        return DnDTheme.ancientGold;         // Altes Gold für Währung
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

  // D&D Rarity Farben (neues System)
  static Color getRarityColor(String rarity) {
    return DnDTheme.getRarityColor(rarity);
  }

  // D&D Rarity Rahmenfarben (neues System)
  static Color getRarityBorderColor(String rarity) {
    final baseColor = getRarityColor(rarity);
    return baseColor.withOpacity(0.7);
  }

  // D&D Haltbarkeitsfarbe mit Fantasy-Farben
  static Color getDurabilityColor(double percentage) {
    if (percentage > 0.6) {
      return DnDTheme.emeraldGreen;       // Grün für gut
    } else if (percentage > 0.3) {
      return DnDTheme.ancientGold;       // Gold für mittel
    } else {
      return DnDTheme.deepRed;             // Rot für schlecht
    }
  }

  // Mystische Glow-Effekte für besondere Items
  static BoxShadow getItemGlow(ItemType type, String rarity) {
    final color = getRarityColor(rarity);
    final intensity = _getGlowIntensity(rarity);
    
    return BoxShadow(
      color: color.withOpacity(intensity),
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

  // D&D Klassen-spezifische Farben für Character Items
  static Color getClassSpecificColor(String? characterClass, ItemType itemType) {
    if (characterClass == null) return getItemTypeColor(itemType);
    
    switch (characterClass) {
      case 'Magier':
      case 'Hexenmeister':
        return DnDTheme.mysticalPurple;      // Magische Klassen bekommen lila Töne
      case 'Kleriker':
      case 'Paladin':
        return DnDTheme.ancientGold;         // Heiligen Klassen bekommen goldene Töne
      case 'Druide':
        return DnDTheme.emeraldGreen;       // Naturklassen bekommen grüne Töne
      case 'Schurke':
        return DnDTheme.stoneGrey;          // Schattenklassen bekommen graue Töne
      case 'Krieger':
      case 'Barbar':
      case 'Todesritter':
        return DnDTheme.deepRed;             // Kampfklassen bekommen rote Töne
      default:
        return getItemTypeColor(itemType);       // Standardfarbe für andere Klassen
    }
  }

  // Erweiterte Item-Styling mit D&D Theme
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
      color: baseColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      border: Border.all(
        color: isSelected ? rarityColor : borderColor,
        width: isSelected ? 3.0 : 2.0,
      ),
      boxShadow: isSelected ? [glow] : DnDTheme.subtleShadow,
    );
  }

  // Text-Styling mit D&D Theme
  static TextStyle getItemTextStyle({
    required String rarity,
    bool isSelected = false,
  }) {
    final rarityColor = getRarityColor(rarity);
    
    return TextStyle(
      color: isSelected ? rarityColor : DnDTheme.stoneGrey,
      fontSize: isSelected ? 16 : 14,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      shadows: isSelected ? [
        Shadow(
          color: rarityColor.withOpacity(0.5),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }
}
