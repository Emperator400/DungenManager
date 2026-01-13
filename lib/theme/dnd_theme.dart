// lib/theme/dnd_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// D&D Dark Theme Configuration
/// Mystisches, dunkles Design für Dungeon Manager
class DnDTheme {
  // === CORE D&D COLORS ===
  
  // Dark Background Colors
  static const Color dungeonBlack = Color(0xFF0F0F1A);        // Tiefstes Schwarz wie ein Dungeon
  static const Color stoneGrey = Color(0xFF1A1A2E);          // Dunkler Stein wie Höhlenwände
  static const Color slateGrey = Color(0xFF2D2D3D);          // Schiefergrau für Surfaces
  static const Color charcoalGrey = Color(0xFF3A3A4A);        // Holzkohle für elevated surfaces
  
  // Primary Fantasy Colors
  static const Color mysticalPurple = Color(0xFF6B46C1);     // Mystisches Lila für Magie
  static const Color ancientGold = Color(0xFFD97706);        // Altes Gold für Werte und Schätze
  static const Color emeraldGreen = Color(0xFF10B981);       // Smaragdgrün für Erfolg/Natur
  static const Color deepRed = Color(0xFFDC2626);            // tiefes Rot für Gefahr/Blut
  static const Color arcaneBlue = Color(0xFF2563EB);        // Arkanes Blau für Wissen
  
  // Status Colors (Dark Theme Optimized)
  static const Color successGreen = Color(0xFF059669);       // Erfolgsgrün
  static const Color warningOrange = Color(0xFFEA580C);      // Warnungsorange
  static const Color errorRed = Color(0xFFDC2626);           // Fehlerrot
  static const Color infoBlue = Color(0xFF0284C7);           // Info-Blau
  
  // Class-Specific Fantasy Colors
  static const Map<String, Color> classColors = {
    'Krieger': Color(0xFFDC2626),        // Blutrot - Kampfkraft
    'Barbar': Color(0xFF991B1B),         // Dunkelrot - Wilde Wut
    'Paladin': Color(0xFFD97706),        // Golden - Heiligkeit
    'Kleriker': Color(0xFFF59E0B),       // Ambra - Göttliche Macht
    'Magier': Color(0xFF6B46C1),         // Mystisch Lila - Arkane Magie
    'Hexenmeister': Color(0xFF7C3AED),   // Violett - Paktmagie
    'Schurke': Color(0xFF059669),        // Smaragdgrün - Schatten
    'Schütze': Color(0xFF92400E),        // Braun - Präzision
    'Druide': Color(0xFF65A30D),         // Waldgrün - Naturverbundenheit
    'Mönch': Color(0xFF6B7280),          // Grau - Disziplin
    'Bard': Color(0xFFDB2777),           // Pink - Inspiration
    'Todesritter': Color(0xFF1F2937),    // Schwarzgrau - Todesmagie
  };
  
  // Rarity Colors mit mystischen Effekten
  static const Map<String, Color> rarityColors = {
    'common': Color(0xFF6B7280),         // Grau - Gewöhnlich
    'uncommon': Color(0xFF059669),       // Grün - Ungewöhnlich
    'rare': Color(0xFF2563EB),          // Blau - Selten
    'very rare': Color(0xFF7C3AED),      // Violett - Sehr selten
    'legendary': Color(0xFFD97706),     // Gold - Legendär
  };
  
  // === TYPOGRAPHY ===
  
  static const String fontFamily = 'Roboto';
  
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: fontFamily,
    letterSpacing: 0.25,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
    fontFamily: fontFamily,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white60,
    fontFamily: fontFamily,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white38,
    fontFamily: fontFamily,
  );
  
  // === SPACING SYSTEM ===
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // === BORDER RADIUS ===
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // === SHADOWS (DARK THEME OPTIMIZED) ===
  
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> heavyShadow = [
    BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
  
  // === MYSTICAL EFFECTS ===
  
  static BoxDecoration getMysticalBorder({Color? borderColor, double? width}) {
    return BoxDecoration(
      border: Border.all(
        color: borderColor ?? mysticalPurple,
        width: width ?? 2.0,
      ),
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: [
        BoxShadow(
          color: (borderColor ?? mysticalPurple).withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }
  
  static BoxDecoration getRarityBorder(String rarity) {
    final color = rarityColors[rarity.toLowerCase()] ?? rarityColors['common']!;
    return BoxDecoration(
      border: Border.all(color: color, width: 2),
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 8,
          spreadRadius: rarity.toLowerCase() == 'legendary' ? 2 : 1,
        ),
      ],
    );
  }
  
  // === ANIMATION EFFECTS ===
  
  /// Glowing animation for magical items

  /// Pulse animation for important elements
  static Animation<double> getPulseAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }
  
  /// Shimmer effect for legendary items
  static LinearGradient getShimmerGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0x00FFFFFF),
        Color(0x33FFFFFF),
        Color(0x66FFFFFF),
        Color(0x33FFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
    );
  }
  
  // === SPECIAL DECORATIONS ===
  
  /// Fantasy-style card with depth and mystical effects
  static BoxDecoration getFantasyCardDecoration({
    Color? borderColor,
    bool isLegendary = false,
  }) {
    final color = borderColor ?? mysticalPurple;
    
    return BoxDecoration(
      color: stoneGrey,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(
        color: color.withValues(alpha: 0.6),
        width: isLegendary ? 3 : 2,
      ),
      boxShadow: [
        // Main shadow
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
        // Mystical glow
        if (isLegendary)
          BoxShadow(
            color: ancientGold.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          )
        else
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
      ],
    );
  }
  
  /// Dungeon wall texture effect
  static BoxDecoration getDungeonWallDecoration() {
    return BoxDecoration(
      color: dungeonBlack,
      borderRadius: BorderRadius.circular(radiusSmall),
      border: Border.all(
        color: charcoalGrey.withValues(alpha: 0.3),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.6),
          blurRadius: 4,
          offset: const Offset(2, 2),
        ),
        BoxShadow(
          color: charcoalGrey.withValues(alpha: 0.1),
          blurRadius: 2,
          offset: const Offset(-1, -1),
        ),
      ],
    );
  }
  
  /// Magical particle effect decoration
  static BoxDecoration getMagicalParticleDecoration({required Color particleColor}) {
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          particleColor.withValues(alpha: 0.1),
          particleColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ),
      borderRadius: BorderRadius.circular(radiusLarge),
    );
  }
  
  // === MAIN THEME DATA ===
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: mysticalPurple,
        secondary: ancientGold,
        surface: stoneGrey,
        background: dungeonBlack,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white70,
        onBackground: Colors.white70,
        onError: Colors.white,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: stoneGrey,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: stoneGrey,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        shadowColor: Colors.black26,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: mysticalPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: mysticalPurple,
          side: const BorderSide(color: mysticalPurple, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: mysticalPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: md, vertical: sm),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: slateGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: mysticalPurple, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: mysticalPurple.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: mysticalPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: headline1,
        headlineMedium: headline2,
        headlineSmall: headline3,
        bodyLarge: bodyText1,
        bodyMedium: bodyText2,
        bodySmall: caption,
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: Colors.white70,
        size: 24,
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white70,
        textColor: Colors.white,
        tileColor: stoneGrey,
        contentPadding: EdgeInsets.symmetric(horizontal: md, vertical: sm),
      ),
      
      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: ancientGold,
        unselectedLabelColor: Colors.white54,
        indicatorColor: ancientGold,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: slateGrey,
        brightness: Brightness.dark,
        labelStyle: const TextStyle(color: Colors.white),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: sm, vertical: xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      
      // Scaffold Theme
      scaffoldBackgroundColor: dungeonBlack,
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.white12,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  // === HELPER METHODS ===
  
  /// Get class-specific color with fallback
  static Color getClassColor(String className) {
    return classColors[className] ?? classColors.values.first;
  }
  
  /// Get rarity-specific color with fallback
  static Color getRarityColor(String rarity) {
    return rarityColors[rarity.toLowerCase()] ?? rarityColors['common']!;
  }
  
  /// Get appropriate text color for background
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Create mystical gradient for special effects
  static LinearGradient getMysticalGradient({
    Color? startColor,
    Color? endColor,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
  }) {
    return LinearGradient(
      begin: begin ?? Alignment.topLeft,
      end: end ?? Alignment.bottomRight,
      colors: [
        startColor ?? mysticalPurple.withValues(alpha: 0.8),
        endColor ?? ancientGold.withValues(alpha: 0.8),
      ],
    );
  }
}
