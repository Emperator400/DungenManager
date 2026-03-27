import 'package:flutter/material.dart';

/// D&D 5e Kreaturentypen
enum CreatureCategory {
  humanoid('Humanoid', 'NPC - Menschen, Elfen, Zwerge, etc.', Icons.person),
  beast('Beast', 'Monster - Tiere und natürliche Kreaturen', Icons.pets),
  dragon('Dragon', 'Monster - Drachen und Drachenblütige', Icons.landscape),
  undead('Undead', 'Monster - Untote wie Zombies, Skelette', Icons.nightlight),
  fiend('Fiend', 'Monster - Dämonen und Teufel', Icons.whatshot),
  construct('Construct', 'Monster - Golems und magische Konstrukte', Icons.smart_toy),
  giant('Giant', 'Monster - Riesen', Icons.accessibility_new),
  elemental('Elemental', 'Monster - Elementare', Icons.water_drop),
  fey('Fey', 'Monster - Feenwesen', Icons.auto_awesome),
  aberration('Aberration', 'Monster - Aberrationen wie Illithiden', Icons.visibility),
  monstrosity('Monstrosity', 'Monster - Monstrositäten', Icons.warning),
  ooze('Ooze', 'Monster - Schleime', Icons.bubble_chart),
  plant('Plant', 'Monster - Pflanzenwesen', Icons.grass),
  celestial('Celestial', 'Monster - Himmlische Wesen', Icons.wb_sunny);

  final String displayName;
  final String description;
  final IconData icon;

  const CreatureCategory(this.displayName, this.description, this.icon);
}