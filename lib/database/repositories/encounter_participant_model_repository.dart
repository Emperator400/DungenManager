import '../core/database_connection.dart';
import '../../models/encounter_participant.dart';
import 'model_repository.dart';

/// Repository für EncounterParticipant Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem EncounterParticipant Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
class EncounterParticipantModelRepository extends ModelRepository<EncounterParticipant> {
  EncounterParticipantModelRepository(DatabaseConnection connection) : super(connection) {
    print('EncounterParticipantModelRepository initialisiert');
  }
  
  @override
  String get tableName => EncounterParticipant.tableName;

  @override
  Map<String, dynamic> toDatabaseMap(EncounterParticipant participant) {
    final map = participant.toDatabaseMap();
    print('toDatabaseMap aufgerufen für Participant: ${participant.name}');
    print('  ID: ${participant.id}');
    print('  Encounter ID: ${participant.encounterId}');
    return map;
  }

  @override
  EncounterParticipant fromDatabaseMap(Map<String, dynamic> map) {
    print('fromDatabaseMap aufgerufen');
    print('  ID: ${map['id']}');
    print('  Name: ${map['name']}');
    return EncounterParticipant.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Teilnehmer nach Encounter
  Future<List<EncounterParticipant>> findByEncounter(String encounterId) async {
    return await findWhere(
      where: 'encounter_id = ?',
      whereArgs: [encounterId],
      orderBy: 'type ASC, name ASC',
    );
  }

  /// Findet Teilnehmer nach Typ
  Future<List<EncounterParticipant>> findByType(ParticipantType type) async {
    return await findWhere(
      where: 'type = ?',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'name ASC',
    );
  }

  /// Findet Teilnehmer nach Encounter und Typ
  Future<List<EncounterParticipant>> findByEncounterAndType(
    String encounterId,
    ParticipantType type,
  ) async {
    return await findWhere(
      where: 'encounter_id = ? AND type = ?',
      whereArgs: [encounterId, type.toString().split('.').last],
      orderBy: 'name ASC',
    );
  }

  /// Findet Teilnehmer nach Character ID
  Future<List<EncounterParticipant>> findByCharacterId(String characterId) async {
    return await findWhere(
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'created_at DESC',
    );
  }

  /// ===== PARTICIPANT-OPERATIONEN =====

  /// Fügt Schaden zu einem Teilnehmer hinzu
  Future<EncounterParticipant> applyDamage(
    String participantId,
    int damage,
  ) async {
    final participant = await findById(participantId);
    if (participant == null) {
      throw Exception('Participant not found: $participantId');
    }

    final damagedParticipant = participant.takeDamage(damage);
    return await update(damagedParticipant);
  }

  /// Heilt einen Teilnehmer
  Future<EncounterParticipant> applyHeal(
    String participantId,
    int amount,
  ) async {
    final participant = await findById(participantId);
    if (participant == null) {
      throw Exception('Participant not found: $participantId');
    }

    final healedParticipant = participant.heal(amount);
    return await update(healedParticipant);
  }

  /// Setzt HP eines Teilnehmers
  Future<EncounterParticipant> setParticipantHp(
    String participantId,
    int newHp,
  ) async {
    final participant = await findById(participantId);
    if (participant == null) {
      throw Exception('Participant not found: $participantId');
    }

    final updatedParticipant = participant.setHp(newHp);
    return await update(updatedParticipant);
  }

  /// Fügt eine Condition hinzu
  Future<EncounterParticipant> addCondition(
    String participantId,
    String condition,
  ) async {
    final participant = await findById(participantId);
    if (participant == null) {
      throw Exception('Participant not found: $participantId');
    }

    final updatedParticipant = participant.addCondition(condition);
    return await update(updatedParticipant);
  }

  /// Entfernt eine Condition
  Future<EncounterParticipant> removeCondition(
    String participantId,
    String condition,
  ) async {
    final participant = await findById(participantId);
    if (participant == null) {
      throw Exception('Participant not found: $participantId');
    }

    final updatedParticipant = participant.removeCondition(condition);
    return await update(updatedParticipant);
  }

  /// ===== STATISTIKEN =====

  /// Zählt Teilnehmer pro Encounter
  Future<int> countByEncounter(String encounterId) async {
    return await count(
      where: 'encounter_id = ?',
      whereArgs: [encounterId],
    );
  }

  /// Zählt Teilnehmer pro Typ
  Future<Map<String, int>> getCountByType() async {
    final result = await rawQuery('''
      SELECT type, COUNT(*) as count
      FROM $tableName
      GROUP BY type
    ''');
    
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['type'] as String] = row['count'] as int;
    }
    return counts;
  }

  /// Zählt Teilnehmer pro Encounter und Typ
  Future<Map<String, int>> getCountByEncounterAndType(String encounterId) async {
    final result = await rawQuery('''
      SELECT type, COUNT(*) as count
      FROM $tableName
      WHERE encounter_id = ?
      GROUP BY type
    ''', [encounterId]);
    
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['type'] as String] = row['count'] as int;
    }
    return counts;
  }

  /// Findet alle lebenden Teilnehmer eines Encounters
  Future<List<EncounterParticipant>> findAliveByEncounter(
    String encounterId,
  ) async {
    return await findWhere(
      where: 'encounter_id = ? AND current_hp > 0',
      whereArgs: [encounterId],
      orderBy: 'type ASC, name ASC',
    );
  }

  /// Findet alle toten Teilnehmer eines Encounters
  Future<List<EncounterParticipant>> findDeadByEncounter(
    String encounterId,
  ) async {
    return await findWhere(
      where: 'encounter_id = ? AND current_hp <= 0',
      whereArgs: [encounterId],
      orderBy: 'type ASC, name ASC',
    );
  }
}