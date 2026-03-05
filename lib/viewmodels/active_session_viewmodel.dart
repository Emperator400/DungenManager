import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../models/scene.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für aktive Sessions mit neuer Repository-Architektur
/// Zentralisiert State Management und Business-Logik für laufende D&D-Sessions
/// 
/// HINWEIS: Verwendet jetzt das neue SessionModelRepository und SceneModelRepository
class ActiveSessionViewModel extends ChangeNotifier {
  final SessionModelRepository _sessionRepository;
  final SceneModelRepository _sceneRepository;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // Session Daten
  Session _currentSession;
  Campaign _campaign;
  List<Scene> _scenes = [];

  // Loading States
  bool _isLoading = false;
  String? _error;

  // ============================================================================
  // GETTERS
  // ============================================================================

  Session get currentSession => _currentSession;
  Campaign get campaign => _campaign;
  List<Scene> get scenes => _scenes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository
  /// 
  ActiveSessionViewModel({
    required Session session,
    required Campaign campaign,
    SessionModelRepository? sessionRepository,
    SceneModelRepository? sceneRepository,
  }) : _currentSession = session,
       _campaign = campaign,
       _sessionRepository = sessionRepository ?? SessionModelRepository(DatabaseConnection.instance),
       _sceneRepository = sceneRepository ?? SceneModelRepository(DatabaseConnection.instance) {
    // Lade Scenes beim Initialisieren
    _loadScenes();
  }

  // ============================================================================
  // SCENE OPERATIONS
  // ============================================================================

  /// Lädt alle Scenes für die aktuelle Session
  Future<void> _loadScenes() async {
    await _executeWithErrorHandling(() async {
      final scenes = await _sceneRepository.findBySession(_currentSession.id);
      // Sortiere nach orderIndex
      _scenes = scenes..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      notifyListeners();
    });
  }

  /// Lädt Scenes neu
  Future<void> reloadScenes() async {
    await _loadScenes();
  }

  /// Erstellt eine neue Scene
  Future<void> createScene({
    required String name,
    String description = '',
    SceneType sceneType = SceneType.Exploration,
    Duration? estimatedDuration,
    Complexity? complexity,
  }) async {
    await _executeWithErrorHandling(() async {
      // Bestimme nächsten orderIndex
      final nextOrderIndex = _scenes.isEmpty ? 0 : _scenes.last.orderIndex + 1;

      final newScene = Scene(
        sessionId: _currentSession.id,
        orderIndex: nextOrderIndex,
        name: name,
        description: description,
        sceneType: sceneType,
        estimatedDuration: estimatedDuration,
        complexity: complexity,
      );

      await _sceneRepository.create(newScene);
      await _loadScenes();
    });
  }

  /// Aktualisiert eine Scene
  Future<void> updateScene(Scene updatedScene) async {
    await _executeWithErrorHandling(() async {
      await _sceneRepository.update(updatedScene);
      await _loadScenes();
    });
  }

  /// Löscht eine Scene
  Future<void> deleteScene(String sceneId) async {
    await _executeWithErrorHandling(() async {
      await _sceneRepository.delete(sceneId);
      await _loadScenes();
    });
  }

  /// Aktualisiert die Reihenfolge von Scenes
  Future<void> reorderScenes(List<Scene> newOrder) async {
    await _executeWithErrorHandling(() async {
      // Aktualisiere orderIndex für alle Scenes
      for (int i = 0; i < newOrder.length; i++) {
        final scene = newOrder[i];
        if (scene.orderIndex != i) {
          await _sceneRepository.updateOrderIndex(scene.id, i);
        }
      }
      await _loadScenes();
    });
  }

  /// Markiert eine Scene als abgeschlossen
  Future<void> markSceneCompleted(String sceneId, bool isCompleted) async {
    await _executeWithErrorHandling(() async {
      await _sceneRepository.updateCompletionStatus(sceneId, isCompleted);
      await _loadScenes();
    });
  }

  /// Setzt die aktive Scene
  Future<void> setActiveScene(String? sceneId) async {
    await _executeWithErrorHandling(() async {
      _currentSession = _currentSession.copyWith(
        activeSceneId: sceneId,
      );
      await _sessionRepository.update(_currentSession);
      notifyListeners();
    });
  }

  // ============================================================================
  // SESSION OPERATIONS
  // ============================================================================

  /// Fügt In-Game-Zeit zur Session hinzu über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository
  Future<void> addInGameTime(int minutesToAdd) async {
    await _executeWithErrorHandling(() async {
      _currentSession = _currentSession.copyWith(
        inGameTimeInMinutes: _currentSession.inGameTimeInMinutes + minutesToAdd,
      );
      
      await _sessionRepository.update(_currentSession);
      notifyListeners();
    });
  }

  /// Aktualisiert den Session-Titel über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository
  Future<void> updateSessionTitle(String newTitle) async {
    await _executeWithErrorHandling(() async {
      _currentSession = _currentSession.copyWith(
        title: newTitle,
      );
      
      await _sessionRepository.update(_currentSession);
      notifyListeners();
    });
  }

  /// Aktualisiert die Live-Notizen über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository
  Future<void> updateLiveNotes(String newNotes) async {
    await _executeWithErrorHandling(() async {
      _currentSession = _currentSession.copyWith(
        liveNotes: newNotes,
      );
      
      await _sessionRepository.update(_currentSession);
      notifyListeners();
    });
  }

  // ============================================================================
  // TIME MANAGEMENT
  // ============================================================================

  /// Formatiert die In-Game-Zeit für die Anzeige
  String getFormattedInGameTime() {
    final totalMinutes = _currentSession.inGameTimeInMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Gibt die In-Game-Zeit in Stunden zurück
  double get inGameTimeInHours {
    return _currentSession.inGameTimeInMinutes / 60.0;
  }

  // ============================================================================
  // ERROR HANDLING
  // ============================================================================

  /// Führt eine Operation mit Error Handling durch
  Future<T> _executeWithErrorHandling<T>(Future<T> Function() operation) async {
    try {
      _error = null;
      notifyListeners();
      
      return await operation();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Löscht den Fehler-Zustand
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================================
  // DATA RELOAD TRIGGER
  // ============================================================================

  /// Signalisiert dass Daten neu geladen werden sollen
  void triggerDataReload() {
    notifyListeners();
  }

  // ============================================================================
  // DISPOSE
  // ============================================================================

  @override
  void dispose() {
    super.dispose();
  }
}
