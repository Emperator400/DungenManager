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

/// ViewModel für Encounter-Planung
/// 
/// Verwaltet das Zusammenstellen von Encounters mit Helden und Monstern.
class EncounterPlanningViewModel extends ChangeNotifier {
  late final EncounterModelRepository _encounterRepo;
  late final EncounterParticipantModelRepository _participantRepo;
  late final PlayerCharacterModelRepository _characterRepo;
  late final CreatureModelRepository _creatureRepo;

  // Campaign ID
  final String campaignId;
  final String sceneId;

  // Zustand
  List<PlayerCharacter> _availableCharacters = [];
  List<Creature> _availableMonsters = [];
  List<String> _selectedCharacterIds = [];
  List<String> _selectedMonsterIds = [];

  // Encounter-Daten
  String _encounterTitle = '';
  String _encounterDescription = '';

  // Loading States
  bool _isLoading = false;
  String? _errorMessage;

  // Vorausgewählte Daten von der Scene
  final List<String> preselectedCharacterIds;
  final List<String> preselectedMonsterIds;
  final String? preselectedDescription;

  EncounterPlanningViewModel({
    required this.campaignId,
    required this.sceneId,
    this.preselectedCharacterIds = const [],
    this.preselectedMonsterIds = const [],
    this.preselectedDescription,
  }) {
    final connection = DatabaseConnection.instance;
    _encounterRepo = EncounterModelRepository(connection);
    _participantRepo = EncounterParticipantModelRepository(connection);
    _characterRepo = PlayerCharacterModelRepository(connection);
    _creatureRepo = CreatureModelRepository(connection);
  }

  // ===== GETTERS =====

  List<PlayerCharacter> get availableCharacters => _availableCharacters;
  List<Creature> get availableMonsters => _availableMonsters;
  List<PlayerCharacter> get selectedCharacters => _availableCharacters
      .where((c) => _selectedCharacterIds.contains(c.id))
      .toList();
  List<Creature> get selectedMonsters => _availableMonsters
      .where((m) => _selectedMonsterIds.contains(m.id))
      .toList();
  String get encounterTitle => _encounterTitle;
  String get encounterDescription => _encounterDescription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalParticipants => _selectedCharacterIds.length + _selectedMonsterIds.length;
  bool get canStartEncounter => totalParticipants > 0 && _encounterTitle.isNotEmpty;

  // ===== DATEN LADEN =====

  /// Lädt alle verfügbaren Helden und Monster
  Future<void> loadData() async {
    print('');
    print('🎯🎯🎯 [EncounterPlanningViewModel] loadData() aufgerufen 🎯🎯🎯');
    print('🎯 [EncounterPlanningViewModel] campaignId: $campaignId, sceneId: $sceneId');
    _setLoading(true);
    _clearError();

    try {
      // Helden der Kampagne laden
      print('🎯 [EncounterPlanningViewModel] Lade Helden für Kampagne...');
      final characters = await _characterRepo.findByCampaign(campaignId);
      print('🎯 [EncounterPlanningViewModel] ${characters.length} Helden geladen');
      _availableCharacters = characters;

      // Monster aus Bestiarium laden (custom und official)
      print('🎯 [EncounterPlanningViewModel] Lade alle Kreaturen aus Datenbank...');
      
      // ERST: Direkte SQL-Abfrage zum Debuggen
      final rawResults = await _creatureRepo.rawQuery('SELECT id, name, is_player, source_type FROM creatures LIMIT 10');
      print('🎯 [EncounterPlanningViewModel] RAW SQL Ergebnis (${rawResults.length} Einträge):');
      for (final row in rawResults) {
        print('🎯   - ID: ${row['id']}, Name: ${row['name']}, is_player: ${row['is_player']}, source_type: ${row['source_type']}');
      }
      
      final allCreatures = await _creatureRepo.findAll();
      print('🎯 [EncounterPlanningViewModel] ${allCreatures.length} Kreaturen insgesamt geladen');
      
      // Debug: Zeige Details jeder Kreatur
      for (final creature in allCreatures) {
        print('🎯 [EncounterPlanningViewModel] Kreatur: ${creature.name}, sourceType: "${creature.sourceType}", isPlayer: ${creature.isPlayer}');
      }
      
      // Debug: Zeige sourceTypes
      final sourceTypes = allCreatures.map((c) => c.sourceType).toSet();
      print('🎯 [EncounterPlanningViewModel] Gefundene sourceTypes: $sourceTypes');
      
      // Alle Kreaturen, die keine Spieler sind, als Monster verfügbar machen
      // Das schließt custom, official, und alle anderen sourceTypes ein
      _availableMonsters = allCreatures.where((c) => 
        c.isPlayer == false || c.isPlayer == null
      ).toList();
      print('🎯 [EncounterPlanningViewModel] ${_availableMonsters.length} Monster nach Filterung verfügbar (isPlayer == false)');
      print('');

      // Vorausgewählte Charaktere und Monster von der Scene übernehmen
      // WICHTIG: preselectedCharacterIds kann sowohl PCs als auch Monster enthalten
      // Wir müssen intelligent unterscheiden, um beides automatisch auszuwählen
      
      // Zuerst: Explizit übergebene preselectedCharacterIds verarbeiten
      if (preselectedCharacterIds.isNotEmpty) {
        for (final id in preselectedCharacterIds) {
          // Prüfen ob es ein Player Character ist
          if (_availableCharacters.any((c) => c.id == id)) {
            if (!_selectedCharacterIds.contains(id)) {
              _selectedCharacterIds.add(id);
            }
          }
          // Prüfen ob es ein Monster ist
          else if (_availableMonsters.any((m) => m.id == id)) {
            if (!_selectedMonsterIds.contains(id)) {
              _selectedMonsterIds.add(id);
            }
          }
        }
      }

      // Dann: Explizit übergebene preselectedMonsterIds verarbeiten
      if (preselectedMonsterIds.isNotEmpty) {
        for (final monsterId in preselectedMonsterIds) {
          // Prüfen ob das Monster existiert
          if (_availableMonsters.any((m) => m.id == monsterId)) {
            if (!_selectedMonsterIds.contains(monsterId)) {
              _selectedMonsterIds.add(monsterId);
            }
          }
        }
      }

      // Vorausgefüllte Beschreibung übernehmen
      if (preselectedDescription != null && preselectedDescription!.isNotEmpty) {
        _encounterDescription = preselectedDescription!;
      }

      _setLoading(false);
    } catch (e) {
      _setError('Fehler beim Laden der Daten: $e');
      _setLoading(false);
    }
  }

  // ===== ENCOUNTER PLANUNG =====

  /// Setzt den Titel des Encounters
  void setEncounterTitle(String title) {
    _encounterTitle = title;
    notifyListeners();
  }

  /// Setzt die Beschreibung des Encounters
  void setEncounterDescription(String description) {
    _encounterDescription = description;
    notifyListeners();
  }

  // ===== AUSWAHL VERWALTUNG =====

  /// Wählt einen Charakter aus oder ab
  void toggleCharacterSelection(String characterId) {
    if (_selectedCharacterIds.contains(characterId)) {
      _selectedCharacterIds.remove(characterId);
    } else {
      _selectedCharacterIds.add(characterId);
    }
    notifyListeners();
  }

  /// Wählt ein Monster aus oder ab
  void toggleMonsterSelection(String monsterId) {
    if (_selectedMonsterIds.contains(monsterId)) {
      _selectedMonsterIds.remove(monsterId);
    } else {
      _selectedMonsterIds.add(monsterId);
    }
    notifyListeners();
  }

  /// Prüft ob ein Charakter ausgewählt ist
  bool isCharacterSelected(String characterId) {
    return _selectedCharacterIds.contains(characterId);
  }

  /// Prüft ob ein Monster ausgewählt ist
  bool isMonsterSelected(String monsterId) {
    return _selectedMonsterIds.contains(monsterId);
  }

  /// Entfernt einen Charakter aus der Auswahl
  void removeCharacter(String characterId) {
    _selectedCharacterIds.remove(characterId);
    notifyListeners();
  }

  /// Entfernt ein Monster aus der Auswahl
  void removeMonster(String monsterId) {
    _selectedMonsterIds.remove(monsterId);
    notifyListeners();
  }

  /// Leert die gesamte Auswahl
  void clearSelection() {
    _selectedCharacterIds.clear();
    _selectedMonsterIds.clear();
    notifyListeners();
  }

  // ===== ENCOUNTER ERSTELLEN =====

  /// Erstellt und speichert einen neuen Encounter
  Future<Encounter?> createEncounter() async {
    if (!canStartEncounter) {
      _setError('Bitte wähle mindestens einen Teilnehmer und gib einen Titel ein.');
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      // Encounter erstellen
      final encounter = Encounter.create(
        sceneId: sceneId,
        title: _encounterTitle,
        description: _encounterDescription,
      );

      final savedEncounter = await _encounterRepo.create(encounter);

      // Teilnehmer erstellen
      final participantIds = <String>[];

      // Helden als Teilnehmer hinzufügen
      for (final characterId in _selectedCharacterIds) {
        final character = _availableCharacters.firstWhere(
          (c) => c.id == characterId,
        );

        final participant = EncounterParticipant(
          encounterId: savedEncounter.id,
          name: character.name,
          type: ParticipantType.player,
          currentHp: character.maxHp,
          maxHp: character.maxHp,
          characterId: character.id,
        );

        final savedParticipant = await _participantRepo.create(participant);
        participantIds.add(savedParticipant.id);
      }

      // Monster als Teilnehmer hinzufügen
      for (final monsterId in _selectedMonsterIds) {
        final monster = _availableMonsters.firstWhere(
          (m) => m.id == monsterId,
        );

        final participant = EncounterParticipant(
          encounterId: savedEncounter.id,
          name: monster.name,
          type: ParticipantType.enemy,
          currentHp: monster.maxHp,
          maxHp: monster.maxHp,
        );

        final savedParticipant = await _participantRepo.create(participant);
        participantIds.add(savedParticipant.id);
      }

      // Encounter mit Teilnehmer-IDs aktualisieren
      final updatedEncounter = savedEncounter.copyWith(
        participantIds: participantIds,
      );
      await _encounterRepo.update(updatedEncounter);

      _setLoading(false);
      return updatedEncounter;
    } catch (e) {
      _setError('Fehler beim Erstellen des Encounters: $e');
      _setLoading(false);
      return null;
    }
  }

  // ===== HELPER METHODEN =====

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

  @override
  void dispose() {
    super.dispose();
  }
}