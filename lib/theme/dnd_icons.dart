import 'package:flutter/material.dart';

// Import DnDTheme für Farb-Zugriff
import 'dnd_theme.dart';

/// D&D Fantasy Icon System
/// Mapping von Material Icons zu Fantasy-Theme mit D&D-spezifischen Symbolen
class DnDIcons {
  // === CLASS-SPECIFIC ICONS ===
  
  static const Map<String, IconData> classIcons = {
    'Krieger': Icons.gavel,                     // Hammer für Kampfkraft
    'Barbar': Icons.front_hand,                  // Faust für Wilde Wut
    'Paladin': Icons.shield,                    // Schild für Heiligkeit
    'Kleriker': Icons.church,                   // Kirche für göttliche Macht
    'Magier': Icons.auto_awesome,               // Magie-Stern für Arkan-Magie
    'Hexenmeister': Icons.nightlight,            // Mondlicht für Paktmagie
    'Schurke': Icons.visibility_off,             // Verstecktes Auge für Schatten
    'Schütze': Icons.gps_fixed,                 // Ziel für Präzision
    'Druide': Icons.nature,                     // Blatt für Naturverbundenheit
    'Mönch': Icons.sports_martial_arts,        // Martial Arts für Disziplin
    'Bard': Icons.music_note,                   // Noten für Inspiration
    'Todesritter': Icons.warning,                 // Warnung für Todesmagie
  };
  
  // === ITEM TYPE ICONS ===
  
  static const Map<String, IconData> itemIcons = {
    'Weapon': Icons.gavel,                      // Waffe
    'Armor': Icons.security,                    // Rüstung
    'Shield': Icons.shield,                     // Schild
    'AdventuringGear': Icons.backpack,            // Ausrüstung
    'Treasure': Icons.monetization_on,           // Schatz
    'MagicItem': Icons.auto_awesome,             // Magisches Item
    'SPELL_WEAPON': Icons.flash_on,               // Zauber
    'Consumable': Icons.restaurant,               // Verbrauchbar
    'Tool': Icons.build,                       // Werkzeug
    'Material': Icons.category,                    // Material
    'Component': Icons.science,                   // Komponente
    'Scroll': Icons.description,                  // Schriftrolle
    'Potion': Icons.local_drink,                // Trank
    'Currency': Icons.attach_money,               // Währung
  };
  
  // === FANTASY ACTION ICONS ===
  
  static const IconData attack = Icons.gavel;
  static const IconData defense = Icons.shield;
  static const IconData magic = Icons.auto_awesome;
  static const IconData heal = Icons.healing;
  static const IconData stealth = Icons.visibility_off;
  static const IconData lockpick = Icons.lock_open;
  static const IconData spell = Icons.flash_on;
  static const IconData buff = Icons.trending_up;
  static const IconData debuff = Icons.trending_down;
  static const IconData fire = Icons.local_fire_department;
  static const IconData ice = Icons.ac_unit;
  static const IconData lightning = Icons.flash_on;
  static const IconData poison = Icons.bug_report;
  static const IconData holy = Icons.church;
  static const IconData shadow = Icons.nights_stay;
  static const IconData nature = Icons.nature;
  
  // === D&D DUNGEON ICONS ===
  
  static const IconData dungeon = Icons.door_sliding;
  static const IconData treasure = Icons.diamond;
  static const IconData key = Icons.key;
  static const IconData trap = Icons.warning;
  static const IconData chest = Icons.inventory_2;
  static const IconData scroll = Icons.description;
  static const IconData potion = Icons.local_drink;
  static const IconData book = Icons.menu_book;
  static const IconData map = Icons.map;
  static const IconData compass = Icons.explore;
  static const IconData torch = Icons.highlight;
  static const IconData skull = Icons.warning;
  static const IconData bones = Icons.sports_score;
  
  // === STATUS ICONS ===
  
  static const IconData success = Icons.check_circle;
  static const IconData warning = Icons.warning_amber;
  static const IconData error = Icons.error;
  static const IconData info = Icons.info;
  static const IconData favorite = Icons.star;
  static const IconData favoriteBorder = Icons.star_border;
  static const IconData locked = Icons.lock;
  static const IconData unlocked = Icons.lock_open;
  static const IconData equipped = Icons.check_circle;
  static const IconData unequipped = Icons.radio_button_unchecked;
  
  // === RARITY ICONS ===
  
  static const IconData common = Icons.circle;
  static const IconData uncommon = Icons.radio_button_checked;
  static const IconData rare = Icons.trip_origin;
  static const IconData veryRare = Icons.change_history;
  static const IconData legendary = Icons.star;
  
  // === MONSTER/NPC ICONS ===
  
  static const Map<String, IconData> monsterTypeIcons = {
    'Aberration': Icons.psychology,              // Aberration (alien-like)
    'Beast': Icons.pets,                         // Tier
    'Celestial': Icons.wb_sunny,                 // Himmelswesen
    'Construct': Icons.construction,               // Konstrukt
    'Dragon': Icons.crisis_alert,                // Drache
    'Elemental': Icons.air,                        // Elementar
    'Fey': Icons.auto_awesome,                  // Feenwesen
    'Fiend': Icons.local_fire_department,         // Teufel/Dämon
    'Giant': Icons.height,                       // Riese
    'Humanoid': Icons.person,                    // Humanoid
    'Monstrosity': Icons.crisis_alert,          // Monstrosität
    'Ooze': Icons.opacity,                      // Schleim
    'Plant': Icons.nature,                       // Pflanze
    'Undead': Icons.warning,                       // Untot
  };
  
  // === ALIGNMENT ICONS ===
  
  static const Map<String, IconData> alignmentIcons = {
    'Lawful Good': Icons.security,                // Gesetzlich Gut
    'Neutral Good': Icons.favorite,                // Neutral Gut
    'Chaotic Good': Icons.local_fire_department,   // Chaotisch Gut
    'Lawful Neutral': Icons.balance,               // Gesetzlich Neutral
    'True Neutral': Icons.adjust,                 // Wahrhaft Neutral
    'Chaotic Neutral': Icons.shuffle,             // Chaotisch Neutral
    'Lawful Evil': Icons.gavel,                  // Gesetzlich Böse
    'neutral evil': Icons.warning,                 // Neutral Böse
    'Chaotic Evil': Icons.whatshot,             // Chaotisch Böse
    'Unaligned': Icons.help_outline,              // Nicht ausgerichtet
  };
  
  // === SKILL ICONS ===
  
  static const Map<String, IconData> skillIcons = {
    'Athletics': Icons.sports_martial_arts,       // Athletik
    'Acrobatics': Icons.air,                     // Akrobatik
    'Sleight of Hand': Icons.back_hand,         // Fingerspitzengefühl
    'Stealth': Icons.visibility_off,              // Verstecken
    'Arcana': Icons.auto_awesome,                // Arkane Kunde
    'History': Icons.history,                    // Geschichte
    'Investigation': Icons.search,               // Untersuchung
    'Nature': Icons.nature,                     // Natur
    'Religion': Icons.church,                   // Religion
    'Animal Handling': Icons.pets,               // Tierhandlung
    'Insight': Icons.psychology,                // Menschenkenntnis
    'Medicine': Icons.healing,                  // Medizin
    'Perception': Icons.visibility,               // Wahrnehmung
    'Survival': Icons.hiking,                   // Überleben
    'Deception': Icons.psychology,               // Täuschung
    'Intimidation': Icons.front_hand,            // Einschüchtern
    'Performance': Icons.mic,                    // Auftreten
    'Persuasion': Icons.record_voice_over,        // Überzeugung
  };
  
  // === HELPER METHODS ===
  
  /// Get class-specific icon with fallback
  static IconData getClassIcon(String className) {
    return classIcons[className] ?? Icons.person;
  }
  
  /// Get item type icon with fallback
  static IconData getItemIcon(String itemType) {
    return itemIcons[itemType] ?? Icons.category;
  }
  
  /// Get monster type icon with fallback
  static IconData getMonsterTypeIcon(String monsterType) {
    return monsterTypeIcons[monsterType] ?? Icons.crisis_alert;
  }
  
  /// Get alignment icon with fallback
  static IconData getAlignmentIcon(String? alignment) {
    if (alignment == null || alignment.isEmpty) return Icons.help_outline;
    return alignmentIcons[alignment] ?? Icons.help_outline;
  }
  
  /// Get skill icon with fallback
  static IconData getSkillIcon(String skillName) {
    return skillIcons[skillName] ?? Icons.school;
  }
  
  /// Get rarity icon based on rarity string
  static IconData getRarityIcon(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return common;
      case 'uncommon':
        return uncommon;
      case 'rare':
        return rare;
      case 'very rare':
        return veryRare;
      case 'legendary':
        return legendary;
      default:
        return common;
    }
  }
  
  /// Get colored icon for rarity
  static Widget getRarityIconColored(String rarity, {double size = 24}) {
    final icon = getRarityIcon(rarity);
    final color = DnDTheme.getRarityColor(rarity);
    
    return Icon(icon, color: color, size: size);
  }
  
  /// Get class icon with class color
  static Widget getClassIconColored(String className, {double size = 24}) {
    final icon = getClassIcon(className);
    final color = DnDTheme.getClassColor(className);
    return Icon(icon, color: color, size: size);
  }
  
  /// Create mystical icon with glow effect
  static Widget createMysticalIcon(
    IconData icon, {
    Color? color,
    double size = 24,
    bool glow = false,
  }) {
    final iconColor = color ?? DnDTheme.mysticalPurple;
    
    if (glow) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size),
      );
    }
    
    return Icon(icon, color: iconColor, size: size);
  }
  
  /// Create rarity icon with appropriate styling
  static Widget createRarityIcon(String rarity, {double size = 24}) {
    final icon = getRarityIcon(rarity);
    final color = DnDTheme.getRarityColor(rarity);
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(icon, color: color, size: size * 0.7),
    );
  }
}
