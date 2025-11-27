import 'package:flutter/foundation.dart';
import '../models/sound.dart';
import '../services/exceptions/service_exceptions.dart';

/// ViewModel für die Sound-Bearbeitung mit Provider-Pattern
class EditSoundViewModel extends ChangeNotifier {
  // State Management
  Sound? _sound;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Getter
  Sound? get sound => _sound;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isEditing => _sound != null;
  bool get canSave => _sound != null && _hasValidSound();

  /// Initialisiert das ViewModel mit einem Sound oder erstellt einen neuen
  Future<void> initialize(Sound? sound) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (sound != null) {
        _sound = sound;
      } else {
        _sound = Sound(
          name: '',
          filePath: '',
          soundType: SoundType.Ambiente,
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

  /// Speichert den aktuellen Sound
  Future<bool> saveSound() async {
    if (_sound == null || !_hasValidSound()) {
      _setError('Ungültige Sound-Daten');
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

  /// Löscht den aktuellen Sound
  Future<bool> deleteSound() async {
    if (_sound == null) {
      _setError('Kein Sound zum Löschen vorhanden');
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

  /// Dupliziert den aktuellen Sound
  Future<void> duplicateSound() async {
    if (_sound == null) return;

    try {
      final duplicatedSound = Sound(
        name: '${_sound!.name} (Kopie)',
        filePath: _sound!.filePath,
        description: _sound!.description,
        duration: _sound!.duration,
        soundType: _sound!.soundType,
        tags: _sound!.tags,
      );
      
      _sound = duplicatedSound;
      _markAsUnsaved();
      notifyListeners();
    } catch (e) {
      _setError('Duplizieren fehlgeschlagen: ${e.toString()}');
    }
  }

  // Update-Methoden für einzelne Felder
  void updateName(String name) {
    if (_sound?.name != name) {
      _sound = _sound!.copyWith(name: name, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateFilePath(String filePath) {
    if (_sound?.filePath != filePath) {
      _sound = _sound!.copyWith(filePath: filePath, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateDescription(String description) {
    if (_sound?.description != description) {
      _sound = _sound!.copyWith(description: description, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateDuration(Duration? duration) {
    if (_sound?.duration != duration) {
      _sound = _sound!.copyWith(duration: duration, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateSoundType(SoundType soundType) {
    if (_sound?.soundType != soundType) {
      _sound = _sound!.copyWith(soundType: soundType, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateTags(String? tags) {
    if (_sound?.tags != tags) {
      _sound = _sound!.copyWith(tags: tags, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void addTag(String tag) {
    if (_sound == null) return;
    
    final currentTags = _sound!.tagList.toList();
    if (!currentTags.contains(tag)) {
      currentTags.add(tag);
      updateTags(currentTags.join(','));
    }
  }

  void removeTag(String tag) {
    if (_sound == null) return;
    
    final currentTags = _sound!.tagList.toList();
    currentTags.remove(tag);
    updateTags(currentTags.join(','));
  }

  /// Setzt die Änderungen zurück
  void resetChanges() async {
    if (_sound != null && isEditing) {
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

  bool _hasValidSound() {
    if (_sound == null) return false;
    
    // Grundlegende Validierung
    return _sound!.name.trim().isNotEmpty && 
           _sound!.filePath.trim().isNotEmpty;
  }

  /// Simuliert eine Datenbankoperation
  Future<void> _simulateDatabaseOperation() async {
    // Simuliere Netzwerkverzögerung
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
