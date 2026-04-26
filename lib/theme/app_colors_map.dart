// lib/theme/app_colors_map.dart
//
// Typ-zu-Farbe Mapping für TypeTag und alle Screens.
// Identisch mit TYP_CFG aus den JSX-Prototypen.

import 'package:flutter/material.dart';

class TypeColorConfig {
  const TypeColorConfig({
    required this.color,
    required this.bgLight,
    required this.bgDark,
    required this.dot,
  });

  final Color color;
  final Color bgLight;
  final Color bgDark;
  final Color dot;
}

class AppTypeColors {
  const AppTypeColors._();

  static const _configs = <String, TypeColorConfig>{
    'NPC':        TypeColorConfig(color: Color(0xFF2F6FEB), bgLight: Color(0xFFEEF3FD), bgDark: Color(0xFF1A2540), dot: Color(0xFF2F6FEB)),
    'Ort':        TypeColorConfig(color: Color(0xFF1A7F4B), bgLight: Color(0xFFEAF4EE), bgDark: Color(0xFF0F2A1C), dot: Color(0xFF1A7F4B)),
    'Lore':       TypeColorConfig(color: Color(0xFF7C3AED), bgLight: Color(0xFFF3EFFE), bgDark: Color(0xFF1E1330), dot: Color(0xFF7C3AED)),
    'Fraktion':   TypeColorConfig(color: Color(0xFFB45309), bgLight: Color(0xFFFDF6EC), bgDark: Color(0xFF2A1F08), dot: Color(0xFFB45309)),
    'Magie':      TypeColorConfig(color: Color(0xFFBE185D), bgLight: Color(0xFFFDF0F7), bgDark: Color(0xFF2A0F1C), dot: Color(0xFFBE185D)),
    'Geschichte': TypeColorConfig(color: Color(0xFF0891B2), bgLight: Color(0xFFECFBFF), bgDark: Color(0xFF0A1F28), dot: Color(0xFF0891B2)),
    'Gegenstand': TypeColorConfig(color: Color(0xFF065F46), bgLight: Color(0xFFECFDF5), bgDark: Color(0xFF071A14), dot: Color(0xFF065F46)),
    'Quest':      TypeColorConfig(color: Color(0xFFC93A3A), bgLight: Color(0xFFFDF0F0), bgDark: Color(0xFF2A1212), dot: Color(0xFFC93A3A)),
    'Kreatur':    TypeColorConfig(color: Color(0xFF6B6B66), bgLight: Color(0xFFF0F0ED), bgDark: Color(0xFF232320), dot: Color(0xFF6B6B66)),
    // Ort-Subtypen
    'Gebäude':    TypeColorConfig(color: Color(0xFF2F6FEB), bgLight: Color(0xFFEEF3FD), bgDark: Color(0xFF1A2540), dot: Color(0xFF2F6FEB)),
    'Stadt':      TypeColorConfig(color: Color(0xFF1A7F4B), bgLight: Color(0xFFEAF4EE), bgDark: Color(0xFF0F2A1C), dot: Color(0xFF1A7F4B)),
    'Dungeon':    TypeColorConfig(color: Color(0xFF7C3AED), bgLight: Color(0xFFF3EFFE), bgDark: Color(0xFF1E1330), dot: Color(0xFF7C3AED)),
    'Wildnis':    TypeColorConfig(color: Color(0xFFB45309), bgLight: Color(0xFFFDF6EC), bgDark: Color(0xFF2A1F08), dot: Color(0xFFB45309)),
    // Charakter-Klassen
    'Barbar':     TypeColorConfig(color: Color(0xFFC93A3A), bgLight: Color(0xFFFDF0F0), bgDark: Color(0xFF2A1212), dot: Color(0xFFC93A3A)),
    'Barde':      TypeColorConfig(color: Color(0xFF7C3AED), bgLight: Color(0xFFF3EFFE), bgDark: Color(0xFF1E1330), dot: Color(0xFF7C3AED)),
    'Kleriker':   TypeColorConfig(color: Color(0xFFD4890A), bgLight: Color(0xFFFDF6EC), bgDark: Color(0xFF2A1F08), dot: Color(0xFFD4890A)),
    'Druide':     TypeColorConfig(color: Color(0xFF1A7F4B), bgLight: Color(0xFFEAF4EE), bgDark: Color(0xFF0F2A1C), dot: Color(0xFF1A7F4B)),
    'Kämpfer':    TypeColorConfig(color: Color(0xFF6B6B66), bgLight: Color(0xFFF0F0ED), bgDark: Color(0xFF232320), dot: Color(0xFF6B6B66)),
    'Mönch':      TypeColorConfig(color: Color(0xFF0891B2), bgLight: Color(0xFFECFBFF), bgDark: Color(0xFF0A1F28), dot: Color(0xFF0891B2)),
    'Paladin':    TypeColorConfig(color: Color(0xFF2F6FEB), bgLight: Color(0xFFEEF3FD), bgDark: Color(0xFF1A2540), dot: Color(0xFF2F6FEB)),
    'Waldläufer': TypeColorConfig(color: Color(0xFF065F46), bgLight: Color(0xFFECFDF5), bgDark: Color(0xFF071A14), dot: Color(0xFF065F46)),
    'Schurke':    TypeColorConfig(color: Color(0xFF4A4A4A), bgLight: Color(0xFFF0F0ED), bgDark: Color(0xFF232320), dot: Color(0xFF4A4A4A)),
    'Zauberer':   TypeColorConfig(color: Color(0xFFBE185D), bgLight: Color(0xFFFDF0F7), bgDark: Color(0xFF2A0F1C), dot: Color(0xFFBE185D)),
    'Hexenmeister': TypeColorConfig(color: Color(0xFF4A235A), bgLight: Color(0xFFF3EFFE), bgDark: Color(0xFF1E1330), dot: Color(0xFF4A235A)),
    'Magier':     TypeColorConfig(color: Color(0xFF1B4F72), bgLight: Color(0xFFECFBFF), bgDark: Color(0xFF0A1F28), dot: Color(0xFF1B4F72)),
  };

  static const TypeColorConfig _fallback = TypeColorConfig(
    color:   Color(0xFF6B6B66),
    bgLight: Color(0xFFF0F0ED),
    bgDark:  Color(0xFF232320),
    dot:     Color(0xFF6B6B66),
  );

  static TypeColorConfig of(String type) => _configs[type] ?? _fallback;

  static List<String> get allTypes => _configs.keys.toList();
}
