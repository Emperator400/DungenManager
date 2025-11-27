import 'package:flutter/material.dart';
import '../../models/player_character.dart';

/// Sortier-Optionen für die Liste
enum SortOption {
  name,
  level,
  className,
  playerName,
  recentlyEdited,
  favorites,
}

/// Helper-Funktionen für die Character List UI
class CharacterListHelpers {
  /// Farbschema für D&D Klassen
  static Map<String, Color> getClassColors() {
    return {
      'Krieger': Colors.red[700]!,
      'Barbar': Colors.red[900]!,
      'Paladin': Colors.yellow[700]!,
      'Kleriker': Colors.amber[700]!,
      'Magier': Colors.blue[700]!,
      'Hexenmeister': Colors.purple[700]!,
      'Schurke': Colors.green[700]!,
      'Schütze': Colors.brown[700]!,
      'Druide': Colors.lightGreen[700]!,
      'Mönch': Colors.grey[700]!,
      'Bard': Colors.pink[700]!,
      'Todesritter': Colors.grey[900]!,
    };
  }

  /// Farbe für eine bestimmte Klasse erhalten
  static Color getClassColor(String className) {
    final colors = getClassColors();
    // Fallback: erste oder graue Farbe verwenden
    return colors[className] ?? colors.values.first;
  }

  /// Farbschema für Gesinnungen
  static Map<String, Color> getAlignmentColors() {
    return {
      'Lawful Good': Colors.blue[600]!,
      'Neutral Good': Colors.green[600]!,
      'Chaotic Good': Colors.red[600]!,
      'Lawful Neutral': Colors.blue[400]!,
      'True Neutral': Colors.grey[600]!,
      'Chaotic Neutral': Colors.orange[600]!,
      'Lawful Evil': Colors.indigo[800]!,
      'neutral evil': Colors.purple[800]!,
      'Chaotic Evil': Colors.red[900]!,
      'Unaligned': Colors.grey[500]!,
    };
  }

  /// Farbe für eine bestimmte Gesinnung erhalten
  static Color getAlignmentColor(String? alignment) {
    if (alignment == null || alignment.isEmpty) return Colors.grey[500]!;
    final colors = getAlignmentColors();
    return colors[alignment] ?? Colors.grey[500]!;
  }

  /// HP-Status Farbe basierend auf aktuellen/maximalen HP
  static Color getHpStatusColor(int currentHp, int maxHp) {
    if (maxHp <= 0) return Colors.grey;
    final percentage = currentHp / maxHp;
    
    if (percentage > 0.75) return Colors.green[600]!;
    if (percentage > 0.5) return Colors.yellow[600]!;
    if (percentage > 0.25) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  /// HP-Status Text erhalten
  static String getHpStatusText(int currentHp, int maxHp) {
    return '$currentHp/$maxHp';
  }

  /// Level Badge Farbe
  static Color getLevelBadgeColor(int level) {
    if (level >= 15) return Colors.purple[600]!; // Legendary
    if (level >= 10) return Colors.amber[600]!;  // Epic
    if (level >= 5) return Colors.blue[600]!;    // Advanced
    return Colors.grey[600]!;                      // Novice
  }

  /// Level Badge Text
  static String getLevelBadgeText(int level) {
    if (level >= 15) return 'LEG';
    if (level >= 10) return 'EPIC';
    if (level >= 5) return 'ADV';
    return 'LVL';
  }

  /// Attribut-Modifier berechnen
  static int getModifier(int attribute) {
    return ((attribute - 10) ~/ 2);
  }

  /// Attribut-Modifier als formatierten String
  static String getModifierDisplay(int attribute) {
    final modifier = getModifier(attribute);
    return modifier >= 0 ? '+$modifier' : '$modifier';
  }

  /// Attribut-Qualitätsfarbe
  static Color getAttributeQualityColor(int value) {
    if (value >= 18) return Colors.green[700]!;
    if (value >= 16) return Colors.green[600]!;
    if (value >= 14) return Colors.green[500]!;
    if (value >= 12) return Colors.blue[600]!;
    if (value >= 10) return Colors.blue[500]!;
    if (value >= 8) return Colors.orange[600]!;
    if (value >= 6) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  /// Wichtige Attribute für schnelle Anzeige (Top 3)
  static List<Map<String, dynamic>> getTopAttributes(PlayerCharacter pc) {
    final attributes = [
      {'name': 'STR', 'value': pc.strength, 'label': 'Stärke'},
      {'name': 'DEX', 'value': pc.dexterity, 'label': 'Geschicklichkeit'},
      {'name': 'CON', 'value': pc.constitution, 'label': 'Konstitution'},
      {'name': 'INT', 'value': pc.intelligence, 'label': 'Intelligenz'},
      {'name': 'WIS', 'value': pc.wisdom, 'label': 'Weisheit'},
      {'name': 'CHA', 'value': pc.charisma, 'label': 'Charisma'},
    ];
    
    // Sortiere nach Wert (höchste zuerst) und nimm Top 3
    attributes.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    return attributes.take(3).cast<Map<String, dynamic>>().toList();
  }

  /// Formatierung für Inventar-Wert
  static String formatInventoryValue(double gold) {
    if (gold >= 1000) {
      return '${(gold / 1000).toStringAsFixed(1)}k';
    }
    return gold.toStringAsFixed(0);
  }

  /// Status-Chip Daten für schnelle Info-Anzeige
  static List<Map<String, dynamic>> getStatusChips(PlayerCharacter pc) {
    final chips = <Map<String, dynamic>>[];
    
    // Level
    chips.add({
      'label': 'LVL ${pc.level}',
      'color': getLevelBadgeColor(pc.level),
      'icon': Icons.star,
    });
    
    // HP mit Status
    chips.add({
      'label': getHpStatusText(pc.maxHp, pc.maxHp), // Aktuell immer max HP
      'color': getHpStatusColor(pc.maxHp, pc.maxHp),
      'icon': Icons.favorite,
    });
    
    // AC
    chips.add({
      'label': 'AC ${pc.armorClass}',
      'color': Colors.blue[600]!,
      'icon': Icons.shield,
    });
    
    // Initiativ-Bonus
    final initiativeBonus = getModifier(pc.dexterity) + pc.initiativeBonus;
    chips.add({
      'label': 'INIT $initiativeBonus',
      'color': Colors.orange[600]!,
      'icon': Icons.bolt,
    });
    
    return chips;
  }

  /// Kompakte Beschreibung für Vorschau
  static String getCompactDescription(PlayerCharacter pc) {
    final parts = <String>[];
    
    if (pc.description != null && pc.description!.isNotEmpty) {
      parts.add(pc.description!);
    }
    
    if (pc.raceName.isNotEmpty) {
      parts.add('${pc.raceName} ${pc.className}');
    }
    
    if (parts.isEmpty) {
      parts.add('${pc.className} Level ${pc.level}');
    }
    
    return parts.join(' • ');
  }

  /// Prüft ob ein Charakter ein Favorit ist (für visuelle Hervorhebung)
  static bool isFavoriteCharacter(PlayerCharacter pc) {
    return pc.isFavorite;
  }

  /// Vergleichsfunktion für Sortierung
  static int compareCharacters(PlayerCharacter a, PlayerCharacter b, SortOption option) {
    switch (option) {
      case SortOption.name:
        return a.name.compareTo(b.name);
      case SortOption.level:
        return b.level.compareTo(a.level); // Höchste zuerst
      case SortOption.className:
        return a.className.compareTo(b.className);
      case SortOption.playerName:
        return a.playerName.compareTo(b.playerName);
      case SortOption.favorites:
        final aFav = a.isFavorite ? 1 : 0;
        final bFav = b.isFavorite ? 1 : 0;
        if (aFav != bFav) return bFav - aFav;
        return a.name.compareTo(b.name);
      case SortOption.recentlyEdited:
        // Implementierung würde Zeitstempel benötigen
        return a.name.compareTo(b.name);
    }
  }
}
