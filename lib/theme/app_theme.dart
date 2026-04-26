// lib/theme/app_theme.dart
//
// Neues Design System nach UI_vorschrift.
// Modern, clean, professionell (Linear/Notion-Ästhetik).

import 'package:flutter/material.dart';

// ── FARB-PALETTEN ─────────────────────────────────────────────────────────────

class AppColors {
  const AppColors._();

  // Light Mode
  static const Color lightBg           = Color(0xFFF7F7F5);
  static const Color lightBgPanel      = Color(0xFFFFFFFF);
  static const Color lightBgHover      = Color(0xFFF0F0ED);
  static const Color lightBgActive     = Color(0xFFEEECEA);
  static const Color lightBorder       = Color(0xFFE4E4E0);
  static const Color lightBorderStrong = Color(0xFFD0D0CA);
  static const Color lightText         = Color(0xFF1A1A18);
  static const Color lightTextMid      = Color(0xFF6B6B66);
  static const Color lightTextSoft     = Color(0xFF9F9F98);
  static const Color lightAccent       = Color(0xFF2F6FEB);
  static const Color lightAccentSoft   = Color(0xFFEEF3FD);
  static const Color lightGreen        = Color(0xFF1A7F4B);
  static const Color lightGreenSoft    = Color(0xFFEAF4EE);
  static const Color lightAmber        = Color(0xFFB45309);
  static const Color lightAmberSoft    = Color(0xFFFDF6EC);
  static const Color lightRed          = Color(0xFFC93A3A);
  static const Color lightRedSoft      = Color(0xFFFDF0F0);

  // Dark Mode
  static const Color darkBg            = Color(0xFF111110);
  static const Color darkBgPanel       = Color(0xFF1A1A18);
  static const Color darkBgHover       = Color(0xFF232320);
  static const Color darkBgActive      = Color(0xFF2A2A27);
  static const Color darkBorder        = Color(0xFF2E2E2B);
  static const Color darkBorderStrong  = Color(0xFF3D3D39);
  static const Color darkText          = Color(0xFFEDEDE8);
  static const Color darkTextMid       = Color(0xFF8A8A82);
  static const Color darkTextSoft      = Color(0xFF5A5A54);
  static const Color darkAccent        = Color(0xFF4F8EF7);
  static const Color darkAccentSoft    = Color(0xFF1A2540);
  static const Color darkGreen         = Color(0xFF34C471);
  static const Color darkGreenSoft     = Color(0xFF0F2A1C);
  static const Color darkAmber         = Color(0xFFD4890A);
  static const Color darkAmberSoft     = Color(0xFF2A1F08);
  static const Color darkRed           = Color(0xFFE05555);
  static const Color darkRedSoft       = Color(0xFF2A1212);

  // Typ-Farben (gleich in light/dark – Helligkeit via bg_l/bg_d)
  static const Color typNpc        = Color(0xFF2F6FEB);
  static const Color typOrt        = Color(0xFF1A7F4B);
  static const Color typLore       = Color(0xFF7C3AED);
  static const Color typFraktion   = Color(0xFFB45309);
  static const Color typMagie      = Color(0xFFBE185D);
  static const Color typGeschichte = Color(0xFF0891B2);
  static const Color typGegenstand = Color(0xFF065F46);
  static const Color typQuest      = Color(0xFFC93A3A);
  static const Color typKreatur    = Color(0xFF6B6B66);
  static const Color typDungeon    = Color(0xFF7C3AED);
  static const Color typWildnis    = Color(0xFFB45309);
  static const Color typGebaeude   = Color(0xFF2F6FEB);
  static const Color typStadt      = Color(0xFF1A7F4B);
}

// ── THEME EXTENSION (Farben per Theme-Kontext abrufbar) ───────────────────────

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.bg,
    required this.bgPanel,
    required this.bgHover,
    required this.bgActive,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textMid,
    required this.textSoft,
    required this.accent,
    required this.accentSoft,
    required this.green,
    required this.greenSoft,
    required this.amber,
    required this.amberSoft,
    required this.red,
    required this.redSoft,
  });

  final Color bg;
  final Color bgPanel;
  final Color bgHover;
  final Color bgActive;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textMid;
  final Color textSoft;
  final Color accent;
  final Color accentSoft;
  final Color green;
  final Color greenSoft;
  final Color amber;
  final Color amberSoft;
  final Color red;
  final Color redSoft;

  static const AppColorsExtension light = AppColorsExtension(
    bg:           AppColors.lightBg,
    bgPanel:      AppColors.lightBgPanel,
    bgHover:      AppColors.lightBgHover,
    bgActive:     AppColors.lightBgActive,
    border:       AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
    text:         AppColors.lightText,
    textMid:      AppColors.lightTextMid,
    textSoft:     AppColors.lightTextSoft,
    accent:       AppColors.lightAccent,
    accentSoft:   AppColors.lightAccentSoft,
    green:        AppColors.lightGreen,
    greenSoft:    AppColors.lightGreenSoft,
    amber:        AppColors.lightAmber,
    amberSoft:    AppColors.lightAmberSoft,
    red:          AppColors.lightRed,
    redSoft:      AppColors.lightRedSoft,
  );

  static const AppColorsExtension dark = AppColorsExtension(
    bg:           AppColors.darkBg,
    bgPanel:      AppColors.darkBgPanel,
    bgHover:      AppColors.darkBgHover,
    bgActive:     AppColors.darkBgActive,
    border:       AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    text:         AppColors.darkText,
    textMid:      AppColors.darkTextMid,
    textSoft:     AppColors.darkTextSoft,
    accent:       AppColors.darkAccent,
    accentSoft:   AppColors.darkAccentSoft,
    green:        AppColors.darkGreen,
    greenSoft:    AppColors.darkGreenSoft,
    amber:        AppColors.darkAmber,
    amberSoft:    AppColors.darkAmberSoft,
    red:          AppColors.darkRed,
    redSoft:      AppColors.darkRedSoft,
  );

  @override
  AppColorsExtension copyWith({
    Color? bg, Color? bgPanel, Color? bgHover, Color? bgActive,
    Color? border, Color? borderStrong,
    Color? text, Color? textMid, Color? textSoft,
    Color? accent, Color? accentSoft,
    Color? green, Color? greenSoft,
    Color? amber, Color? amberSoft,
    Color? red, Color? redSoft,
  }) {
    return AppColorsExtension(
      bg:           bg           ?? this.bg,
      bgPanel:      bgPanel      ?? this.bgPanel,
      bgHover:      bgHover      ?? this.bgHover,
      bgActive:     bgActive     ?? this.bgActive,
      border:       border       ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      text:         text         ?? this.text,
      textMid:      textMid      ?? this.textMid,
      textSoft:     textSoft     ?? this.textSoft,
      accent:       accent       ?? this.accent,
      accentSoft:   accentSoft   ?? this.accentSoft,
      green:        green        ?? this.green,
      greenSoft:    greenSoft    ?? this.greenSoft,
      amber:        amber        ?? this.amber,
      amberSoft:    amberSoft    ?? this.amberSoft,
      red:          red          ?? this.red,
      redSoft:      redSoft      ?? this.redSoft,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColorsExtension(
      bg:           Color.lerp(bg,           other.bg,           t)!,
      bgPanel:      Color.lerp(bgPanel,      other.bgPanel,      t)!,
      bgHover:      Color.lerp(bgHover,      other.bgHover,      t)!,
      bgActive:     Color.lerp(bgActive,     other.bgActive,     t)!,
      border:       Color.lerp(border,       other.border,       t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text:         Color.lerp(text,         other.text,         t)!,
      textMid:      Color.lerp(textMid,      other.textMid,      t)!,
      textSoft:     Color.lerp(textSoft,     other.textSoft,     t)!,
      accent:       Color.lerp(accent,       other.accent,       t)!,
      accentSoft:   Color.lerp(accentSoft,   other.accentSoft,   t)!,
      green:        Color.lerp(green,        other.green,        t)!,
      greenSoft:    Color.lerp(greenSoft,    other.greenSoft,    t)!,
      amber:        Color.lerp(amber,        other.amber,        t)!,
      amberSoft:    Color.lerp(amberSoft,    other.amberSoft,    t)!,
      red:          Color.lerp(red,          other.red,          t)!,
      redSoft:      Color.lerp(redSoft,      other.redSoft,      t)!,
    );
  }
}

// Convenience-Extension: context.appColors
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}

// ── MATERIAL THEMES ───────────────────────────────────────────────────────────

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: AppColorsExtension.light,
    scaffoldBg: AppColors.lightBg,
    accent: AppColors.lightAccent,
    surface: AppColors.lightBgPanel,
    border: AppColors.lightBorder,
    text: AppColors.lightText,
    textSoft: AppColors.lightTextSoft,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: AppColorsExtension.dark,
    scaffoldBg: AppColors.darkBg,
    accent: AppColors.darkAccent,
    surface: AppColors.darkBgPanel,
    border: AppColors.darkBorder,
    text: AppColors.darkText,
    textSoft: AppColors.darkTextSoft,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColorsExtension colors,
    required Color scaffoldBg,
    required Color accent,
    required Color surface,
    required Color border,
    required Color text,
    required Color textSoft,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: '.AppleSystemUIFont',

      scaffoldBackgroundColor: scaffoldBg,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: text,
        error: isDark ? AppColors.darkRed : AppColors.lightRed,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: '.AppleSystemUIFont',
        ),
        iconTheme: IconThemeData(color: textSoft, size: 18),
      ),

      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bgHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: accent),
        ),
        hintStyle: TextStyle(color: textSoft, fontSize: 13),
        labelStyle: TextStyle(color: textSoft, fontSize: 11),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: text),
        headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text),
        headlineSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: text),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: text),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: textSoft),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: text),
        labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSoft),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textSoft),
      ),

      extensions: [colors],
    );
  }
}
