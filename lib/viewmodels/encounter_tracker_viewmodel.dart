import 'package:flutter/foundation.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/encounter_model_repository.dart';
import '../database/repositories/encounter_participant_model_repository.dart';
import '../models/encounter.dart';
import '../models/encounter_participant.dart';

/// ViewModel für den Encounter Tracker
/// 
/// Verwaltet den aktiven Kampf mit Teilnehmern, Initiative und HP.
class EncounterTrackerViewModel extends ChangeNotifier {
  late final EncounterModelRepository _encounterRepo;
  late final EncounterParticipantModelRepository _participantRepo;

  // Encounter-Daten
  Encounter? _encounter;
  List<EncounterParticipant> _participants = [];
  
  // Kampf-Zustand
  int _roundCounter = 1;
  int _currentTurnIndex = 0;
  bool _isInitialized = false;
  
  // Loading States
  bool _isLoading = false;
  String? _errorMessage;

  EncounterTrackerViewModel() {
    final connection = DatabaseConnection.instance;
    _encounterRepo = EncounterModelRepository(connection);
    _participantRepo = EncounterParticipantModelRepository(connection);
  }

  // ===== GETTERS =====

  Encounter? get encounter => _encounter;
  List<EncounterParticipant> get participants => _participants;
  int get roundCounter => _roundCounter;
  int get currentTurnIndex => _currentTurnIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  
  /// Aktueller Teilnehmer am Zug
  EncounterParticipant? get currentParticipant {
    if (_participants.isEmpty || _currentTurnIndex >= _participants.length) {
      return null;
    }
    return _participants[_currentTurnIndex];
  }
  
  /// Prüft ob der Kampf aktiv ist
  bool get isEncounterActive => _encounter?.isActive ?? false;
  
  /// Anzahl der lebenden Teilnehmer
  int get aliveParticipantsCount => _participants.where((p) => p.isAlive).length;
  
  /// Anzahl der lebenden Spieler
  int get alivePlayersCount => _participants
      .where((p) => p.type == ParticipantType.player && p.isAlive)
      .length;
  
  /// Anzahl der lebenden Gegner
  int get aliveEnemiesCount => _participants
      .where((p) => p.type == ParticipantType.enemy && p.isAlive)
      .length;

  // ===== DATEN LADEN =====

  /// Lädt einen Encounter mit allen Teilnehmern
  Future<void> loadEncounter(String encounterId) async {
    _setLoading(true);
    _clearError();

    try {
      // Encounter laden
      final encounter = await _encounterRepo.findById(encounterId);
      if (encounter == null) {
        _setError('Encounter nicht gefunden');
        _setLoading(false);
        return;
      }
      _encounter = encounter;

      // Teilnehmer laden
      _participants = await _participantRepo.findByEncounter(encounterId);
      
      // Initiative rollen falls noch nicht vorhanden
      _rollInitiativeForAll();
      
      // Nach Initiative sortieren (höchste zuerst)
      _sortByInitiative();
      
      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _setError('Fehler beim Laden des Encounters: $e');
      _setLoading(false);
    }
  }

  /// Startet den Encounter (Status ändern)
  Future<void> startEncounter() async {
    if (_encounter == null) return;
    
    try {
      _encounter = await _encounterRepo.startEncounter(_encounter!.id);
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Starten des Encounters: $e');
    }
  }

  /// Beendet den Encounter
  Future<void> completeEncounter() async {
    if (_encounter == null) return;
    
    try {
      _encounter = await _encounterRepo.completeEncounter(_encounter!.id);
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Beenden des Encounters: $e');
    }
  }

  // ===== INITIATIVE =====

  /// Rollt Initiative für alle Teilnehmer die noch keine haben
  void _rollInitiativeForAll() {
    // Diese Methode wird beim Laden aufgerufen
    // Initiative wird lokal gespeichert, nicht in der DB
  }

  /// Sortiert Teilnehmer nach Initiative (absteigend)
  void _sortByInitiative() {
    _participants.sort((a, b) {
      // Tote Teilnehmer ans Ende
      if (a.isDead && b.isAlive) return 1;
      if (a.isAlive && b.isDead) return -1;
      
      // Nach Initiative sortieren (höchste zuerst)
      // Da wir keine Initiative im Model haben, verwenden wir die Reihenfolge
      return 0;
    });
    notifyListeners();
  }

  /// Setzt Initiative für einen Teilnehmer
  Future<void> setInitiative(String participantId, int initiative) async {
    // Initiative wird lokal verwaltet, nicht in der DB gespeichert
    // Für erweiterte Funktionalität könnte man das Model erweitern
    notifyListeners();
  }

  // ===== KAMPF-ABLAUF =====

  /// Nächster Zug
  void nextTurn() {
    if (_participants.isEmpty) return;
    
    // Nächsten lebenden Teilnehmer finden
    int nextIndex = _currentTurnIndex;
    int attempts = 0;
    
    do {
      nextIndex = (nextIndex + 1) % _participants.length;
      attempts++;
      
      // Neue Runde wenn wir wieder am Anfang sind
      if (nextIndex == 0 && attempts > 1) {
        _roundCounter++;
      }
    } while (_participants[nextIndex].isDead && attempts < _participants.length);
    
    _currentTurnIndex = nextIndex;
    notifyListeners();
  }

  /// Zurück zum ersten Teilnehmer
  void resetToFirst() {
    _currentTurnIndex = 0;
    _roundCounter = 1;
    notifyListeners();
  }

  // ===== HP MANAGEMENT =====

  /// Fügt Schaden hinzu
  Future<void> applyDamage(String participantId, int damage) async {
    try {
      final updatedParticipant = await _participantRepo.applyDamage(
        participantId, 
        damage,
      );
      
      // In lokaler Liste aktualisieren
      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = updatedParticipant;
        notifyListeners();
      }
    } catch (e) {
      _setError('Fehler beim Anwenden von Schaden: $e');
    }
  }

  /// Heilt einen Teilnehmer
  Future<void> applyHeal(String participantId, int amount) async {
    try {
      final updatedParticipant = await _participantRepo.applyHeal(
        participantId, 
        amount,
      );
      
      // In lokaler Liste aktualisieren
      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = updatedParticipant;
        notifyListeners();
      }
    } catch (e) {
      _setError('Fehler beim Heilen: $e');
    }
  }

  /// Setzt HP direkt
  Future<void> setHp(String participantId, int newHp) async {
    try {
      final updatedParticipant = await _participantRepo.setParticipantHp(
        participantId, 
        newHp,
      );
      
      // In lokaler Liste aktualisieren
      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = updatedParticipant;
        notifyListeners();
      }
    } catch (e) {
      _setError('Fehler beim Setzen der HP: $e');
    }
  }

  // ===== CONDITIONS =====

  /// Fügt eine Condition hinzu
  Future<void> addCondition(String participantId, String condition) async {
    try {
      final updatedParticipant = await _participantRepo.addCondition(
        participantId, 
        condition,
      );
      
      // In lokaler Liste aktualisieren
      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = updatedParticipant;
        notifyListeners();
      }
    } catch (e) {
      _setError('Fehler beim Hinzufügen der Condition: $e');
    }
  }

  /// Entfernt eine Condition
  Future<void> removeCondition(String participantId, String condition) async {
    try {
      final updatedParticipant = await _participantRepo.removeCondition(
        participantId, 
        condition,
      );
      
      // In lokaler Liste aktualisieren
      final index = _participants.indexWhere((p) => p.id == participantId);
      if (index != -1) {
        _participants[index] = updatedParticipant;
        notifyListeners();
      }
    } catch (e) {
      _setError('Fehler beim Entfernen der Condition: $e');
    }
  }

  /// Toggle eine Condition
  Future<void> toggleCondition(String participantId, String condition) async {
    final participant = _participants.firstWhere((p) => p.id == participantId);
    if (participant.conditions.contains(condition)) {
      await removeCondition(participantId, condition);
    } else {
      await addCondition(participantId, condition);
    }
  }

  // ===== HELFER METHODEN =====

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Prüft ob der Kampf vorbei ist (eine Seite komplett besiegt)
  bool checkBattleEnd() {
    if (_participants.isEmpty) return true;
    
    final alivePlayers = alivePlayersCount;
    final aliveEnemies = aliveEnemiesCount;
    
    // Kampf vorbei wenn eine Seite komplett besiegt
    return alivePlayers == 0 || aliveEnemies == 0;
  }

  /// Gibt zurück welche Seite gewonnen hat (oder null wenn Kampf noch läuft)
  ParticipantType? getWinner() {
    final alivePlayers = alivePlayersCount;
    final aliveEnemies = aliveEnemiesCount;
    
    if (alivePlayers == 0 && aliveEnemies > 0) {
      return ParticipantType.enemy;
    } else if (aliveEnemies == 0 && alivePlayers > 0) {
      return ParticipantType.player;
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}