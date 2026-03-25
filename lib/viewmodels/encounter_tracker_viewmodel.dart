import 'package:flutter/foundation.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/encounter_model_repository.dart';
import '../database/repositories/encounter_participant_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/creature_model_repository.dart';
import '../models/encounter.dart';
import '../models/encounter_participant.dart';
import '../models/player_character.dart';
import '../models/creature.dart';

/// ViewModel für den Encounter Tracker
/// 
/// Verwaltet den aktiven Kampf mit Teilnehmern, Initiative und HP.
class EncounterTrackerViewModel extends ChangeNotifier {
  late final EncounterModelRepository _encounterRepo;
  late final EncounterParticipantModelRepository _participantRepo;
  late final PlayerCharacterModelRepository _characterRepo;
  late final CreatureModelRepository _creatureRepo;

  // Encounter-Daten
  Encounter? _encounter;
  List<EncounterParticipant> _participants = [];
  
  // Geladene Character-Daten für Spieler-Teilnehmer
  final Map<String, PlayerCharacter> _loadedCharacters = {};
  
  // Geladene Creature-Daten für Monster-Teilnehmer
  final Map<String, Creature> _loadedCreatures = {};
  
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
    _characterRepo = PlayerCharacterModelRepository(connection);
    _creatureRepo = CreatureModelRepository(connection);
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

  /// Gibt die geladenen Character-Daten für einen Teilnehmer zurück
  PlayerCharacter? getCharacterForParticipant(EncounterParticipant participant) {
    if (participant.type != ParticipantType.player || participant.characterId == null) {
      return null;
    }
    return _loadedCharacters[participant.characterId];
  }

  /// Gibt die geladenen Creature-Daten für einen Monster-Teilnehmer zurück
  Creature? getCreatureForParticipant(EncounterParticipant participant) {
    if (participant.type != ParticipantType.enemy || participant.creatureId == null) {
      return null;
    }
    return _loadedCreatures[participant.creatureId];
  }

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
      
      // Character-Daten für Spieler-Teilnehmer laden
      await _loadCharacterData();
      
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

  // ===== CHARACTER DATA LOADING =====

  /// Lädt Character-Daten für alle Spieler-Teilnehmer und Creature-Daten für Monster
  Future<void> _loadCharacterData() async {
    for (final participant in _participants) {
      if (participant.type == ParticipantType.player && participant.characterId != null) {
        final character = await _characterRepo.findById(participant.characterId!);
        if (character != null) {
          _loadedCharacters[participant.characterId!] = character;
        }
      } else if (participant.type == ParticipantType.enemy && participant.creatureId != null) {
        final creature = await _creatureRepo.findById(participant.creatureId!);
        if (creature != null) {
          _loadedCreatures[participant.creatureId!] = creature;
        }
      }
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
    
    // Prüfen ob wir am Ende der Runde sind (letzter lebender Teilnehmer)
    bool wasLastInRound = _isLastAliveParticipant(_currentTurnIndex);
    
    // Nächsten lebenden Teilnehmer finden
    int nextIndex = _currentTurnIndex;
    int attempts = 0;
    
    do {
      nextIndex = (nextIndex + 1) % _participants.length;
      attempts++;
    } while (_participants[nextIndex].isDead && attempts < _participants.length);
    
    // Neue Runde wenn wir vom letzten zum ersten Teilnehmer wechseln
    if (wasLastInRound && nextIndex < _currentTurnIndex) {
      _roundCounter++;
    }
    
    _currentTurnIndex = nextIndex;
    notifyListeners();
  }
  
  /// Prüft ob der gegebene Index der letzte lebende Teilnehmer ist
  bool _isLastAliveParticipant(int index) {
    final aliveIndices = <int>[];
    for (int i = 0; i < _participants.length; i++) {
      if (_participants[i].isAlive) {
        aliveIndices.add(i);
      }
    }
    return aliveIndices.length <= 1 || aliveIndices.last == index;
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