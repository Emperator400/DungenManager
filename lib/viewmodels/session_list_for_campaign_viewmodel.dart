import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../services/exceptions/service_exceptions.dart';

/// ViewModel für die Session-Liste einer Kampagne mit Provider-Pattern
class SessionListForCampaignViewModel extends ChangeNotifier {
  // State Management
  Campaign? _campaign;
  List<Session> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getter
  Campaign? get campaign => _campaign;
  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSessions => _sessions.isNotEmpty;

  /// Initialisiert das ViewModel mit einer Kampagne
  Future<void> initialize(Campaign campaign) async {
    try {
      _setLoading(true);
      _clearError();
      _campaign = campaign;
      await _loadSessions();
    } catch (e) {
      _setError('Laden der Sessions fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Lädt die Sessions für die aktuelle Kampagne
  Future<void> _loadSessions() async {
    if (_campaign == null) return;

    try {
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
      
      // Simulierte Session-Daten
      _sessions = [
        Session(
          campaignId: _campaign!.id,
          title: 'Session 1: Der Beginn',
          inGameTimeInMinutes: 240,
          liveNotes: 'Erste Session der Kampagne',
        ),
        Session(
          campaignId: _campaign!.id,
          title: 'Session 2: Die erste Herausforderung',
          inGameTimeInMinutes: 300,
          liveNotes: 'Combat mit Goblins',
        ),
      ];
      
      notifyListeners();
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Laden fehlgeschlagen: ${e.toString()}');
      }
    }
  }

  /// Aktualisiert die Session-Liste
  Future<void> refreshSessions() async {
    await _loadSessions();
  }

  /// Erstellt eine neue Session
  Future<Session?> createSession({String? title}) async {
    if (_campaign == null) return null;

    try {
      _setLoading(true);
      _clearError();
      
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
      
      final newSession = Session(
        campaignId: _campaign!.id,
        title: title ?? 'Neue Session',
        inGameTimeInMinutes: 480, // 8 Stunden Standard
        liveNotes: '',
      );
      
      _sessions.insert(0, newSession);
      notifyListeners();
      return newSession;
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Erstellen fehlgeschlagen: ${e.toString()}');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Löscht eine Session
  Future<bool> deleteSession(String sessionId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
      
      _sessions.removeWhere((session) => session.id == sessionId);
      notifyListeners();
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

  /// Dupliziert eine Session
  Future<Session?> duplicateSession(Session session) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Simuliere Datenbankoperation
      await _simulateDatabaseOperation();
      
      final duplicatedSession = Session(
        campaignId: _campaign!.id,
        title: '${session.title} (Kopie)',
        inGameTimeInMinutes: session.inGameTimeInMinutes,
        liveNotes: session.liveNotes,
      );
      
      // Einfügen nach der Original-Session
      final originalIndex = _sessions.indexWhere((s) => s.id == session.id);
      if (originalIndex != -1) {
        _sessions.insert(originalIndex + 1, duplicatedSession);
      } else {
        _sessions.insert(0, duplicatedSession);
      }
      
      notifyListeners();
      return duplicatedSession;
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Duplizieren fehlgeschlagen: ${e.toString()}');
      }
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Sucht Sessions nach Titel
  List<Session> searchSessions(String query) {
    if (query.isEmpty) return sessions;
    
    return sessions.where((session) {
      return session.title.toLowerCase().contains(query.toLowerCase()) ||
             session.liveNotes.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Sortiert Sessions nach verschiedenen Kriterien
  void sortSessions(SessionSortCriteria criteria) {
    switch (criteria) {
      case SessionSortCriteria.titleAsc:
        _sessions.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SessionSortCriteria.titleDesc:
        _sessions.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SessionSortCriteria.durationAsc:
        _sessions.sort((a, b) => a.inGameTimeInMinutes.compareTo(b.inGameTimeInMinutes));
        break;
      case SessionSortCriteria.durationDesc:
        _sessions.sort((a, b) => b.inGameTimeInMinutes.compareTo(a.inGameTimeInMinutes));
        break;
    }
    notifyListeners();
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

  /// Simuliert eine Datenbankoperation
  Future<void> _simulateDatabaseOperation() async {
    // Simuliere Netzwerkverzögerung
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

/// Sortierkriterien für Sessions
enum SessionSortCriteria {
  titleAsc,
  titleDesc,
  durationAsc,
  durationDesc,
}
