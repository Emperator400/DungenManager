import 'package:flutter/foundation.dart';
import '../models/wiki_entry.dart';
import '../services/exceptions/service_exceptions.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für die WikiEntry-Bearbeitung mit neuer Repository-Architektur
/// 
/// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
class EditWikiEntryViewModel extends ChangeNotifier {
  final WikiEntryModelRepository _wikiRepository;

  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  /// 
  EditWikiEntryViewModel({WikiEntryModelRepository? wikiRepository})
      : _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance);
  // State Management
  WikiEntry? _wikiEntry;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Getter
  WikiEntry? get wikiEntry => _wikiEntry;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isEditing => _wikiEntry != null;
  bool get canSave => _wikiEntry != null && _hasValidWikiEntry();

  /// Initialisiert das ViewModel mit einem WikiEntry oder erstellt einen neuen
  Future<void> initialize(WikiEntry? wikiEntry) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (wikiEntry != null) {
        _wikiEntry = wikiEntry;
      } else {
        _wikiEntry = WikiEntry.create(
          title: '',
          content: '',
          entryType: WikiEntryType.Lore,
          tags: [],
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

  /// Speichert den aktuellen WikiEntry über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue WikiEntryModelRepository
  Future<bool> saveWikiEntry() async {
    if (_wikiEntry == null || !_hasValidWikiEntry()) {
      _setError('Ungültige WikiEntry-Daten');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      if (_wikiEntry!.id.isEmpty) {
        // Create new wiki entry
        final savedWikiEntry = await _wikiRepository.create(_wikiEntry!);
        if (savedWikiEntry != null) {
          _wikiEntry = savedWikiEntry;
        }
      } else {
        // Update existing wiki entry
        final updatedWikiEntry = await _wikiRepository.update(_wikiEntry!);
        if (updatedWikiEntry != null) {
          _wikiEntry = updatedWikiEntry;
        }
      }
      
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

  /// Löscht den aktuellen WikiEntry über neues Repository
  Future<bool> deleteWikiEntry() async {
    if (_wikiEntry == null || _wikiEntry!.id.isEmpty) {
      _setError('Kein WikiEntry zum Löschen vorhanden');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      await _wikiRepository.delete(_wikiEntry!.id);
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

  /// Dupliziert den aktuellen WikiEntry
  Future<void> duplicateWikiEntry() async {
    if (_wikiEntry == null) return;

    try {
      final duplicatedWikiEntry = _wikiEntry!.copyWith(
        title: '${_wikiEntry!.title} (Kopie)',
        updatedAt: DateTime.now(),
      );
      
      _wikiEntry = duplicatedWikiEntry;
      _markAsUnsaved();
      notifyListeners();
    } catch (e) {
      _setError('Duplizieren fehlgeschlagen: ${e.toString()}');
    }
  }

  // Update-Methoden für einzelne Felder
  void updateTitle(String title) {
    if (_wikiEntry?.title != title) {
      _wikiEntry = _wikiEntry?.copyWith(title: title, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateContent(String content) {
    if (_wikiEntry?.content != content) {
      _wikiEntry = _wikiEntry?.copyWith(content: content, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateTags(List<String> tags) {
    if (_wikiEntry?.tags != tags) {
      _wikiEntry = _wikiEntry?.copyWith(tags: tags, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateEntryType(WikiEntryType entryType) {
    if (_wikiEntry?.entryType != entryType) {
      _wikiEntry = _wikiEntry?.copyWith(entryType: entryType, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateImageUrl(String? imageUrl) {
    if (_wikiEntry?.imageUrl != imageUrl) {
      _wikiEntry = _wikiEntry?.copyWith(imageUrl: imageUrl, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateCampaignId(String? campaignId) {
    if (_wikiEntry?.campaignId != campaignId) {
      _wikiEntry = _wikiEntry?.copyWith(campaignId: campaignId, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateIsMarkdown(bool isMarkdown) {
    if (_wikiEntry?.isMarkdown != isMarkdown) {
      _wikiEntry = _wikiEntry?.copyWith(isMarkdown: isMarkdown, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateIsFavorite(bool isFavorite) {
    if (_wikiEntry?.isFavorite != isFavorite) {
      _wikiEntry = _wikiEntry?.copyWith(isFavorite: isFavorite, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void addTag(String tag) {
    if (_wikiEntry == null) return;
    
    final currentTags = List<String>.from(_wikiEntry!.tags);
    if (!currentTags.contains(tag)) {
      currentTags.add(tag);
      updateTags(currentTags);
    }
  }

  void removeTag(String tag) {
    if (_wikiEntry == null) return;
    
    final currentTags = List<String>.from(_wikiEntry!.tags);
    currentTags.remove(tag);
    updateTags(currentTags);
  }

  /// Setzt die Änderungen zurück
  void resetChanges() async {
    if (_wikiEntry != null && isEditing) {
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

  bool _hasValidWikiEntry() {
    if (_wikiEntry == null) return false;
    
    // Grundlegende Validierung
    return _wikiEntry!.title.trim().isNotEmpty && 
           _wikiEntry!.content.trim().isNotEmpty;
  }

  /// Simuliert eine Datenbankoperation
  Future<void> _simulateDatabaseOperation() async {
    // Simuliere Netzwerkverzögerung
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
