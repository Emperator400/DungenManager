import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/core/database_connection.dart';

/// ViewModel für aktive Sessions mit neuer Repository-Architektur
/// Zentralisiert State Management und Business-Logik für laufende D&D-Sessions
/// 
/// HINWEIS: Verwendet jetzt das neue SessionModelRepository
class ActiveSessionViewModel extends ChangeNotifier {
  final SessionModelRepository _sessionRepository;

  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // Session Daten
  Session _currentSession;
  Campaign _campaign;

  // Loading States
  bool _isLoading = false;
  String? _error;

  // ============================================================================
  // GETTERS
  // ============================================================================

  Session get currentSession => _currentSession;
  Campaign get campaign => _campaign;
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
  }) : _currentSession = session,
       _campaign = campaign,
       _sessionRepository = sessionRepository ?? SessionModelRepository(DatabaseConnection.instance);

  // ============================================================================
  // SESSION OPERATIONS
  // ============================================================================

  /// Fügt In-Game-Zeit zur Session hinzu über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue SessionModelRepository
  Future<void> addInGameTime(int minutesToAdd) async {
    await _executeWithErrorHandling(() async {
      _currentSession = Session(
        id: _currentSession.id,
        campaignId: _currentSession.campaignId,
        title: _currentSession.title,
        inGameTimeInMinutes: _currentSession.inGameTimeInMinutes + minutesToAdd,
        liveNotes: _currentSession.liveNotes,
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
      _currentSession = Session(
        id: _currentSession.id,
        campaignId: _currentSession.campaignId,
        title: newTitle,
        inGameTimeInMinutes: _currentSession.inGameTimeInMinutes,
        liveNotes: _currentSession.liveNotes,
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
      _currentSession = Session(
        id: _currentSession.id,
        campaignId: _currentSession.campaignId,
        title: _currentSession.title,
        inGameTimeInMinutes: _currentSession.inGameTimeInMinutes,
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
