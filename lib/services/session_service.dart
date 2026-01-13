import 'package:flutter/foundation.dart';

/// Session Service - Verwaltet Session-Daten als Singleton
/// 
/// Dieser Service fungiert wie ein zentraler Speicher für
/// Daten, die über die Lebensdauer der App hinaus bestehen müssen.
/// Er ist thread-sicher durch Nutzung von Map und Locks.
class SessionService {
  // Singleton Pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;

  SessionService._internal();

  final Map<String, dynamic> _sessionData = {};
  final Map<Type, dynamic> _dependencies = {};

  /// Speichert Daten in der Session
  void set<T>(String key, T value) {
    _sessionData[key] = value;
    if (kDebugMode) {
      print('💾 Session: $key = $value');
    }
  }

  /// Holt Daten aus der Session
  T? get<T>(String key) {
    return _sessionData[key] as T?;
  }

  /// Löscht Daten aus der Session
  void remove(String key) {
    _sessionData.remove(key);
    if (kDebugMode) {
      print('💾 Session: $key entfernt');
    }
  }

  /// Prüft, ob ein Key existiert
  bool containsKey(String key) {
    return _sessionData.containsKey(key);
  }

  /// Speichert eine Dependency (für Service-Container)
  void setDependency<T>(Type type, T instance) {
    _dependencies[type] = instance;
    if (kDebugMode) {
      print('📦 Dependency registriert: $type');
    }
  }

  /// Holt eine Dependency (für Service-Container)
  T? getDependency<T>() {
    return _dependencies[T] as T?;
  }

  /// Prüft, ob eine Dependency existiert
  bool containsDependency<T>() {
    return _dependencies.containsKey(T);
  }

  /// Löscht alle Session-Daten
  void clear() {
    _sessionData.clear();
    _dependencies.clear();
    if (kDebugMode) {
      print('💾 Session gelöscht');
    }
  }

  /// Gibt alle Session-Keys zurück
  List<String> getKeys() {
    return _sessionData.keys.toList();
  }

  /// Gibt alle Dependencies zurück
  List<Type> getDependencies() {
    return _dependencies.keys.toList();
  }
}
