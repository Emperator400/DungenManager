import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../models/scene.dart';
import '../models/sound.dart';
import '../models/wiki_entry.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/sound_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/core/database_connection.dart';
import '../services/scene_service.dart';
import '../services/sound_service.dart';

/// ViewModel für aktive Sessions mit neuer Repository-Architektur
/// Zentralisiert State Management und Business-Logik für laufende D&D-Sessions
/// 
/// HINWEIS: Verwendet jetzt das neue SessionModelRepository und SceneModelRepository
/// HINWEIS: Verwendet SceneService für Scene-Centric Workflow (Encounter/Character Links, Quest Status)
class ActiveSessionViewModel extends ChangeNotifier {
  final SessionModelRepository _sessionRepository;
  final SceneModelRepository _sceneRepository;
  final SceneService _sceneService;
  final SoundModelRepository _soundRepository;
  final SoundService _soundService;
  final WikiEntryModelRepository _wikiRepository;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // Session Daten
  Session _currentSession;
  Campaign _campaign;
  List<Scene> _scenes = [];
  List<Sound> _sessionSounds = [];

  // Wiki Cache für schnellen Zugriff
  final Map<String, WikiEntry> _wikiCache = {};

  // Loading States
  bool _isLoading = false;
  String? _error;

  // ============================================================================
  // GETTERS
  // ============================================================================

  Session get currentSession => _currentSession;
  Campaign get campaign => _campaign;
  List<Scene> get scenes => _scenes;
  List<Sound> get sessionSounds => _sessionSounds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository und SceneService
  /// 
  ActiveSessionViewModel({
    required Session session,
    required Campaign campaign,
    SessionModelRepository? sessionRepository,
    SceneModelRepository? sceneRepository,
    SceneService? sceneService,
    SoundModelRepository? soundRepository,
    SoundService? soundService,
    WikiEntryModelRepository? wikiRepository,
  }) : _currentSession = session,
       _campaign = campaign,
       _sessionRepository = sessionRepository ?? SessionModelRepository(DatabaseConnection.instance),
       _sceneRepository = sceneRepository ?? SceneModelRepository(DatabaseConnection.instance),
       _sceneService = sceneService ?? SceneService(DatabaseConnection.instance),
       _soundRepository = soundRepository ?? SoundModelRepository(DatabaseConnection.instance),
       _soundService = soundService ?? SoundService(),
       _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance) {
    // Lade Scenes beim Initialisieren
    _loadScenes();
    _loadSessionSounds();
  }

  // ============================================================================
  // SCENE OPERATIONS
  // ============================================================================

  /// Lädt alle Scenes für die aktuelle Session
  Future<void> _loadScenes() async {
    print('🔄 [ActiveSessionViewModel] _loadScenes() aufgerufen für Session: ${_currentSession.id}');
    await _executeWithErrorHandling(() async {
      _setLoading(true);
      print('📊 [ActiveSessionViewModel] Rufe findBySession auf...');
      final scenes = await _sceneRepository.findBySession(_currentSession.id);
      print('✅ [ActiveSessionViewModel] ${scenes.length} Scenes geladen');
      // Sortiere nach orderIndex
      _scenes = scenes..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      _setLoading(false);
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

  /// Fügt einen Sound zu einer Scene hinzu (z.B. vom Sound Mixer)
  Future<void> addSoundToScene(String sceneId, String soundId) async {
    await _executeWithErrorHandling(() async {
      final sceneIndex = _scenes.indexWhere((s) => s.id == sceneId);
      if (sceneIndex != -1) {
        final scene = _scenes[sceneIndex];
        final currentSounds = scene.linkedSoundIds.toList();
        if (!currentSounds.contains(soundId)) {
          currentSounds.add(soundId);
          await _sceneRepository.update(scene.copyWith(linkedSoundIds: currentSounds));
          await _loadScenes();
        }
      }
    });
  }

  /// Entfernt einen Sound aus einer Scene (z.B. vom Sound Mixer)
  Future<void> removeSoundFromScene(String sceneId, String soundId) async {
    await _executeWithErrorHandling(() async {
      final sceneIndex = _scenes.indexWhere((s) => s.id == sceneId);
      if (sceneIndex != -1) {
        final scene = _scenes[sceneIndex];
        final currentSounds = scene.linkedSoundIds.toList();
        if (currentSounds.contains(soundId)) {
          currentSounds.remove(soundId);
          await _sceneRepository.update(scene.copyWith(linkedSoundIds: currentSounds));
          await _loadScenes();
        }
      }
    });
  }

  /// Aktualisiert die komplette Liste der verknüpften Sounds einer Szene
  Future<void> updateSceneSounds(String sceneId, List<String> soundIds) async {
    await _executeWithErrorHandling(() async {
      final sceneIndex = _scenes.indexWhere((s) => s.id == sceneId);
      if (sceneIndex != -1) {
        final scene = _scenes[sceneIndex];
        await _sceneRepository.update(scene.copyWith(linkedSoundIds: soundIds));
        await _loadScenes();
      }
    });
  }

  /// Aktualisiert die Lautstärken der verknüpften Sounds einer Szene
  Future<void> updateSceneSoundVolumes(String sceneId, Map<String, double> volumes) async {
    await _executeWithErrorHandling(() async {
      final sceneIndex = _scenes.indexWhere((s) => s.id == sceneId);
      if (sceneIndex != -1) {
        final scene = _scenes[sceneIndex];
        
        await _sceneRepository.update(scene.copyWith(soundVolumes: volumes));
        
        await _loadScenes(); // Lade Szenen neu, um die Änderungen zu reflektieren
      }
    });
  }

  // ============================================================================
  // SCENE WORKFLOW OPERATIONS (über SceneService)
  // ============================================================================

  /// Aktiviert eine Scene - setzt sie als aktiv und aktiviert ihre Quests
  Future<void> activateScene(String sceneId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.activateScene(sceneId);
      await _loadScenes();
    });
  }

  /// Schließt eine Scene ab - schließt auch alle aktiven Quests und Encounters
  Future<void> completeScene(String sceneId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.completeScene(sceneId);
      await _loadScenes();
    });
  }

  /// Verknüpft einen Encounter mit einer Scene
  Future<void> linkEncounter(String sceneId, String encounterId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.linkEncounter(sceneId, encounterId);
      await _loadScenes();
    });
  }

  /// Entfernt die Encounter-Verknüpfung einer Scene
  Future<void> unlinkEncounter(String sceneId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.unlinkEncounter(sceneId);
      await _loadScenes();
    });
  }

  /// Fügt einen Charakter zu einer Scene hinzu
  Future<void> addCharacterToScene(String sceneId, String characterId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.addCharacterToScene(sceneId, characterId);
      await _loadScenes();
    });
  }

  /// Entfernt einen Charakter aus einer Scene
  Future<void> removeCharacterFromScene(String sceneId, String characterId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.removeCharacterFromScene(sceneId, characterId);
      await _loadScenes();
    });
  }

  /// Verschiebt eine Scene nach oben
  Future<void> moveSceneUp(String sceneId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.moveSceneUp(sceneId);
      await _loadScenes();
    });
  }

  /// Verschiebt eine Scene nach unten
  Future<void> moveSceneDown(String sceneId) async {
    await _executeWithErrorHandling(() async {
      await _sceneService.moveSceneDown(sceneId);
      await _loadScenes();
    });
  }

  // ============================================================================
  // SESSION SOUND OPERATIONS
  // ============================================================================

  /// Lädt alle Sounds aus der Datenbank
  Future<List<Sound>> loadAllSounds() async {
    try {
      return await _soundRepository.findAll();
    } catch (e) {
      print('Fehler beim Laden der Sounds: $e');
      return [];
    }
  }

  /// Lädt die verknüpften Sounds der aktuellen Session
  Future<void> _loadSessionSounds() async {
    try {
      if (_currentSession.linkedSoundIds.isEmpty) {
        _sessionSounds = [];
        notifyListeners();
        return;
      }
      final allSounds = await loadAllSounds();
      _sessionSounds = allSounds.where((sound) => _currentSession.linkedSoundIds.contains(sound.id)).toList();
      notifyListeners();
    } catch (e) {
      print('Fehler beim Laden der Session-Sounds: $e');
    }
  }

  /// Fügt einen Sound zur Session hinzu
  Future<void> addSoundToSession(String soundId) async {
    await _executeWithErrorHandling(() async {
      final currentSounds = _currentSession.linkedSoundIds.toList();
      if (!currentSounds.contains(soundId)) {
        currentSounds.add(soundId);
        _currentSession = _currentSession.copyWith(
          linkedSoundIds: currentSounds,
        );
        await _sessionRepository.update(_currentSession);
        await _loadSessionSounds();
        notifyListeners();
      }
    });
  }

  /// Entfernt einen Sound aus der Session
  Future<void> removeSoundFromSession(String soundId) async {
    await _executeWithErrorHandling(() async {
      final currentSounds = _currentSession.linkedSoundIds.toList();
      currentSounds.remove(soundId);
      _currentSession = _currentSession.copyWith(
        linkedSoundIds: currentSounds,
      );
      await _sessionRepository.update(_currentSession);
      await _loadSessionSounds();
      notifyListeners();
    });
  }

  /// Spielt einen Sound ab (für Session-Musik)
  Future<void> playSessionSound(String soundId, String filePath) async {
    try {
      await SoundService.playSound(filePath);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Abspielen des Sounds: $e');
      rethrow;
    }
  }

  /// Pausiert den aktuellen Sound
  Future<void> pauseSessionSound() async {
    try {
      await SoundService.pauseSound();
      notifyListeners();
    } catch (e) {
      print('Fehler beim Pausieren: $e');
    }
  }

  /// Stoppt den aktuellen Sound
  Future<void> stopSessionSound() async {
    try {
      await SoundService.stopSound();
      notifyListeners();
    } catch (e) {
      print('Fehler beim Stoppen: $e');
    }
  }

  /// Setzt die Lautstärke
  Future<void> setSessionVolume(double volume) async {
    try {
      await SoundService.setVolume(volume);
      notifyListeners();
    } catch (e) {
      print('Fehler beim Setzen der Lautstärke: $e');
    }
  }

  /// Prüft ob gerade ein Sound läuft
  Future<bool> getIsPlaying() async {
    return await SoundService.isPlaying();
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
    print('📝 [ActiveSessionViewModel] updateLiveNotes aufgerufen');
    print('📝 [ActiveSessionViewModel] Session ID: ${_currentSession.id}');
    print('📝 [ActiveSessionViewModel] Neue Notizen Länge: ${newNotes.length}');
    
    await _executeWithErrorHandling(() async {
      _currentSession = _currentSession.copyWith(
        liveNotes: newNotes,
      );
      
      print('📝 [ActiveSessionViewModel] Speichere in Datenbank...');
      final updatedSession = await _sessionRepository.update(_currentSession);
      print('📝 [ActiveSessionViewModel] Gespeichert! LiveNotes aus DB: "${updatedSession.liveNotes}"');
      
      _currentSession = updatedSession;
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

  /// Setzt den Loading-Status
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
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

  /// Lädt alle Daten neu (Scenes und Session)
  Future<void> triggerDataReload() async {
    await _loadScenes();
    await _loadSessionSounds();
  }

  /// Lädt die Session-Daten neu aus der Datenbank
  Future<void> reloadSession() async {
    print('🔄 [ActiveSessionViewModel] reloadSession aufgerufen');
    await _executeWithErrorHandling(() async {
      final freshSession = await _sessionRepository.findById(_currentSession.id);
      if (freshSession != null) {
        print('🔄 [ActiveSessionViewModel] Session neu geladen, LiveNotes: "${freshSession.liveNotes}"');
        _currentSession = freshSession;
        await _loadSessionSounds();
        notifyListeners();
      } else {
        print('⚠️ [ActiveSessionViewModel] Session nicht in DB gefunden!');
      }
    });
  }

  // ============================================================================
  // WIKI ENTRY OPERATIONS
  // ============================================================================

  /// Lädt einen Wiki-Eintrag per ID (mit Caching)
  Future<WikiEntry?> getWikiEntryById(String id) async {
    // Prüfe Cache zuerst
    if (_wikiCache.containsKey(id)) {
      return _wikiCache[id];
    }

    try {
      final entry = await _wikiRepository.findById(id);
      if (entry != null) {
        _wikiCache[id] = entry;
      }
      return entry;
    } catch (e) {
      print('Fehler beim Laden des Wiki-Eintrags: $e');
      return null;
    }
  }

  /// Lädt mehrere Wiki-Einträge per IDs (mit Caching)
  Future<List<WikiEntry>> getWikiEntriesByIds(List<String> ids) async {
    final entries = <WikiEntry>[];
    
    for (final id in ids) {
      final entry = await getWikiEntryById(id);
      if (entry != null) {
        entries.add(entry);
      }
    }
    
    return entries;
  }

  /// Lädt alle Wiki-Einträge für eine Szene
  Future<List<WikiEntry>> getWikiEntriesForScene(Scene scene) async {
    if (scene.linkedWikiEntryIds.isEmpty) {
      return [];
    }
    return await getWikiEntriesByIds(scene.linkedWikiEntryIds);
  }

  /// Löscht den Wiki-Cache
  void clearWikiCache() {
    _wikiCache.clear();
  }

  // ============================================================================
  // DISPOSE
  // ============================================================================

  @override
  void dispose() {
    _wikiCache.clear();
    super.dispose();
  }
}
