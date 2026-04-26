// lib/widgets/ui_components/shared/unified_card_theme.dart
//
// Farb-Konfiguration für alle Cards — jetzt auf AppColors/AppTypeColors basierend.

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors_map.dart';

class UnifiedCardTheme {
  const UnifiedCardTheme._();

  // ── TYPE COLORS (delegiert an AppTypeColors) ──────────────────────────────

  static Color getTypeColor(String type) => AppTypeColors.of(type).color;
  static Color getTypeBgLight(String type) => AppTypeColors.of(type).bgLight;
  static Color getTypeBgDark(String type) => AppTypeColors.of(type).bgDark;
  static Color getTypeDot(String type) => AppTypeColors.of(type).dot;

  // ── STATUS COLORS ─────────────────────────────────────────────────────────

  static Color getStatusColor(String status, AppColorsExtension C) {
    final s = status.toLowerCase();
    if (s.contains('aktiv') || s.contains('active') || s.contains('laufend')) {
      return C.accent;
    }
    if (s.contains('done') ||
        s.contains('erledigt') ||
        s.contains('abgeschlossen')) {
      return C.green;
    }
    if (s.contains('failed') ||
        s.contains('fehl') ||
        s.contains('abgebrochen')) {
      return C.red;
    }
    return C.amber;
  }

  static Color getStatusBg(String status, AppColorsExtension C) {
    final s = status.toLowerCase();
    if (s.contains('aktiv') || s.contains('active') || s.contains('laufend')) {
      return C.accentSoft;
    }
    if (s.contains('done') || s.contains('erledigt') || s.contains('abgeschlossen')) {
      return C.greenSoft;
    }
    if (s.contains('failed') || s.contains('fehl') || s.contains('abgebrochen')) {
      return C.redSoft;
    }
    return C.amberSoft;
  }

  // ── PRIORITY COLORS ───────────────────────────────────────────────────────

  static Color getPriorityColor(String priority, AppColorsExtension C) {
    final p = priority.toLowerCase();
    if (p.contains('hoch') || p.contains('high')) return C.red;
    if (p.contains('mittel') || p.contains('medium')) return C.amber;
    return C.green;
  }

  // ── LEGACY: Icon-Farben (für noch nicht migrierte Karten) ─────────────────

  static Color getIconBackgroundColor(String type) {
    return AppTypeColors.of(type).bgLight;
  }

  static Color getIconColor(String type) {
    return AppTypeColors.of(type).color;
  }

  // ── DELETE ACTION ──────────────────────────────────────────────────────────
  // Wird direkt als context.appColors.red abgerufen, aber für Legacy-Code:
  static const Color deleteActionColorFallback = Color(0xFFC93A3A);

  static Color deleteActionColor(AppColorsExtension C) => C.red;
}
