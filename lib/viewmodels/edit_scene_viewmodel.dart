import 'package:flutter/foundation.dart';
import '../models/scene.dart';
import '../services/exceptions/service_exceptions.dart';

/// ViewModel für die Scene-Bearbeitung mit Provider-Pattern
class EditSceneViewModel extends ChangeNotifier {
  // State Management
  Scene? _scene;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Getter
  Scene? get scene => _scene;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isEditing => _scene != null;
  bool get canSave => _scene != null && _hasValidScene();

  /// Initialisiert das ViewModel mit einer Scene oder erstellt eine neue
  Future<void> initialize(Scene? scene, {String? sessionId}) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (scene != null) {
        _scene = scene;
      } else {
        _scene = Scene(
          sessionId: sessionId ?? 'default',
          orderIndex: 0,
          name: '',
          description: '',
        );
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
    if (_scene == null || !_hasValidScene()) {
      _setError('Ungültige Scene-Daten');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
      
      _resetUnsavedChanges();
      return true;
    } catch (e) {
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
      
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
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
    return _scene!.name.trim().isNotEmpty;
  }

  /// Simuliert eine Datenbankoperation
  Future<void> _simulateDatabaseOperation() async {
    // Simuliere Netzwerkverzögerung
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
