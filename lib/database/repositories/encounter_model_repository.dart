import '../core/database_connection.dart';
import '../../models/encounter.dart';
import 'model_repository.dart';

/// Repository für Encounter Modelle
/// 
/// Dieses Repository arbeitet direkt mit dem Encounter Modell,
/// das seine eigene Serialisierung über toDatabaseMap() und fromDatabaseMap() bereitstellt.
class EncounterModelRepository extends ModelRepository<Encounter> {
  EncounterModelRepository(DatabaseConnection connection) : super(connection) {
    print('EncounterModelRepository initialisiert');
  }
  
  @override
  String get tableName => Encounter.tableName;

  @override
  Map<String, dynamic> toDatabaseMap(Encounter encounter) {
    final map = encounter.toDatabaseMap();
    print('toDatabaseMap aufgerufen für Encounter: ${encounter.title}');
    print('  ID: ${encounter.id}');
    print('  Scene ID: ${encounter.sceneId}');
    return map;
  }

  @override
  Encounter fromDatabaseMap(Map<String, dynamic> map) {
    print('fromDatabaseMap aufgerufen');
    print('  ID: ${map['id']}');
    print('  Title: ${map['title']}');
    return Encounter.fromDatabaseMap(map);
  }

  /// ===== SPEZIALISIERTE SUCHMETHODEN =====

  /// Findet Encounters nach Scene
  Future<List<Encounter>> findByScene(String sceneId) async {
    return await findWhere(
      where: 'scene_id = ?',
      whereArgs: [sceneId],
      orderBy: 'created_at ASC',
    );
  }

  /// Findet Encounters nach Status
  Future<List<Encounter>> findByStatus(EncounterStatus status) async {
    return await findWhere(
      where: 'status = ?',
      whereArgs: [status.toString().split('.').last],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet aktive Encounters nach Scene
  Future<List<Encounter>> findActiveByScene(String sceneId) async {
    return await findWhere(
      where: 'scene_id = ? AND status = ?',
      whereArgs: [sceneId, 'active'],
      orderBy: 'created_at DESC',
    );
  }

  /// Findet geplante Encounters nach Scene
  Future<List<Encounter>> findPlannedByScene(String sceneId) async {
    return await findWhere(
      where: 'scene_id = ? AND status = ?',
      whereArgs: [sceneId, 'planning'],
      orderBy: 'created_at DESC',
    );
  }

  /// ===== ENCOUNTER-OPERATIONEN =====

  /// Startet einen Encounter
  Future<Encounter> startEncounter(String encounterId) async {
    final encounter = await findById(encounterId);
    if (encounter == null) {
      throw Exception('Encounter not found: $encounterId');
    }

    final startedEncounter = encounter.startEncounter();
    return await update(startedEncounter);
  }

  /// Beendet einen Encounter
  Future<Encounter> completeEncounter(String encounterId) async {
    final encounter = await findById(encounterId);
    if (encounter == null) {
      throw Exception('Encounter not found: $encounterId');
    }

    final completedEncounter = encounter.completeEncounter();
    return await update(completedEncounter);
  }

  /// Bricht einen Encounter ab
  Future<Encounter> cancelEncounter(String encounterId) async {
    final encounter = await findById(encounterId);
    if (encounter == null) {
      throw Exception('Encounter not found: $encounterId');
    }

    final cancelledEncounter = encounter.cancelEncounter();
    return await update(cancelledEncounter);
  }

  /// Aktualisiert die Teilnehmer-Liste eines Encounters
  Future<Encounter> updateParticipants(
    String encounterId,
    List<String> participantIds,
  ) async {
    final encounter = await findById(encounterId);
    if (encounter == null) {
      throw Exception('Encounter not found: $encounterId');
    }

    final updatedEncounter = encounter.copyWith(
      participantIds: participantIds,
    );
    return await update(updatedEncounter);
  }

  /// Fügt einen Teilnehmer zu einem Encounter hinzu
  Future<Encounter> addParticipant(
    String encounterId,
    String participantId,
  ) async {
    final encounter = await findById(encounterId);
    if (encounter == null) {
      throw Exception('Encounter not found: $encounterId');
    }

    final updatedParticipants = [...encounter.participantIds, participantId];
    final updatedEncounter = encounter.copyWith(
      participantIds: updatedParticipants,
    );
    return await update(updatedEncounter);
  }

  /// Entfernt einen Teilnehmer von einem Encounter
  Future<Encounter> removeParticipant(
    String encounterId,
    String participantId,
  ) async {
    final encounter = await findById(encounterId);
    if (encounter == null) {
      throw Exception('Encounter not found: $encounterId');
    }

    final updatedParticipants = encounter.participantIds
        .where((id) => id != participantId)
        .toList();
    final updatedEncounter = encounter.copyWith(
      participantIds: updatedParticipants,
    );
    return await update(updatedEncounter);
  }

  /// ===== STATISTIKEN =====

  /// Zählt Encounters pro Status
  Future<Map<String, int>> getCountByStatus() async {
    final result = await rawQuery('''
      SELECT status, COUNT(*) as count
      FROM $tableName
      GROUP BY status
    ''');
    
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['status'] as String] = row['count'] as int;
    }
    return counts;
  }

  /// Zählt Encounters pro Scene
  Future<Map<String, int>> getCountByScene(String sceneId) async {
    final result = await rawQuery('''
      SELECT status, COUNT(*) as count
      FROM $tableName
      WHERE scene_id = ?
      GROUP BY status
    ''', [sceneId]);
    
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['status'] as String] = row['count'] as int;
    }
    return counts;
  }
}