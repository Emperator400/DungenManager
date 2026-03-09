import 'package:flutter/foundation.dart';
import '../models/scene.dart';
import '../models/creature.dart';
import '../models/quest.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/creature_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../services/exceptions/service_exceptions.dart';

/// ViewModel für die Scene-Bearbeitung mit Provider-Pattern
class EditSceneViewModel extends ChangeNotifier {
  final SceneModelRepository _sceneRepository;
  final CreatureModelRepository _creatureRepository;
  final PlayerCharacterModelRepository _playerCharacterRepository;
  
  // State Management
  Scene? _scene;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Character/Creature State
  List<Creature> _availableCreatures = [];
  List<Map<String, dynamic>> _availablePlayerCharacters = [];
  List<Map<String, dynamic>> _linkedCharacters = [];
  
  // Trackt ob die Scene aus der Datenbank geladen wurde (bearbeiten) oder neu erstellt (erstellen)
  bool _isEditingExistingScene = false;

  // Getter
  Scene? get scene => _scene;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isEditing => _isEditingExistingScene;
  bool get canSave => _scene != null && _hasValidScene();
  List<Creature> get availableCreatures => _availableCreatures;
  List<Map<String, dynamic>> get availablePlayerCharacters => _availablePlayerCharacters;
  List<Map<String, dynamic>> get linkedCharacters => _linkedCharacters;
  List<Quest> get availableQuests => _availableQuests;
  List<Quest> get linkedQuests => _linkedQuests;

  final QuestModelRepository _questRepository;
  
  // Quest State
  List<Quest> _availableQuests = [];
  List<Quest> _linkedQuests = [];

  EditSceneViewModel({
    required SceneModelRepository sceneRepository,
    required CreatureModelRepository creatureRepository,
    required PlayerCharacterModelRepository playerCharacterRepository,
    required QuestModelRepository questRepository,
  }) : _sceneRepository = sceneRepository,
       _creatureRepository = creatureRepository,
       _playerCharacterRepository = playerCharacterRepository,
       _questRepository = questRepository;

  /// Initialisiert das ViewModel mit einer Scene oder erstellt eine neue
  Future<void> initialize(Scene? scene, {String? sessionId}) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (scene != null) {
        // Bearbeiten einer existierenden Scene
        _scene = scene;
        _isEditingExistingScene = true;
        print('✏️ [EditSceneViewModel] Initialisiere als BEARBEITEN (existierende Scene)');
      } else if (sessionId != null) {
        // Erstellen einer neuen Scene
        _isEditingExistingScene = false;
        
        // Hole den aktuellen orderIndex für neue Szenen
        final sessionScenes = await _sceneRepository.findBySession(sessionId);
        final maxOrderIndex = sessionScenes.isEmpty 
            ?0 
            : sessionScenes.map((s) => s.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
        
        _scene = Scene(
          sessionId: sessionId,
          orderIndex: maxOrderIndex,
          name: '',
          description: '',
        );
        print('➕ [EditSceneViewModel] Initialisiere als NEU (neue Scene)');
      } else {
        // Fallback: Neue Scene ohne sessionId
        _isEditingExistingScene = false;
        _scene = Scene(
          sessionId: 'default',
          orderIndex: 0,
          name: '',
          description: '',
        );
        print('➕ [EditSceneViewModel] Initialisiere als NEU (Fallback ohne sessionId)');
      }
      
      _resetUnsavedChanges();
      notifyListeners();
    } catch (e) {
      _setError('Initialisierung fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Speichert die aktuelle Scene
  Future<bool> saveScene() async {
    print('💾 [EditSceneViewModel] saveScene() aufgerufen');
    print('💾 [EditSceneViewModel] Scene: $_scene');
    print('💾 [EditSceneViewModel] isEditing: $isEditing');
    print('💾 [EditSceneViewModel] hasValidScene: ${_hasValidScene()}');
    
    if (_scene == null || !_hasValidScene()) {
      print('❌ [EditSceneViewModel] Ungültige Scene-Daten');
      _setError('Ungültige Scene-Daten');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      print('✅ [EditSceneViewModel] Starte Speichern...');
      
      // Aktualisiere updatedAt
      _scene = _scene!.copyWith(updatedAt: DateTime.now());
      
      // Speichern in der Datenbank
      if (isEditing) {
        print('✏️ [EditSceneViewModel] Aktualisiere existierende Scene...');
        final updatedScene = await _sceneRepository.update(_scene!);
        if (updatedScene != null) {
          _scene = updatedScene;
        }
        print('✅ [EditSceneViewModel] Scene aktualisiert');
      } else {
        print('➕ [EditSceneViewModel] Erstelle neue Scene...');
        final createdScene = await _sceneRepository.create(_scene!);
        if (createdScene != null) {
          _scene = createdScene;
        }
        print('✅ [EditSceneViewModel] Scene erstellt');
      }
      
      _resetUnsavedChanges();
      print('✅ [EditSceneViewModel] Speichern erfolgreich');
      return true;
    } catch (e) {
      print('❌ [EditSceneViewModel] FEHLER beim Speichern: $e');
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Speichern fehlgeschlagen: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Löscht die aktuelle Scene
  Future<bool> deleteScene() async {
    if (_scene == null) {
      _setError('Keine Scene zum Löschen vorhanden');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      await _sceneRepository.delete(_scene!.id);
      return true;
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Löschen fehlgeschlagen: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dupliziert die aktuelle Scene
  Future<void> duplicateScene() async {
    if (_scene == null) return;

    try {
      final duplicatedScene = _scene!.copyWith(
        name: '${_scene!.name} (Kopie)',
        isCompleted: false, // Duplikate sind standardmäßig nicht abgeschlossen
        updatedAt: DateTime.now(),
      );
      
      _scene = duplicatedScene;
      _markAsUnsaved();
      notifyListeners();
    } catch (e) {
      _setError('Duplizieren fehlgeschlagen: ${e.toString()}');
    }
  }

  // Update-Methoden für einzelne Felder
  void updateName(String name) {
    if (_scene?.name != name) {
      _scene = _scene?.copyWith(name: name, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateDescription(String description) {
    if (_scene?.description != description) {
      _scene = _scene?.copyWith(description: description, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateSceneType(SceneType sceneType) {
    if (_scene?.sceneType != sceneType) {
      _scene = _scene?.copyWith(sceneType: sceneType, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateIsCompleted(bool isCompleted) {
    if (_scene?.isCompleted != isCompleted) {
      _scene = _scene?.copyWith(isCompleted: isCompleted, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateEstimatedDuration(Duration? duration) {
    if (_scene?.estimatedDuration != duration) {
      _scene = _scene?.copyWith(estimatedDuration: duration, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateComplexity(Complexity? complexity) {
    if (_scene?.complexity != complexity) {
      _scene = _scene?.copyWith(complexity: complexity, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateOrderIndex(int orderIndex) {
    if (_scene?.orderIndex != orderIndex) {
      _scene = _scene?.copyWith(orderIndex: orderIndex, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateLinkedWikiEntries(List<String> wikiEntryIds) {
    if (_scene?.linkedWikiEntryIds != wikiEntryIds) {
      _scene = _scene?.copyWith(linkedWikiEntryIds: wikiEntryIds, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateLinkedQuests(List<String> questIds) {
    if (_scene?.linkedQuestIds != questIds) {
      _scene = _scene?.copyWith(linkedQuestIds: questIds, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateLinkedCharacters(List<String> characterIds) {
    if (_scene?.linkedCharacterIds != characterIds) {
      _scene = _scene?.copyWith(linkedCharacterIds: characterIds, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateLinkedEncounter(String? encounterId) {
    if (_scene?.linkedEncounterId != encounterId) {
      _scene = _scene?.copyWith(linkedEncounterId: encounterId, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  /// Lädt alle verfügbaren Creatures (NPCs und Monster)
  Future<void> loadAvailableCreatures() async {
    try {
      final creatures = await _creatureRepository.findAll();
      _availableCreatures = creatures;
      notifyListeners();
    } catch (e) {
      _setError('Laden der Creatures fehlgeschlagen: ${e.toString()}');
    }
  }

  /// Lädt alle verfügbaren Player Characters
  Future<void> loadAvailablePlayerCharacters() async {
    try {
      final pcs = await _playerCharacterRepository.findAll();
      _availablePlayerCharacters = pcs.map((pc) => {
        'id': pc.id,
        'name': pc.name,
        'type': 'PC',
        'level': pc.level,
      }).toList();
      notifyListeners();
    } catch (e) {
      _setError('Laden der Player Characters fehlgeschlagen: ${e.toString()}');
    }
  }

  /// Baut die Liste der verknüpften Charaktere mit Details auf
  Future<void> buildLinkedCharactersList() async {
    if (_scene == null) return;
    
    try {
      _linkedCharacters = [];
      
      for (final charId in _scene!.linkedCharacterIds) {
        // Prüfe zuerst ob es ein PC ist
        try {
          final pc = await _playerCharacterRepository.findById(charId);
          if (pc != null) {
            _linkedCharacters.add({
              'id': pc.id,
              'name': pc.name,
              'type': 'PC',
              'level': pc.level,
            });
            continue;
          }
        } catch (e) {
          // Kein PC, versuche Creature
        }
        
        // Prüfe ob es ein Creature ist
        try {
          final creature = await _creatureRepository.findById(charId);
          if (creature != null) {
            _linkedCharacters.add({
              'id': creature.id,
              'name': creature.name,
              'type': creature.isPlayer ? 'PC' : 'Creature',
              'challengeRating': creature.challengeRating,
              'isPlayer': creature.isPlayer,
            });
          }
        } catch (e) {
          // Fehler beim Laden, überspringen
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Laden der verknüpften Charaktere fehlgeschlagen: ${e.toString()}');
    }
  }

  /// Fügt einen einzelnen Charakter zur Szene hinzu
  Future<void> addCharacter(String characterId) async {
    if (_scene == null) return;
    
    final currentIds = List<String>.from(_scene!.linkedCharacterIds);
    if (!currentIds.contains(characterId)) {
      currentIds.add(characterId);
      updateLinkedCharacters(currentIds);
      await buildLinkedCharactersList();
    }
  }

  /// Entfernt einen einzelnen Charakter aus der Szene
  Future<void> removeCharacter(String characterId) async {
    if (_scene == null) return;
    
    final currentIds = List<String>.from(_scene!.linkedCharacterIds);
    currentIds.remove(characterId);
    updateLinkedCharacters(currentIds);
    await buildLinkedCharactersList();
  }

  /// ===== QUEST METHODEN =====

  /// Lädt alle verfügbaren Quests
  Future<void> loadAvailableQuests() async {
    try {
      final quests = await _questRepository.findAll();
      _availableQuests = quests;
      notifyListeners();
    } catch (e) {
      _setError('Laden der Quests fehlgeschlagen: ${e.toString()}');
    }
  }

  /// Baut die Liste der verknüpften Quests mit Details auf
  Future<void> buildLinkedQuestsList() async {
    if (_scene == null) return;
    
    try {
      _linkedQuests = [];
      
      for (final questId in _scene!.linkedQuestIds) {
        try {
          final quest = await _questRepository.findById(questId);
          if (quest != null) {
            _linkedQuests.add(quest);
          }
        } catch (e) {
          // Fehler beim Laden, überspringen
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Laden der verknüpften Quests fehlgeschlagen: ${e.toString()}');
    }
  }

  /// Fügt einen einzelnen Quest zur Szene hinzu
  Future<void> addQuest(String questId) async {
    if (_scene == null) return;
    
    final currentIds = List<String>.from(_scene!.linkedQuestIds);
    if (!currentIds.contains(questId)) {
      currentIds.add(questId);
      updateLinkedQuests(currentIds);
      await buildLinkedQuestsList();
    }
  }

  /// Entfernt einen einzelnen Quest aus der Szene
  Future<void> removeQuest(String questId) async {
    if (_scene == null) return;
    
    final currentIds = List<String>.from(_scene!.linkedQuestIds);
    currentIds.remove(questId);
    updateLinkedQuests(currentIds);
    await buildLinkedQuestsList();
  }

  /// Setzt die Änderungen zurück
  void resetChanges() async {
    if (_scene != null && isEditing) {
      // In einer echten Implementierung würden wir die Original-Daten neu laden
      _clearError();
      _resetUnsavedChanges();
      notifyListeners();
    }
  }

  /// Löscht die Fehlermeldung
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private Helper-Methoden
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _markAsUnsaved() {
    _hasUnsavedChanges = true;
  }

  void _resetUnsavedChanges() {
    _hasUnsavedChanges = false;
  }

  bool _hasValidScene() {
    if (_scene == null) return false;
    
    // Grundlegende Validierung
    return _scene!.name.trim().isNotEmpty && _scene!.sessionId.isNotEmpty;
  }
}
