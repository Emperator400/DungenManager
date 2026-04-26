// lib/theme/theme_notifier.dart

import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }

  void setDark({required bool value}) {
    if (_isDark == value) {
      return;
    }
    _isDark = value;
    notifyListeners();
  }
}
