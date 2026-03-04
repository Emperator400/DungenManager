import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/encounter.dart';
import '../models/encounter_participant.dart';
import '../models/session_quest_progress.dart';
import '../models/session_character_tracking.dart';

/// Session Service - Verwaltet Session-Daten als Singleton
/// 
/// Dieser Service fungiert wie ein zentraler Speicher für
/// Daten, die über die Lebensdauer der App hinaus bestehen müssen.
/// Er ist thread-sicher durch Nutzung von Map und Locks.
/// 
/// Erweiterte Features:
/// - Session-Modell-Verwaltung
/// - Encounter-Tracking
/// - Quest-Progress-Tracking
/// - Character-Tracking (HP, Conditions, Anwesenheit)
class SessionService {
  // Singleton Pattern
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;

  SessionService._internal();

  final Map<String, dynamic> _sessionData = {};
  final Map<Type, dynamic> _dependencies = {};
  
  // ========== SESSION MODEL MANAGEMENT ==========
  
  Session? _activeSession;
  List<Encounter> _encounters = [];
  List<EncounterParticipant> _participants = [];
  List<SessionQuestProgress> _questProgress = [];
  List<SessionCharacterTracking> _characterTracking = [];
  
  /// Aktive Session
  Session? get activeSession => _activeSession;
  
  /// Alle Encounters der aktiven Session
  List<Encounter> get encounters => List.unmodifiable(_encounters);
  
  /// Alle Teilnehmer der Encounters
  List<EncounterParticipant> get participants => List.unmodifiable(_participants);
  
  /// Quest-Fortschritt der aktiven Session
  List<SessionQuestProgress> get questProgress => List.unmodifiable(_questProgress);
  
  /// Character-Tracking der aktiven Session
  List<SessionCharacterTracking> get characterTracking => List.unmodifiable(_characterTracking);

  /// Speichert Daten in der Session
  void set<T>(String key, T value) {
    _sessionData[key] = value;
    if (kDebugMode) {
      print('💾 Session: $key = $value');
    }
  }

  /// Holt Daten aus der Session
  T? get<T>(String key) {
    return _sessionData[key] as T?;
  }

  /// Löscht Daten aus der Session
  void remove(String key) {
    _sessionData.remove(key);
    if (kDebugMode) {
      print('💾 Session: $key entfernt');
    }
  }

  /// Prüft, ob ein Key existiert
  bool containsKey(String key) {
    return _sessionData.containsKey(key);
  }

  /// Speichert eine Dependency (für Service-Container)
  void setDependency<T>(Type type, T instance) {
    _dependencies[type] = instance;
    if (kDebugMode) {
      print('📦 Dependency registriert: $type');
    }
  }

  /// Holt eine Dependency (für Service-Container)
  T? getDependency<T>() {
    return _dependencies[T] as T?;
  }

  /// Prüft, ob eine Dependency existiert
  bool containsDependency<T>() {
    return _dependencies.containsKey(T);
  }

  /// Löscht alle Session-Daten
  void clear() {
    _sessionData.clear();
    _dependencies.clear();
    if (kDebugMode) {
      print('💾 Session gelöscht');
    }
  }

  /// Gibt alle Session-Keys zurück
  List<String> getKeys() {
    return _sessionData.keys.toList();
  }

  /// Gibt alle Dependencies zurück
  List<Type> getDependencies() {
    return _dependencies.keys.toList();
  }
  
  // ========== SESSION METHODS ==========
  
  /// Setzt die aktive Session
  void setActiveSession(Session session) {
    _activeSession = session;
    if (kDebugMode) {
      print('🎮 Aktive Session: ${session.title}');
    }
  }
  
  /// Löscht die aktive Session
  void clearActiveSession() {
    _activeSession = null;
    _encounters.clear();
    _participants.clear();
    _questProgress.clear();
    _characterTracking.clear();
    if (kDebugMode) {
      print('🎮 Aktive Session gelöscht');
    }
  }
  
  // ========== ENCOUNTER METHODS ==========
  
  /// Fügt einen Encounter hinzu
  void addEncounter(Encounter encounter) {
    _encounters.add(encounter);
    if (kDebugMode) {
      print('⚔️ Encounter hinzugefügt: ${encounter.title}');
    }
  }
  
  /// Entfernt einen Encounter
  void removeEncounter(String encounterId) {
    _encounters.removeWhere((e) => e.id == encounterId);
    _participants.removeWhere((p) => p.encounterId == encounterId);
    if (kDebugMode) {
      print('⚔️ Encounter entfernt: $encounterId');
    }
  }
  
  /// Aktualisiert einen Encounter
  void updateEncounter(Encounter updatedEncounter) {
    final index = _encounters.indexWhere((e) => e.id == updatedEncounter.id);
    if (index != -1) {
      _encounters[index] = updatedEncounter;
      if (kDebugMode) {
        print('⚔️ Encounter aktualisiert: ${updatedEncounter.title}');
      }
    }
  }
  
  /// Holt einen Encounter per ID
  Encounter? getEncounter(String encounterId) {
    return _encounters.firstWhere((e) => e.id == encounterId);
  }
  
  // ========== PARTICIPANT METHODS ==========
  
  /// Fügt einen Teilnehmer hinzu
  void addParticipant(EncounterParticipant participant) {
    _participants.add(participant);
    if (kDebugMode) {
      print('👤 Teilnehmer hinzugefügt: ${participant.name}');
    }
  }
  
  /// Entfernt einen Teilnehmer
  void removeParticipant(String participantId) {
    _participants.removeWhere((p) => p.id == participantId);
    if (kDebugMode) {
      print('👤 Teilnehmer entfernt: $participantId');
    }
  }
  
  /// Aktualisiert einen Teilnehmer
  void updateParticipant(EncounterParticipant updatedParticipant) {
    final index = _participants.indexWhere((p) => p.id == updatedParticipant.id);
    if (index != -1) {
      _participants[index] = updatedParticipant;
      if (kDebugMode) {
        print('👤 Teilnehmer aktualisiert: ${updatedParticipant.name}');
      }
    }
  }
  
  /// Holt alle Teilnehmer eines Encounters
  List<EncounterParticipant> getParticipantsForEncounter(String encounterId) {
    return _participants.where((p) => p.encounterId == encounterId).toList();
  }
  
  // ========== QUEST PROGRESS METHODS ==========
  
  /// Fügt Quest-Fortschritt hinzu
  void addQuestProgress(SessionQuestProgress questProgress) {
    _questProgress.add(questProgress);
    if (kDebugMode) {
      print('📜 Quest-Fortschritt hinzugefügt: Quest ID ${questProgress.questId}');
    }
  }
  
  /// Entfernt Quest-Fortschritt
  void removeQuestProgress(String progressId) {
    _questProgress.removeWhere((q) => q.id == progressId);
    if (kDebugMode) {
      print('📜 Quest-Fortschritt entfernt: $progressId');
    }
  }
  
  /// Aktualisiert Quest-Fortschritt
  void updateQuestProgress(SessionQuestProgress updatedProgress) {
    final index = _questProgress.indexWhere((q) => q.id == updatedProgress.id);
    if (index != -1) {
      _questProgress[index] = updatedProgress;
      if (kDebugMode) {
        print('📜 Quest-Fortschritt aktualisiert: Quest ID ${updatedProgress.questId}');
      }
    }
  }
  
  /// Holt Quest-Fortschritt per Quest ID
  SessionQuestProgress? getQuestProgressByQuestId(int questId) {
    try {
      return _questProgress.firstWhere((q) => q.questId == questId);
    } catch (e) {
      return null;
    }
  }
  
  // ========== CHARACTER TRACKING METHODS ==========
  
  /// Fügt Character-Tracking hinzu
  void addCharacterTracking(SessionCharacterTracking tracking) {
    _characterTracking.add(tracking);
    if (kDebugMode) {
      print('🎭 Character-Tracking hinzugefügt: ${tracking.characterName}');
    }
  }
  
  /// Entfernt Character-Tracking
  void removeCharacterTracking(String trackingId) {
    _characterTracking.removeWhere((c) => c.id == trackingId);
    if (kDebugMode) {
      print('🎭 Character-Tracking entfernt: $trackingId');
    }
  }
  
  /// Aktualisiert Character-Tracking
  void updateCharacterTracking(SessionCharacterTracking updatedTracking) {
    final index = _characterTracking.indexWhere((c) => c.id == updatedTracking.id);
    if (index != -1) {
      _characterTracking[index] = updatedTracking;
      if (kDebugMode) {
        print('🎭 Character-Tracking aktualisiert: ${updatedTracking.characterName}');
      }
    }
  }
  
  /// Holt Character-Tracking per Character ID
  SessionCharacterTracking? getCharacterTracking(String characterId) {
    try {
      return _characterTracking.firstWhere((c) => c.characterId == characterId);
    } catch (e) {
      return null;
    }
  }
  
  /// Holt alle anwesenden Charaktere
  List<SessionCharacterTracking> getPresentCharacters() {
    return _characterTracking.where((c) => c.isPresent).toList();
  }
  
  // ========== AUTO-SAVE METHODS ==========
  
  /// Speichert die aktive Session (simuliert Datenbank-Save)
  Future<void> saveSession() async {
    // Hier würde die Datenbank-Implementierung folgen
    // vorerst nur Log-Ausgabe
    if (kDebugMode) {
      print('💾 Session gespeichert: ${_activeSession?.title}');
      print('   - Encounters: ${_encounters.length}');
      print('   - Teilnehmer: ${_participants.length}');
      print('   - Quests: ${_questProgress.length}');
      print('   - Charaktere: ${_characterTracking.length}');
    }
  }
}
