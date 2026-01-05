import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../services/exceptions/service_exceptions.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für die Session-Bearbeitung mit neuer Repository-Architektur
/// 
/// HINWEIS: Verwendet jetzt das neue SessionModelRepository
class EditSessionViewModel extends ChangeNotifier {
  final SessionModelRepository _sessionRepository;

  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository
  /// 
  EditSessionViewModel({SessionModelRepository? sessionRepository})
      : _sessionRepository = sessionRepository ?? SessionModelRepository(DatabaseConnection.instance);
  // State Management
  Session? _session;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Getter
  Session? get session => _session;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isEditing => _session != null;
  bool get canSave => _session != null && _hasValidSession();

  /// Initialisiert das ViewModel mit einer Session oder erstellt eine neue
  Future<void> initialize(Session? session) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (session != null) {
        _session = session;
      } else {
        _session = Session(
          title: '',
          campaignId: '',
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

  /// Speichert die aktuelle Session über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository
  Future<bool> saveSession() async {
    if (_session == null || !_hasValidSession()) {
      _setError('Ungültige Session-Daten');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      if (_session!.id.isEmpty) {
        // Create new session
        final savedSession = await _sessionRepository.create(_session!);
        if (savedSession != null) {
          _session = savedSession;
        }
      } else {
        // Update existing session
        final updatedSession = await _sessionRepository.update(_session!);
        if (updatedSession != null) {
          _session = updatedSession;
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

  /// Löscht die aktuelle Session über neues Repository
  Future<bool> deleteSession() async {
    if (_session == null || _session!.id.isEmpty) {
      _setError('Keine Session zum Löschen vorhanden');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      await _sessionRepository.delete(_session!.id);
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

  /// Dupliziert die aktuelle Session
  Future<void> duplicateSession() async {
    if (_session == null) return;

    try {
      final duplicatedSession = Session(
        title: '${_session!.title} (Kopie)',
        campaignId: _session!.campaignId,
        inGameTimeInMinutes: _session!.inGameTimeInMinutes,
        liveNotes: _session!.liveNotes,
      );
      
      _session = duplicatedSession;
      _markAsUnsaved();
      notifyListeners();
    } catch (e) {
      _setError('Duplizieren fehlgeschlagen: ${e.toString()}');
    }
  }

  // Update-Methoden für einzelne Felder
  void updateTitle(String title) {
    if (_session?.title != title) {
      _session = Session(
        id: _session!.id,
        title: title,
        campaignId: _session!.campaignId,
        inGameTimeInMinutes: _session!.inGameTimeInMinutes,
        liveNotes: _session!.liveNotes,
      );
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateCampaignId(String campaignId) {
    if (_session?.campaignId != campaignId) {
      _session = Session(
        id: _session!.id,
        title: _session!.title,
        campaignId: campaignId,
        inGameTimeInMinutes: _session!.inGameTimeInMinutes,
        liveNotes: _session!.liveNotes,
      );
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateInGameTimeInMinutes(int inGameTimeInMinutes) {
    if (_session?.inGameTimeInMinutes != inGameTimeInMinutes) {
      _session = Session(
        id: _session!.id,
        title: _session!.title,
        campaignId: _session!.campaignId,
        inGameTimeInMinutes: inGameTimeInMinutes,
        liveNotes: _session!.liveNotes,
      );
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateLiveNotes(String liveNotes) {
    if (_session?.liveNotes != liveNotes) {
      _session = Session(
        id: _session!.id,
        title: _session!.title,
        campaignId: _session!.campaignId,
        inGameTimeInMinutes: _session!.inGameTimeInMinutes,
        liveNotes: liveNotes,
      );
      _markAsUnsaved();
      notifyListeners();
    }
  }

  /// Setzt die Änderungen zurück
  void resetChanges() async {
    if (_session != null && isEditing) {
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

  bool _hasValidSession() {
    if (_session == null) return false;
    
    // Grundlegende Validierung
    return _session!.title.trim().isNotEmpty && 
           _session!.campaignId.trim().isNotEmpty;
  }

  /// Simuliert eine Datenbankoperation
  Future<void> _simulateDatabaseOperation() async {
    // Simuliere Netzwerkverzögerung
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
