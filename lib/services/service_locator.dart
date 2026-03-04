import 'package:flutter/foundation.dart';

import 'package:dungen_manager/database/core/database_connection.dart';
import 'package:dungen_manager/database/repositories/campaign_model_repository.dart';
import 'package:dungen_manager/database/repositories/player_character_model_repository.dart';
import 'package:dungen_manager/database/repositories/creature_repository.dart';
import 'package:dungen_manager/viewmodels/campaign_viewmodel.dart';
import 'package:dungen_manager/services/session_service.dart';

/// Service Locator - Zentralisierte Service-Initialisierung und Dependency Injection
///
/// Dieser Service registriert und verwaltet alle Singletons und Services.
/// Er bietet typsicheren Zugriff auf Services und verhindert direkte Instanziierung.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  final SessionService _sessionService = SessionService();

  // Map für Service-Factories (Lazy Loading)
  final Map<Type, Function> _serviceFactories = {};

  // Initialisierungs-Status
  bool _isInitialized = false;

  factory ServiceLocator() {
    return _instance;
  }

  ServiceLocator._internal();

  /// Registriert einen Service mit Factory-Funktion (Lazy Loading)
  void registerService<T>(T Function() factory) {
    _serviceFactories[T] = factory;
    if (kDebugMode) {
      print('🔧 Service registriert: $T');
    }
  }

  /// Holt oder erstellt einen Service (Lazy Loading)
  T getService<T>() {
    // Prüfe, ob Service bereits existiert
    final existing = _sessionService.getDependency<T>();
    if (existing != null) {
      return existing;
    }

    // Factory holen
    final factory = _serviceFactories[T];
    if (factory == null) {
      throw StateError('Service $T ist nicht registriert!');
    }

    // Neue Instanz erstellen
    final instance = factory() as T;
    _sessionService.setDependency(T, instance);
    
    if (kDebugMode) {
      print('🔧 Service erstellt: $T');
    }
    
    return instance;
  }

  /// Initialisiert alle Core-Services (Database, Repositories, ViewModels)
  Future<void> initializeCoreServices() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔧 Core-Services bereits initialisiert');
      }
      return;
    }

    if (kDebugMode) {
      print('🔧 Initialisiere Core-Services...');
    }

    try {
      // 1. Database Connection initialisieren (Singleton)
      final dbConnection = DatabaseConnection.instance;
      if (kDebugMode) {
        print('  ✅ Database Connection erstellt');
      }

      // 2. Repositories registrieren und initialisieren
      registerService<CampaignModelRepository>(
        () => CampaignModelRepository(dbConnection),
      );
      await getService<CampaignModelRepository>();
      if (kDebugMode) {
        print('  ✅ Campaign Model Repository erstellt');
      }

      registerService<PlayerCharacterModelRepository>(
        () => PlayerCharacterModelRepository(dbConnection),
      );
      await getService<PlayerCharacterModelRepository>();
      if (kDebugMode) {
        print('  ✅ Player Character Model Repository erstellt');
      }

      registerService<CreatureRepository>(
        () => CreatureRepository(dbConnection),
      );
      await getService<CreatureRepository>();
      if (kDebugMode) {
        print('  ✅ Creature Repository erstellt');
      }

      // 3. ViewModels registrieren und initialisieren
      registerService<CampaignViewModel>(
        () => CampaignViewModel(
          campaignRepo: getService<CampaignModelRepository>(),
          characterRepo: getService<PlayerCharacterModelRepository>(),
        ),
      );
      await getService<CampaignViewModel>();
      if (kDebugMode) {
        print('  ✅ Campaign ViewModel erstellt');
      }

      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Alle Core-Services erfolgreich initialisiert');
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('⚠️ Fehler bei der Service-Initialisierung: $e');
      }
      rethrow;
    }
  }

  /// Prüft, ob ein Service initialisiert ist
  bool isServiceInitialized<T>() {
    return _sessionService.containsDependency<T>();
  }

  /// Gibt den Session-Service zurück
  SessionService get sessionService => _sessionService;

  /// Reset (für Tests)
  void reset() {
    _sessionService.clear();
    _serviceFactories.clear();
    _isInitialized = false;
    if (kDebugMode) {
      print('🔧 Service Locator zurückgesetzt');
    }
  }
}
