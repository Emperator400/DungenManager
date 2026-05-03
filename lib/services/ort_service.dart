import 'package:flutter/foundation.dart';

import '../database/core/database_connection.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../models/ort.dart';
import '../models/scene.dart';

class OrtService {
  final OrtModelRepository _ortRepo;
  final SceneModelRepository _sceneRepo;

  OrtService({
    OrtModelRepository? ortRepo,
    SceneModelRepository? sceneRepo,
  })  : _ortRepo = ortRepo ?? OrtModelRepository(DatabaseConnection.instance),
        _sceneRepo = sceneRepo ?? SceneModelRepository(DatabaseConnection.instance);

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<List<Ort>> getOrteForCampaign(String campaignId) =>
      _ortRepo.findByCampaign(campaignId);

  Future<Ort> createOrt(Ort ort) => _ortRepo.create(ort);

  Future<Ort> updateOrt(Ort ort) =>
      _ortRepo.update(ort.copyWith(updatedAt: DateTime.now()));

  Future<void> deleteOrt(String ortId) => _ortRepo.delete(ortId);

  Future<Ort?> getOrtById(String id) => _ortRepo.findById(id);

  // ── BESUCH ────────────────────────────────────────────────────────────────

  Future<Ort> markVisited(Ort ort, {String? memory}) => _ortRepo.update(
        ort.copyWith(
          lastVisitedAt: DateTime.now(),
          memory: memory ?? ort.memory,
          updatedAt: DateTime.now(),
        ),
      );

  Future<Ort> updateMemory(Ort ort, String memory) => _ortRepo.update(
        ort.copyWith(memory: memory, updatedAt: DateTime.now()),
      );

  // ── SZENEN ────────────────────────────────────────────────────────────────

  Future<List<Scene>> getScenesForOrt(String ortId) =>
      _sceneRepo.findByOrtId(ortId);

  // ── REIHENFOLGE ───────────────────────────────────────────────────────────

  Future<void> reorderOrte(List<Ort> orte) async {
    for (var i = 0; i < orte.length; i++) {
      if (orte[i].sortOrder != i) {
        await _ortRepo.update(
          orte[i].copyWith(sortOrder: i, updatedAt: DateTime.now()),
        );
      }
    }
  }

  // ── TEMPLATE-SYNC (manuell) ───────────────────────────────────────────────

  /// Synchronisiert Definitions-Felder (Name, Typ, Beschreibung) von Template-Orten
  /// in alle verknüpften Kopien. Zustandsfelder (lastVisitedAt, memory) bleiben unberührt.
  Future<SyncResult> syncFromTemplate(String templateCampaignId) async {
    final templateOrte = await _ortRepo.findByCampaign(templateCampaignId);
    int updated = 0;
    int added = 0;

    for (final templateOrt in templateOrte) {
      final copies = await _ortRepo.findByTemplateOrtId(templateOrt.id);
      for (final copy in copies) {
        await _ortRepo.update(copy.copyWith(
          name: templateOrt.name,
          type: templateOrt.type,
          description: templateOrt.description,
          updatedAt: DateTime.now(),
        ));
        updated++;
      }
    }

    debugPrint(
      '[OrtService] Sync: $updated Orte aktualisiert, $added neu angelegt',
    );
    return SyncResult(updated: updated, added: added);
  }

  /// Legt für alle Kampagnen, die von [templateCampaignId] kopiert wurden,
  /// einen neuen Ort an, wenn er noch nicht existiert.
  Future<void> propagateNewOrt(
    Ort templateOrt,
    List<String> copyCampaignIds,
  ) async {
    for (final campaignId in copyCampaignIds) {
      final existing =
          await _ortRepo.findByTemplateOrtId(templateOrt.id);
      final alreadyExists =
          existing.any((o) => o.campaignId == campaignId);
      if (!alreadyExists) {
        await _ortRepo.create(Ort.create(
          campaignId: campaignId,
          name: templateOrt.name,
          type: templateOrt.type,
          description: templateOrt.description,
          sortOrder: templateOrt.sortOrder,
          templateOrtId: templateOrt.id,
        ));
      }
    }
  }
}

class SyncResult {
  final int updated;
  final int added;
  const SyncResult({required this.updated, required this.added});
}
