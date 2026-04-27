import 'package:flutter/material.dart';

abstract final class ColorUtils {
  static Color? fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceFirst('#', '');
    final value = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return value != null ? Color(value) : null;
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
