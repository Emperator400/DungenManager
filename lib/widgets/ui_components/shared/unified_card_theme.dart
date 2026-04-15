import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Theme-Konfiguration für Unified Cards
///
/// Definiert Farben und Styles für verschiedene Card-Typen
class UnifiedCardTheme {
  const UnifiedCardTheme();

  /// Standard Card-Farbe
  static Color get defaultCardColor => DnDTheme.slateGrey;

  /// Card-Hintergrundfarben nach Typ
  static Map<String, Color> get cardColors => {
        'campaign': const Color(0xFF3A5A40),
        'quest': const Color(0xFF588157),
        'hero': const Color(0xFF4A6741),
        'item': const Color(0xFF6B8E23),
        'sound': const Color(0xFF4682B4),
        'wiki': const Color(0xFF9370DB),
        'session': const Color(0xFF8B4513),
        'creature': const Color(0xFFCD5C5C),
        'default': const Color(0xFF2C2C2C),
      };

  /// Icon-Hintergrundfarben nach Typ
  static Map<String, Color> get iconBackgroundColors => {
        'campaign': const Color(0xFF3A5A40).withValues(alpha: 0.2),
        'quest': const Color(0xFF588157).withValues(alpha: 0.2),
        'hero': const Color(0xFF4A6741).withValues(alpha: 0.2),
        'item': const Color(0xFF6B8E23).withValues(alpha: 0.2),
        'sound': const Color(0xFF4682B4).withValues(alpha: 0.2),
        'wiki': const Color(0xFF9370DB).withValues(alpha: 0.2),
        'session': const Color(0xFF8B4513).withValues(alpha: 0.2),
        'creature': const Color(0xFFCD5C5C).withValues(alpha: 0.2),
        'default': Colors.grey.withValues(alpha: 0.2),
      };

  /// Icon-Farben nach Typ
  static Map<String, Color> get iconColors => {
        'campaign': const Color(0xFF3A5A40),
        'quest': const Color(0xFF588157),
        'hero': const Color(0xFF4A6741),
        'item': const Color(0xFF6B8E23),
        'sound': const Color(0xFF4682B4),
        'wiki': const Color(0xFF9370DB),
        'session': const Color(0xFF8B4513),
        'creature': const Color(0xFFCD5C5C),
        'default': Colors.grey,
      };

  /// Border-Radii
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;

  /// Elevation
  static const double defaultElevation = 2.0;
  static const double hoverElevation = 4.0;
  static const double selectedElevation = 8.0;

  /// Padding
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;

  /// Spacing
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 12.0;

  /// Farben für Status
  static Color get activeStatusColor => DnDTheme.successGreen;
  static Color get pendingStatusColor => DnDTheme.ancientGold;
  static Color get completedStatusColor => DnDTheme.arcaneBlue;
  static const Color archivedStatusColor = Color(0xFF6B7280);

  /// Farben für Priorität
  static Color get highPriorityColor => DnDTheme.errorRed;
  static Color get mediumPriorityColor => DnDTheme.ancientGold;
  static Color get lowPriorityColor => DnDTheme.successGreen;

  /// Farben für Löschen-Aktionen
  static Color get deleteActionColor => DnDTheme.errorRed;

  /// Hilfsfunktion zum Abrufen der Card-Farbe
  static Color getCardColor(String type) {
    return cardColors[type.toLowerCase()] ?? cardColors['default']!;
  }

  /// Hilfsfunktion zum Abrufen der Icon-Hintergrundfarbe
  static Color getIconBackgroundColor(String type) {
    return iconBackgroundColors[type.toLowerCase()] ?? iconBackgroundColors['default']!;
  }

  /// Hilfsfunktion zum Abrufen der Icon-Farbe
  static Color getIconColor(String type) {
    return iconColors[type.toLowerCase()] ?? iconColors['default']!;
  }

  /// Hilfsfunktion zum Abrufen der Status-Farbe
  static Color getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('aktiv') || lowerStatus.contains('active')) {
      return activeStatusColor;
    } else if (lowerStatus.contains('pending') || lowerStatus.contains('wartet')) {
      return pendingStatusColor;
    } else if (lowerStatus.contains('komplett') || lowerStatus.contains('complete')) {
      return completedStatusColor;
    } else if (lowerStatus.contains('archiv')) {
      return archivedStatusColor;
    }
    return DnDTheme.mysticalPurple;
  }

  /// Hilfsfunktion zum Abrufen der Prioritäts-Farbe
  static Color getPriorityColor(String priority) {
    final lowerPriority = priority.toLowerCase();
    if (lowerPriority.contains('hoch') || lowerPriority.contains('high')) {
      return highPriorityColor;
    } else if (lowerPriority.contains('mittel') || lowerPriority.contains('medium')) {
      return mediumPriorityColor;
    } else if (lowerPriority.contains('niedrig') || lowerPriority.contains('low')) {
      return lowPriorityColor;
    }
    return DnDTheme.charcoalGrey;
  }
}
